import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/stream_extensions.dart';
import 'dart:async';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  
  final _userModelController = StreamController<UserModel?>.broadcast();
  UserModel? _latestUserModel;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  AuthService() {
    _initUserModelStream();
  }

  void _initUserModelStream() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      // Cancel previous document listener whenever auth state changes
      _userDocSubscription?.cancel();
      
      if (user == null) {
        _latestUserModel = null;
        _userModelController.add(null);
      } else {
        _userDocSubscription = _db.collection('users').doc(user.uid).snapshots().listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final userModel = UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
            _latestUserModel = userModel;
            _userModelController.add(userModel);
          } else {
            _latestUserModel = null;
            _userModelController.add(null);
          }
        }, onError: (error) {
          print('AuthService: User Doc Subscription Error: $error');
        });
      }
    });
  }

  Future<void> _ensureInitialized() async {
    if (_isGoogleSignInInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: '1049937932317-1r0itsjvsd1rcq63kec5bk50stvtajls.apps.googleusercontent.com',
    );
    _isGoogleSignInInitialized = true;
  }

  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized.');
    }
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _db {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized.');
    }
    return FirebaseFirestore.instance;
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get user => _auth.authStateChanges();

  // Updated to include the latest value immediately for new subscribers
  Stream<UserModel?> get userModel => _userModelController.stream.startWith(_latestUserModel);

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required UserRole role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          role: role,
          isAdmin: role == UserRole.admin || AppConstants.adminEmails.contains(email.toLowerCase()),
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    _userDocSubscription?.cancel();
    await _auth.signOut();
    _latestUserModel = null;
    _userModelController.add(null);
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            fullName: user.displayName ?? '',
            role: UserRole.none,
            isAdmin: AppConstants.adminEmails.contains((user.email ?? '').toLowerCase()),
          );
          await _db.collection('users').doc(user.uid).set(newUser.toMap());
        }
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserInfo({
    required String uid,
    required String fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> updates = {'fullName': fullName};
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final String email = data['email'] ?? '';
      final bool isEmailAdmin = AppConstants.adminEmails.contains(email.toLowerCase());
      
      final bool currentlyAdmin = (data['role'] == 'admin') || (data['isAdmin'] == true) || isEmailAdmin;
      
      Map<String, dynamic> updates = {
        'role': role.toString().split('.').last,
      };

      if (currentlyAdmin || role == UserRole.admin) {
        updates['isAdmin'] = true;
      } else {
        updates['isAdmin'] = false;
      }

      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> adminUpdateUser(String uid, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    _userModelController.close();
  }
}
