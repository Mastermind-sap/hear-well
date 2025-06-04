import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioControlsPage extends StatefulWidget {
  @override
  _AudioControlsPageState createState() => _AudioControlsPageState();
}

class _AudioControlsPageState extends State<AudioControlsPage> {
  static const platform = MethodChannel('com.example.hear_well/control');

  double _volume = 1.0; // Range 0.0 - 2.0
  double _noiseGateThreshold = -50.0; // dB
  List<double> _equalizerGains = [0, 0, 0, 0, 0]; // 5 bands: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
  

  Future<void> _updateAudioSettings() async {
    try {
      await platform.invokeMethod('updateAudioSettings', {
        'volume': _volume,
        'noiseGateThreshold': _noiseGateThreshold,
        'equalizerGains': _equalizerGains,
      });
    } on PlatformException catch (e) {
      print("Failed to update audio settings: '${e.message}'.");
    }
  }

  Widget _buildSlider(String label, double min, double max, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          min: min,
          max: max,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEqualizerSliders() {
    final bandLabels = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Equalizer", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            return Column(
              children: [
                Text(bandLabels[index]),
                RotatedBox(
                  quarterTurns: -1,
                  child: Slider(
                    min: -12,
                    max: 12,
                    value: _equalizerGains[index],
                    onChanged: (val) {
                      setState(() {
                        _equalizerGains[index] = val;
                      });
                      _updateAudioSettings();
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
    bool initiallyExpanded = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = iconColor ?? colorScheme.primary;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      colorScheme.surface,
                      Color.alphaBlend(
                        baseColor.withOpacity(0.05),
                        colorScheme.surface,
                      ),
                    ]
                    : [
                      Colors.white,
                      Color.alphaBlend(
                        baseColor.withOpacity(0.07),
                        Colors.white,
                      ),
                    ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withOpacity(0.1),
                  baseColor.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: baseColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [Color(0xFF1A1A2E), Color(0xFF16213E)]
                      : [Color(0xFFF8FBFF), Color(0xFFF0F4F8)],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSettingCard(
                        title: "Volume",
                        icon: Icons.volume_up,
                    iconColor: colorScheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withOpacity(0.2),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            value: _volume,
                            onChanged: (val) {
                              setState(() => _volume = val);
                              _updateAudioSettings();
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.volume_mute,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                            Text(
                              '${_volume.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              Icons.volume_up,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                
                      ),
                      SizedBox(height: 10), // Adjusted spacing
                      _buildSettingCard(
                        title: "Noise Gate",
                        icon: Icons.noise_aware,
                    iconColor: Colors.orange,
                    initiallyExpanded: true,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Constrain the height so it doesn't overflow
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Threshold',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.orange,
                                inactiveTrackColor: Colors.orange.withOpacity(0.2),
                                thumbColor: Colors.orange,
                                overlayColor: Colors.orange.withOpacity(0.2),
                              ),
                              child: Slider(
                                min: 0.0,
                                max: 0.5,
                                value: -(_noiseGateThreshold)/100.0,
                                onChanged: (val) {
                                  setState(() => _noiseGateThreshold = -val * 100.0);
                                  _updateAudioSettings();
                                },
                              ),
                            ), ]))
                      ),),
                      SizedBox(height: 10), // Adjusted spacing
                      _buildSettingCard(
                        title: "Equalizer",
                        icon: Icons.graphic_eq,
                        child: _buildEqualizerSliders(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
