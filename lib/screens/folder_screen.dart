import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mythopolis/models/folder.dart';
import 'package:mythopolis/providers/folder_provider.dart';


//////////////////////////////////////////////////////
//                 WIDGET PRINCIPAL                 //
//////////////////////////////////////////////////////

/// Écran affichant le contenu d'un dossier avec 4 onglets :
/// Tout / Dossiers / Notes / Fiches
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
    // Charge les sous-dossiers du dossier courant
    Future.microtask(() =>
      context.read<FolderProvider>().loadFolders(widget.folder.id)
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
        title: Text(widget.folder.name),
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
          // Onglet "Tout" — liste les sous-dossiers
          ListView.builder(
            itemCount: provider.getFolders(widget.folder.id).length,
            itemBuilder: (context, index) {
              final folder = provider.getFolders(widget.folder.id)[index];
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

          // Onglet "Dossiers" — même liste, dédiée aux dossiers uniquement
          ListView.builder(
            itemCount: provider.getFolders(widget.folder.id).length,
            itemBuilder: (context, index) {
              final childFolder = provider.getFolders(widget.folder.id)[index];
              return ListTile(
                title: Text(childFolder.name),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderScreen(folder: childFolder)),
                ).then((_) => context.read<FolderProvider>().loadFolders(null)),
              );
            },
          ),

          // Onglet "Notes" — à venir
          Center(child: Text('Notes - à venir')),

          // Onglet "Fiches" — à venir
          Center(child: Text('Fiches - à venir')),
        ],
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