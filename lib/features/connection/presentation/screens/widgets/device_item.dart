import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:echo_aid/features/connection/presentation/screens/widgets/scanning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {

  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  List<ScanResult> _scanResults = [];
  Uint8List _data = Uint8List(0);
  Device? _connectedDevice;
  List<BluetoothDevice> connectedDevices = [];
  bool isCheckingDevices = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    initBluetooth();
    scanForDevices();
  }
  

  Future<void> initBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        setState(() {
          errorMessage = 'Bluetooth is not available on this device';
          isCheckingDevices = false;
        });
        return;
      }

      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        checkConnectedDevices();
      } else {
        FlutterBluePlus.adapterState.listen((state) {
          if (state == BluetoothAdapterState.on) {
            checkConnectedDevices();
          } else {
            setState(() {
              connectedDevices = [];
              errorMessage = 'Bluetooth is turned off';
              isCheckingDevices = false;
            });
          }
        });
        
        setState(() {
          errorMessage = 'Please turn on Bluetooth';
          isCheckingDevices = false;
        });
      }
      
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing Bluetooth: $e';
        isCheckingDevices = false;
      });
    }
  }

  Future<void> checkConnectedDevices() async {
    setState(() {
      isCheckingDevices = true;
      errorMessage = '';
    });
    
    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
      if (mounted) {
        setState(() {
          connectedDevices = devices;
          isCheckingDevices = false;
        });
      }
      debugPrint("Found ${devices.length} connected devices");
      for (var device in devices) {
        debugPrint("Connected device: ${device.advName ?? device.remoteId.toString()}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to get connected devices: $e';
          isCheckingDevices = false;
        });
      }
      debugPrint("Error checking connected devices: $e");
    }
  }
  
  // Modified method to scan for available devices
  Future<void> scanForDevices() async {
    if (_scanning) return;
    
    setState(() {
      _scanning = true;
      _scanResults = [];
      errorMessage = '';
    });
    
    try {
      // Make sure Bluetooth is enabled
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        setState(() {
          errorMessage = 'Please turn on Bluetooth';
          _scanning = false;
        });
        return;
      }
      
      // Stop any existing scan first
      await FlutterBluePlus.stopScan();
      
      // Create a subscription to continuously update scan results
      var subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          debugPrint("Scan found ${results.length} devices");
          if (mounted) {
            setState(() {
              _scanResults = results;
            });
          }
        },
        onError: (e) {
          debugPrint("Scan error: $e");
          if (mounted) {
            setState(() {
              errorMessage = 'Scan error: $e';
            });
          }
        }
      );
      
      // Start scanning
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      
      // Wait for the scan to complete
      await Future.delayed(Duration(seconds: 10));
      
      // Clean up
      await subscription.cancel();
      
    } catch (e) {
      debugPrint("Error during scan: $e");
      if (mounted) {
        setState(() => errorMessage = 'Error scanning devices: $e');
      }
    } finally {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  // Add a new function to connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        errorMessage = '';
      });
      
      // Show a snackbar to indicate connection attempt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to ${device.advName.isNotEmpty ? device.advName : "device"}...'))
      );
      
      // Attempt to connect to the device
      await device.connect();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected successfully!'))
      );
      
      // Refresh the connected devices list
      await checkConnectedDevices();
      
    } catch (e) {
      debugPrint("Connection error: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e'))
      );
    }
  }

  // Add a function to disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      setState(() {
        errorMessage = '';
      });
      
      // Show a snackbar to indicate disconnection attempt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnecting from ${device.advName.isNotEmpty ? device.advName : "device"}...'))
      );
      
      // Attempt to disconnect from the device
      await device.disconnect();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected successfully!'))
      );
      
      // Refresh the connected devices list
      await checkConnectedDevices();
      
    } catch (e) {
      debugPrint("Disconnection error: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnection failed: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            onPressed: connectedDevices.isNotEmpty 
              ? () async {
                  // Disconnect from the first connected device
                  if (connectedDevices.isNotEmpty) {
                    await disconnectFromDevice(connectedDevices.first);
                  }
                }
              : null,
            icon: Icon(Icons.link_off),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanForDevices,
        child: _scanning 
          ? CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.search),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              // New section for displaying available (scanned) devices
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Available Devices',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                height: 300,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                  gradient: LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                ),
                child: _scanning
                  ? Center(child: CircularProgressIndicator())
                  : _scanResults.isEmpty
                    ? Center(child: Text("No devices found. Tap scan to search."))
                    : ListView.builder(
                        itemCount: _scanResults.length,
                        itemBuilder: (context, index) {
                          final result = _scanResults[index];
                          final device = result.device;
                          return ListTile(
                            title: Text(device.advName.isNotEmpty ? device.advName : 'Unnamed Device'),
                            subtitle: Text(device.remoteId.toString()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('RSSI: ${result.rssi}'),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => connectToDevice(device),
                                  child: Text('Connect'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
