import 'dart:ui';

import 'package:facetime/helpers/notificationHelper.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class RingtonePlayer {
  static void playRingtone() async {
    FlutterRingtonePlayer.playRingtone(
        volume: 1.0, looping: false, asAlarm: false);
  }

  static void stopRingtone() {
    FlutterRingtonePlayer.stop();
  }

  //use to stop backgroundRingtone
  static void stopBackgroundRingtone() {
    final port =
        IsolateNameServer.lookupPortByName(backgroundMessageIsolateName);

    print("Send port message");
    if (port != null) {
      port.send("stopRingtone");
    }
  }
}
