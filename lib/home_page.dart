import 'package:flutter/material.dart';
import 'camera_screen.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Object Detection'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
          child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraScreen()),
          );
        },
        icon: Icon(Icons.camera_alt),
        label: Text('Open Camera'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      )),
    );
  }
}
