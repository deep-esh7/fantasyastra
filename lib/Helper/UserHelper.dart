// helper/user_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/UserModel.dart';
import '../services/notification_service.dart';

class UserHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Device ID Management
  Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'unknown_device';
    } catch (e) {
      print('Error getting device ID: $e');
      return 'unknown_device';
    }
  }

  // User Authentication
  Future<User?> registerAnonymousUser() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      await _notificationService.initialize();
      return userCredential.user;
    } catch (e) {
      print('Error registering anonymous user: $e');
      return null;
    }
  }

  // User Profile Management
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final deviceId = await getDeviceId();
    final deviceToken = await _notificationService.getToken() ?? '';

    try {
      final userDoc = await _firestore.collection('Users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel.fromMap({
          ...userData,
          'uid': currentUser.uid,
          'deviceId': deviceId,
          'deviceToken': deviceToken,
        });
      } else {
        // Create new user if doesn't exist
        final newUser = UserModel(
          name: 'Anonymous User',
          email: '',
          phoneNumber: '',
          registrationDate: DateTime.now(),
          lastActiveDate: DateTime.now(),
          deviceId: deviceId,
          deviceToken: deviceToken,
          isSubscribed: false,
          uid: currentUser.uid,
        );
        await _firestore.collection('Users').doc(currentUser.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<UserModel?> getUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromMap(doc.data()!);
        } catch (e) {
          print('Error parsing user data: $e');
          // Handle legacy data format
          if (doc.data()!.containsKey('registrationDate') &&
              doc.data()!.containsKey('lastActiveDate')) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data()!);

            // Convert dates if needed
            if (data['registrationDate'] is String) {
              data['registrationDate'] = Timestamp.fromDate(
                  DateTime.parse(data['registrationDate']));
            }
            if (data['lastActiveDate'] is String) {
              data['lastActiveDate'] = Timestamp.fromDate(
                  DateTime.parse(data['lastActiveDate']));
            }

            return UserModel.fromMap(data);
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
    return null;
  }

  Future<void> createUserProfile(UserModel userData) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final deviceToken = await _notificationService.getToken() ?? '';

        final user = userData.copyWith(
          deviceToken: deviceToken,
          lastActiveDate: DateTime.now(),
        );

        final userRef = _firestore.collection('Users').doc(userId);
        await userRef.set(user.toMap(), SetOptions(merge: true));

        // Store device token in subcollection
        await _updateDeviceToken(deviceToken, user.deviceId);

        if (user.isSubscribed) {
          await _notificationService.subscribeToTopic('all_users');
        }
      } catch (e) {
        print('Error creating user profile: $e');
        rethrow;
      }
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore.collection('Users').doc(_auth.currentUser!.uid).update({
        ...user.toMap(),
        'lastActiveDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Token Management
  Future<void> updateFCMToken(String newToken) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('Users').doc(userId).update({
        'deviceToken': newToken,
        'lastActiveDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating FCM token: $e');
      rethrow;
    }
  }

  Future<void> _updateDeviceToken(String token, String deviceId) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null && token.isNotEmpty) {
      try {
        final tokenDoc = _firestore
            .collection('Users')
            .doc(userId)
            .collection('devices')
            .doc(deviceId);

        await tokenDoc.set({
          'token': token,
          'deviceId': deviceId,
          'lastUpdated': FieldValue.serverTimestamp(),
          'platform': 'android',
          'isActive': true,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating device token: $e');
        rethrow;
      }
    }
  }

  Future<void> deactivateDeviceToken(String deviceId) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore
            .collection('Users')
            .doc(userId)
            .collection('devices')
            .doc(deviceId)
            .update({
          'isActive': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error deactivating device token: $e');
        rethrow;
      }
    }
  }

  Future<void> cleanupOldTokens() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final devices = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('devices')
            .where('isActive', isEqualTo: true)
            .get();

        final batch = _firestore.batch();

        for (var device in devices.docs) {
          batch.update(device.reference, {
            'isActive': false,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      } catch (e) {
        print('Error cleaning up old tokens: $e');
        rethrow;
      }
    }
  }

  // Subscription Management
  Future<void> handleSubscriptionChange(bool isSubscribed) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        if (isSubscribed) {
          await _notificationService.subscribeToTopic('all_users');
        } else {
          await _notificationService.unsubscribeFromTopic('all_users');
        }

        await updateUserProfile(UserModel(
          name: '',  // These will be merged with existing data
          email: '',
          phoneNumber: '',
          registrationDate: DateTime.now(),
          lastActiveDate: DateTime.now(),
          deviceId: '',
          deviceToken: '',
          isSubscribed: isSubscribed,
        ));
      } catch (e) {
        print('Error handling subscription change: $e');
        rethrow;
      }
    }
  }
}