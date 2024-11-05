import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:objct_recog_try/data/task.dart';
import 'package:objct_recog_try/views/HomeScreen.dart';
import 'package:objct_recog_try/views/addScreen.dart';
import 'package:objct_recog_try/views/camera_view.dart';
import 'package:objct_recog_try/views/task_home.dart';
import 'package:workmanager/workmanager.dart';
import 'views/TextScanner.dart';
import 'views/maps.dart';
import 'views/translate_screen.dart';
import 'widgets/botNavBar.dart'; 


void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  AwesomeNotifications().initialize(
    null, 
    [
      NotificationChannel(
        channelKey: 'basic_channel', 
        channelName: 'Basic Notifications', 
        channelDescription: 'notification for channel basic tests',
        channelShowBadge: true,
        importance: NotificationImportance.High,
        locked: true
      ),
    ],
    debug: true,
  );

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await enableBackgroundExecution();
  
  runApp(obj_recog());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Create the notification using AwesomeNotifications
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: inputData?['title'] ?? 'Reminder',
        body: inputData?['description'] ?? 'This is your background reminder!',
      ),
    );
    print("ok!!!!!!!!!!");
    return Future.value(true); // Indicate task completion success
  });
}


Future<void> enableBackgroundExecution() async {
  var androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Background Service",
    notificationText: "App running in the background",
    notificationImportance: AndroidNotificationImportance.high,
    enableWifiLock: true,
  );

  final hasPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);
  if (hasPermissions) {
    await FlutterBackground.enableBackgroundExecution();
  }
}

void stopBackgroundExecution() {
  FlutterBackground.disableBackgroundExecution();
}

class obj_recog extends StatefulWidget {
  const obj_recog({super.key});

  @override
  _obj_recogState createState() => _obj_recogState();
}

class _obj_recogState extends State<obj_recog> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onBottomNavBarTapped(int index) {
    if (_currentIndex == 0 && index != 0) {
      final cameraViewState = context.findAncestorStateOfType<CameraViewState>();
      cameraViewState?.controller.disposeCamera();
    }

    setState(() {
      _currentIndex = index;
    });
    
    _pageController.jumpToPage(index);

    if (index == 0) {
      final cameraViewState = context.findAncestorStateOfType<CameraViewState>();
      cameraViewState?.controller.initCamera();
    }
  }
  void _changeIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
    _pageController.jumpToPage(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            CameraView(
              onDoubleTapCallback: (index) => _changeIndex(index),
            ),
            MapsTrack(
              onDoubleTapCallback: (index) => _changeIndex(index),
            ),
            TextScanner(
              onDoubleTapCallback: (index) => _changeIndex(index),
            ),
            translate_screen(
              onDoubleTapCallback: (index) => _changeIndex(index),
            ),
            ToDoScreen(
              onDoubleTapCallback: (index) => _changeIndex(index),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          currentIndex: _currentIndex,
          onTap: _onBottomNavBarTapped,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
