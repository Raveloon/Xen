import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository(this._firestore);

  Future<UserModel?> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      print('Attempting login for user: $username'); // DEBUG LOG
      // Direct query on plain text fields per requirement
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      print('Query completed. Found ${snapshot.docs.length} docs.'); // DEBUG LOG

      if (snapshot.docs.isEmpty) {
        return null;
      }

      // Map document to User Model
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Ensure ID is part of the map
      print('User found: ${data['username']}'); // DEBUG LOG
      return UserModel.fromJson(data);
    } catch (e) {
      print('Login Error: $e'); // DEBUG LOG
      throw Exception('Login Query Failed: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseFirestore.instance);
});
