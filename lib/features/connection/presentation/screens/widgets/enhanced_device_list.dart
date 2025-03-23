import 'package:echo_aid/core/theme/app_gradients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EnhancedDeviceList extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) onDeviceTap;
  final bool isScanning;

  const EnhancedDeviceList({
    Key? key,
    required this.devices,
    required this.onDeviceTap,
    this.isScanning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 70,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              isScanning ? "Searching for devices..." : "No devices found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (!isScanning) ...[
              const SizedBox(height: 12),
              Text(
                "Try turning on Bluetooth on your device",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(context, device, index);
      },
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    BluetoothDevice device,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use theme colors for consistency
    final baseColor = colorScheme.primary;
    final isConnected =
        device.connectionState.first == BluetoothConnectionState.connected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => onDeviceTap(device),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.surfaceGradient(
                context,
                baseColor: baseColor,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDeviceIcon(device),
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),
              title: Text(
                device.name.isNotEmpty ? device.name : "Unknown Device",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    device.id.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<BluetoothConnectionState>(
                    stream: device.connectionState,
                    initialData: BluetoothConnectionState.disconnected,
                    builder: (context, snapshot) {
                      final connectionState = snapshot.data;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getConnectionStateColor(
                            connectionState,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getConnectionStateColor(
                              connectionState,
                            ).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getConnectionStateText(connectionState),
                          style: TextStyle(
                            color: _getConnectionStateColor(connectionState),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              trailing: StreamBuilder<BluetoothConnectionState>(
                stream: device.connectionState,
                initialData: BluetoothConnectionState.disconnected,
                builder: (c, snapshot) {
                  final state = snapshot.data;
                  return _buildConnectionIndicator(state, colorScheme);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(BluetoothDevice device) {
    final name = device.name.toLowerCase();
    if (name.contains('headphone') ||
        name.contains('earphone') ||
        name.contains('headset')) {
      return Icons.headphones;
    } else if (name.contains('speaker') || name.contains('sound')) {
      return Icons.speaker;
    } else if (name.contains('watch') || name.contains('band')) {
      return Icons.watch;
    } else {
      return Icons.bluetooth_audio;
    }
  }

  Color _getConnectionStateColor(BluetoothConnectionState? state) {
    switch (state) {
      case BluetoothConnectionState.connected:
        return Colors.green;
      case BluetoothConnectionState.connecting:
        return Colors.orange;
      case BluetoothConnectionState.disconnecting:
        return Colors.orange.shade700;
      case BluetoothConnectionState.disconnected:
      default:
        return Colors.grey;
    }
  }

  String _getConnectionStateText(BluetoothConnectionState? state) {
    switch (state) {
      case BluetoothConnectionState.connected:
        return "Connected";
      case BluetoothConnectionState.connecting:
        return "Connecting...";
      case BluetoothConnectionState.disconnecting:
        return "Disconnecting...";
      case BluetoothConnectionState.disconnected:
      default:
        return "Disconnected";
    }
  }

  Widget _buildConnectionIndicator(
    BluetoothConnectionState? state,
    ColorScheme colorScheme,
  ) {
    if (state == BluetoothConnectionState.connecting ||
        state == BluetoothConnectionState.disconnecting) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    IconData icon;
    Color color;

    if (state == BluetoothConnectionState.connected) {
      icon = Icons.link;
      color = Colors.green;
    } else {
      icon = Icons.link_off;
      color = Colors.grey;
    }

    return Icon(icon, color: color);
  }
}
