class Statistics {
  const Statistics({
    required this.games,
    required this.goals,
    required this.assists,
    required this.penaltyMinutes,
    required this.plusMinus,
  });

  final int games;
  final int goals;
  final int assists;
  final int penaltyMinutes;
  final int plusMinus;

  int get points => goals + assists;

  Statistics copyWith({
    int? games,
    int? goals,
    int? assists,
    int? penaltyMinutes,
    int? plusMinus,
  }) {
    return Statistics(
      games: games ?? this.games,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      penaltyMinutes: penaltyMinutes ?? this.penaltyMinutes,
      plusMinus: plusMinus ?? this.plusMinus,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'games': games,
      'goals': goals,
      'assists': assists,
      'penaltyMinutes': penaltyMinutes,
      'plusMinus': plusMinus,
    };
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      games: json['games'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      penaltyMinutes: json['penaltyMinutes'] as int? ?? 0,
      plusMinus: json['plusMinus'] as int? ?? 0,
    );
  }
}
