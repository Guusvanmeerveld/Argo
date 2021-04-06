import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:futuristic/futuristic.dart';

import 'package:argo/main.dart';
import 'package:argo/src/utils/hive/adapters.dart';

import 'package:argo/src/ui/components/Card.dart';
import 'package:argo/src/ui/components/Utils.dart';
import 'package:argo/src/ui/components/ListTileBorder.dart';
import 'package:argo/src/ui/components/AppPage.dart';
import 'package:argo/src/ui/components/EmptyPage.dart';
import 'package:argo/src/ui/components/CircleShape.dart';
import 'package:argo/src/ui/components/ContentHeader.dart';

class CijferTile extends StatelessWidget {
  final Cijfer cijfer;
  final bool isRecent;
  final Border border;

  CijferTile(this.cijfer, {this.isRecent, this.border});

  @override
  Widget build(BuildContext build) {
    return ListTileBorder(
      border: border,
      trailing: cijfer.cijfer.length > 4
          ? null
          : Stack(
              children: [
                Text(
                  cijfer.cijfer,
                  style: TextStyle(
                    fontSize: 17,
                    color: cijfer.voldoende ? null : Colors.red,
                  ),
                ),
                Transform.translate(
                  offset: Offset(10, -15),
                  child: Text(
                    "${cijfer.weging}x",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              ],
            ),
      subtitle: cijfer.cijfer.length <= 4
          ? Text(isRecent == null ? formatDate.format(cijfer.ingevoerd) : cijfer.vak.naam)
          : Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                cijfer.cijfer,
              ),
            ),
      title: Text(cijfer.title),
    );
  }
}

class Cijfers extends StatefulWidget {
  @override
  _Cijfers createState() => _Cijfers();
}

class _Cijfers extends State<Cijfers> {
  DateFormat formatDate = DateFormat("dd-MM-y");
  int jaar = 0;

  Widget _buildCijfer(Cijfer cijfer, List cijfersInPeriode) {
    return ListTileBorder(
      border: Border(
        left: greyBorderSide(),
        bottom: cijfersInPeriode.last == cijfer
            ? BorderSide(
                width: 0,
                color: Colors.transparent,
              )
            : greyBorderSide(),
      ),
      title: Text("${cijfer.vak.naam}"),
      subtitle: Text("${formatDate.format(cijfer.ingevoerd)}"),
      trailing: CircleShape(
        child: Text(
          cijfer.cijfer,
          textAlign: TextAlign.center,
          overflow: TextOverflow.fade,
          softWrap: false,
          maxLines: 1,
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CijferPagina(cijfer.vak.id, jaar),
          ),
        );
      },
    );
  }

  Widget _recenteCijfers() {
    return RefreshIndicator(
      onRefresh: () async {
        await handleError(account.magister.cijfers.recentCijfers, "Kon cijfers niet verversen", context);
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: account.recenteCijfers.isEmpty
            ? EmptyPage(
                text: "Nog geen cijfers",
                icon: Icons.looks_6_outlined,
              )
            : SeeCard(
                column: [
                  for (Cijfer cijfer in account.recenteCijfers)
                    Container(
                      child: CijferTile(cijfer, isRecent: true),
                      decoration: BoxDecoration(
                        border: Border(
                          top: greyBorderSide(),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _tabBar(List<Periode> perioden) {
    return TabBar(
      isScrollable: true,
      tabs: [
        if (jaar == 0) // Recenst
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Tab(
              text: "Recent",
            ),
          ),
        for (Periode periode in perioden)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Tab(
              text: periode.abbr,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Periode> perioden = account.cijfers[jaar].perioden
        .where(
          (periode) => account.cijfers[jaar].cijfers.where((cijfer) => cijfer.periode.id == periode.id).isNotEmpty,
        )
        .toList();

    return ValueListenableBuilder(
      valueListenable: updateNotifier,
      builder: (BuildContext context, _, _a) {
        return DefaultTabController(
          length: jaar == 0 ? 1 + perioden.length : perioden.length,
          child: AppPage(
            bottom: _tabBar(perioden),
            title: Text("Cijfers - ${account.cijfers[jaar].leerjaar}"),
            actions: [
              PopupMenuButton(
                  initialValue: jaar,
                  onSelected: (value) => setState(() => jaar = value),
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry>[
                      for (int i = 0; i < account.cijfers.length; i++)
                        PopupMenuItem(
                          value: i,
                          child: Text('${account.cijfers[i].leerjaar}'),
                        ),
                    ];
                  }),
            ],
            body: TabBarView(
              children: [
                if (jaar == 0) // Recente Cijfers
                  _recenteCijfers(),
                for (Periode periode in perioden)
                  RefreshIndicator(
                    onRefresh: () async => await handleError(
                      account.magister.cijfers.refresh,
                      "Kon cijfers niet verversen",
                      context,
                    ),
                    child: SingleChildScrollView(
                      child: SeeCard(
                        column: () {
                          List cijfersInPeriode = account.cijfers[jaar].cijfers
                              .where(
                                (cijfer) => cijfer.periode.id == periode.id,
                              )
                              .toList();

                          return [for (Cijfer cijfer in cijfersInPeriode) _buildCijfer(cijfer, cijfersInPeriode)];
                        }(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CijferPagina extends StatefulWidget {
  final int id;
  final int jaar;
  CijferPagina(this.id, this.jaar);
  @override
  _CijferPagina createState() => _CijferPagina(id, jaar);
}

class _CijferPagina extends State<CijferPagina> {
  CijferJaar jaar;
  List<Cijfer> cijfers;
  Vak vak;
  double doubleCijfers;
  List<double> avgCijfers;
  double totalWeging;

  _CijferPagina(int id, int jaar) {
    this.jaar = account.cijfers[jaar];
    this.cijfers = this.jaar.cijfers.where((cijfer) => cijfer.vak.id == id).toList();
    this.vak = cijfers.first.vak;

    avgCijfers = [];
    doubleCijfers = 0;
    totalWeging = 0;

    cijfers.reversed.forEach(
      (Cijfer cijfer) {
        if (cijfer.weging == 0 || cijfer.weging == null) return;
        double cijf;
        try {
          cijf = double.parse(cijfer.cijfer.replaceFirst(",", "."));
        } catch (e) {}
        if (cijf != null) {
          doubleCijfers += cijf * cijfer.weging;
          totalWeging += cijfer.weging;
          avgCijfers.add(doubleCijfers / totalWeging);
        }
      },
    );
  }

  Widget _buildPeriode(Periode periode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: () {
        List<Cijfer> periodecijfers = cijfers
            .where(
              (cijf) => cijf.periode.id == periode.id,
            )
            .toList();
        if (periodecijfers.isEmpty)
          return <Widget>[];
        else
          return [
            ContentHeader(periode.naam),
            SeeCard(
              column: [
                for (Cijfer cijfer in periodecijfers)
                  Futuristic(
                    autoStart: true,
                    futureBuilder: () => account.magister.cijfers.getExtraInfo(cijfer, jaar),
                    busyBuilder: (context) => CircularProgressIndicator(),
                    errorBuilder: (context, error, retry) {
                      return Text("Error $error");
                    },
                    dataBuilder: (context, data) => CijferTile(
                      cijfer,
                      border: periodecijfers.last != cijfer
                          ? Border(
                              bottom: greyBorderSide(),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ];
      }(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          vak.naam,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.flag,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.calculate,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (avgCijfers.isNotEmpty)
              SizedBox(
                height: 200.0,
                child: charts.LineChart(
                  _createCijfers(),
                ),
              ),
            for (Periode periode in jaar.perioden) _buildPeriode(periode),
          ],
        ),
      ),
    );
  }

  List<charts.Series<double, int>> _createCijfers() {
    return [
      new charts.Series<double, int>(
        id: 'Cijfers',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (double cijfer, i) => i,
        measureFn: (double cijfer, _) => cijfer,
        displayName: "Gemiddelde",
        data: avgCijfers,
      )
    ];
  }
}
