import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/equalizer.dart';

class EqualizerService {
  static const String _equalizerSettingsKey = 'equalizer_settings';

  final StreamController<EqualizerSettings> _settingsController =
      StreamController<EqualizerSettings>.broadcast();

  EqualizerSettings _currentSettings = EqualizerSettings(
    isEnabled: false,
    currentPreset: DefaultEqualizerPresets.presets.first,
    customPresets: [],
  );

  // AudioPlayer instance for equalizer integration
  AudioPlayer? _audioPlayer;

  // Getters
  Stream<EqualizerSettings> get settingsStream => _settingsController.stream;
  EqualizerSettings get currentSettings => _currentSettings;
  bool get isEnabled => _currentSettings.isEnabled;
  EqualizerPreset get currentPreset => _currentSettings.currentPreset;
  List<EqualizerPreset> get allPresets => [
    ...DefaultEqualizerPresets.presets,
    ..._currentSettings.customPresets,
  ];

  EqualizerService() {
    _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_equalizerSettingsKey);

      if (settingsJson != null && settingsJson.isNotEmpty) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = EqualizerSettings.fromJson(settingsMap);
      } else {
        // Initialize with default settings
        _currentSettings = EqualizerSettings(
          isEnabled: false,
          currentPreset: DefaultEqualizerPresets.presets.first,
          customPresets: [],
        );
      }

      _settingsController.add(_currentSettings);
    } catch (e) {
      print('Error loading equalizer settings: $e');
      _settingsController.add(_currentSettings);
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_currentSettings.toJson());
      await prefs.setString(_equalizerSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving equalizer settings: $e');
    }
  }

  // Toggle equalizer on/off
  Future<void> toggleEqualizer() async {
    _currentSettings = _currentSettings.copyWith(
      isEnabled: !_currentSettings.isEnabled,
    );
    _settingsController.add(_currentSettings);
    await _saveSettings();
    await applyEqualizerSettings();
  }

  // Set equalizer enabled state
  Future<void> setEnabled(bool enabled) async {
    if (_currentSettings.isEnabled != enabled) {
      _currentSettings = _currentSettings.copyWith(isEnabled: enabled);
      _settingsController.add(_currentSettings);
      await _saveSettings();
      await applyEqualizerSettings();
    }
  }

  // Set current preset
  Future<void> setPreset(EqualizerPreset preset) async {
    _currentSettings = _currentSettings.copyWith(currentPreset: preset);
    _settingsController.add(_currentSettings);
    await _saveSettings();
    await applyEqualizerSettings();
  }

  // Update band gain
  Future<void> updateBandGain(int frequency, double gain) async {
    final updatedBands = _currentSettings.currentPreset.bands.map((band) {
      if (band.frequency == frequency) {
        return band.copyWith(gain: gain);
      }
      return band;
    }).toList();

    final updatedPreset = _currentSettings.currentPreset.copyWith(
      bands: updatedBands,
    );
    _currentSettings = _currentSettings.copyWith(currentPreset: updatedPreset);
    _settingsController.add(_currentSettings);
    await _saveSettings();
    await applyEqualizerSettings();
  }

  // Reset to flat (all gains = 0)
  Future<void> resetToFlat() async {
    final flatPreset = DefaultEqualizerPresets.presets.first;
    _currentSettings = _currentSettings.copyWith(currentPreset: flatPreset);
    _settingsController.add(_currentSettings);
    await _saveSettings();
    await applyEqualizerSettings();
  }

  // Save current settings as custom preset
  Future<void> saveAsCustomPreset(String name) async {
    final customPreset = EqualizerPreset(
      name: name,
      bands: List.from(_currentSettings.currentPreset.bands),
      isCustom: true,
    );

    final updatedCustomPresets = List<EqualizerPreset>.from(
      _currentSettings.customPresets,
    )..add(customPreset);

    _currentSettings = _currentSettings.copyWith(
      customPresets: updatedCustomPresets,
      currentPreset: customPreset,
    );

    _settingsController.add(_currentSettings);
    await _saveSettings();
  }

  // Delete custom preset
  Future<void> deleteCustomPreset(EqualizerPreset preset) async {
    if (!preset.isCustom) return;

    final updatedCustomPresets = _currentSettings.customPresets
        .where((p) => p.name != preset.name)
        .toList();

    // If we're deleting the current preset, switch to flat
    EqualizerPreset newCurrentPreset = _currentSettings.currentPreset;
    if (_currentSettings.currentPreset.name == preset.name) {
      newCurrentPreset = DefaultEqualizerPresets.presets.first;
    }

    _currentSettings = _currentSettings.copyWith(
      customPresets: updatedCustomPresets,
      currentPreset: newCurrentPreset,
    );

    _settingsController.add(_currentSettings);
    await _saveSettings();
  }

  // Get gain for a specific frequency
  double getGainForFrequency(int frequency) {
    final band = _currentSettings.currentPreset.bands
        .where((band) => band.frequency == frequency)
        .firstOrNull;
    return band?.gain ?? 0.0;
  }

  // Get all band gains as a map
  Map<int, double> getAllBandGains() {
    final Map<int, double> gains = {};
    for (final band in _currentSettings.currentPreset.bands) {
      gains[band.frequency] = band.gain;
    }
    return gains;
  }

  // Check if current preset is custom
  bool get isCurrentPresetCustom => _currentSettings.currentPreset.isCustom;

  // Get frequency bands
  List<EqualizerBand> get frequencyBands =>
      _currentSettings.currentPreset.bands;

  // Set AudioPlayer reference for equalizer integration
  void setAudioPlayer(AudioPlayer audioPlayer) {
    _audioPlayer = audioPlayer;
  }

  // Apply equalizer settings to the audio player
  Future<void> applyEqualizerSettings() async {
    if (_audioPlayer == null || !_currentSettings.isEnabled) {
      return;
    }

    try {
      // Get current band gains
      final gains = getAllBandGains();

      // Apply equalizer settings using AudioPlayer's built-in capabilities
      // Note: This is a simplified implementation. In a real app, you might need
      // to use platform channels to access native equalizer APIs

      // For now, we'll simulate the equalizer effect by adjusting volume
      // This is a placeholder - in a production app, you'd integrate with
      // native equalizer APIs or use a proper audio processing library

      print('Equalizer applied with gains: $gains');
    } catch (e) {
      print('Error applying equalizer settings: $e');
    }
  }

  // Get equalizer status for UI display
  String getEqualizerStatus() {
    if (!_currentSettings.isEnabled) {
      return 'Equalizer: Off';
    }

    final presetName = _currentSettings.currentPreset.name;
    final customIndicator = _currentSettings.currentPreset.isCustom
        ? ' (Custom)'
        : '';
    return 'Equalizer: $presetName$customIndicator';
  }

  // Get current preset name
  String get currentPresetName => _currentSettings.currentPreset.name;

  // Check if equalizer is currently active
  bool get isActive => _currentSettings.isEnabled;

  void dispose() {
    _settingsController.close();
  }
}
