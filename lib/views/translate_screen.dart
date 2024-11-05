import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:vibration/vibration.dart';

class translate_screen extends StatefulWidget {
  final Function(int) onDoubleTapCallback;

  const translate_screen({super.key, required this.onDoubleTapCallback});

  @override
  State<translate_screen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<translate_screen> {
  var inp = TextEditingController();
  var translated = TextEditingController();
  FlutterTts flutterTts = FlutterTts();
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String voice_inp = "";
  String selectedLanguageFrom = 'English';
  String selectedLanguageTo = 'Filipino';

  @override
  void initState() {
    _initSpeech();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Translator',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 34,
              fontStyle: FontStyle.italic),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFFF8E00),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          Vibration.vibrate();
          if (_speechToText.isNotListening) {
            _startListening();
          } else {
            _stopListening();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: swapLanguages,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF002347)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller:
                              TextEditingController(text: selectedLanguageFrom),
                          readOnly: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'From Language',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Wrap compare_arrows icon in a styled container
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Color(0xFF002347),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () async {
                        Vibration.vibrate();
                        speakConfirm("Do you want to swap language?");
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Color(
                                  0xFF002347), // Set the background color of the dialog
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Rounded corners
                              ),
                              title: const Text(
                                'Swap Language',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white, // Title text color
                                ),
                              ),
                              content: const Text(
                                'Do you want to swap languages?',
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
                                        foregroundColor: Colors
                                            .white, // Text color for button
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Rounded button corners
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    SizedBox(
                                        width: 20), // Space between buttons
                                    TextButton(
                                      onPressed: () {
                                        Vibration.vibrate();
                                        Navigator.of(context).pop(true);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors
                                            .white, // Text color for button
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Rounded button corners
                                        ),
                                      ),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          swapLanguages();
                        }
                      },
                      icon:
                          const Icon(Icons.compare_arrows, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: swapLanguages,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF002347)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller:
                              TextEditingController(text: selectedLanguageTo),
                          readOnly: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'To Language',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF002347)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: inp,
                            onChanged: (value) {
                              if (inp.text.isEmpty) {
                                translated.text = "";
                              } else {
                                translate();
                              }
                            },
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter text here...',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 19,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: IconButton(
                            onPressed: () => speak(inp.text),
                            icon: const Icon(
                              Icons.volume_up,
                              color: Color(0xFF002347),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              const Divider(thickness: 2, color: Colors.grey),
              const SizedBox(height: 15),
              // Translated text field
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // TextField with styling
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF002347)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: translated,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Translated text will appear here...',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 19,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                            readOnly: true,
                            maxLines: null,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: IconButton(
                            onPressed: () => speak1(translated.text),
                            icon: const Icon(
                              Icons.volume_up,
                              color: Color(0xFF002347),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: translate,
                child: const Text(
                  "Translate",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF002347),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  textStyle: const TextStyle(fontSize: 16),
                  shadowColor: Colors.grey.withOpacity(0.8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _speechToText.isNotListening ? _startListening2 : _stopListening,
        tooltip: 'Listen',
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          size: 33,
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: _speechToText.isNotListening
              ? const Color(0xFF002347)
              : Color(0xFF249EA0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void swapLanguages() {
    setState(() {
      final temp = selectedLanguageFrom;
      selectedLanguageFrom = selectedLanguageTo;
      selectedLanguageTo = temp;
    });
  }

  void translate() async {
    final translator = GoogleTranslator();
    final input = inp.text;

    if (inp.text != "") {
      var translation = await translator.translate(input,
          from: selectedLanguageFrom == 'English' ? 'en' : 'tl',
          to: selectedLanguageTo == 'Filipino' ? 'tl' : 'en');
      translated.text = translation.toString();
      setState(() {});
      speak1(translated.text);
    } else {
      translated.text = "";
    }
  }

  void speak(String text) {
    if (selectedLanguageFrom == "English") {
      flutterTts.setLanguage('en-US');
    } else {
      flutterTts.setLanguage('fil-PH');
    }
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  void speak1(String text) {
    if (selectedLanguageTo == "English") {
      flutterTts.setLanguage('en-US');
    } else {
      flutterTts.setLanguage('fil-PH');
    }
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  void speakConfirm(text) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(text);
  }

  void speakNav(String nav_title) {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak(nav_title);
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
    speakNav("You are in the Translator Screen");
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _startListening2() async {
    await _speechToText.listen(onResult: _onSpeechResult2);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      voice_inp = result.recognizedWords;
      if (voice_inp.isNotEmpty) {
        nav_to_other(voice_inp);
      }
    });
  }

  void _onSpeechResult2(SpeechRecognitionResult result) {
    setState(() {
      voice_inp = result.recognizedWords;
      if (voice_inp.isNotEmpty) {
        inp.text = voice_inp;
      }
      translate();
    });
  }

  void nav_to_other(String voice) {
    if (voice == "what is the time now" ||
        voice == "time" ||
        voice == "time now" ||
        voice == "anong oras na") {
      DateTime now = DateTime.now();
      String formattedTime = DateFormat('h:mm a').format(now);
      flutterTts.speak("The time now is $formattedTime");
      print("okayyyyyy!!!!!!");
    } else if (voice == "what is the date today" ||
        voice == "date" ||
        voice == "anong date ngayon") {
      DateTime now = DateTime.now();
      String formattedDate =
          DateFormat('EEEE, MMMM d, yyyy').format(now); // Format the date
      flutterTts.speak("Today is $formattedDate"); // Speak out the current date
    } else if (voice == "object" || voice == "go to object") {
      widget.onDoubleTapCallback(0);
    } else if (voice == "maps" || voice == "go to maps") {
      widget.onDoubleTapCallback(1);
    } else if (voice == "scanner" || voice == "go to scanner") {
      widget.onDoubleTapCallback(2);
    } else if (voice == "to do" || voice == "go to todo") {
      widget.onDoubleTapCallback(4);
    } else {
      inp.text = voice;
      translate();
      print(voice_inp);
    }
  }
}
