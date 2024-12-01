import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  String _detectedObject = "No object detected";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Check and request permissions
  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initializeCamera();
      await _loadModel();
    } else {
      if (status.isDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Permission Denied"),
            content: Text("Camera permission is required to use this app."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        openAppSettings();
      }
    }
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    _cameraController!.startImageStream((image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _processCameraFrame(image);
      }
    });
  }

  // Load TFLite model
  Future<void> _loadModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
    print("Model loaded: $res");
  }

  // Process camera frame
  Future<void> _processCameraFrame(CameraImage image) async {
    // Convert YUV420 image to RGB for TFLite
    img.Image rgbImage = _convertYUV420ToImage(image);

    // Run inference on the frame
    var recognitions = await Tflite.runModelOnImage(
      path: await _saveTemporaryImage(rgbImage),
      numResults: 5,
      threshold: 0.5,
    );

    // Process recognitions
    if (recognitions != null && recognitions.isNotEmpty) {
      setState(() {
        _detectedObject = recognitions.first["label"];
      });
    } else {
      setState(() {
        _detectedObject = "No object detected";
      });
    }

    _isDetecting = false;
  }

  // Convert YUV420 to RGB
  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    img.Image rgbImage = img.Image(width, height);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    int yIndex = 0;
    int uvIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int yValue = yPlane.bytes[yIndex];
        int uValue = uPlane.bytes[uvIndex];
        int vValue = vPlane.bytes[uvIndex];

        int r = (yValue + 1.402 * (vValue - 128)).toInt();
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .toInt();
        int b = (yValue + 1.772 * (uValue - 128)).toInt();

        rgbImage.setPixel(x, y,
            img.getColor(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)));

        yIndex++;
        if (x % 2 == 0) uvIndex++;
      }
    }
    return rgbImage;
  }

  // Save image temporarily for TFLite
  Future<String> _saveTemporaryImage(img.Image image) async {
    final directory = await getTemporaryDirectory();
    final imagePath = "${directory.path}/frame.png";
    File(imagePath).writeAsBytesSync(img.encodePng(image));
    return imagePath;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Object Detection'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraController?.value.isInitialized ?? false
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _detectedObject,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
