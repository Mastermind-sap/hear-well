import 'package:echo_aid/features/connection/presentation/screens/widgets/device_item.dart';
import 'package:echo_aid/features/connection/presentation/screens/widgets/scanning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
    bool _isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    
    // Listen for Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _isBluetoothOn = state == BluetoothAdapterState.on;
      });
    });
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      setState(() {
        _isBluetoothOn = isOn;
      });
    } catch (e) {
      print("Error checking Bluetooth status: $e");
    }
  }

  Future<void> _toggleBluetooth() async {
    try {
      if (_isBluetoothOn) {
        // Note: Most platforms don't allow programmatically turning off Bluetooth
        print("Please turn off Bluetooth manually from settings");
      } else {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print("Error toggling Bluetooth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: (_isBluetoothOn) ?[
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Lottie.asset('assets/lottiefiles/scanning.json'),
          ),
          SizedBox(height: 20),
          Container(
            width: width,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurpleAccent, Colors.indigoAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                child: const Icon(Icons.bluetooth, size: 50,),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            
            "Bluetooth is on",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          )
        ]:
        [
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Lottie.asset('assets/lottiefiles/scanning.json'),
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () {
              _toggleBluetooth();
            },
            child: Container(
              width: width,
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey, Colors.blueGrey],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                
                child: CircleAvatar(
                  radius: 50,
                  child: const Icon(Icons.bluetooth, size: 50,),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            
            "Press to turn on Bluetooth",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          )

        ]
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanningScreen()),
            );
            await Future.delayed(const Duration(seconds: 3));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeviceScreen()),
            );
          },
      ),
    );
  }
}