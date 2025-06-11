import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioControlsPage extends StatefulWidget {
  @override
  _AudioControlsPageState createState() => _AudioControlsPageState();
}

class _AudioControlsPageState extends State<AudioControlsPage> {
  static const platform = MethodChannel('com.example.hear_well/check');

  double _volume = 50.0; // Range 0.0 - 100.0
  double _noiseGateThreshold = -50.0; // dB
  List<double> _equalizerGains = [0, 0, 0, 0, 0]; // Dynamic based on device equalizer
  List<String> _equalizerBandLabels = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz']; // Default labels
  bool _equalizerInitialized = false;
  int _actualBandCount = 5;
  List<int> _actualCenterFreqs = [];
  bool _isNativeLoopbackActive = false;
  String _nativeLoopbackStatusMessage = "Initializing..."; // Added
  bool _enableNoiseSuppression = false; // Added for NS control

  @override
  void initState() {
    super.initState();
    _initializeEqualizer();
    _checkLoopbackStatus(); // Check status on page load
  }

  Future<void> _initializeEqualizer() async {
    try {
      final result = await platform.invokeMethod('getEqualizerInfo');
      if (result != null) {
        final bandCount = result['bandCount'] as int;
        final bands = result['bands'] as List<dynamic>;
        
        setState(() {
          _actualBandCount = bandCount;
          _equalizerGains = List.filled(bandCount, 0.0);
          _actualCenterFreqs = [];
          _equalizerBandLabels = [];
          
          for (var band in bands) {
            final freq = band['centerFreq'] as int;
            _actualCenterFreqs.add(freq);
            _equalizerBandLabels.add(_formatFrequency(freq));
          }
          
          _equalizerInitialized = true;
        });
        
        print("Equalizer initialized with $bandCount bands");
        // Log the actual frequencies for debugging
        for (int i = 0; i < _equalizerBandLabels.length; i++) {
          print("Band $i: ${_equalizerBandLabels[i]}");
        }
      } else {
        print("getEqualizerInfo returned null - using default values");
        setState(() {
          _equalizerInitialized = true;
        });
      }
    } catch (e) {
      print("Failed to initialize equalizer: $e");
      // Keep using default values
      setState(() {
        _equalizerInitialized = true;
      });
    }
  }

  Future<void> _checkLoopbackStatus() async {
    try {
      final result = await platform.invokeMethod('isNativeLoopbackActive');
      if (mounted) {
        setState(() {
          _isNativeLoopbackActive = result as bool;
          _nativeLoopbackStatusMessage = _isNativeLoopbackActive
              ? "Native Audio Loopback is Active (Global)"
              : "Native Audio Loopback is Inactive (Global)";
        });
      }
      print("Loopback status checked on AudioControlsPage: $_isNativeLoopbackActive");
    } catch (e) {
      print("Failed to check loopback status on AudioControlsPage: $e");
      if (mounted) {
        setState(() {
          _nativeLoopbackStatusMessage = "Error checking global status: $e";
        });
      }
    }
  }

  String _formatFrequency(int freqInMilliHz) {
    final freqInHz = freqInMilliHz ~/ 1000;
    if (freqInHz >= 1000) {
      final freqInKHz = freqInHz / 1000;
      return '${freqInKHz.toStringAsFixed(freqInKHz.truncateToDouble() == freqInKHz ? 0 : 1)}kHz';
    } else {
      return '${freqInHz}Hz';
    }
  }
  

  Future<void> _updateAudioSettings() async {
    try {
      debugPrint("Flutter: Preparing to update audio settings. Volume: $_volume, NoiseGate Threshold: $_noiseGateThreshold, EQ Gains: $_equalizerGains, Enable NS: $_enableNoiseSuppression");
      await platform.invokeMethod('updateAudioSettings', {
        'volume': _volume,
        'noiseGateThreshold': _noiseGateThreshold,
        'equalizerGains': _equalizerGains,
        'enableNoiseSuppression': _enableNoiseSuppression, // Added NS flag
      });
      print("Flutter: Audio settings update method invoked successfully.");
    } on PlatformException catch (e) {
      print("Failed to update audio settings: '${e.message}'.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating audio: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEqualizerSliders() {
    if (!_equalizerInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing Equalizer...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Equalizer",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "$_actualBandCount Bands",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_actualBandCount <= 5)
          // Use vertical sliders for 5 or fewer bands
          Container(
            height: 200, // Fixed height to prevent overflow
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_actualBandCount, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          _equalizerBandLabels[index],
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: 50,
                            child: RotatedBox(
                              quarterTurns: -1,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Theme.of(context).colorScheme.primary,
                                  inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  thumbColor: Theme.of(context).colorScheme.primary,
                                  overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  trackHeight: 4,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  min: -12,
                                  max: 12,
                                  divisions: 24,
                                  value: _equalizerGains[index],
                                  onChanged: (val) {
                                    setState(() {
                                      _equalizerGains[index] = val;
                                    });
                                    _updateAudioSettings();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_equalizerGains[index].toStringAsFixed(1)}dB',
                            style: TextStyle(
                              fontSize: 10, 
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          )
        else
          // Use horizontal sliders for more than 5 bands
          Container(
            constraints: BoxConstraints(maxHeight: 250), // Reduced height
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_actualBandCount, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2.0), // Reduced margin
                    padding: EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60, // Reduced width
                          child: Text(
                            _equalizerBandLabels[index],
                            style: TextStyle(
                              fontSize: 11, // Reduced font size
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              thumbColor: Theme.of(context).colorScheme.primary,
                              overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              trackHeight: 3,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              min: -12,
                              max: 12,
                              divisions: 24,
                              value: _equalizerGains[index],
                              onChanged: (val) {
                                setState(() {
                                  _equalizerGains[index] = val;
                                });
                                _updateAudioSettings();
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50, // Reduced width
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_equalizerGains[index].toStringAsFixed(1)}dB',
                              style: TextStyle(
                                fontSize: 10, // Reduced font size
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        SizedBox(height: 12),
        // Reset button
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _equalizerGains = List.filled(_actualBandCount, 0.0);
              });
              _updateAudioSettings();
            },
            icon: Icon(Icons.refresh, size: 16),
            label: Text('Reset Equalizer'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
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
    
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                SizedBox(height: 10),
                _buildSettingCard(
                  title: "Audio Status",
                  icon: _isNativeLoopbackActive ? Icons.play_circle_filled : Icons.pause_circle_outline,
                  iconColor: _isNativeLoopbackActive ? Colors.green : Colors.grey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isNativeLoopbackActive ? Icons.check_circle : Icons.info_outline,
                            color: _isNativeLoopbackActive ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded( 
                            child: Text(
                              _nativeLoopbackStatusMessage, // Display the detailed status
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isNativeLoopbackActive ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        _isNativeLoopbackActive
                            ? "Audio controls are active. Loopback managed globally."
                            : "Global Native Audio Loopback is inactive. Settings may not apply live.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 16),
                       Center(
                        child: TextButton(
                          onPressed: _checkLoopbackStatus, // Add a button to manually refresh status
                          child: Text("Refresh Loopback Status"),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _buildSettingCard(
                  title: "Noise Gate",
                  icon: Icons.noise_aware,
                  iconColor: Colors.orange,
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
                      SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.orange,
                          inactiveTrackColor: Colors.orange.withOpacity(0.2),
                          thumbColor: Colors.orange,
                          overlayColor: Colors.orange.withOpacity(0.2),
                        ),
                        child: Slider(
                          min: -100.0,
                          max: -10.0,
                          value: _noiseGateThreshold,
                          onChanged: (val) {
                            setState(() => _noiseGateThreshold = val);
                            _updateAudioSettings();
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sensitive',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${_noiseGateThreshold.toStringAsFixed(1)}dB',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Less Sensitive',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Hardware Noise Suppression",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Switch(
                            value: _enableNoiseSuppression,
                            onChanged: (val) {
                              setState(() {
                                _enableNoiseSuppression = val;
                                print("Flutter: Noise Suppression Switch toggled. New state: $_enableNoiseSuppression");
                              });
                              _updateAudioSettings(); // Call general update
                            },
                            activeColor: Colors.teal, // Or your preferred color
                          ),
                        ],
                      ),
                      Text(
                        "Reduces background noise using device hardware. May affect audio quality.",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _buildSettingCard(
                  title: "Equalizer",
                  icon: Icons.graphic_eq,
                  child: _buildEqualizerSliders(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
