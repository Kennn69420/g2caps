import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:objct_recog_try/data/task.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

class TodoScreen extends StatefulWidget {
  final Task? existingTask;
  final int? task_index;
  TodoScreen({this.existingTask, this.task_index});
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool hasReminder = true;
  late Box<Task> taskBox;
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  FlutterTts flutterTts = FlutterTts();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    speakNav();
    taskBox = Hive.box<Task>('tasks');

    if (widget.existingTask != null) {
      titleController.text = widget.existingTask!.title;
      descriptionController.text = widget.existingTask!.description;
      String timeString = widget.existingTask!.time.trim();
      try {
        final parsedTime = DateFormat.jm().parse(timeString);
        selectedTime = TimeOfDay.fromDateTime(parsedTime);
      } catch (e) {
        print('Error parsing time: $e');
      }
      selectedDate = DateFormat('yyyy-MM-dd').parse(widget.existingTask!.date);
      hasReminder = widget.existingTask!.hasReminder;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        Vibration.vibrate();
        if (_speechToText.isNotListening) {
          _startListening();
        } else {
          _stopListening();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFF8E00),
          elevation: 0,
          title: Text('Create Task', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title TextField
                Container(
                  height: 100, // Adjust the height as needed
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF002347)),
                  ),
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: TextStyle(color: Color(0xFF002347), fontSize: 22, fontWeight: FontWeight.bold),
                      floatingLabelBehavior:
                          FloatingLabelBehavior.always, // Always float label
                      alignLabelWithHint: true, // Align label with hint
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 10.0),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        onPressed: _speechToText.isNotListening
                            ? _startListeningTitle
                            : _stopListening,
                        tooltip: 'Listen',
                        icon: Icon(Icons.mic, color: Color(0xFF002347)),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                // Description TextField
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color:
                        Color(0xFFF3F4F6), // Background color for the TextField
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF002347)),
                    // Border color
                  ),
                  child: TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: Color(0xFF002347), fontSize: 22, fontWeight: FontWeight.bold),
                      floatingLabelBehavior:
                          FloatingLabelBehavior.always, // Always float label
                      alignLabelWithHint: true, // Label color
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 10.0), // Padding for the text
                      border: InputBorder.none, // Remove default border
                      focusedBorder:
                          InputBorder.none, // Remove default focused border
                      suffixIcon: IconButton(
                        onPressed: _speechToText.isNotListening
                            ? _startListeningDescription
                            : _stopListening,
                        tooltip: 'Listen',
                        icon: Icon(Icons.mic,
                            color: Color(0xFF002347)), // Microphone icon color
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6), // Background color for the tile
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Color(0xFF002347)), // Border color
                  ),
                  child: ListTile(
                    title: Text(
                      "Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                      style: TextStyle(
                          color: Color(0xFF002347), fontWeight: FontWeight.bold), // Title text color
                    ),
                    trailing: Icon(Icons.calendar_today,
                        color: Color(0xFF002347)), // Calendar icon color
                    onTap: () => _selectDate(context),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6), // Background color for the tile
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Color(0xFF002347)), // Border color
                  ),
                  child: ListTile(
                    title: Text(
                      "Select Time: ${selectedTime.format(context)}",
                      style: TextStyle(
                          color: Color(0xFF002347), fontWeight: FontWeight.bold), // Title text color
                    ),
                    trailing: Icon(Icons.access_time,
                        color: Color(0xFF002347)), // Clock icon color
                    onTap: () => _selectTime(context),
                  ),
                ),
                SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,// Full width
                  child: ElevatedButton(
                    onPressed: () async {
                      Vibration.vibrate();
                      speakConfirm("Are you sure you want to add this task?");
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor:
                                Color(0xFF002347), // Dialog background color
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // Rounded corners
                            ),
                            title: Text(
                              'Add Task',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Title text color
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to add this task?',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white, // Content text color
                              ),
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly, // Evenly spaced buttons
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Vibration.vibrate();
                                      Navigator.of(context).pop(false);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white, // Text color
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8), // Rounded button corners
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style:
                                          TextStyle(fontSize: 15), // Font size
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Vibration.vibrate();
                                      Navigator.of(context).pop(true);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white, // Text color
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8), // Rounded button corners
                                      ),
                                    ),
                                    child: Text(
                                      'Confirm',
                                      style:
                                          TextStyle(fontSize: 15), // Font size
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                      if (titleController.text.isNotEmpty && confirm == true) {
                        final updatedTask = Task(
                          title: titleController.text,
                          description: descriptionController.text,
                          time: selectedTime.format(context),
                          date: DateFormat('yyyy-MM-dd').format(selectedDate),
                          isCompleted: false,
                          hasReminder: hasReminder,
                        );
                        if (widget.existingTask != null) {
                          await taskBox.putAt(widget.task_index!, updatedTask);
                        } else {
                          await taskBox.add(updatedTask);
                        }
                        titleController.clear();
                        descriptionController.clear();
                        Navigator.of(context).pop(updatedTask);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF002347), // Button background color
                      foregroundColor: Colors.white, // Button text color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                    ),
                    child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void speakConfirm(text) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _startListeningTitle() async {
    Vibration.vibrate();
    await _speechToText.listen(onResult: _onSpeechResultTitle);
    setState(() {});
  }

  void _startListeningDescription() async {
    Vibration.vibrate();
    await _speechToText.listen(onResult: _onSpeechResultDescription);
    setState(() {});
  }

  void _startListeningTime() async {
    Vibration.vibrate();
    await _speechToText.listen(onResult: _onSpeechResultTime);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    String recognizedWords = result.recognizedWords.toLowerCase();
    print(recognizedWords);

    if (recognizedWords.startsWith("set time to")) {
      _detectTimeCommand(recognizedWords);
    } else if (recognizedWords.startsWith("set date to")) {
      _detectDateCommand(recognizedWords);
    } else if (recognizedWords.startsWith("set title to")) {
      _detectTitleCommand(recognizedWords);
    } else if (recognizedWords.startsWith("set description to")) {
      _detectDescriptionCommand(recognizedWords);
    } else if (recognizedWords == "save" || recognizedWords == "save task") {
      if (titleController.text.isNotEmpty) {
        final updatedTask = Task(
          title: titleController.text,
          description: descriptionController.text,
          time: selectedTime.format(context),
          date: DateFormat('yyyy-MM-dd').format(selectedDate),
          isCompleted: false,
          hasReminder: hasReminder,
        );
        if (widget.existingTask != null) {
          await taskBox.putAt(widget.task_index!, updatedTask);
        } else {
          await taskBox.add(updatedTask);
        }
        titleController.clear();
        descriptionController.clear();
        Navigator.of(context).pop(updatedTask);
      }
    } else if (recognizedWords == "what is the time now" ||
        recognizedWords == "time" ||
        recognizedWords == "time now" ||
        recognizedWords == "anong oras na") {
      DateTime now = DateTime.now();
      String formattedTime = DateFormat('h:mm a').format(now);
      flutterTts.speak("The time now is $formattedTime");
      print("okayyyyyy!!!!!!");
    } else if (recognizedWords == "what is the date today" ||
        recognizedWords == "date" ||
        recognizedWords == "anong date ngayon") {
      DateTime now = DateTime.now();
      String formattedDate =
          DateFormat('EEEE, MMMM d, yyyy').format(now); // Format the date
      flutterTts.speak("Today is $formattedDate"); // Speak out the current date
    } else if (recognizedWords == "tang ina mo" ||
        recognizedWords == "tang ina") {
      flutterTts.setLanguage('fil-PH');
      flutterTts.speak("Tang ina mo rin");
      flutterTts.setLanguage('en-US');
    } else if (recognizedWords == "g*** ka" ||
        recognizedWords == "g***" ||
        recognizedWords == "ay g***") {
      flutterTts.setLanguage('fil-PH');
      flutterTts.speak("mas Gago ka");
      flutterTts.setLanguage('en-US');
    } else if (recognizedWords == "tanga") {
      flutterTts.setLanguage('fil-PH');
      flutterTts.speak("mas tanga ka");
      flutterTts.setLanguage('en-US');
    } else if (recognizedWords == "bobo") {
      flutterTts.setLanguage('fil-PH');
      flutterTts.speak("walang taong bobo maliban sayo");
      flutterTts.setLanguage('en-US');
    } else if (recognizedWords == "iu") {
      //flutterTts.setLanguage('fil-PH');
      flutterTts.speak("the world's cutest");
      //flutterTts.setLanguage('en-US');
    } else {
      print("Invalid input");
    }
  }

  void _onSpeechResultTitle(SpeechRecognitionResult result) {
    setState(() {
      titleController.text = result.recognizedWords;
    });
  }

  void _onSpeechResultTime(SpeechRecognitionResult result) {
    _detectTimeCommand(result.recognizedWords);
  }

  void _onSpeechResultDescription(SpeechRecognitionResult result) {
    setState(() {
      descriptionController.text = result.recognizedWords;
      //_detectTimeCommand(result.recognizedWords);
    });
  }

  void _detectTitleCommand(String recognizedWords) {
    final RegExp titleRegex =
        RegExp(r"set title to (.+)", caseSensitive: false);
    final match = titleRegex.firstMatch(recognizedWords);

    if (match != null) {
      String title = match.group(1)!.trim();

      if (title.isNotEmpty) {
        title = title[0].toUpperCase() + title.substring(1).toLowerCase();
      }

      setState(() {
        titleController.text = title;
      });

      print("Title set to: $title");
    } else {
      print("Invalid title format or unrecognized input.");
    }
  }

  void _detectDescriptionCommand(String recognizedWords) {
    final RegExp descRegex =
        RegExp(r"set description to (.+)", caseSensitive: false);
    final match = descRegex.firstMatch(recognizedWords);

    if (match != null) {
      String desc = match.group(1)!.trim();

      setState(() {
        descriptionController.text = desc;
      });

      print("Description set to: $desc");
    } else {
      print("Invalid description format or unrecognized input.");
    }
  }

  void _detectTimeCommand(String recognizedWords) {
    final RegExp timeRegex = RegExp(
        r"set time to (\d{1,2}):(\d{2}) (A.M.|P.M.)",
        caseSensitive: false);
    final match = timeRegex.firstMatch(recognizedWords);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!;

      if (period.toUpperCase() == "P.M." && hour != 12) {
        hour += 12;
      } else if (period.toUpperCase() == "A.M." && hour == 12) {
        hour = 0;
      }

      setState(() {
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  void _detectDateCommand(String recognizedWords) {
    print("Recognized date command: $recognizedWords");

    final Map<String, int> monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12
    };

    final RegExp numericDateRegex = RegExp(
        r"set date to (\d{1,2})/(\d{1,2})/(\d{4})",
        caseSensitive: false);
    final RegExp textDateRegex = RegExp(
        r"set date to (\w+) (\d{1,2})(,?) (\d{4})",
        caseSensitive: false);

    if (numericDateRegex.hasMatch(recognizedWords)) {
      final match = numericDateRegex.firstMatch(recognizedWords);
      if (match != null) {
        int month = int.parse(match.group(1)!);
        int day = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);

        DateTime parsedDate = DateTime(year, month, day);

        setState(() {
          selectedDate = parsedDate;
        });

        print("Numeric Date set to: $selectedDate");
        return;
      }
    } else if (textDateRegex.hasMatch(recognizedWords)) {
      final match = textDateRegex.firstMatch(recognizedWords);
      if (match != null) {
        String monthName = match.group(1)!.toLowerCase().trim();
        int? month = monthMap[monthName];
        int day = int.parse(match.group(2)!.trim());
        int year = int.parse(match.group(4)!.trim());

        if (month != null) {
          DateTime parsedDate = DateTime(year, month, day);

          setState(() {
            selectedDate = parsedDate;
          });

          print("Text Date set to: $selectedDate");
          return;
        } else {
          print("Invalid month name: $monthName");
        }
      }
    }
    print("Invalid date format or unrecognized input.");
  }

  void speakNav() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You are in the Create Task Screen");
  }
}
