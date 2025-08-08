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
