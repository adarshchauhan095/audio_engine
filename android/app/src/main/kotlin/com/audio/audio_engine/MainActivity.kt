package com.audio.audio_engine

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
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
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                val refresh = addedDevices.any { d ->
                    d.isSink && isRouteCompetingOutput(d.type)
                }
                if (refresh) {
                    scheduleNotifyPreferredOutputChanged(channel)
                }
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                val refresh = removedDevices.any { d ->
                    d.isSink && isRouteCompetingOutput(d.type)
                }
                if (refresh) {
                    scheduleNotifyPreferredOutputChanged(channel)
                }
            }
        }
        audioManager.registerAudioDeviceCallback(callback, handler)
    }

    private fun scheduleNotifyPreferredOutputChanged(channel: MethodChannel) {
        debounceRunnable?.let { handler.removeCallbacks(it) }
        val runnable = Runnable {
            debounceRunnable = null
            channel.invokeMethod("onPreferredAudioOutputChanged", null)
        }
        debounceRunnable = runnable
        handler.postDelayed(runnable, 350L)
    }

    /**
     * Outputs that should trigger a stream refresh when added or removed
     * (Bluetooth connect/disconnect, wired, USB).
     */
    private fun isRouteCompetingOutput(type: Int): Boolean =
        isBluetoothMediaOutput(type) ||
            type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
            type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
            type == AudioDeviceInfo.TYPE_USB_HEADSET ||
            type == AudioDeviceInfo.TYPE_USB_DEVICE

    /**
     * Prefer A2DP / BLE media for Bluetooth music routing. SCO is voice-grade
     * and excluded here so media stays on speaker until A2DP is available.
     */
    private fun isBluetoothMediaOutput(type: Int): Boolean =
        when (type) {
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> true
            else ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                        type == AudioDeviceInfo.TYPE_BLE_SPEAKER
                } else {
                    false
                }
        }

    /**
     * Pick Oboe output device: wired and USB first (explicit connection),
     * then Bluetooth media, then built-in speaker.
     */
    private fun preferredMusicOutputDeviceId(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

        fun firstId(predicate: (AudioDeviceInfo) -> Boolean): Int? =
            devices.firstOrNull(predicate)?.id

        firstId {
            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET
        }?.let { return it }

        firstId {
            it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_USB_DEVICE
        }?.let { return it }

        firstId { isBluetoothMediaOutput(it.type) }?.let { return it }

        firstId { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }?.let { return it }

        return devices.firstOrNull()?.id ?: -1
    }
}
