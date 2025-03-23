import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProfile {
  final String name;
  final double noiseThreshold;
  final double decibelBoost;
  final List<double> equalizer;
  final double compressionThreshold;
  final double compressionRatio;
  final bool noiseSuppressionEnabled;
  final double adaptiveGain;

  AudioProfile({
    required this.name,
    required this.noiseThreshold,
    required this.decibelBoost,
    required this.equalizer,
    required this.compressionThreshold,
    required this.compressionRatio,
    required this.noiseSuppressionEnabled,
    required this.adaptiveGain,
  });

  // Convert profile to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'noiseThreshold': noiseThreshold,
      'decibelBoost': decibelBoost,
      'equalizer': equalizer,
      'compressionThreshold': compressionThreshold,
      'compressionRatio': compressionRatio,
      'noiseSuppressionEnabled': noiseSuppressionEnabled,
      'adaptiveGain': adaptiveGain,
    };
  }

  // Create profile from JSON
  factory AudioProfile.fromJson(Map<String, dynamic> json) {
    return AudioProfile(
      name: json['name'] as String,
      noiseThreshold: json['noiseThreshold'] as double,
      decibelBoost: json['decibelBoost'] as double,
      equalizer: List<double>.from(json['equalizer'] as List),
      compressionThreshold: json['compressionThreshold'] as double,
      compressionRatio: json['compressionRatio'] as double,
      noiseSuppressionEnabled: json['noiseSuppressionEnabled'] as bool,
      adaptiveGain: json['adaptiveGain'] as double,
    );
  }

  // Copy method for creating modified instances
  AudioProfile copyWith({
    String? name,
    double? noiseThreshold,
    double? decibelBoost,
    List<double>? equalizer,
    double? compressionThreshold,
    double? compressionRatio,
    bool? noiseSuppressionEnabled,
    double? adaptiveGain,
  }) {
    return AudioProfile(
      name: name ?? this.name,
      noiseThreshold: noiseThreshold ?? this.noiseThreshold,
      decibelBoost: decibelBoost ?? this.decibelBoost,
      equalizer: equalizer ?? List.from(this.equalizer),
      compressionThreshold: compressionThreshold ?? this.compressionThreshold,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      noiseSuppressionEnabled:
          noiseSuppressionEnabled ?? this.noiseSuppressionEnabled,
      adaptiveGain: adaptiveGain ?? this.adaptiveGain,
    );
  }
}

class ProfileManager {
  static const String _profilesKey = 'audio_profiles';
  static const String _lastProfileKey = 'last_profile';

  List<AudioProfile> _profiles = [];
  AudioProfile? _currentProfile;

  List<AudioProfile> get profiles => _profiles;
  AudioProfile? get currentProfile => _currentProfile;

  set profile(List<AudioProfile> profiles) {
    _profiles = profiles;
  }

  // Default profiles
  static List<AudioProfile> getDefaultProfiles({
    required double noiseThreshold,
    required double decibelBoost,
    required List<double> equalizer,
    required double compressionThreshold,
    required double compressionRatio,
    required bool noiseSuppressionEnabled,
    required double adaptiveGain,
  }) {
    return [
      AudioProfile(
        name: 'Default',
        noiseThreshold: noiseThreshold,
        decibelBoost: decibelBoost,
        equalizer: List.from(equalizer),
        compressionThreshold: compressionThreshold,
        compressionRatio: compressionRatio,
        noiseSuppressionEnabled: noiseSuppressionEnabled,
        adaptiveGain: adaptiveGain,
      ),
      AudioProfile(
        name: 'Speech Focus',
        noiseThreshold: 0.02,
        decibelBoost: 1.5,
        equalizer: [1.8, 2.0, 2.2, 2.0, 1.8, 1.5, 1.2, 1.0, 0.7, 0.5],
        compressionThreshold: 0.4,
        compressionRatio: 2.5,
        noiseSuppressionEnabled: true,
        adaptiveGain: 1.8,
      ),
      AudioProfile(
        name: 'Music',
        noiseThreshold: 0.005,
        decibelBoost: 1.2,
        equalizer: [1.5, 1.3, 1.2, 1.0, 1.0, 1.0, 1.2, 1.3, 1.5, 1.7],
        compressionThreshold: 0.7,
        compressionRatio: 1.5,
        noiseSuppressionEnabled: false,
        adaptiveGain: 1.3,
      ),
    ];
  }

  // Load profiles from shared preferences
  Future<void> loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_profilesKey);

      if (profilesJson != null) {
        final List<dynamic> decodedList = jsonDecode(profilesJson);
        _profiles =
            decodedList
                .map((profileMap) => AudioProfile.fromJson(profileMap))
                .toList();
      }

      // Load last used profile
      final lastProfileName = prefs.getString(_lastProfileKey);
      if (lastProfileName != null) {
        _currentProfile = _profiles.firstWhere(
          (p) => p.name == lastProfileName,
          orElse:
              () =>
                  _profiles.isNotEmpty
                      ? _profiles[0]
                      : AudioProfile(
                        name: 'Default',
                        noiseThreshold: 0.01,
                        decibelBoost: 1.0,
                        equalizer: List.filled(10, 1.0),
                        compressionThreshold: 0.5,
                        compressionRatio: 2.0,
                        noiseSuppressionEnabled: true,
                        adaptiveGain: 1.0,
                      ),
        );
      }
    } catch (e) {
      print("Error loading profiles: $e");
    }
  }

  // Save profiles to shared preferences
  Future<void> saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = jsonEncode(
        _profiles.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_profilesKey, profilesJson);

      // Save current profile as last used
      if (_currentProfile != null) {
        await prefs.setString(_lastProfileKey, _currentProfile!.name);
      }
    } catch (e) {
      print("Error saving profiles: $e");
    }
  }

  // Set the current profile
  void setCurrentProfile(AudioProfile profile) {
    _currentProfile = profile;
  }

  // Add or update a profile
  void saveProfile(AudioProfile profile) {
    final existingIndex = _profiles.indexWhere((p) => p.name == profile.name);
    if (existingIndex >= 0) {
      _profiles[existingIndex] = profile;
    } else {
      _profiles.add(profile);
    }
    _currentProfile = profile;
  }

  // Delete a profile by name
  void deleteProfile(String name) {
    _profiles.removeWhere((p) => p.name == name);

    // If we deleted the current profile, select the first one
    if (_currentProfile?.name == name && _profiles.isNotEmpty) {
      _currentProfile = _profiles[0];
    }
  }
}
