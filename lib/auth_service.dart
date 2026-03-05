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
      debugPrint('AuthService: Recording login for ${user.email} via $method');
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
      }).timeout(const Duration(seconds: 5));

      // 2. Update the 'users' collection with the latest profile data
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'lastLogin': FieldValue.serverTimestamp(),
        'authMethod': method,
        'emailVerified': user.emailVerified,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
      debugPrint('AuthService: Login recorded successfully');
    } catch (e) {
      debugPrint('AuthService: Error recording login: $e');
    }
  }

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        debugPrint('AuthService: Initializing for Web');
        await _auth.setPersistence(Persistence.LOCAL);
        
        // Handle redirect result if user was sent back to the site
        final UserCredential userCred = await _auth.getRedirectResult();
        if (userCred.user != null) {
          debugPrint('AuthService: User found from redirect: ${userCred.user?.email}');
          _recordLogin(userCred.user!, 'google_redirect');
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error during initialization: $e');
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: Attempting email sign-in for $email');
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      _recordLogin(credential.user!, 'email');
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
    String? photoUrl,
  }) async {
    debugPrint('AuthService: Registering new user: $email');
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String displayName = [
      firstName,
      lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    if (displayName.isNotEmpty || photoUrl != null) {
      await credential.user?.updateDisplayName(displayName);
      if (photoUrl != null) {
        await credential.user?.updatePhotoURL(photoUrl);
      }
    }

    if (credential.user != null && !credential.user!.emailVerified) {
      await credential.user!.sendEmailVerification();
    }

    if (credential.user != null) {
      _firestore.collection('users').doc(credential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'phoneNumber': phoneNumber,
        'email': email,
        'displayName': displayName,
        'photoURL': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': credential.user!.uid,
      }, SetOptions(merge: true));
    }

    _recordLogin(credential.user!, 'email_register');

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
      debugPrint('AuthService: Starting Google Sign-In');
      
      if (kIsWeb) {
        // Use Firebase Popup for Web to ensure data flows back to the same tab
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          _recordLogin(userCredential.user!, 'google_web_popup');
        }
        return userCredential;
      } else {
        // Standard Mobile flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          _recordLogin(userCredential.user!, 'google_mobile');
        }
        return userCredential;
      }
    } catch (e) {
      debugPrint('AuthService: Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGithub() async {
    debugPrint('AuthService: Starting GitHub Sign-In');
    try {
      if (kIsWeb) {
        final githubProvider = GithubAuthProvider();
        final userCredential = await _auth.signInWithPopup(githubProvider);
        if (userCredential.user != null) {
          _recordLogin(userCredential.user!, 'github_web_popup');
        }
        return userCredential;
      } else {
        GithubAuthProvider githubProvider = GithubAuthProvider();
        UserCredential credential = await _auth.signInWithProvider(githubProvider);
        if (credential.user != null) {
          _recordLogin(credential.user!, 'github_mobile');
        }
        return credential;
      }
    } catch (e) {
      debugPrint('AuthService: GitHub Sign-In error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('AuthService: Signing out');
    if (kIsWeb) {
      await _auth.signOut();
    } else {
      await _googleSignIn.signOut();
      await _auth.signOut();
    }
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
