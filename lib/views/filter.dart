  import 'package:flutter/material.dart';
  import 'package:flutter_tts/flutter_tts.dart';
  import 'package:intl/intl.dart';
  import 'package:vibration/vibration.dart';

  class filterScreen extends StatefulWidget {
    final Function(bool?) applyFilter;
    filterScreen({required this.applyFilter});
    @override
    _filterScreenState createState() => _filterScreenState();
  }

  class _filterScreenState extends State<filterScreen> {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool? isCompleted;
    bool hasReminder = false;
    FlutterTts flutterTts = FlutterTts();

    // Method to pick a date
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null && pickedDate != selectedDate)
        setState(() {
          selectedDate = pickedDate;
        });
    }

    // Method to pick a time
    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (pickedTime != null && pickedTime != selectedTime)
        setState(() {
          selectedTime = pickedTime;
        });
    }

    @override
    void initState() {
      // TODO: implement initState
      isCompleted = null;
      super.initState();
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF002347),
        title: Text('Filter Tasks', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: Color(0xFFF3F4F6),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            ListTile(
              title: Text(
                "Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                style: TextStyle(color: Color(0xFF002347)),
              ),
              trailing: Icon(Icons.calendar_today, color: Color(0xFF002347)),
              onTap: () => _selectDate(context),
            ),
            
            Divider(),
            ListTile(
              title: Text(
                "Select Time: ${selectedTime.format(context)}",
                style: TextStyle(color: Color(0xFF002347)),
              ),
              trailing: Icon(Icons.access_time, color: Color(0xFF002347)),
              onTap: () => _selectTime(context),
            ),
            SizedBox(height: 20),

            // Completion status section
            Text(
              'Task Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002347),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF002347)),
              ),
              child: Column(
                children: [
                  RadioListTile(
                    title: Text('Completed'),
                    value: true,
                    groupValue: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        isCompleted = value!;
                      });
                    },
                    activeColor: Color(0xFF002347),
                  ),
                  RadioListTile(
                    title: Text('Incomplete'),
                    value: false,
                    groupValue: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        isCompleted = value!;
                      });
                    },
                    activeColor: Color(0xFF002347),
                  ),
                  RadioListTile(
                    title: Text('Show All'),
                    value: null,
                    groupValue: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        isCompleted = value!;
                      });
                    },
                    activeColor: Color(0xFF002347),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            SwitchListTile(
              title: Text(
                'Set Reminder',
                style: TextStyle(color: Color(0xFF002347)),
              ),
              value: hasReminder,
              onChanged: (value) {
                setState(() {
                  hasReminder = value;
                });
              },
              activeColor: Color(0xFF002347),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  Vibration.vibrate();
                  speakConfirm("Do you want to apply this filter?");
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Color(0xFF002347),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Filter Task',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Do you want to apply this filter?',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Vibration.vibrate();
                              Navigator.of(context).pop(false);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Vibration.vibrate();
                              Navigator.of(context).pop(true);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Confirm'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    widget.applyFilter(isCompleted);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF002347),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void speakConfirm(String text) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }
}