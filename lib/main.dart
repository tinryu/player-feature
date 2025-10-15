import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/playlist_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // This prevents the keyboard error by ensuring proper key event handling
  SystemChannels.keyEvent.setMessageHandler((dynamic message) {
    // Handle key events here if needed
    return Future.value(null);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: PlaylistScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
