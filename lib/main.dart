// main.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fantasyastra/screens/main_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/SettingConfigProvider.dart';
import 'Provider/UserProvider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Check initial connectivity
  final connectivity = await Connectivity().checkConnectivity();
  final isOnline = connectivity != ConnectivityResult.none;

  if (isOnline) {
    try {
      // Test Firestore connection
      await FirebaseFirestore.instance
          .collection('Fantasy Matches List')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Firestore connection timeout'),
      );
      print('Firebase connection successful');
    } catch (e) {
      print('Firebase connection test failed: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider()..loadUserDetails(),
        ),
        ChangeNotifierProvider(
          create: (context) => ConfigProvider()..loadConfig(),
        ),
      ],
      child: MaterialApp(
        title: 'FantasyAstra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B1E65),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            centerTitle: true,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.grey[100],
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        home: const ConnectionAwareWidget(child: SplashScreen()),
      ),
    );
  }
}

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;

  const ConnectionAwareWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ConnectionAwareWidget> createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> {
  bool _isOnline = true;
  bool _showingBanner = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);

    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

    if (wasOnline != _isOnline && mounted) {
      _showConnectionBanner();
    }
  }

  void _showConnectionBanner() {
    if (!mounted) return;

    if (_showingBanner) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }

    _showingBanner = true;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          _isOnline
              ? 'Connection restored'
              : 'No internet connection. Some features may be limited.',
        ),
        leading: Icon(
          _isOnline ? Icons.wifi : Icons.wifi_off,
          color: _isOnline ? Colors.green : Colors.red,
        ),
        backgroundColor: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _showingBanner = false;
            },
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showingBanner) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        _showingBanner = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child is SplashScreen) {
      return widget.child;
    }
    return const MainNavigation();
  }
}