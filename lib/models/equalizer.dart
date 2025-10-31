class EqualizerBand {
  final int frequency;
  final double gain;
  final String label;

  const EqualizerBand({
    required this.frequency,
    required this.gain,
    required this.label,
  });

  EqualizerBand copyWith({int? frequency, double? gain, String? label}) {
    return EqualizerBand(
      frequency: frequency ?? this.frequency,
      gain: gain ?? this.gain,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {'frequency': frequency, 'gain': gain, 'label': label};
  }

  factory EqualizerBand.fromJson(Map<String, dynamic> json) {
    return EqualizerBand(
      frequency: json['frequency'] as int,
      gain: (json['gain'] as num).toDouble(),
      label: json['label'] as String,
    );
  }
}

class EqualizerPreset {
  final String name;
  final List<EqualizerBand> bands;
  final bool isCustom;

  const EqualizerPreset({
    required this.name,
    required this.bands,
    this.isCustom = false,
  });

  EqualizerPreset copyWith({
    String? name,
    List<EqualizerBand>? bands,
    bool? isCustom,
  }) {
    return EqualizerPreset(
      name: name ?? this.name,
      bands: bands ?? this.bands,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bands': bands.map((band) => band.toJson()).toList(),
      'isCustom': isCustom,
    };
  }

  factory EqualizerPreset.fromJson(Map<String, dynamic> json) {
    return EqualizerPreset(
      name: json['name'] as String,
      bands: (json['bands'] as List)
          .map(
            (bandJson) =>
                EqualizerBand.fromJson(bandJson as Map<String, dynamic>),
          )
          .toList(),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class EqualizerSettings {
  final bool isEnabled;
  final EqualizerPreset currentPreset;
  final List<EqualizerPreset> customPresets;

  const EqualizerSettings({
    required this.isEnabled,
    required this.currentPreset,
    required this.customPresets,
  });

  EqualizerSettings copyWith({
    bool? isEnabled,
    EqualizerPreset? currentPreset,
    List<EqualizerPreset>? customPresets,
  }) {
    return EqualizerSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      currentPreset: currentPreset ?? this.currentPreset,
      customPresets: customPresets ?? this.customPresets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'currentPreset': currentPreset.toJson(),
      'customPresets': customPresets.map((preset) => preset.toJson()).toList(),
    };
  }

  factory EqualizerSettings.fromJson(Map<String, dynamic> json) {
    return EqualizerSettings(
      isEnabled: json['isEnabled'] as bool,
      currentPreset: EqualizerPreset.fromJson(
        json['currentPreset'] as Map<String, dynamic>,
      ),
      customPresets: (json['customPresets'] as List)
          .map(
            (presetJson) =>
                EqualizerPreset.fromJson(presetJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// Default equalizer presets
class DefaultEqualizerPresets {
  static const List<EqualizerPreset> presets = [
    EqualizerPreset(
      name: 'Flat',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 0.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 0.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
    EqualizerPreset(
      name: 'Pop',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 1.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 1.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
    EqualizerPreset(
      name: 'Rock',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 0.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 0.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
    EqualizerPreset(
      name: 'Jazz',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 0.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 0.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
    EqualizerPreset(
      name: 'Classical',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 0.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 0.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
    EqualizerPreset(
      name: 'Dance',
      bands: [
        EqualizerBand(frequency: 60, gain: 0.0, label: '60Hz'),
        EqualizerBand(frequency: 170, gain: 0.0, label: '170Hz'),
        EqualizerBand(frequency: 310, gain: 0.0, label: '310Hz'),
        EqualizerBand(frequency: 600, gain: 0.0, label: '600Hz'),
        EqualizerBand(frequency: 1000, gain: 0.0, label: '1kHz'),
        EqualizerBand(frequency: 3000, gain: 0.0, label: '3kHz'),
        EqualizerBand(frequency: 6000, gain: 0.0, label: '6kHz'),
        EqualizerBand(frequency: 12000, gain: 0.0, label: '12kHz'),
        EqualizerBand(frequency: 14000, gain: 0.0, label: '14kHz'),
        EqualizerBand(frequency: 16000, gain: 0.0, label: '16kHz'),
      ],
    ),
  ];
}
