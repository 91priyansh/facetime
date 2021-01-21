
package com.facetime.face_time.facetime
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin
import io.flutter.view.FlutterMain
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService
import me.carda.awesome_notifications.AwesomeNotificationsPlugin
import io.inway.ringtone.player.FlutterRingtonePlayerPlugin
///
//me.carda.awesome_notifications.AwesomeNotificationsPlugin()
//com.ryanheise.just_audio.JustAudioPlugin()
///
class Application : FlutterApplication(), PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
        FlutterFirebaseMessagingService.setPluginRegistrant(this);
        FlutterMain.startInitialization(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        if (!registry!!.hasPlugin("io.flutter.plugins.firebasemessaging")) {
            FirebaseMessagingPlugin.registerWith(registry!!.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
        }
        if (!registry!!.hasPlugin("me.carda.awesome_notifications")) {
            AwesomeNotificationsPlugin.registerWith(registry!!.registrarFor("me.carda.awesome_notifications.AwesomeNotificationsPlugin"))
        }
        if (!registry!!.hasPlugin("io.inway.ringtone.player")) {
            FlutterRingtonePlayerPlugin.registerWith(registry!!.registrarFor("io.inway.ringtone.player.FlutterRingtonePlayerPlugin"))
        }

        //if (!registry!!.hasPlugin("com.ryanheise.just_audio")) {
        //    JustAudioPlugin.registerWith(registry!!.registrarFor("com.ryanheise.just_audio.JustAudioPlugin"))
        //}
        //com.ryanheise.audio_session
    }
}