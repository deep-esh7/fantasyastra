import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/FantasyMatchListModel.dart';

import 'timer_widget.dart';

class MatchCard extends StatelessWidget {
  final FantasyMatchListModel match;

  const MatchCard({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.tournament,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTeamInfo(match.team1Name, match.team1Flag),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Vs',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTeamInfo(match.team2Name, match.team2Flag),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: TimerWidget(
                initialTime: match.matchTime,
                matchId: '${match.team1Name}_vs_${match.team2Name}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String teamName, String flagUrl) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: flagUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.error),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}