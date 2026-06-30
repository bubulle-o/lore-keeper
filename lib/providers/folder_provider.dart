import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/folder_service.dart';


//////////////////////////////////////////////////////
//                    PROVIDER                      //
//////////////////////////////////////////////////////

/// Gère l'état des dossiers et notifie l'UI à chaque changement.
/// Les dossiers sont indexés par ID de parent pour un accès rapide
/// (clé null = dossiers racine).
class FolderProvider extends ChangeNotifier {

  final FolderService _service = FolderService();

  // Cache : parentId → liste de ses enfants directs
  Map<String?, List<Folder>> _foldersByParent = {};

  // Résultats de la dernière recherche
  List<Folder> _searchResults = [];


  //////////////////////////////////////////////////////
  //                   ACCESSEURS                     //
  //////////////////////////////////////////////////////

  /// Retourne les enfants directs d'un dossier ([] si pas encore chargés).
  List<Folder> getFolders(String? parentId) {
    return _foldersByParent[parentId] ?? [];
  }

  /// Retourne les résultats de la dernière recherche.
  List<Folder> getSearchFolders() {
    return _searchResults;
  }


  //////////////////////////////////////////////////////
  //                    ACTIONS                       //
  //////////////////////////////////////////////////////

  /// Charge les enfants directs d'un dossier depuis la BDD et notifie l'UI.
  Future<void> loadFolders(String? parentId) async {
    _foldersByParent[parentId] = await _service.getDescendants(parentId);
    notifyListeners();
  }

  /// Crée un dossier et recharge la liste du parent.
  Future<void> createFolder(String name, String? parentFolder, String? iconPath) async {
    try {
      await _service.createFolder(name, parentFolder, iconPath);
      await loadFolders(parentFolder);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Renomme ou déplace un dossier, puis recharge les deux parents concernés.
  Future<void> changeFolder(String id, String? name, String? newParentFolder) async {
    Folder old = await _service.loadFolder(id);
    String? oldParentFolder = old.parentFolder;
    await _service.changeFolder(id, name, newParentFolder);
    await loadFolders(newParentFolder);
    await loadFolders(oldParentFolder);
    notifyListeners();
  }

  /// Supprime un dossier et recharge la liste du parent.
  Future<void> deleteFolder(String id, String? parentFolder) async {
    await _service.deleteFolder(id);
    await loadFolders(parentFolder);
    notifyListeners();
  }

  /// Retourne tous les dossiers (utilisé pour construire l'arbre de déplacement).
  Future<List<Folder>> getAllFolders() async {
    return await _service.getAllFolders();
  }


  //////////////////////////////////////////////////////
  //                   RECHERCHE                      //
  //////////////////////////////////////////////////////

  Future<void> searchFolders(String query, Folder? folder) async {
    _searchResults = await _service.searchFolder(query, folder);
    notifyListeners();
  }
}