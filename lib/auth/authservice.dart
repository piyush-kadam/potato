import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  // Get current user
  User? getCurrentUser() => auth.currentUser;

  // Listen for authentication state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Helper to ensure user document exists in Firestore
  Future<void> ensureUserDocumentExists(User user) async {
    final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      await docRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        // Add other default fields as needed
      });
    }
  }

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure user doc exists after sign-in
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure user doc exists after sign-up
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-email',
        message: 'Please enter your email address',
      );
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );
      // Ensure user doc exists after Google sign-in
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception("Google Sign-In failed: ${e.code}");
    }
  }

  // Apple Sign-In
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available (iOS 13+, macOS 10.15+)
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception("Apple Sign-In is not available on this device");
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.potato.slideme', // Replace with your bundle ID
          redirectUri: Uri.parse(
            'https://slideme-87da5.firebaseapp.com/__/auth/handler',
          ), // Replace with your Firebase redirect URI
        ),
      );

      // Create an OAuth credential from the Apple ID credential
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );

      // Update display name if available (Apple only provides this on first sign-in)
      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if we should update the user's display name
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
          if (displayName.isNotEmpty && user.displayName == null) {
            await user.updateDisplayName(displayName);
          }
        }

        // Ensure user doc exists after Apple sign-in
        await ensureUserDocumentExists(user);

        // Optionally update Firestore with additional info
        final docRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid);
        await docRef.update({
          'displayName': user.displayName,
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle specific Apple Sign-In errors
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return null; // User canceled
        case AuthorizationErrorCode.failed:
          throw Exception("Apple Sign-In failed");
        case AuthorizationErrorCode.invalidResponse:
          throw Exception("Invalid response from Apple Sign-In");
        case AuthorizationErrorCode.notHandled:
          throw Exception("Apple Sign-In not handled");
        case AuthorizationErrorCode.unknown:
          throw Exception("Unknown Apple Sign-In error");
        default:
          throw Exception("Apple Sign-In error: ${e.code}");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception("Firebase authentication failed: ${e.code}");
    } catch (e) {
      throw Exception("Apple Sign-In failed: $e");
    }
  }

  // Check if Apple Sign-In is supported on this platform
  Future<bool> isAppleSignInAvailable() async {
    try {
      // Apple Sign-In is only available on iOS 13+, macOS 10.15+
      if (Platform.isIOS || Platform.isMacOS) {
        return await SignInWithApple.isAvailable();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await auth.signOut();
    } catch (e) {
      throw Exception("Error signing out: $e");
    }
  }
}
