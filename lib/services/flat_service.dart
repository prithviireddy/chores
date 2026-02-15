import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flat_chore/services/chore_service.dart';
import '../models/flat_model.dart';
import '../models/user_model.dart';

class FlatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ChoreService _choreService = ChoreService();

  // Create Flat
  Future<FlatModel> createFlat({required String name, required UserModel user, String? password}) async {
    String code = _generateFlatCode();
    // Todo: Check for collision, but for now assume unique
    
    DocumentReference flatRef = _db.collection('flats').doc();
    DocumentReference userRef = _db.collection('users').doc(user.uid);

    FlatModel newFlat = FlatModel(
      id: flatRef.id,
      code: code,
      name: name,
      ownerId: user.uid,
      memberIds: [user.uid],
      memberCount: 1,
      createdAt: DateTime.now(),
      password: password,
    );

    await _db.runTransaction((transaction) async {
       // Create flat
       transaction.set(flatRef, newFlat.toMap());
       
       // Update user
       transaction.update(userRef, {
         'currentFlatId': newFlat.id,
         'flatIds': FieldValue.arrayUnion([newFlat.id])
       });
    });
    return newFlat;
  }

  // Join Flat
  Future<FlatModel?> joinFlat({required String code, required UserModel user, String? providedPassword}) async {
    QuerySnapshot query = await _db.collection('flats').where('code', isEqualTo: code).limit(1).get();
    
    if (query.docs.isEmpty) {
      throw Exception('Flat not found with code: $code');
    }

    DocumentSnapshot flatDoc = query.docs.first;
    DocumentReference flatRef = flatDoc.reference;
    DocumentReference userRef = _db.collection('users').doc(user.uid);
    
    FlatModel? joinedFlat;

    await _db.runTransaction((transaction) async {
      DocumentSnapshot freshFlatSnapshot = await transaction.get(flatRef);
      if (!freshFlatSnapshot.exists) throw Exception("Flat does not exist!");
      
      FlatModel flat = FlatModel.fromFirestore(freshFlatSnapshot);
      

      // Verification: Check password if set
      if (flat.password != null && flat.password!.isNotEmpty) {
        if (flat.password != providedPassword) {
           throw Exception("Incorrect password for this flat.");
        }
      }

      if (flat.memberIds.contains(user.uid)) {
         // Already a member, ensure user has flatId set and in flatIds list
         joinedFlat = flat;
         transaction.update(userRef, {
           'currentFlatId': flat.id,
           'flatIds': FieldValue.arrayUnion([flat.id])
         });
         return;
      }

      List<String> newMembers = List.from(flat.memberIds)..add(user.uid);
      
      transaction.update(flatRef, {
        'memberIds': newMembers,
        'memberCount': flat.memberCount + 1
      });
      
      transaction.update(userRef, {
        'currentFlatId': flat.id,
        'flatIds': FieldValue.arrayUnion([flat.id])
      });
      
      joinedFlat = FlatModel(
        id: flat.id,
        code: flat.code,
        name: flat.name,
        ownerId: flat.ownerId,
        memberIds: newMembers,
        memberCount: flat.memberCount + 1,
        createdAt: flat.createdAt,
        password: flat.password,
      );
    });
    
    return joinedFlat;
  }

  Stream<FlatModel?> getFlatStream(String flatId) {
    return _db.collection('flats').doc(flatId).snapshots().map((doc) {
      if (doc.exists) {
        return FlatModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<List<UserModel>> getFlatMembers(String flatId) async {
    DocumentSnapshot flatDoc = await _db.collection('flats').doc(flatId).get();
    if (!flatDoc.exists) return [];
    
    FlatModel flat = FlatModel.fromFirestore(flatDoc);
    if (flat.memberIds.isEmpty) return [];

    // Chunking logic for whereIn (max 10)
    List<UserModel> members = [];
    for (var i = 0; i < flat.memberIds.length; i += 10) {
      var chunk = flat.memberIds.sublist(i, min(i + 10, flat.memberIds.length));
      try {
        QuerySnapshot usersQuery = await _db.collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
        members.addAll(usersQuery.docs.map((doc) => UserModel.fromFirestore(doc)));
      } catch (e) {
      }
    }
    
    return members;
  }

  Future<List<FlatModel>> getFlatsForUser(List<String> flatIds) async {
    if (flatIds.isEmpty) return [];
    
    // Firestore whereIn supports up to 10
    List<FlatModel> flats = [];
    
    for (var i = 0; i < flatIds.length; i += 10) {
      var chunk = flatIds.sublist(i, min(i + 10, flatIds.length));
      QuerySnapshot query = await _db.collection('flats')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      flats.addAll(query.docs.map((doc) => FlatModel.fromFirestore(doc)));
    }
    
    return flats;
  }

  Stream<List<FlatModel>> getPublicFlats() {
    return _db.collection('flats').limit(20).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FlatModel.fromFirestore(doc)).toList();
    });
  }

  String _generateFlatCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }

  Future<void> leaveFlat(String flatId, UserModel user) async {
    DocumentReference flatRef = _db.collection('flats').doc(flatId);
    DocumentReference userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot flatSnapshot = await transaction.get(flatRef);
      if (!flatSnapshot.exists) return;

      FlatModel flat = FlatModel.fromFirestore(flatSnapshot);
      if (!flat.memberIds.contains(user.uid)) return;

      // Cannot leave if owner? For now, let's allow it but warn or transfer? 
      // User requested "option to leave the flat". 
      // If owner leaves, maybe the flat should be deleted or owner transferred?
      // For MVP: If owner, they should probably delete it or transfer. 
      // But let's just let them leave.
      
      List<String> newFlatMembers = List.from(flat.memberIds)..remove(user.uid);
      transaction.update(flatRef, {
        'memberIds': newFlatMembers,
        'memberCount': flat.memberCount - 1,
      });

      List<String> newUserFlats = List.from(user.flatIds)..remove(flatId);
      String? newCurrentFlatId = newUserFlats.isNotEmpty ? newUserFlats.first : null;
      
      transaction.update(userRef, {
        'flatIds': newUserFlats,
        'currentFlatId': newCurrentFlatId,
      });
    });

    // Cleanup chores
    await _choreService.removeUserFromAllChoreRotations(flatId, user.uid);
  }
}
