package com.example.hear_well

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.hear_well/check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getConnectedA2DPDevices") {
                val adapter = BluetoothAdapter.getDefaultAdapter()
                val connectedDevices = mutableListOf<String>()

                if (adapter != null && adapter.isEnabled) {
                    adapter.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                            if (profile == BluetoothProfile.A2DP) {
                                val devices = proxy.connectedDevices
                                for (device in devices) {
                                    connectedDevices.add(device.name ?: "Unknown Device")
                                }
                                result.success(connectedDevices)
                                adapter.closeProfileProxy(BluetoothProfile.A2DP, proxy)
                            }
                        }

                        override fun onServiceDisconnected(profile: Int) {}
                    }, BluetoothProfile.A2DP)
                } else {
                    result.success(emptyList<String>())
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
