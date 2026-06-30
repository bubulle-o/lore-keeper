import 'package:flutter/material.dart';
import 'package:mythopolis/screens/folder_screen.dart';
import 'package:mythopolis/screens/folder_search_delegate.dart';
import 'package:provider/provider.dart';
import '../providers/folder_provider.dart';
import 'package:mythopolis/models/folder.dart';


//////////////////////////////////////////////////////
//                 WIDGET PRINCIPAL                 //
//////////////////////////////////////////////////////

/// Écran d'accueil — affiche les dossiers à la racine (parentFolder = null).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //////////////////////////////////////////////////////
  //                 INITIALISATION                   //
  //////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    // Charge les dossiers racine au premier affichage
    Future.microtask(() =>
      context.read<FolderProvider>().loadFolders(null)
    );
  }


  //////////////////////////////////////////////////////
  //                     BUILD                        //
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FolderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mythopolis'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: FolderSearchDelegate(null),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: provider.getFolders(null).length,
        itemBuilder: (context, index) {
          final folder = provider.getFolders(null)[index];
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
                if (value == 'rename') _showRenameDialog(context, folder);
                if (value == 'move') _showMoveDialog(context, folder);
                if (value == 'delete') _showDeleteDialog(context, folder);
              });
            },
            child: ListTile(
              title: Text(folder.name),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FolderScreen(folder: folder)),
              ).then((_) => context.read<FolderProvider>().loadFolders(null)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }


  //////////////////////////////////////////////////////
  //                   DIALOGUES                      //
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
                    null,
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

  void _showRenameDialog(BuildContext context, Folder folder) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renommer'),
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

  void _showMoveDialog(BuildContext context, Folder folder) async {
    List<Folder> allFolders = await context.read<FolderProvider>().getAllFolders();
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

  void _showDeleteDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Si vous supprimer ce dossier, tout son contenu le sera également.'),
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
  //                   UTILITAIRES                    //
  //////////////////////////////////////////////////////

  /// Construit récursivement l'arbre de dossiers pour le dialogue de déplacement.
  /// excludeId : le dossier qu'on déplace (ne doit pas apparaître comme destination).
  List<Map<String, dynamic>> _buildFolderTree(
      List<Folder> allFolders, String? parentId, int depth, String excludeId) {
    List<Map<String, dynamic>> result = [];
    for (Folder folder in allFolders) {
      if (folder.parentFolder == parentId && folder.id != excludeId) {
        print('${folder.name} - depth: $depth - parent: ${folder.parentFolder}');
        result.add({'folder': folder, 'depth': depth});
        result.addAll(_buildFolderTree(allFolders, folder.id, depth + 1, excludeId));
      }
    }
    return result;
  }
}