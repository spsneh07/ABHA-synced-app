import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1066376738841-nqmi894hi81b9b82b7917f165ou0emr9.apps.googleusercontent.com',
  );

  auth.User? _user;
  auth.User? get user => _user;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((auth.User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on auth.FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign in.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on auth.FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign up.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      // Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'Sign in aborted by user'; // The user canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final auth.OAuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _firebaseAuth.signInWithCredential(credential);
      return null; // success
    } on auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Firebase Google Sign-In failed.';
    } catch (e) {
      return 'Google Sign-In failed. Did you enable it in Firebase Console? Error: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null; // success
    } on auth.FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        await _googleSignIn.signOut();
        return null;
      }
      return 'No user currently logged in.';
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please sign out and sign back in before deleting your account.';
      }
      return e.message ?? 'Failed to delete account.';
    } catch (e) {
      return e.toString();
    }
  }
}
