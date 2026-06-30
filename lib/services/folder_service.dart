import 'package:mythopolis/services/database_helper.dart';
import '../models/folder.dart';


//////////////////////////////////////////////////////
//                    SINGLETON                     //
//////////////////////////////////////////////////////

/// Service responsable de toutes les opérations CRUD sur les dossiers.
/// Communique directement avec la base de données via DatabaseHelper.
class FolderService {

  static final FolderService _instance = FolderService._internal();
  factory FolderService() => _instance;
  FolderService._internal();


  //////////////////////////////////////////////////////
  //                      CRUD                        //
  //////////////////////////////////////////////////////

  /// Crée un dossier. Lève une exception si un dossier du même nom
  /// existe déjà au même emplacement.
  Future<void> createFolder(String folderName, String? parentFolder, String? iconPath) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> nameOk = [];
    if (parentFolder == null) {
      nameOk = await db.rawQuery('select name from folders where parentFolder is null');
    } else {
      nameOk = await db.rawQuery('select name from folders where parentFolder = ?', [parentFolder]);
    }

    if (!nameOk.any((map) => map['name'] == folderName)) {
      String id = await _generateId();
      Folder folder = Folder(id, folderName, parentFolder, iconPath);
      await db.insert('folders', folder.toMap());
    } else {
      throw Exception('Il existe déjà un dossier du même nom à cet emplacement');
    }
  }

  /// Génère un ID unique incrémental au format "folder_00001".
  Future<String> _generateId() async {
    final db = await DatabaseHelper().database;
    String? lastId = (await db.rawQuery('select MAX(id) from folders')).first['MAX(id)'] as String?;
    int nextId = lastId == null ? 1 : int.parse(lastId.substring(7)) + 1;
    return "folder_" + nextId.toString().padLeft(5, '0');
  }

  /// Charge un dossier par son ID. Lève une exception s'il est introuvable.
  Future<Folder> loadFolder(String id) async {
    final db = await DatabaseHelper().database;
    return await db.rawQuery('SELECT * FROM folders WHERE id = ?', [id]).then((maps) {
      if (maps.isNotEmpty) return Folder.fromMap(maps.first);
      throw Exception('Folder not found');
    });
  }

  /// Retourne les enfants directs d'un dossier (null = racine).
  Future<List<Folder>> getDescendants(String? folderId) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> descendantsMap = folderId == null
        ? await db.rawQuery('SELECT * FROM folders WHERE parentFolder is null')
        : await db.rawQuery('SELECT * FROM folders WHERE parentFolder = ?', [folderId]);

    return descendantsMap.map((data) => Folder.fromMap(data)).toList();
  }

  /// Renomme ou déplace un dossier.
  /// Lève une exception si le nouveau nom est déjà pris à la destination,
  /// sauf si c'est le même dossier qu'on renomme (même nom = on laisse passer).
  Future<void> changeFolder(String id, String? newName, String? newParent) async {
    final db = await DatabaseHelper().database;
    Folder folder = await loadFolder(id);
    newName ??= folder.name;
    newParent ??= folder.parentFolder;

    List<Map<String, Object?>> nameOk = newParent == null
        ? await db.rawQuery('select name from folders where parentFolder is null')
        : await db.rawQuery('select name from folders where parentFolder = ?', [newParent]);

    if (!nameOk.any((map) => map['name'] == newName) || newName == folder.name) {
      await db.update(
        'folders',
        {'name': newName, 'parentFolder': newParent},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      throw Exception('Il existe déjà un fichier du même nom à cet emplacement');
    }
  }

  /// Supprime un dossier (et son contenu en cascade grâce à la FK SQLite).
  Future<void> deleteFolder(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }


  //////////////////////////////////////////////////////
  //                   RECHERCHE                      //
  //////////////////////////////////////////////////////

  /// Retourne tous les dossiers de la base de données.
  Future<List<Folder>> getAllFolders() async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = await db.rawQuery('SELECT * FROM folders');
    return maps.map((data) => Folder.fromMap(data)).toList();
  }

  /// Recherche des dossiers par nom (LIKE) dans un dossier donné.
  /// Si folder est null, cherche à la racine.
  Future<List<Folder>> searchFolder(String query, Folder? folder) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = folder == null
        ? await db.rawQuery('SELECT * FROM folders WHERE name LIKE ? AND parentFolder IS null', ['%$query%'])
        : await db.rawQuery('SELECT * FROM folders WHERE name LIKE ? AND parentFolder = ?', ['%$query%', folder.id]);
    return maps.map((data) => Folder.fromMap(data)).toList();
  }
}