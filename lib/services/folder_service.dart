import 'package:lore_keeper/services/database_helper.dart';
import '../models/folder.dart';

class FolderService {
  
  // Instance unique (Singleton)
  static final FolderService _instance = FolderService._internal();
  factory FolderService() => _instance;
  FolderService._internal();


  Future<void> createFolder(String folderName, String? parentFolder, String? iconPath) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> nameOk = [];
    if(parentFolder == null){
      nameOk = await db.rawQuery('select name from folders where parentFolder is null');
    }
    else{
      nameOk = await db.rawQuery('select name from folders where parentFolder = ?', [parentFolder]);
    }

    if(!nameOk.any((map) => map['name'] == folderName)){
    String id = await _generateId();
    Folder folder = Folder(id, folderName, parentFolder, iconPath);
    Map<String, dynamic> folderMap = folder.toMap();
    await db.insert('folders', folderMap);
    }
    else{
      throw Exception('Il existe déjà un dossier du même nom à cet emplacement');
    }
  }

  Future<String> _generateId() async {
    final db = await DatabaseHelper().database;
    String? lastId = (await db.rawQuery('select MAX(id) from folders')).first['MAX(id)'] as String? ;
    int nextId = lastId == null ? 1 : int.parse(lastId.substring(7)) + 1; // Incrémente le compteur pour le nouvel ID
    return "folder_"+ nextId.toString().padLeft( 5, '0');
  }


  Future<Folder> loadFolder(String id) async{
    final db = await DatabaseHelper().database;
    Folder folder = await db.rawQuery('SELECT * FROM folders WHERE id = ?', [id]).then((List<Map<String, dynamic>> maps) {
      if (maps.isNotEmpty) {
        return Folder.fromMap(maps.first);
      } else {
        throw Exception('Folder not found');
      }
    });

    return folder;
  }


  Future<List<Folder>> getDescendants(String? folderId) async {
    List<Map<String, Object?>> descendantsMap = [];
    final db = await DatabaseHelper().database;
    if(folderId == null){
        descendantsMap = await db.rawQuery('SELECT * FROM folders WHERE parentFolder is null');

    }
    else {
      descendantsMap = await db.rawQuery('SELECT * FROM folders WHERE parentFolder = ?', [folderId]);
    }
    List<Folder> descendants = <Folder>[];
    if(descendantsMap.isEmpty){
      return descendants;
    }
    for(Map<String, Object?> data in descendantsMap){
      descendants.add(Folder.fromMap(data));

    }

    return descendants ;
  }

  Future<void> changeFolder(String id, String? newName, String? newParent) async {
    final db = await DatabaseHelper().database;
    Folder folder = await loadFolder(id);
    newName ??= folder.name;
    newParent ??= folder.parentFolder;

    List<Map<String, Object?>> nameOk = [];

    if(newParent == null){
      nameOk = await db.rawQuery('select name from folders where parentFolder is null');
    }
    else{
      nameOk = await db.rawQuery('select name from folders where parentFolder = ?', [newParent]);
    }

    if(!nameOk.any((map) => map['name'] == newName) || newName == folder.name ){
      await db.update('folders', 
      {'name': newName, 'parentFolder' : newParent},
      where : 'id = ?',
      whereArgs: [id]);
    }
    else{
      throw Exception('Il existe déjà un fichier du même nom à cet emplacement');
    }

    
  }

  Future<void> deleteFolder(String id) async{
    final db = await DatabaseHelper().database ;
    await db.delete( 'folders',
    where : 'id = ?',
    whereArgs: [id]);
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = await db.rawQuery('SELECT * FROM folders');
    List<Folder> folders = [];
    for (Map<String, Object?> data in maps) {
      folders.add(Folder.fromMap(data));
    }
    return folders;
  }

  Future<List<Folder>> searchFolder(String query, Folder? folder) async{
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = [];
    if(folder == null){
      maps = await db.rawQuery('SELECT * FROM folders WHERE name LIKE ? AND parentFolder IS null',['%$query%']);
    } else {
      maps = await db.rawQuery('SELECT * FROM folders WHERE name LIKE ? AND parentFolder = ?',['%$query%' , folder.id]);
    }
    List<Folder> folders = [];
    for (Map<String, Object?> data in maps) {
      folders.add(Folder.fromMap(data));
    }
    return folders;
  }


  


}