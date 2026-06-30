import 'package:flutter/material.dart';
import 'package:mythopolis/utils/enum.dart';


//////////////////////////////////////////////////////
//                    PROVIDER                      //
//////////////////////////////////////////////////////

/// Gère les préférences globales de l'application (thème, etc.)
/// et notifie l'UI à chaque changement de paramètre.
class SettingsProvider extends ChangeNotifier {

  //////////////////////////////////////////////////////
  //                     THÈME                        //
  //////////////////////////////////////////////////////

  // Thème actif — light par défaut
  AppTheme appTheme = AppTheme.light;

  /// Change le thème de l'application et notifie l'UI.
  void setTheme(AppTheme theme) {
    appTheme = theme;
    notifyListeners();
  }
}