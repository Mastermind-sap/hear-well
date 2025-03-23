import 'package:echo_aid/services/audio/models/audio_profile.dart';
import 'package:flutter/material.dart';
import 'package:echo_aid/services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  final AudioService audioService;

  const SettingsScreen({Key? key, required this.audioService})
    : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Audio settings
  double _currentVolume = 50;
  double _noiseThreshold = 0.01;
  double _decibelBoost = 1.0;
  bool _noiseSuppressionEnabled = true;
  double _compressionThreshold = 0.5;
  double _compressionRatio = 2.0;
  double _adaptiveGain = 1.0;
  int _selectedEqBand = 0;
  late List<double> _eqValues;

  // Profile management
  final _profileNameController = TextEditingController();
  late List<AudioProfile> _profiles;
  AudioProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    setState(() {
      // Load current values from the audio service
      _currentVolume = widget.audioService.getVolume() * 100;
      _noiseThreshold = widget.audioService.noiseThreshold;
      _decibelBoost = widget.audioService.decibelBoost;
      _noiseSuppressionEnabled = widget.audioService.isNoiseSuppressionEnabled;
      _compressionThreshold = widget.audioService.compressionThreshold;
      _compressionRatio = widget.audioService.compressionRatio;
      _adaptiveGain = widget.audioService.adaptiveGain;
      _eqValues = List.from(widget.audioService.equalizer);
      _profiles = widget.audioService.profiles;
      _currentProfile = widget.audioService.currentProfile;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Enhancement Settings'),
            Tab(text: 'Profiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildEnhancementSettings(), _buildProfileSettings()],
      ),
    );
  }

  Widget _buildEnhancementSettings() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Volume control
            ListTile(
              title: const Text('Volume'),
              subtitle: Slider(
                min: 0,
                max: 100,
                value: _currentVolume,
                onChanged: (val) {
                  setState(() => _currentVolume = val);
                  widget.audioService.setVolume(val / 100);
                },
              ),
              trailing: Text('${_currentVolume.toStringAsFixed(0)}%'),
            ),

            const Divider(),

            // Noise gate controls
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Noise Gate'),
              children: [
                ListTile(
                  title: const Text('Threshold'),
                  subtitle: Slider(
                    min: 0.0,
                    max: 0.5,
                    value: _noiseThreshold,
                    onChanged: (val) {
                      setState(() => _noiseThreshold = val);
                      widget.audioService.setNoiseThreshold(val);
                    },
                  ),
                  trailing: Text(_noiseThreshold.toStringAsFixed(3)),
                ),
                SwitchListTile(
                  title: const Text('Advanced Noise Suppression'),
                  subtitle: const Text('Reduces background noise'),
                  value: _noiseSuppressionEnabled,
                  onChanged: (val) async {
                    setState(() => _noiseSuppressionEnabled = val);
                    await widget.audioService.setNoiseSuppressionEnabled(val);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.audioService.startNoiseCalibration();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calibrating noise reduction...'),
                      ),
                    );
                  },
                  child: const Text('Calibrate Noise Floor'),
                ),
              ],
            ),

            // Amplitude controls
            ExpansionTile(
              title: const Text('Amplitude Enhancement'),
              children: [
                ListTile(
                  title: const Text('Decibel Boost'),
                  subtitle: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _decibelBoost,
                    onChanged: (val) {
                      setState(() => _decibelBoost = val);
                      widget.audioService.setDecibelBoost(val);
                    },
                  ),
                  trailing: Text('${_decibelBoost.toStringAsFixed(1)}x'),
                ),
                ListTile(
                  title: const Text('Adaptive Gain'),
                  subtitle: Slider(
                    min: 0.5,
                    max: 3.0,
                    value: _adaptiveGain,
                    onChanged: (val) {
                      setState(() => _adaptiveGain = val);
                      widget.audioService.setAdaptiveGain(val);
                    },
                  ),
                  trailing: Text('${_adaptiveGain.toStringAsFixed(1)}x'),
                ),
              ],
            ),

            // Dynamic range compression
            ExpansionTile(
              title: const Text('Dynamic Range Compression'),
              children: [
                ListTile(
                  title: const Text('Threshold'),
                  subtitle: Slider(
                    min: 0.1,
                    max: 0.9,
                    value: _compressionThreshold,
                    onChanged: (val) {
                      setState(() => _compressionThreshold = val);
                      widget.audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                  trailing: Text(_compressionThreshold.toStringAsFixed(2)),
                ),
                ListTile(
                  title: const Text('Compression Ratio'),
                  subtitle: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _compressionRatio,
                    onChanged: (val) {
                      setState(() => _compressionRatio = val);
                      widget.audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                  trailing: Text('${_compressionRatio.toStringAsFixed(1)}:1'),
                ),
              ],
            ),

            // Equalizer
            ExpansionTile(
              title: const Text('Frequency Equalizer'),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Adjust frequency bands to enhance specific ranges of sound',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      10,
                      (index) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedEqBand = index);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getFrequencyLabel(index),
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 25,
                              height: 100,
                              decoration: BoxDecoration(
                                color:
                                    _selectedEqBand == index
                                        ? Colors.blue
                                        : Colors.grey[300],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 20,
                                    height: _eqValues[index] * 80,
                                    color: _getEqColor(_eqValues[index]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Slider(
                  min: 0.1,
                  max: 3.0,
                  value: _eqValues[_selectedEqBand],
                  onChanged: (val) {
                    setState(() {
                      _eqValues[_selectedEqBand] = val;
                      widget.audioService.setEqualizer(_eqValues);
                    });
                  },
                  activeColor: _getEqColor(_eqValues[_selectedEqBand]),
                ),
                Text(
                  'Band ${_selectedEqBand + 1} (${_getFrequencyLabel(_selectedEqBand)}): ${_eqValues[_selectedEqBand].toStringAsFixed(2)}x',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEqPresetButton('Flat', [
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                    ]),
                    _buildEqPresetButton('Bass+', [
                      2,
                      1.8,
                      1.5,
                      1.2,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                    ]),
                    _buildEqPresetButton('Speech', [
                      1,
                      1.2,
                      1.5,
                      2,
                      1.8,
                      1.5,
                      1.2,
                      1,
                      1,
                      1,
                    ]),
                    _buildEqPresetButton('Treble+', [
                      1,
                      1,
                      1,
                      1,
                      1,
                      1.2,
                      1.5,
                      1.8,
                      2,
                      2,
                    ]),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Enhancement Profiles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Save current settings as profile
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save Current Settings as Profile',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _profileNameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter a name for this profile',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_profileNameController.text.isNotEmpty) {
                        await widget.audioService.saveCurrentAsProfile(
                          _profileNameController.text,
                        );
                        _loadCurrentSettings();
                        _profileNameController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile "${_profileNameController.text}" saved',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a profile name'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Available Profiles',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),

          // List of saved profiles
          Expanded(
            child:
                _profiles.isEmpty
                    ? const Center(child: Text('No saved profiles yet'))
                    : ListView.builder(
                      itemCount: _profiles.length,
                      itemBuilder: (context, index) {
                        final profile = _profiles[index];
                        final isSelected =
                            _currentProfile?.name == profile.name;

                        return Card(
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: ListTile(
                            title: Text(profile.name),
                            subtitle: Text(
                              'Noise: ${profile.noiseThreshold.toStringAsFixed(2)}, '
                              'Boost: ${profile.decibelBoost.toStringAsFixed(1)}x',
                            ),
                            leading:
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                    )
                                    : const Icon(Icons.equalizer),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await _showDeleteProfileDialog(
                                      profile.name,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () async {
                                    await widget.audioService.applyProfile(
                                      profile,
                                    );
                                    _loadCurrentSettings();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Applied profile "${profile.name}"',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () async {
                              await widget.audioService.applyProfile(profile);
                              _loadCurrentSettings();
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqPresetButton(String label, List<double> values) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () {
        setState(() {
          _eqValues = List.from(values);
          widget.audioService.setEqualizer(_eqValues);
        });
      },
      child: Text(label),
    );
  }

  Future<void> _showDeleteProfileDialog(String profileName) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: Text('Are you sure you want to delete "$profileName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await widget.audioService.deleteProfile(profileName);
                Navigator.of(context).pop();
                _loadCurrentSettings();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted profile "$profileName"')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getFrequencyLabel(int index) {
    // Approximate frequency bands for 10-band EQ
    final List<String> labels = [
      '32Hz',
      '64Hz',
      '125Hz',
      '250Hz',
      '500Hz',
      '1kHz',
      '2kHz',
      '4kHz',
      '8kHz',
      '16kHz',
    ];
    return labels[index];
  }

  Color _getEqColor(double value) {
    if (value < 0.8) return Colors.blue.shade300;
    if (value < 1.2) return Colors.green;
    if (value < 2.0) return Colors.orange;
    return Colors.red;
  }
}