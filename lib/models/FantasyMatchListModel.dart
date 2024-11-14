class FantasyMatchListModel {
  final String tournament;
  final String team1Name;
  final String team2Name;
  final String team1Flag;
  final String team2Flag;
  final bool isMatchStarted;
  final String headToHeadTeamImageUrl;
  final String lastUpdateMegaContestTime;
  final String lastUpdateHeadToHeadTime;
  final String megaTeamImageUrl;
  final String matchTime;
  int likeVotes;    // Tracks the number of likes
  int dislikeVotes; // Tracks the number of dislikes

  FantasyMatchListModel({
    required this.tournament,
    required this.team1Name,
    required this.team2Name,
    required this.team1Flag,
    required this.team2Flag,
    required this.isMatchStarted,
    required this.headToHeadTeamImageUrl,
    required this.lastUpdateMegaContestTime,
    required this.lastUpdateHeadToHeadTime,
    required this.megaTeamImageUrl,
    required this.matchTime,
    this.likeVotes = 0,
    this.dislikeVotes = 0,
  });

  // Convert a Firestore document to FantasyMatchListModel
  factory FantasyMatchListModel.fromMap(Map<String, dynamic> map) {
    return FantasyMatchListModel(
      tournament: map['tournament'] ?? '',
      team1Name: map['team1Name'] ?? '',
      team2Name: map['team2Name'] ?? '',
      team1Flag: map['team1Flag'] ?? '',
      team2Flag: map['team2Flag'] ?? '',
      isMatchStarted: map['isMatchStarted'] ?? false,
      headToHeadTeamImageUrl: map['headToHeadTeamImageUrl'] ?? '',
      lastUpdateMegaContestTime: map['lastUpdateMegaContestTime'] ?? '',
      lastUpdateHeadToHeadTime: map['lastUpdateHeadToHeadTime'] ?? '',
      megaTeamImageUrl: map['megaTeamImageUrl'] ?? '',
      matchTime: map['matchTime'] ?? '',
      likeVotes: map['likeVotes'] ?? 0,
      dislikeVotes: map['dislikeVotes'] ?? 0,
    );
  }

  // Convert FantasyMatchListModel to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'tournament': tournament,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'team1Flag': team1Flag,
      'team2Flag': team2Flag,
      'isMatchStarted': isMatchStarted,
      'headToHeadTeamImageUrl': headToHeadTeamImageUrl,
      'lastUpdateMegaContestTime': lastUpdateMegaContestTime,
      'lastUpdateHeadToHeadTime': lastUpdateHeadToHeadTime,
      'megaTeamImageUrl': megaTeamImageUrl,
      'matchTime': matchTime,
      'likeVotes': likeVotes,
      'dislikeVotes': dislikeVotes,
    };
  }

  // Helper method to create a copy with updated vote counts
  FantasyMatchListModel copyWith({
    int? likeVotes,
    int? dislikeVotes,
  }) {
    return FantasyMatchListModel(
      tournament: this.tournament,
      team1Name: this.team1Name,
      team2Name: this.team2Name,
      team1Flag: this.team1Flag,
      team2Flag: this.team2Flag,
      isMatchStarted: this.isMatchStarted,
      headToHeadTeamImageUrl: this.headToHeadTeamImageUrl,
      lastUpdateMegaContestTime: this.lastUpdateMegaContestTime,
      lastUpdateHeadToHeadTime: this.lastUpdateHeadToHeadTime,
      megaTeamImageUrl: this.megaTeamImageUrl,
      matchTime: this.matchTime,
      likeVotes: likeVotes ?? this.likeVotes,
      dislikeVotes: dislikeVotes ?? this.dislikeVotes,
    );
  }
}
