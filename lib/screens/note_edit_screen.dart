import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lore_keeper/models/note.dart';
import 'package:lore_keeper/providers/note_provider.dart';
import 'package:lore_keeper/providers/settings_provider.dart';
import 'package:lore_keeper/utils/enum.dart';
import 'package:provider/provider.dart';
 
class NoteEditScreen extends StatefulWidget {
  final Note note;

  const NoteEditScreen({super.key, required this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  
  // Mode d'écriture actuel (classic ou markdown)
  late NoteMode _writingMode;
  
  // Contrôleur du champ de texte — contient le texte tapé par l'utilisateur
  late TextEditingController _controller;

  // Contenu compilé affiché à l'utilisateur
  late String _renderedContent ;
  
  // Contrôleur pour le Ctrl+Z / Ctrl+Y
  late UndoHistoryController _undoController;

  @override
  void initState() {
    super.initState();
    
    // Lire le mode d'écriture préféré depuis les paramètres
    _writingMode = context.read<SettingsProvider>().defaultWritingMode;
    
    // Initialiser le contrôleur avec le contenu existant de la note
    _controller = TextEditingController(text: widget.note.content ?? '');

    _renderedContent = widget.note.content ?? '' ;
    
    // Initialiser le contrôleur d'historique (Ctrl+Z)
    _undoController = UndoHistoryController();
  }

  @override
  void dispose() {
    // OBLIGATOIRE : libérer la mémoire des contrôleurs quand l'écran est détruit
    _controller.dispose();
    _undoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.name),
        actions: [
          // Bouton pour basculer entre classic et markdown
          IconButton(
            icon: Icon(
              _writingMode == NoteMode.classic 
                ? Icons.code        // icône "code" quand on est en classic
                : Icons.edit,       // icône "edit" quand on est en markdown
            ),
            onPressed: _toggleWritingMode,
          ),
          // Bouton enregistrer
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
          

          // Bouton compiler
          if (_writingMode == NoteMode.markdown)
            IconButton(
              icon : Icon(Icons.play_arrow),
              tooltip : 'compiler',
              onPressed: _compile,
            ),
        ],
      ),
      body: _writingMode == NoteMode.classic 
        ? _buildClassicEditor()
        : _buildMarkdownEditor(),
    );
  }

  // Bascule entre classic et markdown
  void _toggleWritingMode() {
    setState(() {
      _writingMode = _writingMode == NoteMode.classic 
        ? NoteMode.markdown 
        : NoteMode.classic;
    });
  }

  // Sauvegarde le contenu dans la base de données
  Future<void> _saveNote() async {
    await context.read<NoteProvider>().changeNote(
      widget.note.id,
      null,              // on ne change pas le nom
      null,              // On ne changera pas le dossier parent
      _controller.text  // TODO: adapter changeNote pour accepter le contenu
    );
  }

  // Éditeur classique — TextField plein écran + barre d'outils (à faire)
  Widget _buildClassicEditor() {
    return TextField(
      controller: _controller,
      undoController: _undoController,
      maxLines: null,     // permet les sauts de ligne infinis
      expands: true,      // occupe tout l'espace disponible
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  // Éditeur Markdown — écran splitté gauche/droite
  Widget _buildMarkdownEditor() {
    return Row(
      children: [
        // Gauche : éditeur de texte brut
        Expanded(
          child: TextField(
            controller: _controller,
            undoController: _undoController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        // Séparateur vertical
        const VerticalDivider(width: 1),
        // Droite : rendu Markdown
        Expanded(
          child: Markdown(data: _renderedContent),
        ),
      ],
    );
  }

  Future<void> _compile() async{
     setState(() {
      // ici tu modifies tes variables
      _renderedContent = _controller.text;
    });
     _saveNote();
  }
}