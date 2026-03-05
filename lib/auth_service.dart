import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '127205810460-r2mf8j2476qnmp8q9cl33u21gdrnacon.apps.googleusercontent.com'
        : null,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService();

  Future<void> _recordLogin(User user, String method) async {
    try {
      await _firestore.collection('login_records').add({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'loginTime': FieldValue.serverTimestamp(),
        'method': method,
        'userAgent': 'Flutter App', // In a real app, you could get more details
      });
    } catch (e) {
      debugPrint('Error recording login: $e');
    }
  }

  Future<void> initialize() async {
    // No initialization needed with modern google_sign_in package
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(
      {required String email, required String password}) async {
    UserCredential credential =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      await _recordLogin(credential.user!, 'email');
    }
    return credential;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? username,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    String displayName = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    // Update display name
    if (displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }

    // Note: To store extra fields like phone number and username,
    // we would typically use Firestore. For now, we update the user object where possible.
    // Firebase Auth has a phoneNumber field but it's usually set via phone auth.
    // We can use the 'displayName' or a custom Firestore document for more metadata.

    return credential;
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? photoUrl}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (firstName != null || lastName != null) {
        String displayName = [firstName, lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _recordLogin(userCredential.user!, 'google');
      }
      return userCredential;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signInWithGithub() async {
    GithubAuthProvider githubProvider = GithubAuthProvider();
    UserCredential credential = await _auth.signInWithProvider(githubProvider);
    if (credential.user != null) {
      await _recordLogin(credential.user!, 'github');
    }
    return credential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
