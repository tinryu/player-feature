import 'package:flutter/material.dart';
import '../services/equalizer_service.dart';
import '../models/equalizer.dart';

class EqualizerDialog extends StatefulWidget {
  final EqualizerService equalizerService;

  const EqualizerDialog({super.key, required this.equalizerService});

  @override
  State<EqualizerDialog> createState() => _EqualizerDialogState();
}

class _EqualizerDialogState extends State<EqualizerDialog> {
  late EqualizerSettings _currentSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.equalizerService.currentSettings;
    _isLoading = false;

    // Listen to settings changes
    widget.equalizerService.settingsStream.listen((settings) {
      if (mounted) {
        setState(() {
          _currentSettings = settings;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.equalizer_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Equalizer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Enable/Disable toggle
                      _buildEnableToggle(),
                      const SizedBox(height: 24),

                      // Preset selector
                      _buildPresetSelector(),
                      const SizedBox(height: 24),

                      // Frequency bands
                      if (_currentSettings.isEnabled) ...[
                        _buildFrequencyBands(),
                        const SizedBox(height: 24),
                      ],

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Enable Equalizer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: _currentSettings.isEnabled,
            onChanged: (value) {
              widget.equalizerService.setEnabled(value);
            },
            activeTrackColor: Colors.redAccent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.equalizerService.allPresets.length,
            itemBuilder: (context, index) {
              final preset = widget.equalizerService.allPresets[index];
              final isSelected =
                  _currentSettings.currentPreset.name == preset.name;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    widget.equalizerService.setPreset(preset);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (preset.isCustom)
                          const Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 16,
                          )
                        else
                          const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          preset.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.redAccent
                                : Colors.white70,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyBands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Frequency Bands',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                widget.equalizerService.resetToFlat();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: _currentSettings.currentPreset.bands.map((band) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildFrequencySlider(band),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySlider(EqualizerBand band) {
    return Row(
      children: [
        // Frequency label
        SizedBox(
          width: 50,
          child: Text(
            band.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),

        // Slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.redAccent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.redAccent,
              overlayColor: Colors.redAccent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: band.gain.clamp(-12.0, 12.0),
              min: -12.0,
              max: 12.0,
              divisions: 48,
              onChanged: (value) {
                widget.equalizerService.updateBandGain(band.frequency, value);
              },
            ),
          ),
        ),

        // Gain value
        SizedBox(
          width: 40,
          child: Text(
            '${band.gain.toStringAsFixed(1)}dB',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showSavePresetDialog();
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Preset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showSavePresetDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Save Custom Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter preset name',
            hintStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                widget.equalizerService.saveAsCustomPreset(
                  nameController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preset saved successfully!'),
                    backgroundColor: Color(0xFF2D2D2D),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
