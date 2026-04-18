import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _upsertUserProfile(User user) async {
    final email = user.email;
    if (email == null || email.trim().isEmpty) return;

    final docRef = _firestore.collection('users').doc(email);
    final snapshot = await docRef.get();

    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : email.split('@').first;

    if (!snapshot.exists) {
      await docRef.set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set(
        {
          'email': email,
          'name': name,
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _upsertUserProfile(user);
      }
      return credential;
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromAuthError(error));
    }
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _upsertUserProfile(user);
      }
      return credential;
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromAuthError(error));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _messageFromAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
