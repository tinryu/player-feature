import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:playermusic1/screens/home_screen.dart';
import 'package:playermusic1/providers/theme_provider.dart';
import 'package:playermusic1/providers/song_provider.dart';
import 'package:playermusic1/providers/audio_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Add this line before runApp
  GestureBinding.instance.resamplingEnabled = true;
  // This prevents the keyboard error by ensuring proper key event handling
  SystemChannels.keyEvent.setMessageHandler((dynamic message) {
    // Handle key events here if needed
    return Future.value(null);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AudioProvider()),
        ChangeNotifierProxyProvider<AudioProvider, SongProvider>(
          create: (context) => SongProvider(
            audioProvider: Provider.of<AudioProvider>(context, listen: false),
          ),
          update: (context, audioProvider, previous) =>
              previous ?? SongProvider(audioProvider: audioProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
