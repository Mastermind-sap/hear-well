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

class _DeviceScreenState extends State<DeviceScreen> with SingleTickerProviderStateMixin {
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
  
  // Animation controller for list animations
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    initBluetooth();
    scanForDevices();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              // Reset and start animation when new results arrive
              _animationController.reset();
              _animationController.forward();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Bluetooth Devices',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => scanForDevices(),
            icon: _scanning 
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: theme.appBarTheme.foregroundColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.refresh, color: theme.appBarTheme.foregroundColor),
            tooltip: 'Scan for devices',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _scanning ? colorScheme.primary : 
                             connectedDevices.isNotEmpty ? colorScheme.secondary : 
                             Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: _scanning ? _PulsingDot(color: colorScheme.primary) : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _scanning ? 'Scanning for devices...' : 
                    connectedDevices.isNotEmpty ? 'Connected to ${connectedDevices.length} device(s)' : 
                    'Ready to connect',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _scanning ? colorScheme.primary : 
                             connectedDevices.isNotEmpty ? colorScheme.secondary : 
                             colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (connectedDevices.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        if (connectedDevices.isNotEmpty) {
                          await disconnectFromDevice(connectedDevices.first);
                        }
                      },
                      icon: Icon(Icons.link_off, size: 16),
                      label: Text('Disconnect All'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            
            // Error message if any
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Device sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Connected devices section
                  if (connectedDevices.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Connected Device', Icons.bluetooth_connected, colorScheme.secondary),
                    ...connectedDevices.map((device) => _buildAnimatedItem(
                      child: _buildConnectedDeviceCard(device, theme, colorScheme),
                      index: connectedDevices.indexOf(device),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  // Available devices section
                  _buildSectionHeader(
                    context, 
                    'Available Devices (${_scanResults.length})', 
                    Icons.bluetooth_searching, 
                    colorScheme.primary,
                    trailing: _scanning ? Row(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scanning...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ) : null,
                  ),
                  
                  // Debug info for scan results - will help during development
                  if (_scanResults.isNotEmpty && _scanResults.length > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Found ${_scanResults.length} devices',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // List of available devices or empty state
                  _scanResults.isEmpty
                    ? _buildEmptyState(theme, colorScheme)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scanResults.length,
                        itemBuilder: (context, index) {
                          final result = _scanResults[index];
                          return _buildAnimatedItem(
                            child: _buildDeviceCard(result, theme, colorScheme),
                            index: index,
                          );
                        },
                      ),
                ]
              ),
            ),
            
            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: scanForDevices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Rescan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedItem({required Widget child, required int index}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final value = _animationController.value - delay;
        final opacity = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
        
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  Widget _buildSectionHeader(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color color, 
    {Widget? trailing}
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_disabled,
              size: 40,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No devices found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your devices are turned on\nand in pairing mode',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: scanForDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceCard(ScanResult result, ThemeData theme, ColorScheme colorScheme) {
    final device = result.device;
    final isConnected = connectedDevices.any((d) => d.remoteId == device.remoteId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected ? colorScheme.secondary : Colors.transparent,
          width: isConnected ? 2 : 0,
        ),
      ),
      elevation: isConnected ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Device icon/avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Device details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.advName.isNotEmpty ? device.advName : 'Unnamed Device',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.remoteId.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Signal strength and action button
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
              child: Row(
                children: [
                  // Signal strength indicator
                  _buildSignalStrengthIndicator(result.rssi, theme, colorScheme),
                  const Spacer(),
                  
                  // Connect/Disconnect button
                  ElevatedButton.icon(
                    onPressed: isConnected 
                      ? () => disconnectFromDevice(device)
                      : () => connectToDevice(device),
                    icon: Icon(
                      isConnected ? Icons.link_off : Icons.link,
                      size: 18,
                    ),
                    label: Text(isConnected ? 'Disconnect' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? colorScheme.errorContainer : colorScheme.primary,
                      foregroundColor: isConnected ? colorScheme.onErrorContainer : colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectedDeviceCard(BluetoothDevice device, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.secondaryContainer,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Connected icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth_connected,
                    color: colorScheme.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Device info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Connected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.advName.isNotEmpty ? device.advName : 'Connected Device',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.remoteId.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    // Device settings action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Device settings not implemented'))
                    );
                  },
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                _buildActionButton(
                  icon: Icons.link_off,
                  label: 'Disconnect',
                  onTap: () => disconnectFromDevice(device),
                  theme: theme,
                  colorScheme: colorScheme,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive 
                ? colorScheme.error.withOpacity(0.1)
                : colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? colorScheme.error : colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDestructive 
                ? colorScheme.error 
                : colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignalStrengthIndicator(int rssi, ThemeData theme, ColorScheme colorScheme) {
    // Determine signal strength level (1-4)
    int signalLevel = 1;
    if (rssi >= -60) signalLevel = 4;
    else if (rssi >= -70) signalLevel = 3;
    else if (rssi >= -80) signalLevel = 2;
    
    Color signalColor = Colors.red;
    if (signalLevel >= 3) signalColor = Colors.green;
    else if (signalLevel >= 2) signalColor = Colors.orange;
    
    return Row(
      children: [
        // Custom signal strength bars
        Container(
          width: 40,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              return Container(
                width: 5,
                height: 5 + (index * 3),
                decoration: BoxDecoration(
                  color: index < signalLevel 
                      ? signalColor 
                      : colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$rssi dBm',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
  
  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}

// Pulsing dot animation for scanning indicator
class _PulsingDot extends StatefulWidget {
  final Color color;
  
  const _PulsingDot({required this.color});
  
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
