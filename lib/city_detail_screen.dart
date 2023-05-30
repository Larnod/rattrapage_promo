import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';


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
      //print('Timezone result: $zoneName');
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
  final response = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&timezone=$timezone&current_weather=true&hourly=temperature_2m,relativehumidity_2m&daily=precipitation_probability_mean,apparent_temperature_max'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    //print('Weather data: $data');
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
      //print('Geocoding result: $locationData');
      return locationData;
    }
  }
  throw Exception('Failed to geocode city');
}

class CityDetailScreen extends StatelessWidget {
  final String city;

  CityDetailScreen({required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$city'),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
          future: getWeather(city),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final weatherData = snapshot.data!;


              List<String> timeList = (weatherData['hourly']['time'] as List<dynamic>).cast<String>();
              List<double> temperatureList = (weatherData['hourly']['temperature_2m'] as List<dynamic>).cast<double>();

              final currentTimestamp = DateTime.now();
              final currentHourIndex = timeList.indexWhere((time) {
                final hourTimestamp = DateTime.parse(time);
                return hourTimestamp.hour == currentTimestamp.hour;
              });

              print(currentHourIndex);
              final next10HoursCount = currentHourIndex + 10;
              final limitedHourIndex = next10HoursCount >= timeList.length ? timeList.length : next10HoursCount;

              List<String> dayList = getDayList(timeList);

              return Column(
                children: <Widget>[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.grey,
                    color: Colors.white,
                    child: Container(
                      height: MediaQuery.of(context).size.height / 7,
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment(-0.5, 0),
                                child: SvgPicture.asset(
                                  getWeatherIconPath(weatherData['current_weather']['weathercode']),
                                  width: MediaQuery.of(context).size.width / 4,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment(0.5, 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      '${weatherData['current_weather']['temperature']}°',
                                      style: TextStyle(fontSize: 45.0, color: Color(0xFF414851)),
                                    ),
                                    Text(
                                      getWeatherDescription(weatherData['current_weather']['weathercode']),
                                      style: TextStyle(fontSize: 20.0, color: Color(0xFF414851)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.grey,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE').format(DateTime.now()),
                          style: TextStyle(fontSize: 25.0, color: Color(0xFF414851)),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height / 8,
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: limitedHourIndex - currentHourIndex,
                            itemBuilder: (context, index) {
                              final temperature = temperatureList[currentHourIndex + index];
                              final timestamp = DateTime.parse(timeList[currentHourIndex + index]);
                              final weatherCode = weatherData['current_weather']['weathercode'];

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Container(
                                  height: MediaQuery.of(context).size.height / 8,
                                  width: 80.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${timestamp.hour}:00',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                      SizedBox(height: 4.0),
                                      SvgPicture.asset(
                                        getWeatherIconPath(weatherCode),
                                        width: 30.0,
                                      ),
                                      SizedBox(height: 4.0),
                                      Text(
                                        '$temperature°C',
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.grey,
                    color: Colors.white,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      child: Column(
                        children: [
                          for (int i = 0; i < 4; i++)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dayList[i],
                                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${getMinTemperatureByDay(weatherData, timeList, temperatureList, i).toStringAsFixed(1)}°C',
                                    style: TextStyle(fontSize: 20.0),
                                  ),
                                  Text(
                                    '${getMaxTemperatureByDay(weatherData, timeList, temperatureList, i).toStringAsFixed(1)}°C',
                                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF414851)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.grey,
                    color: Colors.white,
                    child: Container(
                      height: MediaQuery.of(context).size.height / 4.5,
                      child: GridView.count(
                        crossAxisCount: 2, // Deux colonnes
                        childAspectRatio: 2, // Rectangles
                        padding: EdgeInsets.all(10),
                        children: <Widget>[
                          createRectangle('Chances de pluie', '${weatherData['daily']['precipitation_probability_mean'][0]}%', 'icons/rain-drops-3.svg'),
                          createRectangle("Taux d'humidité", '${weatherData['hourly']['relativehumidity_2m'][currentHourIndex]}%', 'icons/rain.svg'),
                          createRectangle('Vent', '${weatherData['current_weather']['windspeed']} km/h', 'icons/windy-2.svg'),
                          createRectangle('Température ressentie', '${weatherData['daily']['apparent_temperature_max'][0]}°', 'icons/direction-1.svg'),
                        ],
                      ),
                    ),
                  ),
                ],
              );
          }
          },
        ),
      ),
    );
  }

// ... le reste de vos fonctions ici ...

}

  List<String> getDayList(List<String> timeList) {
    List<String> dayList = [];
    for (String time in timeList) {
      DateTime timestamp = DateTime.parse(time);
      String day = DateFormat('EEEE').format(timestamp);
      if (!dayList.contains(day)) {
        dayList.add(day);
      }
    }
    return dayList;
  }

  double getMinTemperatureByDay(
      Map<String, dynamic> weatherData, List<String> timeList, List<double> temperatureList, int dayIndex) {
    String day = getDayList(timeList)[dayIndex];
    double minTemperature = double.infinity;
    for (int i = 0; i < timeList.length; i++) {
      DateTime timestamp = DateTime.parse(timeList[i]);
      String timestampDay = DateFormat('EEEE').format(timestamp);
      if (timestampDay == day) {
        double temperature = temperatureList[i];
        if (temperature < minTemperature) {
          minTemperature = temperature;
        }
      }
    }
    return minTemperature;
  }

  double getMaxTemperatureByDay(
      Map<String, dynamic> weatherData, List<String> timeList, List<double> temperatureList, int dayIndex) {
    String day = getDayList(timeList)[dayIndex];
    double maxTemperature = double.negativeInfinity;
    for (int i = 0; i < timeList.length; i++) {
      DateTime timestamp = DateTime.parse(timeList[i]);
      String timestampDay = DateFormat('EEEE').format(timestamp);
      if (timestampDay == day) {
        double temperature = temperatureList[i];
        if (temperature > maxTemperature) {
          maxTemperature = temperature;
        }
      }
    }
    return maxTemperature;
  }

Widget createRectangle(String title, String value, String imagePath) {
  return Card(
    color: Colors.white, // Vous pouvez choisir la couleur que vous voulez
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(fontSize: 16.0, color: Color(0xFF414851)),
        ),
        SvgPicture.asset(
          imagePath,
          width: 25,
          height: 25,
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16.0, color: Color(0xFF414851)),
        ),
      ],
    ),
  );
}







