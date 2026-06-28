import 'package:flutter/material.dart';
import 'package:lore_keeper/utils/enum.dart';

class SettingsProvider extends ChangeNotifier {
  
  // Mode d'écriture par défaut (classic ou markdown)
  NoteMode defaultWritingMode = NoteMode.classic;
  
  // Thème de l'application
  AppTheme appTheme = AppTheme.light;

  void setDefaultWritingMode(NoteMode noteMode) {
    // On ne peut pas définir "reading" comme mode d'écriture par défaut
    if (noteMode == NoteMode.reading) return;
    defaultWritingMode = noteMode;
    notifyListeners();
  }

  void setTheme(AppTheme theme) {
    appTheme = theme;
    notifyListeners();
  }
}