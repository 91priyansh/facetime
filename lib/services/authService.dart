import 'package:facetime/models/customException.dart';
import 'package:firebase_auth/firebase_auth.dart';

///
///Auth class to create and login user
///
class AuthService {
  static FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  ///
  ///to create accoutn using email and password
  ///
  static Future<String> createAccount(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user.uid;
    } on FirebaseAuthException catch (e) {
      throw CustomException(errorMessage: e.message);
    } catch (e) {
      throw CustomException(errorMessage: "Unwanted error occurred");
    }
  }

  ///
  ///Login user using email and password
  ///
  static Future<String> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user.uid;
    } on FirebaseAuthException catch (e) {
      throw CustomException(errorMessage: e.message);
    } catch (e) {
      throw CustomException(errorMessage: "Unwanted error occurred");
    }
  }

  static void signOut() {
    _firebaseAuth.signOut();
  }
}
