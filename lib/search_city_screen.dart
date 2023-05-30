// file: search_city_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rattrapage_promo/bloc/city_bloc.dart';

class SearchCityScreen extends StatefulWidget {
  @override
  _SearchCityScreenState createState() => _SearchCityScreenState();
}

class _SearchCityScreenState extends State<SearchCityScreen> {
  final cityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une ville'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: 'Selectionner le nom d une ville',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CityBloc>().addCity(cityController.text);
                Navigator.pushNamed(context, '/cityList');
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }
}
