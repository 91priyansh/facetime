import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  TestPage({Key key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _topPositionAnimation;
  Animation<double> _borderRadiusAnimation;
  Animation<double> _opacityAnimation;
  Animation<double> _scaleAnimation;
  Animation<double> _buttonShadowOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);
    _topPositionAnimation = Tween(begin: 0.5, end: 1.5).animate(CurvedAnimation(
        curve: Curves.easeInOutCirc,
        reverseCurve: Curves.easeInOutCirc,
        parent: _animationController));

    _borderRadiusAnimation = Tween(begin: 0.9, end: 1.25).animate(
        CurvedAnimation(
            curve: Curves.easeInOutCirc,
            reverseCurve: Curves.easeInOutCirc,
            parent: _animationController));

    _opacityAnimation = Tween(begin: 1.0, end: 0.5).animate(CurvedAnimation(
        curve: Curves.easeInOutCirc,
        reverseCurve: Curves.easeInOutCirc,
        parent: _animationController));

    _scaleAnimation = Tween(begin: 1.0, end: 1.4).animate(CurvedAnimation(
        curve: Curves.easeInOutCirc,
        reverseCurve: Curves.easeInOutCirc,
        parent: _animationController));

    _buttonShadowOpacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            curve: Curves.easeInOutCirc,
            reverseCurve: Curves.easeInOutCirc,
            parent: _animationController));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dheight = MediaQuery.of(context).size.height;
    final dwidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: dwidth,
            height: dheight,
            color: Colors.blue.shade500,
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                  top: -dwidth * _topPositionAnimation.value,
                  right: -dwidth * (0.5),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: dwidth * (2),
                      height: dwidth * (2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            dwidth * _borderRadiusAnimation.value),
                        color: Colors.white12,
                      ),
                    ),
                  ));
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 60.0, bottom: 75.0),
              child: FadeTransition(
                opacity: _buttonShadowOpacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 60.0, bottom: 75.0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 60.0, bottom: 75.0),
              child: FadeTransition(
                opacity: _buttonShadowOpacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 60.0, bottom: 75.0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
