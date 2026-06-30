//////////////////////////////////////////////////////
//                     MODÈLE                       //
//////////////////////////////////////////////////////

/// Représente une note textuelle appartenant à un dossier.
/// Le contenu est stocké au format Delta JSON (flutter_quill).
class Note {

  String id;
  String name;
  String parentFolder; // toujours rattachée à un dossier
  String? iconPath;
  String? content;   // Delta JSON produit par flutter_quill
  String? bookmarks; // signets éventuels (non encore implémentés)

  Note(this.id, this.name, this.parentFolder, this.iconPath, this.content, this.bookmarks);


  //////////////////////////////////////////////////////
  //                  SÉRIALISATION                   //
  //////////////////////////////////////////////////////

  /// Convertit la note en Map pour insertion en base de données.
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "parentFolder": parentFolder,
      "iconPath": iconPath,
      "content": content,
      "bookmarks": bookmarks,
    };
  }

  /// Crée un objet Note depuis une Map issue de la base de données.
  static Note fromMap(Map<String, dynamic> data) {
    return Note(
      data["id"],
      data["name"],
      data["parentFolder"],
      data["iconPath"],
      data["content"],
      data["bookmarks"],
    );
  }
}