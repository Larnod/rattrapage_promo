import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rattrapage_promo/bloc/city_bloc.dart';
import 'package:rattrapage_promo/navigation_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: BlocProvider<CityBloc>(
        create: (context) => CityBloc(),
        child: NavigationScreen(),
      ),
    );
  }
}
