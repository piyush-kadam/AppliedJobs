// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final GoogleSignIn googleSignIn = GoogleSignIn();

//   // Get current user
//   User? getCurrentUser() => auth.currentUser;

//   // Listen for authentication state changes
//   Stream<User?> get authStateChanges => auth.authStateChanges();

//   // Email & Password Sign In
//   Future<UserCredential> signInWithEmailPassword(
//     String email,
//     String password,
//   ) async {
//     try {
//       UserCredential userCredential = await auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.code);
//     }
//   }

//   // Email & Password Sign Up
//   Future<UserCredential> signUpWithEmailPassword(
//     String email,
//     String password,
//   ) async {
//     try {
//       UserCredential userCredential = await auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.code);
//     }
//   }

//   Future<void> sendPasswordResetEmail(String email) async {
//     if (email.isEmpty) {
//       throw FirebaseAuthException(
//         code: 'empty-email',
//         message: 'Please enter your email address',
//       );
//     }

//     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//   }

//   // Google Sign-In
//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//       if (googleUser == null) {
//         // User canceled the sign-in
//         return null;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       UserCredential userCredential = await auth.signInWithCredential(
//         credential,
//       );
//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       throw Exception("Google Sign-In failed: ${e.code}");
//     }
//   }


//   // Sign Out
//   Future<void> signOut() async {
//     try {
//       await googleSignIn.signOut();
//       await auth.signOut();
//     } catch (e) {
//       throw Exception("Error signing out: $e");
//     }
//   }
// }



import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
