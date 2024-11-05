import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  FlutterTts flutterTts = FlutterTts();

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x = 0.0;
  var y = 0.0;
  var w = 0.0;
  var h = 0.0;

  var label = "";
  var newlabel = "";
  var show = "hi";

  @override
  void onInit() {
    super.onInit();
    initTFlite();
  }

  void disposeCamera() {
    stopImageStream();  // Stop the image stream
    if (cameraController.value.isInitialized) {
      cameraController.dispose();  // Dispose of the camera controller
    }
    Tflite.close();  // Close the TensorFlow Lite interpreter
    isCameraInitialized(false);
    update();
  }

  Future<void> initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      await cameraController.initialize();
      await initTFlite();  // Ensure the TFLite model is initialized when starting the camera
      startImageStream();  // Start the image stream
      isCameraInitialized(true);
      update();
    } else {
      print("Camera permission denied");
    }
  }

  void startImageStream() {
    cameraController.startImageStream((image) {
      cameraCount++;
      if (cameraCount % 10 == 0) {
        cameraCount = 0;
        objectDetector(image);
      }
      update();
    });
  }

  void stopImageStream() {
    if (cameraController.value.isStreamingImages) {
      cameraController.stopImageStream();
    }
  }

  void pauseCamera() {
    if (cameraController.value.isStreamingImages) {
      cameraController.stopImageStream();  // Stop image stream
    }
    print("Camera paused.");
  }

  void resumeCamera() async {
    if (!cameraController.value.isInitialized) {
      await initCamera();  // Initialize the camera if not initialized
    } else {
      await initTFlite();  // Reinitialize TensorFlow Lite
      startImageStream();  // Restart the image stream
    }
    print("Camera and TFLite resumed.");
  }

  Future<void> initTFlite() async {
    // Load the Teachable Machine model and labels
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",  // Update with the Teachable Machine model path
      labels: "assets/labels.txt",   // Update with the corresponding labels file path
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var results = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) => e.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,  // Adjust based on how many results you want
      threshold: 0.5, // Confidence threshold, adjust as needed
    );

    if (results != null && results.isNotEmpty) {
      log("Results: $results");

      var detectedObject = results.first;
      if (detectedObject['confidence'] != null && detectedObject['confidence'] > 0.95) {
        var confidence = detectedObject['confidence'];
        if (confidence != 0 && confidence > 0.55) {
          label = detectedObject['label'].toString();

          // Remove index from label, assuming format "0 dog" or "1 cat"
          label = label.split(" ").last; // This will remove the index

          if (newlabel != label) {
            newlabel = label;
            show = label;
            speak(label);
          }
        }
        update();
      }
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    stopImageStream();
    cameraController.dispose();
    Tflite.close();
    super.dispose();
  }
}
