Live Photo Capture

## Features

A Flutter plugin to use for Face Detection to detect faces in an image, identify key facial features, and get the contours of detected faces.
Multiple liveness challenge types (blinking, smiling, head turns, nodding)
🔄 Random challenge sequence generation for enhanced security
🎯 Face centering guidance with visual feedback
🔍 Anti-spoofing measures (screen glare detection, motion correlation)
🎨 Fully customizable UI with theming support
🌈 Animated progress indicators, status displays, and overlays
📱 Simple integration with Flutter apps
📸 Optional image capture capability

## Installation

1. Add the latest version of package to your pubspec.yaml (and rundart pub get):

```dart
dependencies:
 livephotocapture: ^1.0.0
```

2. Import the package and use it in your Flutter App.

```dart
 import 'package:livephotocapture/livephotocapture.dart';
```

Make sure to add camera permission to your app:
ios
Add the following to your Info.plist:

```dart
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face liveness verification</string>
```

Android
Add the following to your AndroidManifest.xml:

```dart
<uses-permission android:name="android.permission.CAMERA" />
```

## Usage

```dart
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livephotocapture/livephotocapture.dart';

class FaceDetector extends StatelessWidget {
 const FaceDetector({super.key});

 @override
 Widget build(BuildContext context) {
   return const _FaceDetector();
 }
}

class _FaceDetector extends StatefulWidget {
 const _FaceDetector();

 @override
 State<_FaceDetector> createState() => __FaceDetectorState();
}

class __FaceDetectorState extends State<_FaceDetector> {
 final List<Rulesets> _completedRuleset = [];
 XFile? capturedImage;
 bool _hasCapturedImage = false;

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: Colors.white,
     body: SafeArea(
       child: FaceDetectorScreen(
         onSuccessValidation: (validated) {
           log('Face verification is completed', name: 'Validation');
         },
         onValidationDone: (controller) {
           _captureIfSmiled(controller);

           return Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Text(
                 "Liveness Detection Complete",
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 20),
               if (capturedImage != null)
                 Column(
                   children: [
                     Image.file(
                       File(capturedImage!.path),
                       width: 200,
                       height: 200,
                       fit: BoxFit.cover,
                     ),
                     const SizedBox(height: 10),
                     Text(
                       "Image saved at:\n${capturedImage!.path}",
                       textAlign: TextAlign.center,
                       style: const TextStyle(fontSize: 12),
                     ),
                   ],
                 )
               else
                 const Text("No image captured yet."),
             ],
           );
         },
         child:
             ({
               required int countdown,
               required Rulesets state,
               required bool hasFace,
             }) => Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // const Spacer(),
                 SizedBox(height: 60),
                 // Face Detection Status
                 AnimatedSize(
                   duration: const Duration(milliseconds: 200),
                   child: Text(
                     hasFace ? "✅ Face detected" : "❌ Face not detected",
                     style: TextStyle(
                       fontSize: 16,
                       color: hasFace ? Colors.green : Colors.red,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ),
                 const SizedBox(height: 20),

                 // Hint Text
                 Text(
                   getHintText(state),
                   style: const TextStyle(
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                   ),
                 ),

                 const SizedBox(height: 30),
               ],
             ),
         onRulesetCompleted: (ruleset) {
           if (!_completedRuleset.contains(ruleset)) {
             setState(() {
               _completedRuleset.add(ruleset);
             });
           }
         },
       ),
     ),
   );
 }

 void _captureIfSmiled(dynamic controller) async {
   try {
     if (_hasCapturedImage) return;
     if (controller != null && controller.value.isInitialized) {
       final XFile image = await controller.takePicture();
       log('Captured image at: ${image.path}');
       setState(() {
         capturedImage = image;
         _hasCapturedImage = true;
       });
     } else {
       log("Camera controller not initialized");
     }
   } catch (e) {
     log("Error capturing image: $e");
   }
 }
}

String getHintText(Rulesets state) {
 switch (state) {
   case Rulesets.smiling:
     return '😊 Please Smile';
   case Rulesets.blink:
     return '😉 Please Blink';
   case Rulesets.tiltUp:
     return '👆 Look Up';
   case Rulesets.tiltDown:
     return '👇 Look Down';
   case Rulesets.toLeft:
     return '👈 Look Left';
   case Rulesets.toRight:
     return '👉 Look Right';
   case Rulesets.normal:
     return '🧍‍♂️ Center Your Face';
 }
}
```

## Available Challenge Types

```dart

Rulesets.smiling - Verify that the user can smile
Rulesets.blink - Verify that the user can blink
Rulesets.tiltUp - Verify that the user can turn their head up
Rulesets.tiltDown - Verify that the user can turn their head down
Rulesets.toLeft - Verify that the user can turn their head left
Rulesets.toRight - Verify that the user can turn their head right
Rulesets.normal - Verify that the user can keep neutral
```
