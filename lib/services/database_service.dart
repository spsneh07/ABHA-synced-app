import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record.dart';
import '../models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Profile Methods ---
  
  Future<void> saveUserProfile(UserProfile profile) async {
    // Fire and forget. Local cache updates instantly, syncs in background.
    _firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Stream<UserProfile?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Create default profile with Google info if none exists
        final user = auth.FirebaseAuth.instance.currentUser;
        String initialName = '';
        String initialPhoto = '';
        if (user != null && user.uid == uid) {
          initialName = user.displayName ?? '';
          initialPhoto = user.photoURL ?? '';
        }
        
        final newProfile = UserProfile(
          uid: uid,
          name: initialName,
          photoUrl: initialPhoto,
        );
        
        // Save it asynchronously so it's initialized
        saveUserProfile(newProfile);
        
        return newProfile;
      }
      
      return UserProfile.fromMap(uid, snapshot.data()!);
    });
  }

  // --- Record Methods ---

  Future<void> addRecord(MedicalRecord record) async {
    // Fire and forget.
    _firestore.collection('records').doc(record.id).set(record.toMap());
  }

  Future<void> deleteRecord(String recordId) async {
    // Fire and forget.
    _firestore.collection('records').doc(recordId).delete();
  }

  Stream<List<MedicalRecord>> getUserRecords(String userId) {
    return _firestore
        .collection('records')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MedicalRecord.fromMap(doc.id, doc.data())).toList();
    });
  }
}
