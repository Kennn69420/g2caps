import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

class TextScanner extends StatefulWidget {
  final Function(int) onDoubleTapCallback; // Accepts index for navigation

  const TextScanner({super.key, required this.onDoubleTapCallback});

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  bool isPermissionGranted = false;
  late final Future<void> future;
  FlutterTts flutterTts = FlutterTts();
  bool _isProcessing = false;
  bool _isCoolingDown = false;
  Duration cooldownDuration = Duration(seconds: 2);
  SpeechToText _speechToText = SpeechToText();
  String voice_inp = "";
  bool _speechEnabled = false;
  bool _light = false;

  //For controlling camera
  CameraController? cameraController;
  final textRecogniser = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    future = requestCameraPermission();
    speakNav();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopCamera();
    textRecogniser.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      startCamera();
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color(0xFFFF8E00), // Set to your desired background color
    body: SafeArea(
      child: GestureDetector(
        onDoubleTap: () {
          Vibration.vibrate();
          print("you double tap");
          if (_speechToText.isNotListening) {
            _startListening();
          } else {
            _stopListening();
          }
        },
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            return isPermissionGranted
                ? FutureBuilder<List<CameraDescription>>(
                    future: availableCameras(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        initCameraController(snapshot.data!);
                        // Using Padding to create space around the CameraPreview
                        return Padding(
                          padding: const EdgeInsets.all(16.0), // Adjust padding as needed
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // Background color of the frame
                              border: Border.all(color: Color(0xFF249EA0), width: 4), // Border color and width
                              borderRadius: BorderRadius.circular(16), // Rounded corners (optional)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // Match the border radius
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                child: CameraPreview(cameraController!),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const Center(child: LinearProgressIndicator());
                      }
                    },
                  )
                : const Center(child: Text("Permission not granted"));
          },
        ),
      ),
    ),
  );
}



  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      isPermissionGranted = status == PermissionStatus.granted;
    });
  }

  void initCameraController(List<CameraDescription> cameras) {
    if (cameraController != null) {
      return;
    }
    CameraDescription? camera;
    for (var a = 0; a < cameras.length; a++) {
      final CameraDescription current = cameras[a];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }
    if (camera != null) {
      cameraSelected(camera);
    }
  }

  Future<void> cameraSelected(CameraDescription camera) async {
    cameraController =
        CameraController(camera, ResolutionPreset.max, enableAudio: false);
    await cameraController?.initialize();
    await cameraController?.setFlashMode(FlashMode.off);
    if (!mounted) {
      return;
    }
    setState(() {});
    startRealTimeTextRecognition();
  }

  void startCamera() {
    if (cameraController != null) {
      cameraSelected(cameraController!.description);
    }
  }

  void stopCamera() {
    if (cameraController != null) {
      cameraController?.dispose();
    }
  }

  void startRealTimeTextRecognition() {
    cameraController?.startImageStream((CameraImage cameraImage) {
      if (_isProcessing || _isCoolingDown) return;

      _isProcessing = true;

      scanTextFromCamera(cameraImage).then((_) {
        _isProcessing = false;
      });
    });
  }

  Future<void> scanTextFromCamera(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (var plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final InputImageRotation imageRotation = InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          (image.format.raw == ImageFormatGroup.yuv420)
              ? InputImageFormat.yuv420
              : InputImageFormat.bgra8888;

      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

      final RecognizedText recognizedText =
          await textRecogniser.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        int textLength = recognizedText.text.length;
        cooldownDuration = Duration(seconds: 2 + (textLength ~/ 20));

        speak(recognizedText.text);
        print(recognizedText.text);
        startCooldown();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred during real-time text recognition'),
        ),
      );
    }
  }

  // Cooldown mechanism
  void startCooldown() {
    _isCoolingDown = true;
    Future.delayed(cooldownDuration, () {
      _isCoolingDown = false;
    });
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  void speakNav() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    flutterTts.speak("You are in the Text Scanner Screen");
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
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
      if (voice_inp == "open flashlight" || voice_inp == "flashlight open") {
        torchlightOpen();
      } else if (voice_inp == "close flashlight" ||
          voice_inp == "flashlight close") {
        torchlightClose();
      } else if (voice_inp != "") {
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

  void torchlightOpen() async {
    if (cameraController != null && _light == false) {
      try {
        await cameraController!
            .setFlashMode(FlashMode.torch); // Turn on the flashlight
        setState(() {
          _light = true;
        });
      } catch (e) {
        print("Error enabling flashlight: $e");
      }
    }
  }

  void torchlightClose() async {
    if (cameraController != null && _light == true) {
      try {
        await cameraController!
            .setFlashMode(FlashMode.off); // Turn off the flashlight
        setState(() {
          _light = false;
        });
      } catch (e) {
        print("Error disabling flashlight: $e");
      }
    }
  }
}
