import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'HomeScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final accentColor = Color(0xFFb3e5fc);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Color(0xFF1F8FAB), //Color(0xFF37474F),
          accentColor: accentColor,
          textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white),
              bodyText1: TextStyle(color: Colors.white),
              subtitle1: TextStyle(color: Colors.white)),
          scaffoldBackgroundColor: Color(0xFF1F8FAB),//Color(0xFFF3F5F7),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme( color: Colors.white.withOpacity(0.1), shadowColor: Colors.white.withOpacity(0.0))
        ),
        home: HomeScreenWidget());
  }
}
