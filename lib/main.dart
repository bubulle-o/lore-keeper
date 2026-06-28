import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/note_provider.dart';
import 'package:lore_keeper/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'providers/folder_provider.dart';
import 'screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lore Keeper',
      home: HomeScreen(),
    );
  }

  
}