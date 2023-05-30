// file: city_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class CityBloc extends Cubit<List<String>> {
  CityBloc() : super([]);

  void addCity(String city) {
    if (!state.contains(city)) {
      emit([...state, city]);
    }
  }
}
