// file: city_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rattrapage_promo/bloc/city_bloc.dart';
import 'city_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String getWeatherIconPath(int weatherCode) {
  switch (weatherCode) {
    case 0:
      return 'icons/sunlight.svg';
    case 1:
    case 2:
    case 3:
      return 'icons/sun-cloud.svg';
    case 45:
    case 48:
      return 'icons/haze.svg';
    case 51:
    case 53:
    case 55:
      return 'icons/rain-drops-1.svg';
    case 56:
    case 57:
      return 'icons/sprinkle.svg';
    case 61:
    case 63:
    case 65:
      return 'icons/rain-3.svg';
    case 66:
    case 67:
      return 'icons/snow-1.svg';
    case 71:
    case 73:
    case 75:
      return 'icons/snow-2.svg';
    case 77:
      return 'icons/snow.svg';
    case 80:
    case 81:
    case 82:
      return 'icons/rain.svg';
    case 85:
    case 86:
      return 'icons/snow-2.svg';
    case 95:
    case 96:
    case 99:
      return 'icons/thunderstorm.svg';
  // Ajoutez plus de cas ici pour chaque code météo que vous avez
    default:
      return 'icons/umbrella-1.svg';  // une icône par défaut pour les codes météo inconnus
  }
}

String getWeatherDescription(int weatherCode) {
  switch (weatherCode) {
    case 0:
      return "Aujourd'hui le temps est ensoleillé";
    case 1:
    case 2:
    case 3:
      return 'Peu nuageux';
    case 45:
    case 48:
      return 'Brume';
    case 51:
    case 53:
    case 55:
      return 'Pluie légère';
    case 56:
    case 57:
      return 'Pluie fine';
    case 61:
    case 63:
    case 65:
      return 'Pluie forte';
    case 66:
    case 67:
      return 'Neige légère';
    case 71:
    case 73:
    case 75:
      return 'Neige modérée';
    case 77:
      return 'Neige';
    case 80:
    case 81:
    case 82:
      return 'Pluie torrentielle';
    case 85:
    case 86:
      return 'Neige lourde';
    case 95:
    case 96:
    case 99:
      return 'Orage';
    default:
      return 'Météo inconnue';  // Une description par défaut pour les codes météo inconnus
  }
}


Future<String> getTimezone(double latitude, double longitude) async {
  final apiKey = 'HJZ1238NTGJV';
  final url = 'http://api.timezonedb.com/v2.1/get-time-zone?key=$apiKey&format=json&by=position&lat=$latitude&lng=$longitude';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.isNotEmpty) {
      final zoneName = data['zoneName'];
      print('Timezone result: $zoneName');
      return zoneName;
    }
  }
  throw Exception('Failed to get timezone');
}
Future<Map<String, dynamic>> getWeather(String city) async {
  final locationData = await geocode(city);
  final latitude = locationData['latitude'];
  final longitude = locationData['longitude'];
  final timezone = await getTimezone(latitude, longitude);
  final response = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Weather data: $data');
    return data; // Ici on renvoie la data
  } else {
    throw Exception('Failed to load weather data');
  }
}

Future<Map<String, dynamic>> geocode(String city) async {
  final response = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?city=$city&format=json&limit=1'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    if (data.isNotEmpty) {
      final locationData = {
        'latitude': double.tryParse(data[0]['lat']) ?? 0,
        'longitude': double.tryParse(data[0]['lon']) ?? 0,
      };
      print('Geocoding result: $locationData');
      return locationData;
    }
  }
  throw Exception('Failed to geocode city');
}


class CityListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, List<String>>(
      builder: (context, cityList) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Mes Villes'),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(cityList.map(getWeather)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.data != null) {
                final weatherDataList = snapshot.data!;
                return ListView.builder(
                  itemCount: weatherDataList.length,
                  itemBuilder: (context, index) {
                    final city = cityList[index];
                    final weatherData = weatherDataList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CityDetailScreen(city: city),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(city),
                          subtitle: Text('${weatherData['current_weather']['temperature'] ?? 'N/A'}'),
                          leading: SvgPicture.asset(getWeatherIconPath(weatherData['current_weather']['weathercode'])),
                        ),
                      ),
                    );
                  },
                );
              } else {
                // Gérer le cas où snapshot.data est null
                return Text('Données non disponibles');
              }
            },
          ),
        );
      },
    );
  }
}
