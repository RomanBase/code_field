import 'package:flutter_control/core.dart';

import 'auth_control.dart';
import 'auth_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      initializers: {
        AuthControl: (_) => AuthControl(),
      },
      states: [
        AppState.main.build((context) => AuthPage()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        home: home,
        title: 'Code Field',
        theme: ThemeData(
          backgroundColor: Colors.white,
          primaryColor: Colors.lightBlueAccent,
          primaryColorDark: Colors.blueAccent,
        ),
      ),
    );
  }
}
