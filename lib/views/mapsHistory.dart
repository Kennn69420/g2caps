import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:objct_recog_try/views/mapsFav.dart';

class MapsSetting extends StatefulWidget {
  final Function(int) onDoubleTapCallback;

  const MapsSetting({super.key, required this.onDoubleTapCallback});

  @override
  State<MapsSetting> createState() => _MapsSettingState();
}

class _MapsSettingState extends State<MapsSetting> {
  late Box recentLocationsBox;
  List<Map<String, dynamic>> loc_history = [];

  @override
  void initState() {
    super.initState();
    openHiveBox();
  }

  // Open the Hive box to access the recent locations
  Future<void> openHiveBox() async {
    recentLocationsBox = await Hive.openBox('recentLocations');
    load_history();
  }

  // Load recent locations from Hive
  void load_history() {
    final locations = recentLocationsBox.values.toList();
    setState(() {
      loc_history = locations.map((location) {
        // Check if the location has a valid structure
        return {
          'name': location['name'] ?? 'Unknown Location',
          'lat': location['lat'] ?? 0.0,
          'lng': location['lng'] ?? 0.0,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: loc_history.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      // Remove from Hive and UI
                      setState(() {
                        recentLocationsBox.deleteAt(index);
                        loc_history.removeAt(index); // Remove item from list
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${loc_history[index]['name']} deleted'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: TodoItem(title: loc_history[index]['name'] ?? 'Unknown'),
                  );
                },
              ),
            ),
            // const Text(
            //   'ADD TO',
            //   style: TextStyle(
            //       color: Colors.black,
            //       fontWeight: FontWeight.bold,
            //       fontSize: 20),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => MapsFav(onDoubleTapCallback: widget.onDoubleTapCallback,)),
                      );
                    },
                    leading: const Icon(
                      Icons.favorite_border,
                      size: 40,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Favorite',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8), // Space between title and description
                        Text(
                          '0 Places',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: Align(
      //   alignment: Alignment.bottomCenter,
      //   child: Padding(
      //     padding: const EdgeInsets.only(bottom: 16.0),
      //     child: FloatingActionButton(
      //       onPressed: () {
      //         // Handle mic button press
      //       },
      //       backgroundColor: Colors.lightBlue,
      //       child: const Icon(Icons.mic),
      //     ),
      //   ),
      // ),
    );
  }
}

class TodoItem extends StatelessWidget {
  final String title;

  const TodoItem({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
