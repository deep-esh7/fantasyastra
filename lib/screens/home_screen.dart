// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/FantasyDataHelper.dart';
import '../Provider/UserProvider.dart';
import '../models/FantasyMatchListModel.dart';
import '../widgets/match_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FantasyMatchDataHelper _matchHelper = FantasyMatchDataHelper();
  bool _isLoading = true;
  bool _isRefreshing = false;

  // List of football-related keywords to filter out
  final List<String> footballKeywords = [
    'football',
    'soccer',
    'fc',
    'united',
    'arsenal',
    'chelsea',
    'liverpool',
    'manchester',
    'barcelona',
    'real madrid',
    'juventus',
    'bayern',
    'psg',
  ];

  // Function to check if a match contains football-related terms
  bool _isFootballMatch(FantasyMatchListModel match) {
    final matchName = '${match.team1Name} ${match.team2Name}'.toLowerCase();
    return footballKeywords.any((keyword) => matchName.contains(keyword.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _clearTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('start_time_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _matchHelper.waitForConnection();
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await _clearTimerData();
      await _initializeData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matches refreshed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _buildMatchList(List<FantasyMatchListModel> matches) {
    // Filter OUT football matches to show only cricket matches
    final cricketMatches = matches.where((match) => !_isFootballMatch(match)).toList();

    if (cricketMatches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: cricketMatches.length,
        itemBuilder: (context, index) {
          final match = cricketMatches[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(
                    matchName: '${match.team1Name} vs ${match.team2Name}',
                  ),
                ),
              );
            },
            child: MatchCard(match: match),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active matches',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Upcoming Matches List'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const CustomLoadingWidget()
          : StreamBuilder<List<FantasyMatchListModel>>(
        stream: _matchHelper.getActiveMatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Stream error: ${snapshot.error}');
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingWidget();
          }

          final matches = snapshot.data;
          if (matches == null || matches.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMatchList(matches);
        },
      ),
    );
  }
}