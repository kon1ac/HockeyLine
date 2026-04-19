import 'package:flutter/foundation.dart';
import 'package:hockeyline/models/app_data.dart';
import 'package:hockeyline/models/app_enums.dart';
import 'package:hockeyline/models/line.dart';
import 'package:hockeyline/services/storage_service.dart';

class LinesProvider extends ChangeNotifier {
  LinesProvider(this._storageService);

  final StorageService _storageService;
  final List<Line> _lines = <Line>[];

  List<Line> get lines => List<Line>.unmodifiable(_lines);

  Future<void> loadLines() async {
    final AppData data = await _storageService.loadAppData();
    _lines
      ..clear()
      ..addAll(data.lines);
    bool hasChanges = false;
    if (_lines.isEmpty) {
      _lines.addAll(_defaultLines());
      hasChanges = true;
    } else {
      hasChanges = _ensureRequiredLines();
    }
    if (hasChanges) {
      await saveLines();
    }
    notifyListeners();
  }

  Future<void> movePlayer({
    required String playerId,
    required String targetLineId,
    required PlayerPosition playerPosition,
  }) async {
    final int targetIndex = _lines.indexWhere((Line line) => line.id == targetLineId);
    if (targetIndex == -1) {
      return;
    }
    final Line targetLine = _lines[targetIndex];
    if (!isPositionAllowedForLine(
      playerPosition: playerPosition,
      lineType: targetLine.type,
    )) {
      return;
    }
    if (!canAddPlayerToLine(line: targetLine, playerId: playerId)) {
      return;
    }
    for (int i = 0; i < _lines.length; i++) {
      final List<String> updatedIds = List<String>.from(_lines[i].playerIds)
        ..remove(playerId);
      _lines[i] = _lines[i].copyWith(playerIds: updatedIds);
    }
    final List<String> ids = List<String>.from(_lines[targetIndex].playerIds);
    ids.add(playerId);
    _lines[targetIndex] = _lines[targetIndex].copyWith(playerIds: ids);
    await saveLines();
  }

  Future<void> removePlayerFromLine({
    required String playerId,
    required String lineId,
  }) async {
    final int lineIndex = _lines.indexWhere((Line line) => line.id == lineId);
    if (lineIndex == -1) {
      return;
    }
    final List<String> updatedIds = List<String>.from(_lines[lineIndex].playerIds)
      ..remove(playerId);
    _lines[lineIndex] = _lines[lineIndex].copyWith(playerIds: updatedIds);
    await saveLines();
  }

  Future<void> clearAllLines() async {
    for (int i = 0; i < _lines.length; i++) {
      _lines[i] = _lines[i].copyWith(playerIds: <String>[]);
    }
    await saveLines();
  }

  Future<void> removePlayerFromAllLines(String playerId) async {
    bool hasChanges = false;
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].playerIds.contains(playerId)) {
        final List<String> updatedIds = List<String>.from(_lines[i].playerIds)
          ..remove(playerId);
        _lines[i] = _lines[i].copyWith(playerIds: updatedIds);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      await saveLines();
    }
  }

  Future<void> saveLines() async {
    final AppData data = await _storageService.loadAppData();
    await _storageService.saveAppData(
      AppData(
        users: data.users,
        players: data.players,
        lines: _lines,
        notes: data.notes,
      ),
    );
    notifyListeners();
  }

  bool isPositionAllowedForLine({
    required PlayerPosition playerPosition,
    required LineType lineType,
  }) {
    if (lineType == LineType.forward) {
      return playerPosition == PlayerPosition.forward;
    }
    if (lineType == LineType.defense) {
      return playerPosition == PlayerPosition.defender;
    }
    return playerPosition == PlayerPosition.goalkeeper;
  }

  int lineCapacity(LineType lineType) {
    switch (lineType) {
      case LineType.goalkeeper:
        return 2;
      case LineType.forward:
        return 3;
      case LineType.defense:
        return 2;
    }
  }

  bool canAddPlayerToLine({
    required Line line,
    required String playerId,
  }) {
    final int capacity = lineCapacity(line.type);
    final int occupied = line.playerIds.where((String id) => id != playerId).length;
    return occupied < capacity;
  }

  bool _ensureRequiredLines() {
    bool changed = false;
    final Map<String, Line> existingById = <String, Line>{
      for (final Line line in _lines) line.id: line,
    };
    final List<Line> defaults = _defaultLines();
    for (final Line line in defaults) {
      if (!existingById.containsKey(line.id)) {
        _lines.add(line);
        changed = true;
      }
    }
    return changed;
  }

  List<Line> _defaultLines() {
    return <Line>[
      for (int i = 1; i <= 2; i++)
        Line(
          id: 'goalkeeper-$i',
          lineNumber: i,
          type: LineType.goalkeeper,
          playerIds: <String>[],
        ),
      for (int i = 1; i <= 4; i++)
        Line(
          id: 'forward-$i',
          lineNumber: i,
          type: LineType.forward,
          playerIds: <String>[],
        ),
      for (int i = 1; i <= 3; i++)
        Line(
          id: 'defense-$i',
          lineNumber: i,
          type: LineType.defense,
          playerIds: <String>[],
        ),
    ];
  }
}
