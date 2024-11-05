import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:objct_recog_try/data/task.dart';
import 'package:objct_recog_try/data/tasks.dart';
import 'package:objct_recog_try/views/addScreen.dart';
import 'package:objct_recog_try/views/filter.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:workmanager/workmanager.dart';

class ToDoScreen extends StatefulWidget {
  final Function(int) onDoubleTapCallback;

  const ToDoScreen({super.key, required this.onDoubleTapCallback});

  @override
  _ToDoScreen createState() => _ToDoScreen();
}

class _ToDoScreen extends State<ToDoScreen> {
  late Box<Task> taskBox;
  bool? filterCompleted;
  FlutterTts flutterTts = FlutterTts();
  SpeechToText _speechToText = SpeechToText();
  String voice_inp = "";
  bool _light = false;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
    _requestNotificationPermission();
    speakNav();
    //_initSpeech();
    //taskBox.clear();
  }

  void torchlightOpen() async {
    if (_light == false) {
      await TorchLight.enableTorch();
    }
    setState(() {
      _light = true;
    });
  }

  void torchlightClose() async {
    if (_light == true) {
      await TorchLight.disableTorch();
    }
    setState(() {
      _light = false;
    });
  }

  void applyFilter(bool? completed) {
    setState(() {
      filterCompleted = completed;
    });
  }

  void isCompleted(int index, bool? value) {
    setState(() {
      final task = taskBox.getAt(index)!;
      task.isCompleted = value ?? false; // Update the completion status
      taskBox.putAt(index, task); // Update in Hive
    });
  }

  void scheduleNotification(Task task) {
    if (task.hasReminder) {
      final DateTime scheduledDateTime =
          DateFormat('yyyy-MM-dd hh:mm a').parse('${task.date} ${task.time}');

      if (scheduledDateTime.isAfter(DateTime.now())) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: taskBox.getAt(taskBox.values.toList().indexOf(task)).hashCode,
              channelKey: 'basic_channel',
              title: task.title,
              body: task.description ?? 'Task reminder',
              displayOnBackground: true,
              displayOnForeground: true,
              locked: true),
          schedule: NotificationCalendar.fromDate(date: scheduledDateTime),
        );
      } else {
        print('Scheduled time is not in the future');
      }
    }
  }

  void scheduleBackgroundNotification(Task task) {
    final DateTime scheduledDateTime =
        DateFormat('yyyy-MM-dd hh:mm a').parse('${task.date} ${task.time}');

    if (scheduledDateTime.isAfter(DateTime.now())) {
      Workmanager().registerOneOffTask(
        'task_${task.hashCode}',
        'notificationTask', // The task name
        inputData: {
          'title': task.title,
          'description': task.description ?? 'Task reminder',
        },
        initialDelay:
            scheduledDateTime.difference(DateTime.now()), // Schedule delay
        constraints: Constraints(
          networkType: NetworkType.not_required, // No network constraint
          requiresBatteryNotLow: false, // Doesn't require low battery
          requiresCharging: false, // Doesn't require charging
          requiresDeviceIdle: false, // Doesn't require idle
        ),
      );
    }
  }

  void _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        Vibration.vibrate();
        //print("you double tap");
        if (_speechToText.isNotListening) {
          _startListening();
        } else {
          _stopListening();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'To Do List',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFFFF8E00),
          actions: [
            IconButton(
              color: Colors.white,
              onPressed: () async {
                Vibration.vibrate();
                speakConfirm("Do you want to delete this task/tasks");
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
                        'Delete Task',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Title text color
                        ),
                      ),
                      content: Text(
                        'Do you want to delete this task/tasks?',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white, // Content text color
                        ),
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
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.white, // Text color for button
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded button corners
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize:
                                        15), // Optional: adjust the font size
                              ),
                            ),
                            SizedBox(width: 20), // Space between buttons
                            TextButton(
                              onPressed: () {
                                Vibration.vibrate();
                                Navigator.of(context).pop(true);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.white, // Text color for button
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded button corners
                                ),
                              ),
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                    fontSize:
                                        15), // Optional: adjust the font size
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  setState(() {
                    final tasksToRemove = taskBox.values
                        .where((task) => task.isCompleted)
                        .toList();

                    for (var task in tasksToRemove) {
                      final index = taskBox.values.toList().indexOf(task);
                      taskBox.deleteAt(index);
                    }
                  });
                }
              },
              icon: const Icon(
                Icons.delete,
                size: 30,
              ),
            ),
          ],
          leading: IconButton(
            color: Colors.white,
            onPressed: () async {
              Vibration.vibrate();
              speakConfirm("Do you want to filter tasks?");
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
                      'Filter Task',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Title text color
                      ),
                    ),
                    content: Text(
                      'Do you want to filter tasks?',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white, // Content text color
                      ),
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
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white, // Text color for button
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8), // Rounded button corners
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize:
                                      15), // Optional: adjust the font size
                            ),
                          ),
                          SizedBox(width: 20), // Space between buttons
                          TextButton(
                            onPressed: () {
                              Vibration.vibrate();
                              Navigator.of(context).pop(true);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white, // Text color for button
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8), // Rounded button corners
                              ),
                            ),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                  fontSize:
                                      15), // Optional: adjust the font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => filterScreen(
                      applyFilter: applyFilter,
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.filter_list,
              size: 35,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFFF3F4F6), // Background color for the entire body
          ),
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
            valueListenable: taskBox.listenable(),
            builder: (context, Box<Task> box, _) {
              final filteredTasks = box.values.where((task) {
                if (filterCompleted == null) return true;
                return task.isCompleted == filterCompleted;
              }).toList();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: Text(
                    'No tasks yet.',
                    style: TextStyle(fontSize: 22),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return GestureDetector(
                    onTap: () async {
                      final updatedTask = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TodoScreen(
                            existingTask: task,
                            task_index: index,
                          ),
                        ),
                      );

                      if (updatedTask != null) {
                        scheduleBackgroundNotification(updatedTask);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFFF002347), // Card background color
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Color(0xFF002347)), // Border color
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TodoItem(
                          title: task.title,
                          description: task.description,
                          time: task.time,
                          date: task.date,
                          isCompleted: task.isCompleted,
                          onChanged: (bool? value) {
                            isCompleted(index, value);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFF002347),
          foregroundColor: Color(0xFFF3F4F6),
          onPressed: () async {
            Vibration.vibrate();
            speakConfirm("Do you want to add a new task?");
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
                    'Do you want to add a new task?',
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
              final newTask = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TodoScreen()),
              );
              if (newTask != null) {
                scheduleNotification(newTask);
              }
            }
          },
          child: Icon(Icons.add_outlined),
        ),
      ),
    );
  }

  // Positioned(
  //   bottom: 5,
  //   right: 0,
  //   child: FloatingActionButton(
  //     backgroundColor: Color(0xFF002347),
  //     foregroundColor: Colors.white,
  //     onPressed: () {},
  //     child: Icon(Icons.flashlight_on),
  //   ),
  // ),
  void speakNav() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You are in the To-Do List Screen");
  }

  void speakConfirm(text) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  // void _initSpeech() async {
  //   _speechEnabled = await _speechToText.initialize();
  //   setState(() {

  //   });
  // }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() async {
      voice_inp = result.recognizedWords;
      if (voice_inp == "open flashlight") {
        torchlightOpen();
      } else if (voice_inp == "close flashlight") {
        torchlightClose();
      } else if (voice_inp == "add" || voice_inp == "add to do") {
        print("add!!!!!!!!!!");
        final newTask = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TodoScreen()),
        );
        if (newTask != null) {
          scheduleNotification(newTask);
        }
      } else if (voice_inp != "") {
        print(voice_inp);
        nav_to_other(voice_inp);
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
