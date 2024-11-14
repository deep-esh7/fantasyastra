// match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/registeration_form.dart';
import '../screens/team_generator_screen.dart';
import '../Helper/UserHelper.dart';
import '../Provider/SettingConfigProvider.dart';
import '../Provider/UserProvider.dart';
import '../models/FantasyMatchListModel.dart';
import '../widgets/timer_widget.dart';
import '../Helper/FantasyDataHelper.dart';
import '../services/notification_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchName;

  const MatchDetailScreen({Key? key, required this.matchName}) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final FantasyMatchDataHelper _matchHelper = FantasyMatchDataHelper();
  final UserHelper _userHelper = UserHelper();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserIfNeeded();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadUserIfNeeded() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && userProvider.user == null) {
        await userProvider.loadUserDetails();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Widget _buildMatchHeader(FantasyMatchListModel match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFb34d46),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      match.team1Flag,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sports_cricket, size: 50),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.team1Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TimerWidget(
                    initialTime: match.matchTime,
                    matchId: '${match.team1Name}_vs_${match.team2Name}',
                    color: Colors.white,
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      match.team2Flag,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sports_cricket, size: 50),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.team2Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _checkAndRegisterUser(BuildContext context, String title, String teamImageUrl) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      // Check subscription status
      final isSubscriptionActive = configProvider.config?.isSubscriptionActive ?? false;

      // Case 1: No user exists - Register first
      if (currentUser == null) {
        final newUser = await _userHelper.registerAnonymousUser();
        if (newUser == null) return;

        await _showRegistrationForm(context);
        // Check subscription after registration
        if (isSubscriptionActive && !(userProvider.user?.isSubscribed ?? false)) {
          _showSubscriptionMessage(context);
          return;
        }
      }
      // Case 2: User exists but no profile or name is "Anonymous User"
      else if (userProvider.user == null || userProvider.user!.name.trim() == "Anonymous User") {
        await _showRegistrationForm(context);
        // Check subscription after registration
        if (isSubscriptionActive && !(userProvider.user?.isSubscribed ?? false)) {
          _showSubscriptionMessage(context);
          return;
        }
      }
      // Case 3: User exists with profile but not subscribed
      else if (isSubscriptionActive && !userProvider.user!.isSubscribed) {
        _showSubscriptionMessage(context);
        return;
      }

      // All conditions met - proceed to team screen
      await _subscribeToMatchNotifications();
      if (mounted) {
        _navigateToTeamGeneratorScreen(context, title, teamImageUrl);
      }
    } catch (e) {
      print('Error in _checkAndRegisterUser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRegistrationForm(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegistrationForm(
        onRegister: (userModel) async {
          try {
            await _userHelper.createUserProfile(userModel);
            await userProvider.setUserDetails(userModel);
            if (mounted) Navigator.pop(context);
          } catch (e) {
            print('Error during registration: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registration failed: ${e.toString()}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showSubscriptionMessage(BuildContext context) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please subscribe to see the team.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _subscribeToMatchNotifications() async {
    final matchTopic = widget.matchName
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_')
        .toLowerCase();
    await _notificationService.subscribeToTopic('match_$matchTopic');
  }

  void _navigateToTeamGeneratorScreen(BuildContext context, String title, String teamImageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (title == "Head 2 Head Team") {
            return TeamGeneratorScreen(
              matchName: widget.matchName,
              headToheadImagePath: teamImageUrl,
            );
          } else {
            return TeamGeneratorScreen(
              matchName: widget.matchName,
              megaContestImagePath: teamImageUrl,
            );

          }
        },
      ),
    );
  }

  Widget _buildTeamSection(String title, String imageUrl, BuildContext context, String teamImageUrl) {
    return Consumer2<ConfigProvider, UserProvider>(
      builder: (context, configProvider, userProvider, _) {
        final isSubscriptionActive = configProvider.config?.isSubscriptionActive ?? false;
        final isSubscribed = userProvider.user?.isSubscribed ?? false;
        final isUserRegistered = userProvider.user != null;
        final showLock = isSubscriptionActive && (!isUserRegistered || !isSubscribed);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: const DecorationImage(
                        image: AssetImage("assets/bgimage.png"),
                        fit: BoxFit.cover,
                        opacity: 0.7,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      color: showLock ? Colors.black.withOpacity(0.5) : Colors.transparent,
                    ),
                    child: Center(
                      child: showLock
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUserRegistered
                                ? 'Subscribe to View'
                                : 'Register & Subscribe to View',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (showLock) {
                    if (!isUserRegistered) {
                      _checkAndRegisterUser(context, title, teamImageUrl);
                    } else {
                      _showSubscriptionMessage(context);
                    }
                  } else {
                    _checkAndRegisterUser(context, title, teamImageUrl);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFb34d46).withOpacity(.95),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFb34d46),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Match Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<FantasyMatchListModel?>(
        stream: _matchHelper.getMatchStream(widget.matchName),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final match = snapshot.data;
          if (match == null) {
            return const Center(child: Text('Match not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMatchHeader(match),
                const SizedBox(height: 16),
                _buildTeamSection(
                    'Head 2 Head Team',
                    match.headToHeadTeamImageUrl,
                    context,
                    match.headToHeadTeamImageUrl
                ),
                _buildTeamSection(
                    'Mega League Team',
                    match.megaTeamImageUrl,
                    context,
                    match.megaTeamImageUrl
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}