import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  //Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
}

class AuthServiceImpl implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  //final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // @override
  // Future<UserCredential> signInWithGoogle() async {
  //   final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //   final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    
  //   final OAuthCredential credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );

  //   return await _firebaseAuth.signInWithCredential(credential);
  // }

  @override
  Future<void> signOut() async {
    //await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}