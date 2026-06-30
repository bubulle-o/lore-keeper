import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


//////////////////////////////////////////////////////
//                    SINGLETON                     //
//////////////////////////////////////////////////////

/// Point d'accès unique à la base de données SQLite.
/// Le pattern Singleton garantit qu'une seule instance
/// de la base est ouverte pendant toute la durée de vie de l'app.
class DatabaseHelper {

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// Retourne la base de données, en l'initialisant si nécessaire.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }


  //////////////////////////////////////////////////////
  //                 INITIALISATION                   //
  //////////////////////////////////////////////////////

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createSchema,
      onOpen: (db) async {
        // Active les clés étrangères à chaque ouverture (désactivées par défaut sur SQLite)
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }


  //////////////////////////////////////////////////////
  //                     SCHÉMA                       //
  //////////////////////////////////////////////////////

  Future<void> _createSchema(Database db, int version) async {
    // Table des dossiers — supporte la hiérarchie via parentFolder
    await db.execute('''
      CREATE TABLE folders(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parentFolder TEXT,
        iconPath TEXT,
        FOREIGN KEY (parentFolder) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');

    // Table des notes — toujours rattachée à un dossier
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parentFolder TEXT NOT NULL,
        iconPath TEXT,
        content TEXT,
        bookmarks TEXT,
        FOREIGN KEY (parentFolder) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
  }
}