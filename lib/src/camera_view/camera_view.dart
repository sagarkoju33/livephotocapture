import 'dart:developer';
import 'dart:io';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livephotocapture/livephotocapture.dart';
import 'package:livephotocapture/src/debouncer/debouncer.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.onImage,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onController,
    this.cameraSize = const Size(200, 200),
  });
  final Size cameraSize;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final void Function(CameraController controller)? onController;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  Debouncer? _debouncer;

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);

  //   _initCamera();
  // }

  // Future<void> _initialize() async {
  //   // 1️⃣ Check current permission status
  //   var status = await Permission.camera.status;
  //   dev.log("the status is ============>$status");

  //   // 2️⃣ Request permission if not granted
  //   if (!status.isGranted) {
  //     status = await Permission.camera.request();
  //   }

  //   if (status.isPermanentlyDenied) {
  //     // User pressed "Don't ask again", open app settings
  //     await openAppSettings();
  //   } else {
  //     _initCamera();
  //   }
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PermissionManager.requestCameraPermission();
    // _checkPermission();

    // Initialize camera if permission already granted (hot restart case)
    Permission.camera.status.then((status) {
      if (status.isGranted && _controller == null) {
        _initializeCameraController();
      }
    });
  }

  // Future<void> _checkPermission() async {
  //   var status = await Permission.camera.status;

  //   if (!status.isGranted) {
  //     status = await Permission.camera.request();
  //   }

  //   if (status.isGranted) {
  //   } else if (status.isPermanentlyDenied || status.isDenied) {
  //     if (!mounted) return;

  //     await openAppSettings();
  //   }
  // }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    log("App lifecycle state: $state");
    if (state == AppLifecycleState.resumed) {
      if (_controller == null) {
        var status = await Permission.camera.status;
        if (status.isGranted) {
          await _initializeCameraController();
        }
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopLiveFeed();
    }
  }

  bool _isInitializing = false;

  Future<void> _initializeCameraController() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      _cameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == widget.initialCameraLensDirection,
      );
      if (_cameraIndex == -1) return;

      final camera = _cameras[_cameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.startImageStream(_processCameraImage);

      widget.onController?.call(_controller!);
      widget.onCameraFeedReady?.call();
      setState(() {});
    } finally {
      _isInitializing = false;
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed && _controller == null) {
  //     // Try initializing camera again after permission dialog
  //     _initCamera();
  //   } else if (state == AppLifecycleState.inactive ||
  //       state == AppLifecycleState.paused) {
  //     _stopLiveFeed();
  //   }
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveFeed();
    _debouncer?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty || _controller == null) return Container();
    if (!_controller!.value.isInitialized) return Container();
    if (_controller == null || _controller!.value.isCaptureOrientationLocked) {
      return Container();
    }

    // Prevent using disposed controller

    widget.onController?.call(_controller!);

    return SizedBox(
      height: widget.cameraSize.height,
      width: widget.cameraSize.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cameraSize.width),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  // Future<void> _startLiveFeed() async {
  //   try {
  //     final camera = _cameras[_cameraIndex];

  //     _controller = CameraController(
  //       camera,
  //       ResolutionPreset.high,
  //       enableAudio: false,
  //       imageFormatGroup: Platform.isIOS
  //           ? ImageFormatGroup.bgra8888
  //           : ImageFormatGroup.yuv420,
  //     );

  //     await _controller!.initialize();
  //     if (!mounted) return;

  //     await _controller!.startImageStream(_processCameraImage);

  //     widget.onController?.call(_controller!);
  //     widget.onCameraFeedReady?.call();

  //     setState(() {});
  //   } catch (e) {
  //     debugPrint('Camera error: $e');
  //   }
  // }

  // Future<void> _startLiveFeed() async {
  //   try {
  //     final status = await Permission.camera.status;

  //     if (status.isDenied || status.isRestricted) {
  //       final result = await Permission.camera.request();
  //       if (!result.isGranted) return;
  //     }

  //     if (status.isPermanentlyDenied) {
  //       await openAppSettings();
  //       return;
  //     }

  //     final camera = _cameras[_cameraIndex];

  //     _controller = CameraController(
  //       camera,
  //       ResolutionPreset.high,
  //       enableAudio: false,
  //       imageFormatGroup: ImageFormatGroup.bgra8888,
  //     );

  //     await _controller!.initialize();

  //     if (!mounted) return;

  //     await _controller!.startImageStream(_processCameraImage);

  //     setState(() {});
  //   } catch (e) {
  //     debugPrint('Camera error: $e');
  //   }
  // }

  Uint8List convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    final numPixels = width * height + (width * height ~/ 2);
    final nv21 = Uint8List(numPixels);

    int idY = 0;
    int idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 2;

    for (int y = 0; y < height; ++y) {
      final yOffset = y * yRowStride;
      for (int x = 0; x < width; ++x) {
        nv21[idY++] = yBuffer[yOffset + x * yPixelStride];
      }
    }

    for (int y = 0; y < uvHeight; ++y) {
      final uvOffset = y * uvRowStride;
      for (int x = 0; x < uvWidth; ++x) {
        final bufferIndex = uvOffset + (x * uvPixelStride);
        nv21[idUV++] = vBuffer[bufferIndex];
        nv21[idUV++] = uBuffer[bufferIndex];
      }
    }

    return nv21;
  }

  Future<void> _stopLiveFeed() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
      } on CameraException catch (e) {
        debugPrint('CameraException while stopping stream: $e');
      }

      try {
        await _controller!.dispose();
      } on CameraException catch (e) {
        debugPrint('CameraException while disposing: $e');
      }

      _controller = null;
    }
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    // if (Platform.isIOS) {
    //   rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    // } else if (Platform.isAndroid) {
    var rotationCompensation =
        _orientations[_controller!.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    // }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    bool shouldOverride =
        Platform.isAndroid && (format != InputImageFormat.nv21);
    if (image.planes.length != 1 && !shouldOverride) return null;
    final plane = image.planes.first;

    if (Platform.isIOS) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes, // Only use first plane for BGRA
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
    return InputImage.fromBytes(
      bytes: shouldOverride ? convertYUV420ToNV21(image) : plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: InputImageFormat.nv21, // used only in iOS
        bytesPerRow: image.width,
      ),
    );
  }
}
