import 'package:hockeyline/models/app_enums.dart';

class Line {
  const Line({
    required this.id,
    required this.lineNumber,
    required this.type,
    required this.playerIds,
  });

  final String id;
  final int lineNumber;
  final LineType type;
  final List<String> playerIds;

  Line copyWith({
    String? id,
    int? lineNumber,
    LineType? type,
    List<String>? playerIds,
  }) {
    return Line(
      id: id ?? this.id,
      lineNumber: lineNumber ?? this.lineNumber,
      type: type ?? this.type,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'lineNumber': lineNumber,
      'type': type.name,
      'playerIds': playerIds,
    };
  }

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      id: json['id'] as String? ?? '',
      lineNumber: json['lineNumber'] as int? ?? 1,
      type: LineType.values.firstWhere(
        (LineType t) => t.name == json['type'],
        orElse: () => LineType.forward,
      ),
      playerIds: (json['playerIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(growable: false),
    );
  }
}
