import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:objct_recog_try/views/TextScanner.dart';
import 'package:objct_recog_try/views/camera_view.dart';
import 'package:objct_recog_try/views/mapsHistory.dart';
import 'package:objct_recog_try/views/maps_constants.dart';
import 'package:objct_recog_try/views/translate_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

class MapsTrack extends StatefulWidget {
  final Function(int) onDoubleTapCallback;
  final favedestination;

  const MapsTrack(
      {super.key, required this.onDoubleTapCallback, this.favedestination});

  @override
  State<MapsTrack> createState() => _MapsTrackState();
}

class _MapsTrackState extends State<MapsTrack> {
  final Completer<GoogleMapController> _controller = Completer();
  bool isNavigating = false; // State to track if navigation is active

  LatLng sourceLocation = LatLng(16.388844, 119.892884);
  LatLng destination = LatLng(16.160447, 119.973093);
  String? _currentAddress;
  bool map_created = false;

  //hive
  late Box recentLocationsBox;
  late GoogleMapController mapController;

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;
  Set<Marker> markers = {};
  bool hasReachedDestination = false;

  Future<BitmapDescriptor> sourceIcon = BitmapDescriptor.fromAssetImage(
    const ImageConfiguration(size: Size(48, 48)),
    'assets/circle_icon.png',
  );
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  String dest = "";
  List<dynamic> places = [];
  TextEditingController searchController = TextEditingController();
  List<String> navigationSteps = [];
  int currentStepIndex = 0;
  String nextInstruction = '';

  double searchRadiusMeters = 2000;
  String googleApiKey = google_api_key;
  SpeechToText _speechToText = SpeechToText();
  String voice_inp = "";
  bool _speechEnabled = false;

  FlutterTts flutterTts = FlutterTts();

  Future<void> searchNearbyPlaces(String keyword) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${currentLocation!.latitude},${currentLocation!.longitude}&radius=$searchRadiusMeters&keyword=$keyword&key=$googleApiKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data['results'] != null && data['results'].isNotEmpty) {
        setState(() {
          places = data['results'];
        });

        Vibration.vibrate();
        speakConfirm("Navigate");
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Add Task'),
              content:
                  Text('Do you want to navigate to ' + places[0]['name'] + '?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Vibration.vibrate();
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Vibration.vibrate();
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
        if (confirm == true) {
          sourceLocation =
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
          _updateNearestMarker();
          getPolyPoints();
        }
      } else {
        setState(() {
          places = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('No places found within $searchRadiusMeters meters.')),
        );
        speak_not_found();
      }
    } else {
      throw Exception('Failed to load places');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    map_created = true;
  }

  void _zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }

  double calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  void _updateNearestMarker() {
    if (places.isEmpty) return;

    double nearestDistance = double.infinity;
    Map<String, dynamic>? nearestPlace;
    LatLng? nearestPlaceLatLng;

    for (var place in places) {
      var location = place['geometry']['location'];
      LatLng placeLatLng = LatLng(location['lat'], location['lng']);

      double distance = calculateDistance(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          placeLatLng);

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestPlace = place;
        nearestPlaceLatLng = placeLatLng;
        destination =
            LatLng(nearestPlaceLatLng!.latitude, nearestPlaceLatLng.longitude);
      }
    }

    if (nearestPlace != null && nearestPlaceLatLng != null) {
      String placeName = nearestPlace['name'];
      dest = placeName;

      Set<Marker> newMarkers = {
        Marker(
          markerId: MarkerId(nearestPlace['place_id']),
          position: nearestPlaceLatLng,
          infoWindow: InfoWindow(title: placeName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: MarkerId('current loc'),
          position:
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
      };

      setState(() {
        markers = newMarkers;
      });
    }
  }

  //geocoding
  Future<void> _getAddressFromLatLng() async {
    await geocode
        .placemarkFromCoordinates(
            currentLocation!.latitude!, currentLocation!.longitude!)
        .then((List<geocode.Placemark> placemarks) {
      geocode.Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  void searchFor7Eleven() {
    searchNearbyPlaces('7-Eleven');
  }

  void getCurrentLocation() {
    Location location = Location();

    location.getLocation().then((location) {
      currentLocation = location;
      markers.add(
        Marker(
          markerId: const MarkerId("current Location"),
          position:
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        ),
      );
    });

    location.onLocationChanged.listen((newLoc) {
      if (map_created) {
        currentLocation = newLoc;

        // Remove the old marker
        markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation');

        // Add a new marker for the updated current location
        markers.add(
          Marker(
            markerId: const MarkerId("current Location"),
            position:
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            infoWindow: InfoWindow(title: 'Current Location'),
          ),
        );

        // Optional: Animate camera to follow user's movement
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ),
        );

        // Check if the user is near the destination and update as needed
        double distanceToDestination = calculateDistance(
          LatLng(newLoc.latitude!, newLoc.longitude!),
          destination,
        );

        // If near the destination, trigger the arrival event
        if (distanceToDestination < 0.05 && !hasReachedDestination) {
          hasReachedDestination = true;
          String destinationName = markers
                  .firstWhere((m) => m.markerId == MarkerId('destination'))
                  .infoWindow
                  .title ??
              "Unknown Destination";
          addLocationToHistory(destination, destinationName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have reached your destination!')),
          );
          speak_reached();
        }

        setState(() {});
      }
    });
  }

  void addLocationToHistory(LatLng loc, String name) {
    if (recentLocationsBox.length >= 5) {
      recentLocationsBox.deleteAt(0);
    }

    recentLocationsBox
        .add({'lat': loc.latitude, 'lng': loc.longitude, 'name': name});

    // markers.add(Marker(
    //   markerId: MarkerId(name),
    //   position: loc,
    //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    //   infoWindow: InfoWindow(title: name),
    // ));
    setState(() {});
  }

  // Future<void> openHiveBox() async {
  //   recentLocationsBox = await Hive.openBox('recentLocations');
  //   //loadRecentLocations();
  // }

  // void loadRecentLocations() {
  //   final recentLocations = recentLocationsBox.values.toList();
  //   if (recentLocations.isNotEmpty) {
  //     for (var loc in recentLocations) {
  //       LatLng location = LatLng(loc['lat'], loc['lng']);
  //       markers.add(Marker(
  //         markerId: MarkerId(loc['name']),
  //         position: location,
  //         infoWindow: InfoWindow(title: loc['name']),
  //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //       ));
  //     }
  //     setState(() {});
  //   }
  // }

  double totalDistance = 0.0;

  Future<void> getPolyPoints() async {
    polylineCoordinates.clear();

    String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${sourceLocation.latitude},${sourceLocation.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$googleApiKey';

    print("Fetching polyline points from URL: $url");

    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        print("Directions API Response: $data");

        if (data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          var leg = route['legs'][0];
          var encodedPolyline = route['overview_polyline']['points'];

          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result =
              polylinePoints.decodePolyline(encodedPolyline);

          print("Number of polyline points decoded: ${result.length}");

          if (result.isNotEmpty) {
            polylineCoordinates.clear();
            for (var point in result) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }

            // Set navigation steps
            navigationSteps.clear();
            totalDistance = leg['distance']['value'].toDouble();
            for (var step in leg['steps']) {
              String instruction =
                  step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
              navigationSteps.add(instruction);
            }

            if (navigationSteps.isNotEmpty) {
              nextInstruction = navigationSteps[0];
              isNavigating = true;
            }

            setState(() {});

            print("Polyline and navigation steps updated.");
          }
        } else {
          print("No routes found.");
        }
      } else {
        print("Failed to fetch directions: Status Code ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching directions: $error");
    }
  }

  void endNavigation() {
    setState(() {
      totalDistance = 0.0;
      isNavigating = false;
      polylineCoordinates.clear();
      nextInstruction = '';

      markers = {
        Marker(
          markerId: MarkerId('current loc'),
          position:
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
      };
    });
  }

  void setLocation(LatLng loc) {
    markers.add(
      Marker(
        markerId: const MarkerId("destination"),
        position: LatLng(loc.latitude, loc.longitude),
      ),
    );
    sourceLocation =
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    destination = LatLng(loc.latitude, loc.longitude);
    getPolyPoints();
    setState(() {});
  }

  void share_loc() {
    _getAddressFromLatLng();
    Share.share(_currentAddress.toString());
    //print(_currentAddress);
  }

  @override
  void initState() {
    getCurrentLocation();
    getPolyPoints();
    openHiveBox();
    speakNav();
    _initSpeech();
    super.initState();
  }

  Future<void> openHiveBox() async {
    recentLocationsBox = await Hive.openBox('favoriteLocations');
  }

  void saveToFavorite() {
    if (currentLocation != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String inputName = _currentAddress ?? "Unnamed Location";
          return AlertDialog(
            title: const Text("Save to Favorite"),
            content: TextField(
              onChanged: (value) {
                inputName = value;
              },
              decoration: const InputDecoration(
                hintText: "Enter location name",
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text("Save"),
                onPressed: () {
                  // Save the location with the input name
                  LatLng loc = LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!);

                  recentLocationsBox.add({
                    'lat': loc.latitude,
                    'lng': loc.longitude,
                    'name': inputName,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$inputName saved as favorite!')),
                  );

                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maps',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 27),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFFF8E00),
        leading: IconButton(
          onPressed: () async {
            Vibration.vibrate();
            speakConfirm("Do you want to share your location?");
            bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Color(
                      0xFF002347), // Set the background color of the dialog
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  title: Text(
                    'Add Task',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // Bold title text
                  ),
                  content: Text(
                    'Do you want to see your location history?',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceEvenly, // Evenly distribute space
                      children: [
                        TextButton(
                          onPressed: () {
                            Vibration.vibrate();
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 20), 
                        TextButton(
                          onPressed: () {
                            Vibration.vibrate();
                            Navigator.of(context).pop(true);
                          },
                          child: Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
            if (confirm == true) {
              share_loc();
            }
          },
          icon: const Icon(
            Icons.share,
            color: Colors.white,
            size: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () async {
              Vibration.vibrate();
              speakConfirm("Do you want to see your location history?");
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(
                        0xFF002347), // Set the background color of the dialog
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded corners
                    ),
                    title: Text(
                      'Add Task',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white), // Bold title text
                    ),
                    content: Text(
                      'Do you want to see your location history?',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceEvenly, // Evenly distribute space
                        children: [
                          TextButton(
                            onPressed: () {
                              Vibration.vibrate();
                              Navigator.of(context).pop(false);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 20), // Space between buttons
                          TextButton(
                            onPressed: () {
                              Vibration.vibrate();
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                //   Navigator.of(context).push(
                //   MaterialPageRoute(builder: (_) => MapsSetting()),
                // );
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: () {
          Vibration.vibrate();
          _startListening();
        },
        child: currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!),
                      zoom: 15.5,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId("route"),
                        points: polylineCoordinates,
                        color: Color.fromARGB(255, 14, 53, 209),
                        width: 6,
                      ),
                    },
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    markers: markers,
                    onMapCreated: (mapController) {
                      polylineCoordinates.clear();
                      _controller.complete(mapController);
                      isNavigating = false;
                      _getAddressFromLatLng();
                      navigationSteps.clear();
                      _onMapCreated(mapController);
                      totalDistance = 0.0;
                    },
                    //onTap: setLocation,
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.2,
                    minChildSize: 0.1,
                    maxChildSize: 0.5,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10.0,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: isNavigating == false
                            ? Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 24.0),
                                    child: Text(
                                      'No Destination',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 24.0),
                                    child: Text(
                                      'Distance to $dest: $totalDistance meters',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF002347),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(
                                        top: 8.0,
                                        bottom:
                                            16.0), // Add space below the line
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Expanded(
                                    child: isNavigating == false
                                        ? Center(
                                            child: Text(
                                              'No steps yet',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: scrollController,
                                            itemCount: navigationSteps.length,
                                            itemBuilder: (context, index) {
                                              return Card(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 16.0),
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    child: Text(
                                                      (index + 1).toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    navigationSteps[index],
                                                    style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),

                  Positioned(
                    top:
                        270, // Increased from 150 to 250 to move the button lower
                    right: 10,
                    child: FloatingActionButton(
                      backgroundColor: Color(0xFF002347),
                      foregroundColor: Colors.white,
                      onPressed: _zoomIn,
                      child: Icon(
                        Icons.add,
                        size: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    top:
                        350, // Increased from 220 to 320 to move the button lower
                    right: 10,
                    child: FloatingActionButton(
                      backgroundColor: Color(0xFF002347),
                      foregroundColor: Colors.white,
                      onPressed: _zoomOut,
                      child: Icon(
                        Icons.remove,
                        size: 36,
                      ),
                    ),
                  ),

                  // Positioned(
                  //   top: 10,
                  //   left: 15,
                  //   right: 15,
                  //   child: Column(
                  //     children: [
                  //       TextField(
                  //         controller: searchController,
                  //         decoration: InputDecoration(
                  //           hintText: 'Search Places (e.g., 7-Eleven)',
                  //           filled: true,
                  //           fillColor: Colors.white,
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10),
                  //             borderSide: BorderSide.none,
                  //           ),
                  //           contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  //           suffixIcon: IconButton(
                  //             icon: Icon(Icons.search),
                  //             onPressed: () {
                  //               searchNearbyPlaces(searchController.text);
                  //             },
                  //           ),
                  //         ),
                  //       ),
                  //       ElevatedButton(
                  //         onPressed: searchFor7Eleven,
                  //         child: Text('Find Nearest 7-Eleven'),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  if (isNavigating)
                    Positioned(
                      top:
                          kToolbarHeight, // Adjust this to position below the AppBar
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: endNavigation,
                          child: Text('End Navigation'),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void speakNav() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You are in the Maps Screen");
  }

  void speak_not_found() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("No places found within 2000 meters");
  }

  void speak_reached() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You've Reached Your Destination");
  }

  void speak_instruction(speak) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(speak);
  }

  void speakConfirm(text) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult1);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult1(SpeechRecognitionResult result) {
    setState(() {
      voice_inp = result.recognizedWords;
      if (voice_inp == "end navigation" ||
          voice_inp == "and navigation" ||
          voice_inp == "end") {
        endNavigation();
        print("navigation ended");
      } else if (voice_inp == "save to favorite" ||
          voice_inp == "add to favorite" ||
          voice_inp == "save to favorites" ||
          voice_inp == "add to favorites") {
        saveToFavorite();
      } else if (voice_inp == "share location" ||
          voice_inp == "share my location" ||
          voice_inp == "location share") {
        share_loc();
      } else if (voice_inp != "") {
        searchNearbyPlaces(voice_inp);
        print(voice_inp);
      }
    });
  }

  void nav_to_other(voice) {
    if (voice == "object" || voice == "go to object") {
      widget.onDoubleTapCallback(0);
    } else if (voice == "maps" || voice == "go to maps") {
      widget.onDoubleTapCallback(1);
    } else if (voice == "scanner" || voice == "go to scanner") {
      widget.onDoubleTapCallback(2);
    } else if (voice == "to do" || voice == "go to todo") {
      widget.onDoubleTapCallback(4);
    } else {
      print(voice_inp);
    }
  }
}
