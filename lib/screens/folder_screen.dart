import 'package:lore_keeper/models/note.dart';
import 'package:lore_keeper/providers/note_provider.dart';
import 'package:lore_keeper/screens/folder_search_delegate.dart';
import 'package:lore_keeper/screens/note_read_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:lore_keeper/models/folder.dart';
import 'package:lore_keeper/providers/folder_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';


//////////////////////////////////////////////////////
//                   WIDGET PRINCIPAL               //
//////////////////////////////////////////////////////

class FolderScreen extends StatefulWidget {
  final Folder folder;
  
  const FolderScreen({super.key, required this.folder});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}
  
class _FolderScreenState extends State<FolderScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;


  //////////////////////////////////////////////////////
  //                 INITIALISATION                   //
  //////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Charge les dossiers enfants du dossier courant
    Future.microtask(() => 
      context.read<FolderProvider>().loadFolders(widget.folder.id)  
    );
    // Charge les notes du dossier courant
    Future.microtask(() => 
      context.read<NoteProvider>().loadNotes(widget.folder.id)
    );
  }


  //////////////////////////////////////////////////////
  //                     BUILD                        //
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final noteProvider = context.watch<NoteProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: FolderSearchDelegate(widget.folder),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tout'),
            Tab(text: 'Dossiers'),
            Tab(text: 'Notes'),
            Tab(text: 'Fiches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [

          // ── Onglet "Tout" ──────────────────────────────
          // TODO: mélanger dossiers + notes avec List<Object>
          ListView.builder(
            itemCount: folderProvider.getFolders(widget.folder.id).length,
            itemBuilder: (context, index) {
              final folder = folderProvider.getFolders(widget.folder.id)[index];
              return _buildFolderTile(context, folder);
            },
          ),

          // ── Onglet "Dossiers" ──────────────────────────
          ListView.builder(
            itemCount: folderProvider.getFolders(widget.folder.id).length,
            itemBuilder: (context, index) {
              final folder = folderProvider.getFolders(widget.folder.id)[index];
              return _buildFolderTile(context, folder);
            },
          ),

          // ── Onglet "Notes" ─────────────────────────────
          ListView.builder(
            itemCount: noteProvider.getNotes(widget.folder.id).length,
            itemBuilder: (context, index) {
              final note = noteProvider.getNotes(widget.folder.id)[index];
              return _buildNoteTile(context, note);
            },
          ),

          // ── Onglet "Fiches" ────────────────────────────
          Center(child: Text('Fiches - à venir')),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.folder),
            label: 'Nouveau dossier',
            onTap: () => _showCreateFolderDialog(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.note),
            label: 'Nouvelle note',
            onTap: () => _showCreateNoteDialog(context),
          ),
        ],
      ),
    );
  }


  //////////////////////////////////////////////////////
  //               WIDGETS RÉUTILISABLES              //
  //////////////////////////////////////////////////////

  /// Carte cliquable pour un dossier avec menu contextuel clic droit
  Widget _buildFolderTile(BuildContext context, Folder folder) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            PopupMenuItem(value: 'rename', child: Text('Renommer')),
            PopupMenuItem(value: 'move', child: Text('Déplacer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ).then((value) {
          if (value == 'rename') _showRenameFolderDialog(context, folder);
          if (value == 'move') _showMoveFolderDialog(context, folder);
          if (value == 'delete') _showDeleteFolderDialog(context, folder);
        });
      },
      child: ListTile(
        leading: Icon(Icons.folder),
        title: Text(folder.name),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FolderScreen(folder: folder)),
        ).then((_) => context.read<FolderProvider>().loadFolders(widget.folder.id)),
      ),
    );
  }

  /// Carte cliquable pour une note avec menu contextuel clic droit
  Widget _buildNoteTile(BuildContext context, Note note) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            PopupMenuItem(value: 'rename', child: Text('Renommer')),
            PopupMenuItem(value: 'move', child: Text('Déplacer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ).then((value) {
          if (value == 'rename') _showRenameNoteDialog(context, note);
          if (value == 'move') _showMoveNoteDialog(context, note);
          if (value == 'delete') _showDeleteNoteDialog(context, note);
        });
      },
      child: ListTile(
        leading: Icon(Icons.note),
        title: Text(note.name),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteReadScreen(note: note)),
        ).then((_) => context.read<NoteProvider>().loadNotes(widget.folder.id)),
      ),
    );
  }


  //////////////////////////////////////////////////////
  //              CRÉATION DOSSIER / NOTE             //
  //////////////////////////////////////////////////////

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau dossier'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nom du dossier'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await context.read<FolderProvider>().createFolder(
                    controller.text,
                    widget.folder.id,
                    null,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouvelle note'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nom de la note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await context.read<NoteProvider>().createNote(
                    controller.text,
                    widget.folder.id,
                    null,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }


  //////////////////////////////////////////////////////
  //             MODIFICATION DOSSIER                 //
  //////////////////////////////////////////////////////

  void _showRenameFolderDialog(BuildContext context, Folder folder) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renommer le dossier'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await context.read<FolderProvider>().changeFolder(
                    folder.id,
                    controller.text,
                    folder.parentFolder,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _showMoveFolderDialog(BuildContext context, Folder folder) async {
    List<Folder> allFolders = await context.read<FolderProvider>().getAllFolders();
    // Exclut le dossier lui-même et ses descendants de la liste
    List<Map<String, dynamic>> tree = _buildFolderTree(allFolders, null, 0, folder.id);
    String? selectedId = folder.parentFolder;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Déplacer vers...'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: [
                // Option racine (sans dossier parent)
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Bureau'),
                  selected: selectedId == null,
                  onTap: () => setState(() => selectedId = null),
                ),
                ...tree.map((item) {
                  Folder f = item['folder'];
                  int depth = item['depth'];
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16.0 + depth * 20),
                    leading: Icon(Icons.folder),
                    title: Text(f.name),
                    selected: selectedId == f.id,
                    onTap: () => setState(() => selectedId = f.id),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await context.read<FolderProvider>().changeFolder(
                    folder.id,
                    null,
                    selectedId,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Déplacer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ce dossier ?'),
        content: Text('Tout son contenu sera également supprimé de façon irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<FolderProvider>().deleteFolder(
                  folder.id,
                  folder.parentFolder,
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }


  //////////////////////////////////////////////////////
  //               MODIFICATION NOTE                  //
  //////////////////////////////////////////////////////

  void _showRenameNoteDialog(BuildContext context, Note note) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renommer la note'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await context.read<NoteProvider>().changeNote(
                    note.id,
                    controller.text,
                    note.parentFolder,
                    note.content,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _showMoveNoteDialog(BuildContext context, Note note) async {
    List<Folder> allFolders = await context.read<FolderProvider>().getAllFolders();
    // Une note peut aller dans n'importe quel dossier
    List<Map<String, dynamic>> tree = _buildWholeFolderTree(allFolders, null, 0);
    String selectedId = note.parentFolder;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Déplacer vers...'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: [
                ...tree.map((item) {
                  Folder f = item['folder'];
                  int depth = item['depth'];
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16.0 + depth * 20),
                    leading: Icon(Icons.folder),
                    title: Text(f.name),
                    selected: selectedId == f.id,
                    onTap: () => setState(() => selectedId = f.id),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await context.read<NoteProvider>().changeNote(
                    note.id,
                    null,
                    selectedId,
                    note.content,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Déplacer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteNoteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer cette note ?'),
        content: Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<NoteProvider>().deleteNote(
                  note.id,
                  note.parentFolder,
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }


  //////////////////////////////////////////////////////
  //             UTILITAIRES ARBORESCENCE             //
  //////////////////////////////////////////////////////

  /// Construit l'arborescence en excluant un dossier et ses descendants
  /// Utilisé pour le déplacement de dossiers
  List<Map<String, dynamic>> _buildFolderTree(
      List<Folder> allFolders, String? parentId, int depth, String excludeId) {
    List<Map<String, dynamic>> result = [];
    for (Folder folder in allFolders) {
      if (folder.parentFolder == parentId && folder.id != excludeId) {
        result.add({'folder': folder, 'depth': depth});
        result.addAll(_buildFolderTree(allFolders, folder.id, depth + 1, excludeId));
      }
    }
    return result;
  }

  /// Construit l'arborescence complète sans exclusion
  /// Utilisé pour le déplacement de notes et fiches
  List<Map<String, dynamic>> _buildWholeFolderTree(
      List<Folder> allFolders, String? parentId, int depth) {
    List<Map<String, dynamic>> result = [];
    for (Folder folder in allFolders) {
      if (folder.parentFolder == parentId) {
        result.add({'folder': folder, 'depth': depth});
        result.addAll(_buildWholeFolderTree(allFolders, folder.id, depth + 1));
      }
    }
    return result;
  }

}