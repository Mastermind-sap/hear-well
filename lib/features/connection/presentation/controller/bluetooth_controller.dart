import 'dart:typed_data';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

class BluetoothControllers {
  Future<List<Device>> getPairedDevices() async {
    final _bluetoothClassicPlugin = BluetoothClassic();
    await _bluetoothClassicPlugin.initPermissions();
    List<Device> _discoveredDevices = await _bluetoothClassicPlugin.getPairedDevices();
    return _discoveredDevices;
  }
  Future<List<Device>> getScannedDevices() async {
    final _bluetoothClassicPlugin = BluetoothClassic();
    List<Device> _discoveredDevices = [];
    await _bluetoothClassicPlugin.initPermissions();
    _bluetoothClassicPlugin.onDeviceDiscovered().listen(
      (event) {
        _discoveredDevices = [..._discoveredDevices, event];
      },
    );
    await _bluetoothClassicPlugin.startScan();
    
    await _bluetoothClassicPlugin.stopScan();
    return _discoveredDevices;
  }
  Future<void> connectToDevice(Device device) async {
    final _bluetoothClassicPlugin = BluetoothClassic();
    Uint8List _data = Uint8List(0);

    await _bluetoothClassicPlugin.initPermissions();
    // connect to a device with its MAC address and the application uuid you want to use (in this example, serial)
    await _bluetoothClassicPlugin.connect(device.address, "00001101-0000-1000-8000-00805F9B34FB");
  }
}