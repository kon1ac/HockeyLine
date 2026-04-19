import 'package:flutter/foundation.dart';
import 'package:hockeyline/models/app_data.dart';
import 'package:hockeyline/models/app_enums.dart';
import 'package:hockeyline/models/note.dart';
import 'package:hockeyline/models/player.dart';
import 'package:hockeyline/services/storage_service.dart';
import 'package:hockeyline/utils/validators.dart';

class TeamProvider extends ChangeNotifier {
  TeamProvider(this._storageService);

  final StorageService _storageService;
  final List<Player> _players = <Player>[];
  final List<Note> _notes = <Note>[];
  String _searchQuery = '';
  PlayerPosition? _positionFilter;
  PlayerStatus? _statusFilter;
  bool? _rosterFilter;
  PlayerSortType _sortType = PlayerSortType.nameAsc;
  bool _isLoading = false;

  List<Player> get players {
    final String query = _searchQuery.trim().toLowerCase();
    List<Player> result = List<Player>.from(_players);
    if (query.isNotEmpty) {
      result = result
          .where(
            (Player player) =>
                player.firstName.toLowerCase().contains(query) ||
                player.lastName.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_positionFilter != null) {
      result = result
          .where((Player player) => player.position == _positionFilter)
          .toList();
    }
    if (_statusFilter != null) {
      result = result.where((Player player) => player.status == _statusFilter).toList();
    }
    if (_rosterFilter != null) {
      result = result.where((Player player) => player.inRoster == _rosterFilter).toList();
    }

    result.sort((Player a, Player b) {
      switch (_sortType) {
        case PlayerSortType.nameAsc:
          return a.fullName.compareTo(b.fullName);
        case PlayerSortType.nameDesc:
          return b.fullName.compareTo(a.fullName);
        case PlayerSortType.ageAsc:
          return a.age.compareTo(b.age);
        case PlayerSortType.ageDesc:
          return b.age.compareTo(a.age);
      }
    });
    return result;
  }

  List<Player> get favoritePlayers {
    return _players.where((Player player) => player.isFavorite).toList(growable: false);
  }

  List<Player> get rosterPlayers {
    return _players.where((Player player) => player.inRoster).toList(growable: false);
  }
  PlayerSortType get sortType => _sortType;
  bool get isLoading => _isLoading;

  List<Note> notesByPlayerId(String playerId) {
    return _notes.where((Note note) => note.playerId == playerId).toList(growable: false);
  }

  Player? playerById(String playerId) {
    try {
      return _players.firstWhere((Player player) => player.id == playerId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPlayers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final AppData data = await _storageService.loadAppData();
      _players
        ..clear()
        ..addAll(data.players);
      _notes
        ..clear()
        ..addAll(data.notes);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Импорт полного бэкапа в формате основного JSON (как после экспорта).
  Future<String?> importBackupJson(String utf8Text) async {
    final String? error = await _storageService.importFullBackupJson(utf8Text);
    if (error != null) {
      return error;
    }
    await loadPlayers();
    return null;
  }

  /// Полный дамп `hockeyline_data.json` (users, players, lines, notes) — тот же формат, что для импорта.
  Future<String> exportFullAppDataJson() async {
    return _storageService.exportJson();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleFavorite(String playerId) async {
    final int index = _players.indexWhere((Player p) => p.id == playerId);
    if (index == -1) {
      return;
    }
    final Player current = _players[index];
    _players[index] = current.copyWith(isFavorite: !current.isFavorite);
    await _savePlayers();
    notifyListeners();
  }

  void updateFilters({
    PlayerPosition? position,
    PlayerStatus? status,
    bool? rosterStatus,
    bool clearPosition = false,
    bool clearStatus = false,
    bool clearRoster = false,
  }) {
    if (clearPosition) {
      _positionFilter = null;
    } else if (position != null) {
      _positionFilter = position;
    }
    if (clearStatus) {
      _statusFilter = null;
    } else if (status != null) {
      _statusFilter = status;
    }
    if (clearRoster) {
      _rosterFilter = null;
    } else if (rosterStatus != null) {
      _rosterFilter = rosterStatus;
    }
    notifyListeners();
  }

  void updateSortType(PlayerSortType sortType) {
    _sortType = sortType;
    notifyListeners();
  }

  Future<String?> addPlayer(Player player) async {
    final String? validationError = _validatePlayer(player, creating: true);
    if (validationError != null) {
      return validationError;
    }
    _players.add(player);
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<String?> updatePlayer(Player player) async {
    final int index = _players.indexWhere((Player p) => p.id == player.id);
    if (index == -1) {
      return 'Игрок не найден';
    }
    final String? validationError = _validatePlayer(player, creating: false);
    if (validationError != null) {
      return validationError;
    }
    _players[index] = player;
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<void> deletePlayer(String playerId) async {
    _players.removeWhere((Player p) => p.id == playerId);
    _notes.removeWhere((Note n) => n.playerId == playerId);
    await _saveAll();
    notifyListeners();
  }

  Future<String?> addNote({
    required String playerId,
    required String authorId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return 'Текст заметки не может быть пустым';
    }
    final DateTime now = DateTime.now();
    _notes.add(
      Note(
        id: now.microsecondsSinceEpoch.toString(),
        playerId: playerId,
        authorId: authorId,
        text: text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<String?> updateNote({
    required String noteId,
    required String text,
    required String currentUserId,
    required bool canEditAny,
  }) async {
    final int index = _notes.indexWhere((Note note) => note.id == noteId);
    if (index == -1) {
      return 'Заметка не найдена';
    }
    final Note old = _notes[index];
    if (!canEditAny && old.authorId != currentUserId) {
      return 'Недостаточно прав для редактирования';
    }
    _notes[index] = old.copyWith(text: text.trim(), updatedAt: DateTime.now());
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<String?> deleteNote({
    required String noteId,
    required String currentUserId,
    required bool canDeleteAny,
  }) async {
    final int index = _notes.indexWhere((Note note) => note.id == noteId);
    if (index == -1) {
      return 'Заметка не найдена';
    }
    final Note note = _notes[index];
    if (!canDeleteAny && note.authorId != currentUserId) {
      return 'Недостаточно прав для удаления';
    }
    _notes.removeAt(index);
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<void> toggleRoster(String playerId, bool inRoster) async {
    final int index = _players.indexWhere((Player p) => p.id == playerId);
    if (index == -1) {
      return;
    }
    _players[index] = _players[index].copyWith(inRoster: inRoster);
    await _savePlayers();
    notifyListeners();
  }

  Future<void> incrementStats({
    required String playerId,
    int goals = 0,
    int assists = 0,
    int penalties = 0,
    int games = 0,
    int plusMinus = 0,
  }) async {
    final int index = _players.indexWhere((Player p) => p.id == playerId);
    if (index == -1) {
      return;
    }
    final Player player = _players[index];
    final current = player.statistics;
    _players[index] = player.copyWith(
      statistics: current.copyWith(
        goals: current.goals + goals,
        assists: current.assists + assists,
        penaltyMinutes: current.penaltyMinutes + penalties,
        games: current.games + games,
        plusMinus: current.plusMinus + plusMinus,
      ),
    );
    await _saveAll();
    notifyListeners();
  }

  Future<void> _savePlayers() async {
    final AppData data = await _storageService.loadAppData();
    await _storageService.saveAppData(
      AppData(
        users: data.users,
        players: _players,
        lines: data.lines,
        notes: _notes,
      ),
    );
  }

  Future<void> _saveAll() async {
    await _savePlayers();
  }

  String? _validatePlayer(Player player, {required bool creating}) {
    final String? firstNameError = Validators.validateName(player.firstName, 'Имя');
    if (firstNameError != null) {
      return firstNameError;
    }
    final String? lastNameError = Validators.validateName(player.lastName, 'Фамилия');
    if (lastNameError != null) {
      return lastNameError;
    }
    final String? dateError = Validators.validateBirthDate(player.birthDate);
    if (dateError != null) {
      return dateError;
    }
    final String? numberError = Validators.validateNumber(player.number);
    if (numberError != null) {
      return numberError;
    }
    final bool exists = _players.any(
      (Player p) => p.number == player.number && (!creating ? p.id != player.id : true),
    );
    if (exists) {
      return 'Игрок с таким номером уже существует в команде';
    }
    final String? heightError = Validators.validateHeight(player.height);
    if (heightError != null) {
      return heightError;
    }
    final String? weightError = Validators.validateWeight(player.weight);
    if (weightError != null) {
      return weightError;
    }
    final String? photoError = Validators.validatePhotoUrl(player.photoUrl ?? '');
    if (photoError != null) {
      return photoError;
    }
    return null;
  }

  String formatPosition(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'Вратарь';
      case PlayerPosition.defender:
        return 'Защитник';
      case PlayerPosition.forward:
        return 'Нападающий';
    }
  }
}
