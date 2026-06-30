import 'package:flutter/material.dart';
import 'package:mythopolis/services/note_service.dart';
import '../models/note.dart';


//////////////////////////////////////////////////////
//                    PROVIDER                      //
//////////////////////////////////////////////////////

/// Gère l'état des notes et notifie l'UI à chaque changement.
/// Les notes sont indexées par ID de dossier parent pour un accès rapide.
class NoteProvider extends ChangeNotifier {

  final NoteService _service = NoteService();

  // Cache : parentId → liste des notes de ce dossier
  Map<String, List<Note>> _notesByParent = {};

  // Résultats de la dernière recherche
  List<Note> _searchResults = [];


  //////////////////////////////////////////////////////
  //                   ACCESSEURS                     //
  //////////////////////////////////////////////////////

  /// Retourne les notes d'un dossier ([] si pas encore chargées).
  List<Note> getNotes(String parentId) {
    return _notesByParent[parentId] ?? [];
  }

  /// Retourne les résultats de la dernière recherche.
  List<Note> getSearchNotes() {
    return _searchResults;
  }


  //////////////////////////////////////////////////////
  //                    ACTIONS                       //
  //////////////////////////////////////////////////////

  /// Charge les notes d'un dossier depuis la BDD et notifie l'UI.
  Future<void> loadNotes(String parentId) async {
    _notesByParent[parentId] = await _service.getNotesFromFolder(parentId);
    notifyListeners();
  }

  /// Crée une note et recharge la liste du dossier parent.
  Future<void> createNote(String name, String parentFolder, String? iconPath) async {
    try {
      await _service.createNote(name, parentFolder, iconPath);
      await loadNotes(parentFolder);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour une note (nom, parent, contenu). Recharge les deux parents
  /// si la note est déplacée.
  Future<void> changeNote(String id, String? name, String? newParentFolder, String? newContent) async {
    Note old = await _service.loadNote(id);
    String? oldParentFolder = old.parentFolder;
    await _service.changeNote(id, name, newParentFolder, newContent);
    if (newParentFolder != null) {
      await loadNotes(newParentFolder);
    }
    await loadNotes(oldParentFolder);
    notifyListeners();
  }

  /// Supprime une note et recharge la liste du dossier parent.
  Future<void> deleteNote(String id, String parentFolder) async {
    await _service.deleteNote(id);
    await loadNotes(parentFolder);
    notifyListeners();
  }


  //////////////////////////////////////////////////////
  //                   RECHERCHE                      //
  //////////////////////////////////////////////////////

  Future<void> searchNotes(String query, String parentFolder) async {
    _searchResults = await _service.searchNote(query, parentFolder);
    notifyListeners();
  }
}