import 'package:flutter/material.dart';

class SleepTimerDialog extends StatefulWidget {
  final Function(int minutes) onTimerSet;
  final int? currentTimerMinutes;

  const SleepTimerDialog({
    super.key,
    required this.onTimerSet,
    this.currentTimerMinutes,
  });

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  double _sliderValue = 0;
  final List<int> _timerOptions = [0, 1, 15, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    if (widget.currentTimerMinutes != null) {
      final index = _timerOptions.indexOf(widget.currentTimerMinutes!);
      _sliderValue = index >= 0 ? index.toDouble() : 0;
    }
  }

  String _getTimerLabel() {
    final minutes = _timerOptions[_sliderValue.toInt()];
    if (minutes == 0) {
      return 'Off';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Sleep Timer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Timer display
            Text(
              _getTimerLabel(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: _sliderValue == 0 ? Colors.grey : Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey[600],
                trackHeight: 2.0,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16.0,
                ),
                overlayColor: Colors.white.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: (_timerOptions.length - 1).toDouble(),
                divisions: _timerOptions.length - 1,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // Timer labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _timerOptions.map((minutes) {
                  return Text(
                    minutes == 0 ? 'Off' : '$minutes min',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Divider
                Container(height: 20, width: 1, color: Colors.grey[600]),

                // Finished button
                TextButton(
                  onPressed: () {
                    final minutes = _timerOptions[_sliderValue.toInt()];
                    widget.onTimerSet(minutes);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Finished',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
