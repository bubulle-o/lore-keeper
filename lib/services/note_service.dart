import 'package:lore_keeper/models/note.dart';
import 'package:lore_keeper/services/database_helper.dart';


class NoteService {
  
  // Instance unique (Singleton)
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();


  Future<void> createNote(String folderName, String parentFolder, String? iconPath) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> nameOk = await db.rawQuery('select name from notes where parentFolder = ?', [parentFolder]);

    if(!nameOk.any((map) => map['name'] == folderName)){
    String id = await _generateId();
    Note note = Note(id, folderName, parentFolder, iconPath, null, null);
    Map<String, dynamic> noteMap = note.toMap();
    await db.insert('notes', noteMap);
    }
    else{
      throw Exception('Il existe déjà une note du même nom à cet emplacement');
    }
  }

  Future<String> _generateId() async {
    final db = await DatabaseHelper().database;
    String? lastId = (await db.rawQuery('select MAX(id) from notes')).first['MAX(id)'] as String? ;
    int nextId = lastId == null ? 1 : int.parse(lastId.substring(5)) + 1; // Incrémente le compteur pour le nouvel ID
    return "note_"+ nextId.toString().padLeft( 5, '0');
  }


  Future<Note> loadNote(String id) async{
    final db = await DatabaseHelper().database;
    Note note = await db.rawQuery('SELECT * FROM notes WHERE id = ?', [id]).then((List<Map<String, dynamic>> maps) {
      if (maps.isNotEmpty) {
        return Note.fromMap(maps.first);
      } else {
        throw Exception('Note not found');
      }
    });

    return note;
  }

  Future<void> changeNote(String id, String? newName, String? newParent, String? newContent) async {
    final db = await DatabaseHelper().database;
    Note note = await loadNote(id);
    newName ??= note.name;
    newParent ??= note.parentFolder;
    newContent ??= note.content;

    List<Map<String, Object?>> nameOk = await db.rawQuery('select name from notes where parentFolder = ?', [newParent]);
    

    if(!nameOk.any((map) => map['name'] == newName) || newName == note.name){
      await db.update('notes', 
      {'name': newName, 'parentFolder' : newParent, 'content' : newContent},
      where : 'id = ?',
      whereArgs: [id]);
    }
    else{
      throw Exception('Il existe déjà une note du même nom à cet emplacement');
    }

    
  }

  Future<void> deleteNote(String id) async{
    final db = await DatabaseHelper().database ;
    await db.delete( 'notes',
    where : 'id = ?',
    whereArgs: [id]);
  }

  Future<List<Note>> getNotesFromFolder(String parentFolder) async {
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = await db.rawQuery('SELECT * FROM notes WHERE parentFolder = ?', [parentFolder]);
    List<Note> notes = [];
    for (Map<String, Object?> data in maps) {
      notes.add(Note.fromMap(data));
    }
    return notes;
  }

  Future<List<Note>> searchNote(String query, String parentFolder) async{
    final db = await DatabaseHelper().database;
    List<Map<String, Object?>> maps = await db.rawQuery('SELECT * FROM notes WHERE name LIKE ? AND parentFolder = ?',['%$query%' , parentFolder]);
    
    List<Note> notes = [];
    for (Map<String, Object?> data in maps) {
      notes.add(Note.fromMap(data));
    }
    return notes;
  }
}