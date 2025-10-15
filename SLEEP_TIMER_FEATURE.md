# Sleep Timer Feature

## Overview
Added a sleep timer feature to the music player that allows users to set a timer to automatically pause playback after a specified duration.

## Features Implemented

### 1. Sleep Timer Dialog (`lib/widgets/sleep_timer_dialog.dart`)
- Beautiful dark-themed dialog matching the reference image
- Slider with 4 options: Off, 30 min, 60 min, 90 min
- Large display showing selected timer value
- Cancel and Finished buttons
- Smooth animations and transitions

### 2. AudioService Sleep Timer (`lib/services/audio_service.dart`)
Added the following methods and properties:
- `setSleepTimer(int minutes)` - Set a sleep timer
- `cancelSleepTimer()` - Cancel active timer
- `sleepTimerStream` - Stream to listen for timer changes
- `sleepTimerMinutes` - Get current timer value

### 3. Player UI Integration (`lib/widgets/player_vertical.dart`)
- Added bedtime icon button next to song title
- Icon changes color to amber when timer is active
- Shows tooltip with remaining time
- Opens sleep timer dialog on tap
- Real-time updates via StreamBuilder

## How It Works

1. **User taps the bedtime icon** in the player screen
2. **Sleep timer dialog appears** with slider to select duration
3. **User selects time** (Off, 30, 60, or 90 minutes)
4. **Timer starts** when user taps "Finished"
5. **Icon turns amber** to indicate active timer
6. **Music pauses automatically** when timer expires
7. **Timer resets** to off state

## Usage

```dart
// Set a 30-minute sleep timer
audioService.setSleepTimer(30);

// Cancel the timer
audioService.cancelSleepTimer();

// Listen to timer changes
audioService.sleepTimerStream.listen((minutes) {
  print('Timer set to: $minutes minutes');
});
```

## UI Design
- Matches the reference image with dark theme
- Smooth slider interaction
- Clear visual feedback (amber icon when active)
- Positioned next to song title for easy access
- Non-intrusive design that doesn't clutter the UI

## Files Modified
1. `lib/services/audio_service.dart` - Added sleep timer logic
2. `lib/widgets/player_vertical.dart` - Added sleep timer button and dialog integration
3. `lib/widgets/sleep_timer_dialog.dart` - New file with dialog UI

## Testing
To test the sleep timer:
1. Open the app and play a song
2. Tap the full-screen player to expand it
3. Tap the bedtime icon next to the song title
4. Select a timer duration (30, 60, or 90 minutes)
5. Tap "Finished"
6. The icon will turn amber indicating the timer is active
7. Music will pause automatically after the selected duration
