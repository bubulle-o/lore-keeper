import 'package:mythopolis/models/note.dart';
import 'package:mythopolis/services/database_helper.dart';


//////////////////////////////////////////////////////
//                    SINGLETON                     //
//////////////////////////////////////////////////////

/// Service responsable de toutes les opérations CRUD sur les notes.
/// Communique directement avec la base de données via DatabaseHelper.
class NoteService {

  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();


  //////////////////////////////////////////////////////
  //                      CRUD                        //
  //////////////////////////////////////////////////////

  /// Crée une note dans un dossier. Lève une exception si une note
  /// du même nom existe déjà dans ce dossier.
  Future<void> createNote(String folderName, String parentFolder, String? iconPath) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> nameOk =
        await db.rawQuery('select name from notes where parentFolder = ?', [parentFolder]);

    if (!nameOk.any((map) => map['name'] == folderName)) {
      String id = await _generateId();
      Note note = Note(id, folderName, parentFolder, iconPath, null, null);
      await db.insert('notes', note.toMap());
    } else {
      throw Exception('Il existe déjà une note du même nom à cet emplacement');
    }
  }

  /// Génère un ID unique incrémental au format "note_00001".
  Future<String> _generateId() async {
    final db = await DatabaseHelper().database;
    String? lastId =
        (await db.rawQuery('select MAX(id) from notes')).first['MAX(id)'] as String?;
    int nextId = lastId == null ? 1 : int.parse(lastId.substring(5)) + 1;
    return "note_" + nextId.toString().padLeft(5, '0');
  }

  /// Charge une note par son ID. Lève une exception si elle est introuvable.
  Future<Note> loadNote(String id) async {
    final db = await DatabaseHelper().database;
    return await db.rawQuery('SELECT * FROM notes WHERE id = ?', [id]).then((maps) {
      if (maps.isNotEmpty) return Note.fromMap(maps.first);
      throw Exception('Note not found');
    });
  }

  /// Met à jour le nom, le dossier parent ou le contenu d'une note.
  /// Les paramètres null conservent la valeur actuelle.
  /// Lève une exception si le nouveau nom est déjà pris, sauf si c'est
  /// le même (renommage identique = on laisse passer).
  Future<void> changeNote(String id, String? newName, String? newParent, String? newContent) async {
    final db = await DatabaseHelper().database;
    Note note = await loadNote(id);
    newName ??= note.name;
    newParent ??= note.parentFolder;
    newContent ??= note.content;

    List<Map<String, Object?>> nameOk =
        await db.rawQuery('select name from notes where parentFolder = ?', [newParent]);

    if (!nameOk.any((map) => map['name'] == newName) || newName == note.name) {
      await db.update(
        'notes',
        {'name': newName, 'parentFolder': newParent, 'content': newContent},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      throw Exception('Il existe déjà une note du même nom à cet emplacement');
    }
  }

  /// Supprime une note par son ID.
  Future<void> deleteNote(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }


  //////////////////////////////////////////////////////
  //                   RECHERCHE                      //
  //////////////////////////////////////////////////////

  /// Retourne toutes les notes d'un dossier.
  Future<List<Note>> getNotesFromFolder(String parentFolder) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps =
        await db.rawQuery('SELECT * FROM notes WHERE parentFolder = ?', [parentFolder]);
    return maps.map((data) => Note.fromMap(data)).toList();
  }

  /// Recherche des notes par nom (LIKE) dans un dossier donné.
  Future<List<Note>> searchNote(String query, String parentFolder) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = await db.rawQuery(
        'SELECT * FROM notes WHERE name LIKE ? AND parentFolder = ?',
        ['%$query%', parentFolder]);
    return maps.map((data) => Note.fromMap(data)).toList();
  }
}