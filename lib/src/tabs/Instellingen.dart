part of main;

class Instellingen extends StatefulWidget {
  static const title = 'Settings';
  static const androidIcon = Icon(Icons.settings);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<Instellingen> {
  Widget build(BuildContext context) {
    var darkThemeOpt = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 15, top: 20),
          child: Text(
            "Uiterlijk",
            style: TextStyle(color: Colors.orange),
          ),
        ),
        ListTile(
          title: Text('Donker thema'),
          // The Material switch has a platform adaptive constructor.
          trailing: Switch.adaptive(
            value: darkThemeOpt,
            onChanged: (value) {
              setState(() => darkThemeOpt = value);
              DynamicTheme.of(context).setBrightness(value ? Brightness.dark : Brightness.light);
            },
          ),
        ),
      ],
    );
  }
}