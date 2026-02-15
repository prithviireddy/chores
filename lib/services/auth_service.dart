import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of UserModel? (null if signed out)
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncExpand((User? user) {
      if (user == null) return Stream.value(null);
      return _db.collection('users').doc(user.uid).snapshots().map((doc) {
         if (doc.exists) {
           return UserModel.fromFirestore(doc);
         }
         return null; 
      });
    });
  }

  // Sign In
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Recovery: User exists in Auth but not in Firestore
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          displayName: result.user!.displayName ?? email.split('@')[0],
          currentFlatId: null,
          flatIds: [],
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(result.user!.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up
  Future<UserModel?> signUp(String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          currentFlatId: null,
          flatIds: [],
          createdAt: DateTime.now(),
        );

        // Create user doc
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update Display Name
  Future<void> updateDisplayName(String newName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
      await _db.collection('users').doc(user.uid).update({'displayName': newName});
    }
  }
}
