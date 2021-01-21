import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //initalization of firebase app
  await Firebase.initializeApp();
  //initializeAwesomeNotifications plugin(to send and receive local notification)
  await NotificationHelper.initializeAwesomeNotification();
  //createing shared pref instaance before app runs
  SharedPreferences _sharedPreferences = await SharedPreferences.getInstance();

  runApp(MyApp(
    sharedPreferences: _sharedPreferences,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  const MyApp({Key key, @required this.sharedPreferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ///
        ///Root provider for app
        ///
        ChangeNotifierProvider<RootProvider>(
          create: (context) => RootProvider(sharedPreferences),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: "/",
        onGenerateRoute: Routes.onGenerateRoute,
      ),
    );
  }
}
