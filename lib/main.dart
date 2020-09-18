import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'HomeScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final primaryColor = Color(0xFF2B7A83);
  final accentColor = Color(0xFFe0f7fa);
  final bkgColorLight = Color(0xFF4fb3bf);
  final bkgColorDark = Color(0xFF00363a);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: primaryColor, //Color(0xFF37474F),
          accentColor: accentColor,
          primaryColorLight: bkgColorLight,
          primaryColorDark: bkgColorDark,
          textTheme: Typography.material2018().white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme( color: Colors.white.withOpacity(0.1), shadowColor: Colors.white.withOpacity(0.0))
        ),
        home: HomeScreenWidget());
  }
}
