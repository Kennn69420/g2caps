import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:objct_recog_try/controller/scan_controller.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

class CameraView extends StatefulWidget {
  final Function(int) onDoubleTapCallback; // Accepts index for navigation

  const CameraView({super.key, required this.onDoubleTapCallback});

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  final ScanController controller = Get.put(ScanController());
  FlutterTts flutterTts = FlutterTts();
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String voice_inp = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.initCamera();
    _initSpeech();
    speakNav();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.disposeCamera(); // Stop and dispose of the camera resources
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller.pauseCamera(); // Stop the camera when the app is paused
    } else if (state == AppLifecycleState.resumed) {
      if (controller.isCameraInitialized.value) {
        controller.resumeCamera(); // Restart the camera if it was previously initialized
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color(0xFFFF8E00), // Set to your desired background color
    body: SafeArea( // Add SafeArea here
      child: GestureDetector(
        onDoubleTap: () {
          Vibration.vibrate();
          _startListening();
        },
        child: GetBuilder<ScanController>(
          builder: (controller) {
            return controller.isCameraInitialized.value
                ? Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0), // Padding for the frame
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black, // Change this to your desired color
                            border: Border.all(color: Color(0xFF249EA0), width: 4), // Border color and width
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12), // Match the border radius
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: CameraPreview(controller.cameraController),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: (controller.y) * MediaQuery.of(context).size.height,
                        right: (controller.x) * MediaQuery.of(context).size.width,
                        child: Container(
                          width: controller.w * MediaQuery.of(context).size.width,
                          height: controller.h * MediaQuery.of(context).size.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 4.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                child: Text(controller.show),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text("Loading Preview"));
          },
        ),
      ),
    ),
  );
}




  void speakNav() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You are in the Object Recognition Screen");
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {

    });
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      voice_inp = result.recognizedWords;
      if(voice_inp != ""){
        nav_to_other(voice_inp);
      }
    });
  }

  void nav_to_other(voice){
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
