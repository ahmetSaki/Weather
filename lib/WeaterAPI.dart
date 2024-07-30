import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'apiService.dart';

class WeatherApi extends StatefulWidget {
  const WeatherApi({super.key});

  @override
  State<WeatherApi> createState() => _WeatherApiState();
}

class _WeatherApiState extends State<WeatherApi> {
  final TextEditingController cityController = TextEditingController();
  final ApiService apiService = ApiService();
  String city = '';
  Map<String, dynamic>? weatherData;
  List<dynamic>? hourlyWeatherData;
  bool isLoading = false;
  bool isTextEmpty = true;
  String userLocation = "";


  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    setState(() {
      getCurrentLocation();
    });
  }

  void getCurrentLocation() async {
    final hasPermission = await handlePermission();

    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    getAddressFromLatLng(position);
  }

  void getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      setState(() {
        if (cityController.text.isNotEmpty) {
          userLocation = cityController.text;
          fetchWeather();
        } else {
          userLocation = "${place.administrativeArea}";
          city = userLocation;
          fetchWeather();
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void fetchWeather() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await apiService.fetchWeather(city);
      final hourlyData = await apiService.fetchHourlyWeather(city);
      setState(() {
        weatherData = data;
        hourlyWeatherData = hourlyData;
      });
    } catch (e) {
      setState(() {
        weatherData = null;
        hourlyWeatherData = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blue[300],
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: screenSize.width * 0.7,
              child: TextField(
                controller: cityController,
                onChanged: (String value) {
                  setState(() {
                    isTextEmpty = value.isEmpty;
                    city = value;
                  });
                },
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixIcon: isTextEmpty
                      ? null
                      : IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      getCurrentLocation();
                    },
                  ),
                  border: UnderlineInputBorder(),
                  hintText: 'City',
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20.0,
                        offset: Offset(0, 17))
                  ],
                  color: Colors.blue[400]),
              height: screenSize.height * 0.59,
              width: screenSize.width * 0.8,
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userLocation,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.star, color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 80),
                      Image.asset(
                        'assets/partly_cloudy.jpg',
                        width: 142,
                        fit: BoxFit.fill,
                      ),
                      isLoading
                          ? CircularProgressIndicator()
                          : weatherData != null
                          ? Text(
                        '${weatherData!['main']['temp']} °C',
                        style: TextStyle(
                            fontSize: 35, color: Colors.white),
                      )
                          : city.isEmpty
                          ? Container()
                          : Text(
                        'City not found',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  weatherData != null
                      ? Column(
                    children: [
                      Text(
                        'Weather: ${weatherData!['weather'][0]['description']}',
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(
                        width: 17,
                      ),
                      Text(
                        'Humidity: ${weatherData!['main']['humidity']} %',
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(
                        width: 17,
                      ),
                      Text(
                        'Wind: ${weatherData!['wind']['speed']}',
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  )
                      : Container(),
                ],
              ),
            ),

            hourlyWeatherData != null
                ? Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hourlyWeatherData!.length,
                itemBuilder: (context, index) {
                  final hourly = hourlyWeatherData![index];

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.0 , vertical: 21.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 5.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${DateTime.parse(hourly['dt_txt']).hour}:00',
                          style: TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                        Image.asset(
                          'assets/partly_cloudy.jpg', // You can change this based on actual weather condition
                          width: 50,
                          fit: BoxFit.fill,
                        ),
                        Text(
                          '${hourly['main']['temp']} °C',
                          style: TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),

                      ],
                    ),
                  );
                }
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
