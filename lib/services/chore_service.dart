import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore_model.dart';

class ChoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChoreModel>> streamChores(String flatId) {
    return _db
        .collection('flats')
        .doc(flatId)
        .collection('chores')
        .orderBy('nextDueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChoreModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addChore(String flatId, ChoreModel chore) async {
    await _db
        .collection('flats')
        .doc(flatId)
        .collection('chores')
        .add(chore.toMap());
  }

  Future<void> deleteChore(String flatId, String choreId) async {
    await _db
        .collection('flats')
        .doc(flatId)
        .collection('chores')
        .doc(choreId)
        .delete();
  }
  
  Future<void> completeChore(String flatId, String choreId, String userId, {bool isAdmin = false}) async {
    DocumentReference choreRef = _db.collection('flats').doc(flatId).collection('chores').doc(choreId);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(choreRef);
      if (!snapshot.exists) throw Exception("Chore not found");
      
      ChoreModel chore = ChoreModel.fromFirestore(snapshot);
      
      if (chore.assignedTo != userId && !isAdmin) {
        throw Exception("You are not assigned to this chore");
      }
      
      int nextIdx = (chore.rotationIndex + 1) % chore.participants.length;
      String nextUser = chore.participants[nextIdx];
      
      DateTime now = DateTime.now();
      DateTime nextDueDate;
      switch(chore.frequency) {
        case 'Daily': nextDueDate = now.add(const Duration(days: 1)); break;
        case 'Weekly': nextDueDate = now.add(const Duration(days: 7)); break;
        case 'Monthly': nextDueDate = now.add(const Duration(days: 30)); break;
        default: nextDueDate = now.add(const Duration(days: 7));
      }
      
      transaction.update(choreRef, {
        'rotationIndex': nextIdx,
        'assignedTo': nextUser,
        'nextDueDate': Timestamp.fromDate(nextDueDate),
        'lastCompletedAt': Timestamp.fromDate(now),
        'lastCompletedBy': userId,
      });
    });
    
    // Save completion history to subcollection
    await choreRef.collection('completions').add({
      'completedBy': userId,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> joinChore(String flatId, String choreId, String userId) async {
    await _db
        .collection('flats')
        .doc(flatId)
        .collection('chores')
        .doc(choreId)
        .update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> leaveChore(String flatId, String choreId, String userId) async {
    return removeParticipant(flatId, choreId, userId);
  }

  Future<void> removeParticipant(String flatId, String choreId, String userId) async {
    DocumentReference choreRef = _db.collection('flats').doc(flatId).collection('chores').doc(choreId);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(choreRef);
      if (!snapshot.exists) throw Exception("Chore not found");
      
      ChoreModel chore = ChoreModel.fromFirestore(snapshot);
      
      if (!chore.participants.contains(userId)) return; // Already not in it
      
      if (chore.participants.length <= 1) {
        throw Exception("Cannot remove: This is the only participant. Delete the chore instead.");
      }

      List<String> newParticipants = List.from(chore.participants)..remove(userId);
      Map<String, dynamic> updates = {
         'participants': newParticipants
      };
      
      if (chore.assignedTo == userId) {
         updates['rotationIndex'] = 0;
         updates['assignedTo'] = newParticipants[0];
      } else {
         int currentAssignedIdx = newParticipants.indexOf(chore.assignedTo);
         if (currentAssignedIdx != -1) {
             updates['rotationIndex'] = currentAssignedIdx;
         } else {
             updates['rotationIndex'] = 0;
             updates['assignedTo'] = newParticipants[0];
         }
      }
      
      transaction.update(choreRef, updates);
    });
  }

  static String getRandomSuccessMessage() {
    const messages = [
      "Heroic effort! 🦸‍♂️",
      "Squeaky clean! ✨",
      "Flat looks better already! 🏡",
      "One less mess! 🗑️",
      "You're a legend! 🏆",
      "Task destroyed! 💥",
      "Flawless victory! 🎮",
      "Boom! Done. 💣",
      "Pure magic! 🪄",
      "Productivity x100! 🚀"
    ];
    return messages[Random().nextInt(messages.length)];
  }

  Future<void> removeUserFromAllChoreRotations(String flatId, String userId) async {
    QuerySnapshot choresQuery = await _db.collection('flats').doc(flatId).collection('chores').get();
    
    for (var doc in choresQuery.docs) {
      ChoreModel chore = ChoreModel.fromFirestore(doc);
      if (chore.participants.contains(userId)) {
        try {
          await removeParticipant(flatId, chore.id, userId);
        } catch (e) {
          // If it's the only participant, we can't remove without deleting the chore.
          // For now, we skip. Ideally, we might want to flag the chore as "no participants".
        }
      }
    }
  }
}
