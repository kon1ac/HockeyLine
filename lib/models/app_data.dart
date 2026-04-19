import 'package:hockeyline/models/line.dart';
import 'package:hockeyline/models/note.dart';
import 'package:hockeyline/models/player.dart';
import 'package:hockeyline/models/user.dart';

class AppData {
  const AppData({
    required this.users,
    required this.players,
    required this.lines,
    required this.notes,
  });

  final List<User> users;
  final List<Player> players;
  final List<Line> lines;
  final List<Note> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'users': users.map((User e) => e.toJson()).toList(),
      'players': players.map((Player e) => e.toJson()).toList(),
      'lines': lines.map((Line e) => e.toJson()).toList(),
      'notes': notes.map((Note e) => e.toJson()).toList(),
    };
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      users: (json['users'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => User.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      players: (json['players'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => Player.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => Line.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => Note.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
