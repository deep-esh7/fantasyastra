// provider/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/UserModel.dart';
import '../Helper/UserHelper.dart';
import '../services/notification_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final UserHelper _userHelper = UserHelper();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load user details from Firestore
  Future<void> loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.isAnonymous) {
      try {
        _setLoading(true);
        _setError(null);

        // Fetch user details from Firestore
        _user = await _userHelper.getCurrentUser();

        if (_user != null) {
          // Check if FCM token needs updating
          final currentToken = await _notificationService.getToken();
          if (currentToken != null && currentToken != _user!.deviceToken) {
            await updateFCMToken();
          }

          // Subscribe to relevant topics
          if (_user!.isSubscribed) {
            await _notificationService.subscribeToTopic('all_users');
          }
        } else {
          _setError('User profile not found in Firestore.');
        }
      } catch (e) {
        _setError('Error loading user details: $e');
        print('Error fetching user details from Firestore: $e');
      } finally {
        _setLoading(false);
      }
    } else {
      _setError('No anonymous user signed in.');
    }
  }

  // Set user details and save to Firestore
  Future<void> setUserDetails(UserModel userModel) async {
    try {
      _setLoading(true);
      _setError(null);

      final deviceToken = await _notificationService.getToken() ?? '';
      final deviceId = await _userHelper.getDeviceId();

      _user = userModel.copyWith(
        deviceId: deviceId,
        deviceToken: deviceToken,
        lastActiveDate: DateTime.now(),
      );

      await _userHelper.createUserProfile(_user!);

      if (_user!.isSubscribed) {
        await _notificationService.subscribeToTopic('all_users');
      }
    } catch (e) {
      _setError('Error setting user details: $e');
      print('Error setting user details: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateUser(UserModel newUser) async {
    try {
      _setLoading(true);
      _setError(null);

      await _userHelper.updateUserProfile(newUser);
      _user = newUser;
    } catch (e) {
      _setError('Error updating user: $e');
      print('Error updating user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update subscription status
  Future<void> updateSubscriptionStatus(bool isSubscribed) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _setError(null);

      await _userHelper.handleSubscriptionChange(isSubscribed);
      _user = _user!.copyWith(isSubscribed: isSubscribed);

    } catch (e) {
      _setError('Error updating subscription: $e');
      print('Error updating subscription status: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update FCM token
  Future<void> updateFCMToken() async {
    if (_user != null) {
      try {
        _setLoading(true);
        _setError(null);

        final newToken = await _notificationService.getToken();
        if (newToken != null) {
          await _userHelper.updateFCMToken(newToken);
          _user = _user!.copyWith(
            deviceToken: newToken,
            lastActiveDate: DateTime.now(),
          );
        }
      } catch (e) {
        _setError('Error updating notification token: $e');
        print('Error updating FCM token: $e');
      } finally {
        _setLoading(false);
      }
    }
  }

  // Clean up old device tokens
  Future<void> cleanupDeviceTokens() async {
    try {
      _setLoading(true);
      _setError(null);

      await _userHelper.cleanupOldTokens();
    } catch (e) {
      _setError('Error cleaning up old tokens: $e');
      print('Error cleaning up device tokens: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    try {
      _setLoading(true);
      _setError(null);

      await loadUserDetails();
      await updateFCMToken();
    } catch (e) {
      _setError('Error refreshing user data: $e');
      print('Error refreshing user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user != null) {
        // Unsubscribe from topics
        if (_user!.isSubscribed) {
          await _notificationService.unsubscribeFromTopic('all_users');
        }

        // Deactivate current device token
        await _userHelper.deactivateDeviceToken(_user!.deviceId);
      }

      // Clear user data
      _user = null;
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _setError('Error signing out: $e');
      print('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if token needs update
  Future<bool> checkTokenNeedsUpdate() async {
    if (_user != null) {
      final currentToken = await _notificationService.getToken();
      return currentToken != null && currentToken != _user!.deviceToken;
    }
    return false;
  }

  // Initialize user if needed
  Future<void> initializeUserIfNeeded() async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && _user == null) {
        await loadUserDetails();
      }
    } catch (e) {
      _setError('Error initializing user: $e');
      print('Error initializing user: $e');
    } finally {
      _setLoading(false);
    }
  }
}