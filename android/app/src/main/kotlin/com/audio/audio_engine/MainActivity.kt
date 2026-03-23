package com.audio.audio_engine

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val handler = Handler(Looper.getMainLooper())
    private var debounceRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.audio.audio_engine/audio_route",
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPreferredMusicOutputDeviceId" ->
                    result.success(preferredMusicOutputDeviceId())
                else -> result.notImplemented()
            }
        }

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val callback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {}

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                val lostBt = removedDevices.any { isBluetoothAudioOutput(it.type) }
                if (lostBt) {
                    scheduleNotifyRouteChange(channel)
                }
            }
        }
        audioManager.registerAudioDeviceCallback(callback, handler)
    }

    private fun scheduleNotifyRouteChange(channel: MethodChannel) {
        debounceRunnable?.let { handler.removeCallbacks(it) }
        val runnable = Runnable {
            debounceRunnable = null
            channel.invokeMethod("onBluetoothAudioRouteLost", null)
        }
        debounceRunnable = runnable
        handler.postDelayed(runnable, 350L)
    }

    private fun isBluetoothAudioOutput(type: Int): Boolean = when (type) {
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> true
        else ->
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                    type == AudioDeviceInfo.TYPE_BLE_SPEAKER
            } else {
                false
            }
    }

    private fun preferredMusicOutputDeviceId(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

        devices.firstOrNull {
            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET
        }?.id?.let { return it }

        devices.firstOrNull {
            it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_USB_DEVICE
        }?.id?.let { return it }

        devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            ?.id?.let { return it }

        return -1
    }
}
