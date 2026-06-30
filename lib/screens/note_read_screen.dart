import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:mythopolis/models/folder.dart';
import 'package:mythopolis/models/note.dart';
import 'package:mythopolis/screens/folder_screen.dart';
import 'package:mythopolis/screens/note_edit_screen.dart';
import 'package:mythopolis/services/folder_service.dart';
import 'dart:convert';
import 'package:mythopolis/services/note_service.dart';


//////////////////////////////////////////////////////
//                   WIDGET PRINCIPAL               //
//////////////////////////////////////////////////////

class NoteReadScreen extends StatefulWidget {
  final Note note;

  const NoteReadScreen({super.key, required this.note});

  @override
  State<NoteReadScreen> createState() => _NoteReadScreenState();
}

class _NoteReadScreenState extends State<NoteReadScreen> {

  // Contrôleur Quill en lecture seule
  late QuillController _quillController;


  //////////////////////////////////////////////////////
  //                 INITIALISATION                   //
  //////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    // Charger le contenu existant ou document vide
    final content = widget.note.content;
    final doc = (content != null && content.isNotEmpty)
        ? Document.fromJson(jsonDecode(content))
        : Document();

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,  // lecture seule — l'utilisateur ne peut pas modifier
    );
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }


  //////////////////////////////////////////////////////
  //                     BUILD                        //
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.name),
        actions: [
          // Bouton pour passer en mode édition
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _goToEditScreen(context),
          ),
        ],
      ),
      // Affichage du contenu en lecture seule avec marges
      // TODO: à terme, deux pages A4 côte à côte façon livre
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
        child: QuillEditor.basic(
          controller: _quillController,
          config: QuillEditorConfig(
            onLaunchUrl: _handleLinkTap,
            embedBuilders: FlutterQuillEmbeds.editorBuilders(),
          ),
        ),
      ),
    );
  }


  //////////////////////////////////////////////////////
  //                   NAVIGATION                     //
  //////////////////////////////////////////////////////

  /// Navigation vers l'écran d'édition
  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(note: widget.note),
      ),
    );
  }


  //////////////////////////////////////////////////////
  //                     LIENS                        //
  //////////////////////////////////////////////////////

  /// Gère les liens internes de l'application.
  /// Un lien vers une note ou un dossier ouvre l'écran correspondant,
  /// les autres liens sont ignorés.
  Future<void> _handleLinkTap(String url) async {
    if (url.substring(8).startsWith('note_')) {
      Note note = await NoteService().loadNote(url.substring(8));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteReadScreen(note: note)),
      );
    }

    if (url.substring(8).startsWith('folder_')) {
      Folder folder = await FolderService().loadFolder(url.substring(8));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FolderScreen(folder: folder)),
      );
    } else {
      return;
    }
  }
}