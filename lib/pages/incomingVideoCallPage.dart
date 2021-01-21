import 'dart:ui';

import 'package:facetime/helpers/ringtoneHelper.dart';
import 'package:facetime/models/callHistory.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/routes.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IncomingVideoCallPage extends StatefulWidget {
  final CallHistory callDetails;
  const IncomingVideoCallPage({Key key, this.callDetails}) : super(key: key);

  static Route<IncomingVideoCallPage> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (context) => IncomingVideoCallPage(
        callDetails: routeSettings.arguments,
      ),
    );
  }

  @override
  _IncomingVideoCallPageState createState() => _IncomingVideoCallPageState();
}

class _IncomingVideoCallPageState extends State<IncomingVideoCallPage>
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

  void acceptCall(BuildContext context) {
    RingtonePlayer.stopBackgroundRingtone();
    RingtonePlayer.stopRingtone();
    Navigator.of(context)
        .pushReplacementNamed(Routes.videocallPage, arguments: {
      "channelName": widget.callDetails.channelName,
      "incomingCall": true,
      "userDetails": UserDetails(
          userId: widget.callDetails.to,
          userImageUrl: widget.callDetails.toImageUrl,
          username: widget.callDetails.toUsername)
    });
  }

  void rejectCall(BuildContext context) {
    FirebaseDatabase.removeCurrentCall(
        currentUserId:
            Provider.of<RootProvider>(context, listen: false).currentUserId,
        friendId: widget.callDetails.to);
  }

  @override
  Widget build(BuildContext context) {
    final dheight = MediaQuery.of(context).size.height;
    final dwidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
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
                child: GestureDetector(
                  onTap: () {
                    acceptCall(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.call,
                      color: Colors.green,
                    ),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30)),
                  ),
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
                child: GestureDetector(
                  onTap: () {
                    rejectCall(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Icon(Icons.call_end, color: Colors.red),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: 200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfilePictureContainer(
                      imageUrl: widget.callDetails.toImageUrl,
                      size: 60.0,
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      widget.callDetails.toUsername,
                      style: TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
