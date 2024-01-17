import 'package:flutter/material.dart';
import 'package:week3/const/color.dart';
import 'package:week3/main.dart'; // SplitScreen 위젯을 import 해야 합니다.
import 'dart:math' as math;

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(minutes: 1), // 오래 지속되는 애니메이션을 위해 1분으로 설정
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double smallOrbitSize = screenSize.width / 3;
    final double largeOrbitSize = screenSize.width / 2;
    final double cometOrbitSize = screenSize.width * 2;

    return Scaffold(
      backgroundColor: MyColor.surface,
      body: GestureDetector(
        onTap: () => _navigateToMainView(context),
        child: Stack(
          children: [
            // Small orbit rotation
            Positioned(
              left: -screenSize.width / 8,
              top: -screenSize.height / 4,
              child: AnimatedBuilder(
                animation: _animationController,
                child: Image.asset('assets/images/image_orbit_small.png',
                    width: smallOrbitSize, height: smallOrbitSize),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * math.pi,
                    child: child,
                  );
                },
              ),
            ),
            // Large orbit rotation
            Positioned(
              right: -screenSize.width / 3,
              bottom: -screenSize.height / 4,
              child: AnimatedBuilder(
                animation: _animationController,
                child: Image.asset('assets/images/image_orbit_large.png',
                    width: largeOrbitSize, height: largeOrbitSize),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * math.pi,
                    child: child,
                  );
                },
              ),
            ),
            // comet
            Positioned(
              left: -screenSize.width * 3 / 2,
              bottom: -screenSize.height * 2,
              child: AnimatedBuilder(
                animation: _animationController,
                child: Image.asset('assets/images/image_comet.png',
                    width: cometOrbitSize, height: cometOrbitSize),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * math.pi,
                    child: child,
                  );
                },
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      MyColor.onSurface,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset('assets/images/logo_intro.png',
                        height: 180),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 120.0),
                    child: Text(
                      'Press Any Key Or Click To Continue',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: MyColor.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMainView(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SplitScreen(),
        transitionDuration: Duration(milliseconds: 1000), // 전환에 걸리는 시간 설정
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOut; // easeInOut 곡선 적용
          var curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return FadeTransition(
            opacity: curvedAnimation, // 곡선 애니메이션 적용
            child: child,
          );
        },
      ),
    );
  }
}
