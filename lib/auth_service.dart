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
      // 1. Record the login event in 'login_records' collection
      await _firestore.collection('login_records').add({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'loginTime': FieldValue.serverTimestamp(),
        'method': method,
        'userAgent': 'Flutter App',
      });

      // 2. Update the 'users' collection with the latest profile data
      // This ensures we have a master record for each user
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'lastLogin': FieldValue.serverTimestamp(),
        'authMethod': method,
        'emailVerified': user.emailVerified,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording login: $e');
    }
  }

  Future<void> initialize() async {
    // No initialization needed with modern google_sign_in package
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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
      email: email,
      password: password,
    );

    String displayName = [
      firstName,
      lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    // Update display name
    if (displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }

    // Send email verification
    if (credential.user != null && !credential.user!.emailVerified) {
      await credential.user!.sendEmailVerification();
    }

    // Save additional user data to Firestore 'users' collection
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'phoneNumber': phoneNumber, // Manual phone input
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': credential.user!.uid,
      }, SetOptions(merge: true));
    }

    // Record registration
    await _recordLogin(credential.user!, 'email_register');

    return credential;
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (firstName != null || lastName != null) {
        String displayName = [
          firstName,
          lastName,
        ].where((s) => s != null && s.isNotEmpty).join(' ');
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

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
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

  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  Future<void> reauthenticateWithEmail(String email, String password) async {
    User? user = _auth.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }
}
