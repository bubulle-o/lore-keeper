import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lore_keeper/models/note.dart';
import 'package:lore_keeper/screens/note_edit_screen.dart';

class NoteReadScreen extends StatelessWidget {
  final Note note;

  const NoteReadScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.name),
        actions: [
          // Bouton pour passer en mode écriture
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _goToEditScreen(context),
          ),
        ],
      ),
      // Affichage du contenu Markdown rendu
      body: Markdown(data: note.content ?? ''),
    );
  }

  // Navigation vers l'écran d'édition
  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(note: note),
      ),
    );
  }
}