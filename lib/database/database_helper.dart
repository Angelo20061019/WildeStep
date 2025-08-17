import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  // Register user with Auth, upload profile image, save profile to Firestore
  Future<String?> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
    required String userType, // 'camper', 'guide', 'gearStore'
    File? profileImage,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      // Upload profile image if provided
      String? imageUrl;
      if (profileImage != null) {
        final ref = _storage.ref().child('profile_images/$uid.jpg');
        await ref.putFile(profileImage);
        imageUrl = await ref.getDownloadURL();
      }

      // Save profile data in Firestore
      String collection;
      switch (userType) {
        case 'camper':
          collection = 'campers';
          break;
        case 'guide':
          collection = 'guides';
          break;
        case 'gearStore':
          collection = 'gearStores';
          break;
        default:
          throw Exception('Invalid user type');
      }
      await _firestore.collection(collection).doc(uid).set({
        ...profileData,
        'email': email,
        'profileImageUrl': imageUrl,
        'createdAt': DateTime.now(),
        'id': uid,
      });
      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  // Login user with Firebase Auth and get profile from Firestore
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      String collection;
      switch (userType) {
        case 'camper':
          collection = 'campers';
          break;
        case 'guide':
          collection = 'guides';
          break;
        case 'gearStore':
          collection = 'gearStores';
          break;
        default:
          throw Exception('Invalid user type');
      }
      DocumentSnapshot doc = await _firestore.collection(collection).doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // Update user profile (optionally with new image)
  Future<void> updateUserProfile({
    required String uid,
    required String userType,
    required Map<String, dynamic> updatedData,
    File? newProfileImage,
  }) async {
    String collection;
    switch (userType) {
      case 'camper':
        collection = 'campers';
        break;
      case 'guide':
        collection = 'guides';
        break;
      case 'gearStore':
        collection = 'gearStores';
        break;
      default:
        throw Exception('Invalid user type');
    }

    // Upload new profile image if provided
    if (newProfileImage != null) {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.putFile(newProfileImage);
      String imageUrl = await ref.getDownloadURL();
      updatedData['profileImageUrl'] = imageUrl;
    }

    await _firestore.collection(collection).doc(uid).update(updatedData);
  }

  // Admin analytics methods
  Future<int> getTotalUsersCount() async {
    final campers = await _firestore.collection('campers').get();
    final guides = await _firestore.collection('guides').get();
    final gearStores = await _firestore.collection('gearStores').get();
    return campers.size + guides.size + gearStores.size;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    List<Map<String, dynamic>> allUsers = [];

    final campers = await _firestore.collection('campers').get();
    for (var camper in campers.docs) {
      allUsers.add({
        ...camper.data(),
        'userType': 'Camper/Hiker',
        'displayName': camper.data()['fullName'],
      });
    }

    final guides = await _firestore.collection('guides').get();
    for (var guide in guides.docs) {
      allUsers.add({
        ...guide.data(),
        'userType': 'Guide',
        'displayName': guide.data()['fullName'],
      });
    }

    final gearStores = await _firestore.collection('gearStores').get();
    for (var gearStore in gearStores.docs) {
      allUsers.add({
        ...gearStore.data(),
        'userType': 'Gear Store',
        'displayName': gearStore.data()['storeName'],
      });
    }

    return allUsers;
  }

  // Location management methods (unchanged)
  Future<String> insertLocation(Map<String, dynamic> locationData) async {
    final doc = await _firestore.collection('locations').add(locationData);
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final query = await _firestore
        .collection('locations')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<Map<String, dynamic>?> getLocationById(String id) async {
    final doc = await _firestore.collection('locations').doc(id).get();
    return doc.exists ? {...doc.data()!, 'id': doc.id} : null;
  }

  Future<void> updateLocation(String docId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('locations').doc(docId).update(updatedData);
  }

  Future<void> deleteLocation(String docId) async {
    await _firestore.collection('locations').doc(docId).delete();
  }

  Future<int> getLocationsCount() async {
    final query = await _firestore.collection('locations').get();
    return query.size;
  }

  Future<int> getCampingLocationsCount() async {
    final query = await _firestore
        .collection('locations')
        .where('locationType', isEqualTo: 'Camping')
        .get();
    return query.size;
  }

  Future<int> getHikingLocationsCount() async {
    final query = await _firestore
        .collection('locations')
        .where('locationType', isEqualTo: 'Hiking')
        .get();
    return query.size;
  }

  Future<int> getTotalReviewsCount() async {
    final query = await _firestore.collection('location_reviews').get();
    return query.size;
  }

  // Location reviews methods (unchanged)
  Future<String> insertLocationReview(Map<String, dynamic> reviewData) async {
    final doc =
        await _firestore.collection('location_reviews').add(reviewData);
    await _updateLocationRating(reviewData['locationId']);
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getLocationReviews(String locationId) async {
    final query = await _firestore
        .collection('location_reviews')
        .where('locationId', isEqualTo: locationId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> deleteLocationReview(String reviewId, String locationId) async {
    await _firestore.collection('location_reviews').doc(reviewId).delete();
    await _updateLocationRating(locationId);
  }

  Future<List<Map<String, dynamic>>> getAllLocationReviews() async {
    final reviews = await _firestore
        .collection('location_reviews')
        .orderBy('createdAt', descending: true)
        .get();
    List<Map<String, dynamic>> result = [];
    for (var review in reviews.docs) {
      final locationId = review.data()['locationId'];
      final locationDoc =
          await _firestore.collection('locations').doc(locationId).get();
      final locationName = locationDoc.exists
          ? locationDoc.data()!['locationName']
          : null;
      result.add({
        ...review.data(),
        'id': review.id,
        'locationName': locationName,
      });
    }
    return result;
  }

  Future<void> _updateLocationRating(String locationId) async {
    final reviews = await _firestore
        .collection('location_reviews')
        .where('locationId', isEqualTo: locationId)
        .get();

    if (reviews.docs.isNotEmpty) {
      double averageRating = reviews.docs
              .map((doc) => doc.data()['rating'] as int)
              .reduce((a, b) => a + b) /
          reviews.docs.length;

      await _firestore.collection('locations').doc(locationId).update({
        'averageRating': averageRating,
        'reviewCount': reviews.docs.length,
      });
    }
  }

  Future<bool> hasUserReviewedLocation(
    String locationId,
    String userId,
    String userType,
  ) async {
    final query = await _firestore
        .collection('location_reviews')
        .where('locationId', isEqualTo: locationId)
        .where('userId', isEqualTo: userId)
        .where('userType', isEqualTo: userType)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<int> getGearStoresCount() async {
    final query = await _firestore.collection('gearStores').get();
    return query.size;
  }

  Future<Map<String, dynamic>?> getAdminById(String adminUid) async {
    try {
      final doc = await _firestore.collection('admins').doc(adminUid).get();
      if (doc.exists) {
        final data = doc.data();
        // Optionally add the id to the map
        if (data != null) data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching admin by id: $e');
      return null;
    }
  }
}
