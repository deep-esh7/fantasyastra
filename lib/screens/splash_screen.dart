// splash_screen.dart
import 'package:fantasyastra/screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Provider/SettingConfigProvider.dart';
import '../Provider/UserProvider.dart';
import '../services/notification_service.dart';
import '../Helper/UserHelper.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserHelper _userHelper = UserHelper();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      if (!mounted) return;

      // Initialize providers
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Initialize notifications first
      await _notificationService.initialize();

      // Load configuration settings
      await configProvider.loadConfig();

      // Check for existing user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Create anonymous user if none exists
        final newUser = await _userHelper.registerAnonymousUser();
        if (newUser == null) {
          throw Exception('Failed to create anonymous user');
        }
      }

      // Load user details if user exists and details not loaded
      if (FirebaseAuth.instance.currentUser != null && userProvider.user == null) {
        try {
          await userProvider.loadUserDetails();

          // Update token if needed
          if (userProvider.user != null) {
            final needsTokenUpdate = await userProvider.checkTokenNeedsUpdate();
            if (needsTokenUpdate) {
              await userProvider.updateFCMToken();
            }
          }
        } catch (e) {
          print('Error loading user details: $e');
        }
      }

      // Minimum splash screen duration
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Verify config loaded properly
        if (configProvider.config == null) {
          throw Exception('Failed to load app configuration');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      print('Error in _loadInitialData: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied. Please check your settings and try again.';
    } else if (error.toString().contains('anonymous user')) {
      return 'Failed to initialize app. Please restart the application.';
    } else if (error.toString().contains('configuration')) {
      return 'Failed to load app settings. Please try again.';
    } else {
      return 'Failed to load app data. Please try again.';
    }
  }

  Future<void> _retryLoading() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _loadInitialData();
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1E65)),
          strokeWidth: 3,
        ),
        const SizedBox(height: 10),
        Text(
          'Loading...',
          style: TextStyle(
              color:  Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              shadows: [
              Shadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 1),
        ),
      ],
    ),
    ),
    ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E65),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/fantasyastralogo.png',
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.sports_cricket,
                      size: 150,
                      color: Color(0xFF8B1E65),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Hero(
                  tag: 'app_title',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      'Fantasy Astra',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_errorMessage != null)
                  _buildErrorWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}