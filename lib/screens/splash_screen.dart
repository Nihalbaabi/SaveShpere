import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/SaveSphereSplash.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setVolume(0.0); // Required for web autoplay
        _controller.play();

        _controller.addListener(() {
          if (!_hasFinished &&
              _controller.value.isInitialized && 
              !_controller.value.isPlaying && 
              _controller.value.position >= _controller.value.duration) {
            _hasFinished = true;
            widget.onFinished();
          }
        });
      }).catchError((error) {
        debugPrint("Video initialization failed: $error");
        // Fallback if video fails to load
        if (!_hasFinished) {
           _hasFinished = true;
           widget.onFinished();
        }
      });
      
    // Absolute fallback: proceed after 6 seconds regardless of state
    Future.delayed(const Duration(seconds: 6), () {
      if (!_hasFinished) {
         _hasFinished = true;
         widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          if (!_hasFinished) {
            _hasFinished = true;
            widget.onFinished();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: _isVideoInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : const SizedBox.shrink(), // Prevents UI flash before loading
        ),
      ),
    );
  }
}
