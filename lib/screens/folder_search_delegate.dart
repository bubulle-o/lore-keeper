import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../providers/folder_provider.dart';
import 'folder_screen.dart';

class FolderSearchDelegate extends SearchDelegate {
  Folder? folder;

  FolderSearchDelegate(this.folder);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return Center(child: Text('Tapez pour chercher...'));
    context.read<FolderProvider>().searchFolders(query, folder );
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final folders = context.watch<FolderProvider>().getSearchFolders();
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          leading: Icon(Icons.folder),
          title: Text(folder.name),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FolderScreen(folder: folder)),
            );
          },
        );
      },
    );
  }
}