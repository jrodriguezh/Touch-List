// import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import "package:sqflite/sqflite.dart";
// import "package:path_provider/path_provider.dart";
// import "package:path/path.dart" show join;
// import 'package:touchandlist/extensions/list/filter.dart';
// import 'crud_exceptions.dart';

// //THIS LOCAL CRUD IS NOT USED ON THE FINAL VERSION OF THE APP, WE MIGRATED IT TO FIRESTORE
// class NotesService {
//   Database? _db;

//   List<DatabaseNote> _notes = [];

//   DatabaseUser? _user;

//   // This will create a singleton for the NotesService, so it will be only one.
//   static final NotesService _shared = NotesService._sharedInstance();
//   NotesService._sharedInstance() {
//     _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
//       onListen: () {
//         _notesStreamController.sink.add(_notes);
//       },
//     );
//   }
//   factory NotesService() {
//     return _shared;
//   }

//   late final StreamController<List<DatabaseNote>> _notesStreamController;

// // We create a bool flag that filters the notes get from the database
// // from users

//   Stream<List<DatabaseNote>> get allNotes {
//     return _notesStreamController.stream.filter((note) {
//       final currentUser = _user;
//       if (currentUser != null) {
//         return note.userId == currentUser.id;
//       } else {
//         throw UserShouldBeSetBeforeReadingAllNotes();
//       }
//     });
//   }

//   Future<DatabaseUser> getOtCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     try {
//       final user = await getUser(email: email);
//       if (setAsCurrentUser) {
//         _user = user;
//       }
//       return user;
//     } on CouldNotFindUser {
//       final createdUser = await createUser(email: email);
//       if (setAsCurrentUser) {
//         _user = createdUser;
//       }
//       return createdUser;
//     } catch (e) {
//       //We can place a stop here to debug the code if we need it in the future
//       rethrow;
//     }
//   }

//   Future<void> _cacheNotes() async {
//     final allNotes = await getAllNotes();
//     _notes = allNotes.toList();
//     _notesStreamController.add(_notes);
//   }

//   Future<DatabaseNote> updateNote({
//     required DatabaseNote note,
//     required String text,
//   }) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();

//     // Make sure that the note exists
//     await getNote(id: note.id);

//     //Update DB
//     final updatesCount = await db.update(
//       noteTable,
//       {
//         textColumn: text,
//         isSincedWithCloudColumn: 0,
//       },
//       where: "id = ?",
//       whereArgs: [note.id],
//     );

//     if (updatesCount == 0) {
//       throw CouldNotUpdateNote();
//     } else {
//       final updatedNote = await getNote(id: note.id);
//       _notes.removeWhere((note) => note.id == updatedNote.id);
//       _notes.add(updatedNote);
//       _notesStreamController.add(_notes);
//       return updatedNote;
//     }
//   }

//   Future<Iterable<DatabaseNote>> getAllNotes() async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(noteTable);

//     return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
//   }

//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final notes = await db.query(
//       noteTable,
//       limit: 1,
//       where: "id = ?",
//       whereArgs: [id],
//     );

//     if (notes.isEmpty) {
//       throw CouldNotFindNote();
//     } else {
//       final note = DatabaseNote.fromRow(notes.first);
//       _notes.removeWhere((note) => note.id == id);
//       _notes.add(note);
//       _notesStreamController.add(_notes);
//       return note;
//     }
//   }

//   Future<int> deleteAllNotes() async {
//     final db = _getDatabaseOrThrow();
//     final numberOfDeletions = await db.delete(noteTable);

//     //We replace the List _notes with an empty List
//     _notes = [];
//     _notesStreamController.add(_notes);

//     return numberOfDeletions;
//   }

//   Future<void> deleteNote({required int id}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       noteTable,
//       where: "id= ?",
//       whereArgs: [id],
//     );
//     if (deletedCount == 0) {
//       throw CouldNotDeleteNote();
//     } else {
//       // Removes the note and update the List
//       _notes.removeWhere((note) => note.id == id);
//       _notesStreamController.add(_notes);
//     }
//   }

//   Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();

//     // make sure owner exists in the database with the correct id
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) {
//       throw CouldNotFindUser();
//     }

//     const text = "";
//     // create the note
//     final noteId = await db.insert(noteTable, {
//       userIdColumn: owner.id,
//       textColumn: text,
//       isSincedWithCloudColumn: 1,
//     });
//     final note = DatabaseNote(
//       id: noteId,
//       userId: owner.id,
//       text: text,
//       isSyncedWithCloud: true,
//     );

//     //afer we create the notes we are placing it on the List of notes

//     _notes.add(note);
//     _notesStreamController.add(_notes);

//     return note;
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isEmpty) {
//       throw CouldNotFindUser();
//     } else {
//       return DatabaseUser.fromRow(results.first);
//     }
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );

//     if (results.isNotEmpty) {
//       throw UserAlreadyExists();
//     }

//     final userId = await db.insert(
//       userTable,
//       {emailColumn: email.toLowerCase()},
//     );

//     return DatabaseUser(id: userId, email: email);
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDBIsOpen();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: "email = ?",
//       whereArgs: [email.toLowerCase()],
//     );

//     if (deletedCount != 1) {
//       throw CouldNotDeleteUser();
//     }
//   }

//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       return db;
//     }
//   }

//   Future<void> close() async {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpen();
//     } else {
//       await db.close();
//     }
//   }

//   Future<void> _ensureDBIsOpen() async {
//     try {
//       await open();
//     } on DatabaseAlreadyOpenException {
//       //empty
//     }
//   }

//   Future<void> open() async {
//     if (_db != null) {
//       throw DatabaseAlreadyOpenException();
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);

//       _db = db;

// // Execute the query that creates both tables, user and note, read constants below for + info
//       await db.execute(createUserTableQuery);
//       await db.execute(createNoteTableQuery);

// // Read all thenotes and place it on the List cachenotes
//       await _cacheNotes();
//     } on MissingPlatformDirectoryException {
//       throw UnableToGetDocumentsDirectory();
//     }
//   }
// }

// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;

//   const DatabaseUser({required this.id, required this.email});

//   DatabaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() {
//     "Person, ID = $id, email =$email";
//     return super.toString();
//   }

//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// @immutable
// class DatabaseNote {
//   final int id;
//   final int userId;
//   final String text;
//   final bool isSyncedWithCloud;

//   DatabaseNote({
//     required this.id,
//     required this.userId,
//     required this.text,
//     required this.isSyncedWithCloud,
//   });

//   //If isSignWithCloud is read as 1, the boolean of isSyncWithCloud will be true, otherwise will be false
//   DatabaseNote.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userId = map[userIdColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedWithCloud =
//             (map[isSincedWithCloudColumn] as int) == 1 ? true : false;

//   @override
//   String toString() {
//     " Note, ID =$id, userId =$userId, isSyncWithCloud = $isSyncedWithCloud, text = $text";
//     return super.toString();
//   }

//   @override
//   bool operator ==(covariant DatabaseNote other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// const dbName = "notes.db";
// const noteTable = "note";
// const userTable = "user";
// const idColumn = "id";
// const emailColumn = "email";
// const userIdColumn = "user_id";
// const textColumn = "text";
// const isSincedWithCloudColumn = "is_synced_with_cloud";

// //For create the DB NOTE, if it doesn't exist, we will take the query and ***add IF NOT EXISTS *** before the name of the table
// const createNoteTableQuery = """CREATE TABLE IF NOT EXISTS "note" (
// 	"id"	INTEGER NOT NULL,
// 	"user_id"	INTEGER NOT NULL,
// 	"text"	TEXT,
// 	"is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
// 	PRIMARY KEY("id" AUTOINCREMENT),
// 	FOREIGN KEY("user_id") REFERENCES "user"("id")
// );""";

// //For create the DB USER, if it doesn't exist, we will take the query and ***add IF NOT EXISTS *** before the name of the table
// const createUserTableQuery = """CREATE TABLE IF NOT EXISTS "user" (
// 	"id"	INTEGER NOT NULL,
// 	"email"	TEXT NOT NULL UNIQUE,
// 	PRIMARY KEY("id" AUTOINCREMENT)
// );""";
