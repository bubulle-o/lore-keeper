//////////////////////////////////////////////////////
//                     MODÈLE                       //
//////////////////////////////////////////////////////

/// Représente un dossier pouvant contenir des notes, des fiches
/// et d'autres dossiers (structure arborescente).
class Folder {

  String id;
  String name;
  String? parentFolder; // null si le dossier est à la racine
  String? iconPath;

  Folder(this.id, this.name, this.parentFolder, this.iconPath);


  //////////////////////////////////////////////////////
  //                  SÉRIALISATION                   //
  //////////////////////////////////////////////////////

  /// Convertit le dossier en Map pour insertion en base de données.
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "iconPath": iconPath,
      "parentFolder": parentFolder,
    };
  }

  /// Crée un objet Folder depuis une Map issue de la base de données.
  static Folder fromMap(Map<String, dynamic> data) {
    return Folder(
      data["id"],
      data["name"],
      data["parentFolder"],
      data["iconPath"],
    );
  }
}