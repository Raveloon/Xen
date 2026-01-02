import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepository(this._firestore, this._storage);

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

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<String> uploadProfileImage(XFile image, String userId) async {
    try {
      // 1. Read bytes (Web & Native compatible)
      final bytes = await image.readAsBytes();

      // 2. Define upload path
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      // 3. Upload data
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      // 4. Get Download URL
      final downloadUrl = await ref.getDownloadURL();

      // 5. Update Firestore User Profile
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> addInterest(String userId, String interest) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'interests': FieldValue.arrayUnion([interest]),
      });
    } catch (e) {
      throw Exception('Failed to add interest: $e');
    }
  }

  Future<void> removeInterest(String userId, String interest) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'interests': FieldValue.arrayRemove([interest]),
      });
    } catch (e) {
      throw Exception('Failed to remove interest: $e');
    }
  }

  // --- Global Tag System ---

  Stream<List<String>> getGlobalTags() {
    return _firestore
        .collection('settings')
        .doc('tags')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      if (data == null || !data.containsKey('list')) return [];
      return List<String>.from(data['list']);
    });
  }

  Future<void> addGlobalTag(String tag) async {
    try {
      final ref = _firestore.collection('settings').doc('tags');
      final doc = await ref.get();
      
      if (!doc.exists) {
        await ref.set({'list': [tag]});
      } else {
        await ref.update({
          'list': FieldValue.arrayUnion([tag]),
        });
      }
    } catch (e) {
      throw Exception('Failed to add global tag: $e');
    }
  }

  Future<void> removeGlobalTag(String tag) async {
    try {
      await _firestore.collection('settings').doc('tags').update({
        'list': FieldValue.arrayRemove([tag]),
      });
    } catch (e) {
      throw Exception('Failed to remove global tag: $e');
    }
  }

  // --- Favorites System ---

  Future<void> addFavorite(String userId, String jobId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Add to user's favoriteIds array (for quick UI check)
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'favoriteIds': FieldValue.arrayUnion([jobId]),
      });

      // 2. Add to detailed favorites subcollection (for sorting)
      final favRef = userRef.collection('favorites').doc(jobId);
      batch.set(favRef, {
        'jobId': jobId,
        'favoritedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(String userId, String jobId) async {
    try {
      final batch = _firestore.batch();

      // 1. Remove from user's favoriteIds array
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'favoriteIds': FieldValue.arrayRemove([jobId]),
      });

      // 2. Remove from favorites subcollection
      final favRef = userRef.collection('favorites').doc(jobId);
      batch.delete(favRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Fetches favorite jobs sorted by favoritedAt (descending)
  Future<List<String>> getFavoriteJobIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('favoritedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  Future<String?> findUserIdByUsername(String username) async {
    try {
      print('Looking up user by name: $username');
      
      // 1. Try Exact Match
      var snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Found by exact match: ${snapshot.docs.first.id}');
        return snapshot.docs.first.id;
      }

      // 2. Try Lowercase
      snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        print('Found by lowercase match: ${snapshot.docs.first.id}');
        return snapshot.docs.first.id;
      }

      // 3. Try "Capitalized" (First letter upper)
      if (username.isNotEmpty) {
        final capitalized = username[0].toUpperCase() + username.substring(1).toLowerCase();
        snapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: capitalized)
            .limit(1)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          print('Found by capitalized match: ${snapshot.docs.first.id}');
          return snapshot.docs.first.id;
        }
      }

      print('User not found by name: $username');
      return null;
    } catch (e) {
      throw Exception('Failed to find user ID: $e');
    }
  }

  Future<void> createTestUser() async {
    try {
      final user = UserModel(
        id: 'user1',
        username: 'user1@xen.com',
        password: 'user1password',
        fullName: 'Test User',
        interests: [],
      );
      
      final data = user.toJson();
      data.remove('id'); // ID is the document ID
      
      await _firestore.collection('users').doc('user1').set(data);
      print('Test user created: user1@xen.com');
    } catch (e) {
      throw Exception('Failed to create test user: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

final globalTagsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(authRepositoryProvider).getGlobalTags();
});
