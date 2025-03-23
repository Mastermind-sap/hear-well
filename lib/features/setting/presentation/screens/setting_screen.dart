import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/main.dart';
import 'package:echo_aid/services/audio/models/audio_profile.dart';
import 'package:flutter/material.dart';
import 'package:echo_aid/services/audio_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioService _audioService = AudioService();
  final AuthService _authService = AuthService();

  // Theme mode state
  bool _isDarkMode = false;

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
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Added a tab for app settings
    _loadCurrentSettings();

    // Check current theme mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brightness = Theme.of(context).brightness;
      setState(() {
        _isDarkMode = brightness == Brightness.dark;
      });
    });
  }

  void _loadCurrentSettings() {
    setState(() {
      // Load current values from the audio service
      _currentVolume = _audioService.getVolume() * 100;
      _noiseThreshold = _audioService.noiseThreshold;
      _decibelBoost = _audioService.decibelBoost;
      _noiseSuppressionEnabled = _audioService.isNoiseSuppressionEnabled;
      _compressionThreshold = _audioService.compressionThreshold;
      _compressionRatio = _audioService.compressionRatio;
      _adaptiveGain = _audioService.adaptiveGain;
      _eqValues = List.from(_audioService.equalizer);
      _profiles = _audioService.profiles;
      _currentProfile = _audioService.currentProfile;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    // Actually change the theme instead of just showing a snackbar
    final newThemeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Use a provider or a shared preference to persist the theme mode
    // For simplicity, we're using a global variable in this example
    _updateAppTheme(newThemeMode);

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       'Theme changed to ${_isDarkMode ? 'dark' : 'light'} mode',
    //     ),
    //     behavior: SnackBarBehavior.floating,
    //     width: MediaQuery.of(context).size.width * 0.9,
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }

  void _updateAppTheme(ThemeMode mode) {
    // This is a simple way to access the MaterialApp and update its themeMode
    // In a real app, you might use a provider or another state management solution
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MyApp.of(context)?.updateThemeMode(mode);
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Add gradient background to the entire screen
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
        child: Column(
          children: [
            // Custom app bar with better styling
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [
                            colorScheme.primary.withOpacity(0.8),
                            colorScheme.primary,
                          ]
                          : [
                            colorScheme.primary,
                            colorScheme.primary.withBlue(
                              colorScheme.primary.blue + 30,
                            ),
                          ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fix tabs overflow by making them adapt to screen width
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      return TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isNarrow ? 12 : 15,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: isNarrow ? 11 : 14,
                        ),
                        // Adjust padding for smaller screens
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 4 : 8,
                        ),
                        indicator: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                        tabs: [
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 2 : 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.equalizer),
                                  Text('Enhance'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 2 : 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: isNarrow ? 4 : 8),
                                  Text('Profiles'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 2 : 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.settings),
                                  SizedBox(width: isNarrow ? 4 : 8),
                                  Text('App'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEnhancementSettings(),
                  _buildProfileSettings(),
                  _buildAppSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancementSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume control
          _buildSettingCard(
            title: 'Volume',
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
                    value: _currentVolume,
                    onChanged: (val) {
                      setState(() => _currentVolume = val);
                      _audioService.setVolume(val / 100);
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
                      '${_currentVolume.toStringAsFixed(0)}%',
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

          const SizedBox(height: 16),

          // Noise gate controls
          _buildSettingCard(
            title: 'Noise Gate',
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
                        value: _noiseThreshold,
                        onChanged: (val) {
                          setState(() => _noiseThreshold = val);
                          _audioService.setNoiseThreshold(val);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Less Sensitive',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          _noiseThreshold.toStringAsFixed(3),
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'More Sensitive',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: Text(
                        'Advanced Noise Suppression',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text('Reduces background noise'),
                      value: _noiseSuppressionEnabled,
                      activeColor: Colors.orange,
                      onChanged: (val) async {
                        setState(() => _noiseSuppressionEnabled = val);
                        await _audioService.setNoiseSuppressionEnabled(val);
                      },
                      secondary: Icon(
                        _noiseSuppressionEnabled
                            ? Icons.noise_control_off
                            : Icons.noise_control_off_outlined,
                        color:
                            _noiseSuppressionEnabled
                                ? Colors.orange
                                : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () {
                        _audioService.startNoiseCalibration();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calibrating noise reduction...'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: Icon(Icons.tune),
                      label: Text('Calibrate Noise Floor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Amplitude controls
          _buildSettingCard(
            title: 'Amplitude Enhancement',
            icon: Icons.graphic_eq,
            iconColor: Colors.blue,
            initiallyExpanded: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decibel Boost',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.blue.withOpacity(0.2),
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _decibelBoost,
                    onChanged: (val) {
                      setState(() => _decibelBoost = val);
                      _audioService.setDecibelBoost(val);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Normal',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${_decibelBoost.toStringAsFixed(1)}x',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Maximum',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Adaptive Gain',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.blue.withOpacity(0.2),
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0.5,
                    max: 3.0,
                    value: _adaptiveGain,
                    onChanged: (val) {
                      setState(() => _adaptiveGain = val);
                      _audioService.setAdaptiveGain(val);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${_adaptiveGain.toStringAsFixed(1)}x',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic range compression
          _buildSettingCard(
            title: 'Dynamic Range Compression',
            icon: Icons.compress,
            iconColor: Colors.purple,
            initiallyExpanded: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    activeTrackColor: Colors.purple,
                    inactiveTrackColor: Colors.purple.withOpacity(0.2),
                    thumbColor: Colors.purple,
                    overlayColor: Colors.purple.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0.1,
                    max: 0.9,
                    value: _compressionThreshold,
                    onChanged: (val) {
                      setState(() => _compressionThreshold = val);
                      _audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _compressionThreshold.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Compression Ratio',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.purple,
                    inactiveTrackColor: Colors.purple.withOpacity(0.2),
                    thumbColor: Colors.purple,
                    overlayColor: Colors.purple.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _compressionRatio,
                    onChanged: (val) {
                      setState(() => _compressionRatio = val);
                      _audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'None',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${_compressionRatio.toStringAsFixed(1)}:1',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Maximum',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Equalizer
          _buildSettingCard(
            title: 'Frequency Equalizer',
            icon: Icons.equalizer,
            iconColor: Colors.green,
            initiallyExpanded: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                                            ? Colors.green
                                            : colorScheme.onSurface.withOpacity(
                                              0.1,
                                            ),
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
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getEqColor(
                          _eqValues[_selectedEqBand],
                        ),
                        inactiveTrackColor: _getEqColor(
                          _eqValues[_selectedEqBand],
                        ).withOpacity(0.2),
                        thumbColor: _getEqColor(_eqValues[_selectedEqBand]),
                        overlayColor: _getEqColor(
                          _eqValues[_selectedEqBand],
                        ).withOpacity(0.2),
                      ),
                      child: Slider(
                        min: 0.1,
                        max: 3.0,
                        value: _eqValues[_selectedEqBand],
                        onChanged: (val) {
                          setState(() {
                            _eqValues[_selectedEqBand] = val;
                            _audioService.setEqualizer(_eqValues);
                          });
                        },
                      ),
                    ),
                    Text(
                      'Band ${_selectedEqBand + 1} (${_getFrequencyLabel(_selectedEqBand)}): ${_eqValues[_selectedEqBand].toStringAsFixed(2)}x',
                      style: TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
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
              ),
            ),
          ),

          // Add some bottom padding to ensure everything is scrollable
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save current settings as profile
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.save_alt, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Save Current Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _profileNameController,
                    decoration: InputDecoration(
                      labelText: 'Profile Name',
                      hintText: 'Enter a name for this profile',
                      prefixIcon: Icon(Icons.label_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_profileNameController.text.isNotEmpty) {
                          await _audioService.saveCurrentAsProfile(
                            _profileNameController.text,
                          );
                          _loadCurrentSettings();
                          _profileNameController.clear();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Profile saved successfully',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              width: MediaQuery.of(context).size.width * 0.9,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter a profile name',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              width: MediaQuery.of(context).size.width * 0.9,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Header for profiles list
          Row(
            children: [
              Icon(Icons.list_alt, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Available Profiles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List of saved profiles (removed Expanded and using a Container with fixed height instead)
          _profiles.isEmpty
              ? _buildEmptyProfilesState(theme)
              : Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    final isSelected = _currentProfile?.name == profile.name;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          width: isSelected ? 2 : 0,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          profile.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Noise: ${profile.noiseThreshold.toStringAsFixed(2)}, '
                          'Boost: ${profile.decibelBoost.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? colorScheme.primary.withOpacity(0.2)
                                    : colorScheme.onSurface.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.equalizer,
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _showDeleteProfileDialog(profile.name);
                              },
                              tooltip: 'Delete profile',
                            ),
                            IconButton(
                              icon: Icon(Icons.play_arrow, color: Colors.green),
                              onPressed: () async {
                                await _audioService.applyProfile(profile);
                                _loadCurrentSettings();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Applied profile "${profile.name}"',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Apply profile',
                            ),
                          ],
                        ),
                        onTap: () async {
                          await _audioService.applyProfile(profile);
                          _loadCurrentSettings();
                        },
                      ),
                    );
                  },
                ),
              ),

          // Add padding at the bottom to ensure everything is reachable
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      // Added SingleChildScrollView to prevent overflow
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Theme toggle with improved UI
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.color_lens, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Theme Appearance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Light Theme Option
                      GestureDetector(
                        onTap: () {
                          if (_isDarkMode) _toggleTheme();
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    !_isDarkMode
                                        ? colorScheme.primary.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      !_isDarkMode
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.light_mode,
                                size: 40,
                                color:
                                    !_isDarkMode
                                        ? colorScheme.primary
                                        : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Light',
                              style: TextStyle(
                                fontWeight:
                                    !_isDarkMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    !_isDarkMode
                                        ? colorScheme.primary
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Theme Mode Switch
                      Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          color:
                              _isDarkMode
                                  ? Colors.blue.shade800
                                  : Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              left: _isDarkMode ? 30 : 0,
                              child: GestureDetector(
                                onTap: _toggleTheme,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isDarkMode
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                      size: 16,
                                      color:
                                          _isDarkMode
                                              ? Colors.blue.shade800
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dark Theme Option
                      GestureDetector(
                        onTap: () {
                          if (!_isDarkMode) _toggleTheme();
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    _isDarkMode
                                        ? colorScheme.primary.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _isDarkMode
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.dark_mode,
                                size: 40,
                                color:
                                    _isDarkMode
                                        ? colorScheme.primary
                                        : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dark',
                              style: TextStyle(
                                fontWeight:
                                    _isDarkMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    _isDarkMode
                                        ? colorScheme.primary
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User account settings (logout)
          _buildSettingsCard(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            onTap: _logout,
            showArrow: false,
          ),

          const SizedBox(height: 24),

          // About section
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingsCard(
            icon: Icons.info_outline,
            title: 'App Info',
            subtitle: 'Version 1.0.0',
            showArrow: false,
          ),

          _buildSettingsCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
          ),

          _buildSettingsCard(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get assistance with the app',
          ),
        ],
      ),
    );
  }

  // Helper widget for settings items in App Settings tab
  Widget _buildSettingsCard({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = iconColor ?? colorScheme.primary;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
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
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          trailing:
              trailing ??
              (showArrow ? Icon(Icons.arrow_forward_ios, size: 16) : null),
          onTap: onTap,
        ),
      ),
    );
  }

  // Widget for empty profiles state
  Widget _buildEmptyProfilesState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.save_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved profiles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust your audio settings and save them as a profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Expandable settings card widget
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

  Widget _buildEqPresetButton(String label, List<double> values) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: colorScheme.surfaceVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          _eqValues = List.from(values);
          _audioService.setEqualizer(_eqValues);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Profile'),
            ],
          ),
          content: Text('Are you sure you want to delete "$profileName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_forever),
              label: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _audioService.deleteProfile(profileName);
                Navigator.of(context).pop();
                _loadCurrentSettings();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted profile "$profileName"',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
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
