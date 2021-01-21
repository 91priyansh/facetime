import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/pages/homePage.dart';
import 'package:facetime/pages/loginPage.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Root page of the application
class RootPage extends StatefulWidget {
  const RootPage({Key key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  void showNotificataionRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Allow us to send notifications"),
        actions: [
          CupertinoButton(
            onPressed: () {
              AwesomeNotifications().requestPermissionToSendNotifications();
              Navigator.pop(context);
            },
            child: Text("Allow"),
          ),
          CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Deny"),
          )
        ],
      ),
    );
  }

  void requestForNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    print(isAllowed);
    if (!isAllowed) {
      showNotificataionRequestDialog();
    }
  }

  void setNotificationStreams() {
    AwesomeNotifications().actionStream.listen((actionData) {
      NotificationHelper.navigateToPage(context, actionData);
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      //initilization of notification fcm  and local
      requestForNotification();
      setNotificationStreams();
    });
  }

  //disposing the all streams
  @override
  void dispose() {
    AwesomeNotifications().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RootProvider>(
      builder: (context, rootProvider, _) {
        if (rootProvider.isLoggedIn) {
          return HomePage(
            currentUserId: rootProvider.currentUserId,
          );
        }
        return LoginPage();
      },
    );
  }
}
