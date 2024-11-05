import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:objct_recog_try/views/maps.dart';

class MapsFav extends StatefulWidget {
  final Function(int) onDoubleTapCallback;

  const MapsFav({super.key, required this.onDoubleTapCallback});

  @override
  State<MapsFav> createState() => _MapsFavState();
}

class _MapsFavState extends State<MapsFav> {
  List<Map<String, dynamic>> favoriteItems = [];
  late Box recentLocationsBox;

  @override
  void initState() {
    super.initState();
    openHiveBox();
  }

  Future<void> openHiveBox() async {
    recentLocationsBox = await Hive.openBox('favoriteLocations');
    loadFavorites();
  }

  void loadFavorites() {
    final favorites = recentLocationsBox.values.toList();
    setState(() {
      favoriteItems = favorites.cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently Added',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            Expanded(
              child: favoriteItems.isEmpty
                  ? const Center(child: Text('No favorites added'))
                  : ListView.builder(
                      itemCount: favoriteItems.length,
                      itemBuilder: (context, index) {
                        final favorite = favoriteItems[index];
                        final title = favorite['name'] ?? 'Unknown Location';
                        final lat = favorite['lat'];
                        final lng = favorite['lng'];

                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              recentLocationsBox.deleteAt(index);
                              favoriteItems.removeAt(index);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorite deleted'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapsTrack(
                                    onDoubleTapCallback: widget.onDoubleTapCallback,
                                    favedestination: LatLng(lat, lng),
                                  ),
                                ),
                              );
                            },
                            child: TodoItem(title: title),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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
