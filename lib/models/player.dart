import 'package:hockeyline/models/app_enums.dart';
import 'package:hockeyline/models/statistics.dart';

class Player {
  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.position,
    required this.number,
    required this.status,
    required this.inRoster,
    required this.statistics,
    this.height,
    this.weight,
    this.photoUrl,
    this.isFavorite = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final PlayerPosition position;
  final int number;
  final int? height;
  final int? weight;
  final String? photoUrl;
  final PlayerStatus status;
  final bool inRoster;
  final bool isFavorite;
  final Statistics statistics;

  int get age {
    final DateTime now = DateTime.now();
    int years = now.year - birthDate.year;
    final bool hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) {
      years--;
    }
    return years;
  }

  String get fullName => '$firstName $lastName';

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    PlayerPosition? position,
    int? number,
    int? height,
    int? weight,
    String? photoUrl,
    PlayerStatus? status,
    bool? inRoster,
    bool? isFavorite,
    Statistics? statistics,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      position: position ?? this.position,
      number: number ?? this.number,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      inRoster: inRoster ?? this.inRoster,
      isFavorite: isFavorite ?? this.isFavorite,
      statistics: statistics ?? this.statistics,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'position': position.name,
      'number': number,
      'height': height,
      'weight': weight,
      'photoUrl': photoUrl,
      'status': status.name,
      'inRoster': inRoster,
      'isFavorite': isFavorite,
      'statistics': statistics.toJson(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthDate:
          DateTime.tryParse(json['birthDate'] as String? ?? '') ??
          DateTime(2000),
      position: PlayerPosition.values.firstWhere(
        (position) => position.name == json['position'],
        orElse: () => PlayerPosition.forward,
      ),
      number: json['number'] as int? ?? 0,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      photoUrl: json['photoUrl'] as String?,
      status: PlayerStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PlayerStatus.active,
      ),
      inRoster: json['inRoster'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      statistics: Statistics.fromJson(
        (json['statistics'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}
