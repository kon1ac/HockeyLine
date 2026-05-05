import 'package:flutter/foundation.dart';
import 'package:hockeyline/models/app_enums.dart';
import 'package:hockeyline/models/app_data.dart';
import 'package:hockeyline/models/user.dart';
import 'package:hockeyline/services/storage_service.dart';
import 'package:hockeyline/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._storageService);

  static const String _kSessionKind = 'hockeyline_auth_session_kind';
  static const String _kSessionUserId = 'hockeyline_auth_session_user_id';
  static const String _sessionKindGuest = 'guest';
  static const String _sessionKindRegistered = 'registered';

  final StorageService _storageService;
  bool _systemAccountsEnsured = false;
  User? _currentUser;
  bool _isLoading = false;
  bool _bootstrapDone = false;

  User? get currentUser => _currentUser;
  bool get isAuthorized => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isBootstrapDone => _bootstrapDone;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isCoach => _currentUser?.role == UserRole.coach;
  bool get isGuest => _currentUser?.role == UserRole.guest;

  Future<List<User>> allUsers() async {
    final AppData appData = await _storageService.loadAppData();
    return List<User>.from(appData.users);
  }

  /// После полной замены данных (импорт JSON) нужно снова проверить системного администратора.
  void invalidateSystemAccountsCache() {
    _systemAccountsEnsured = false;
  }

  static const String systemAdminEmail = 'isip_i.v.egorov@mpt.ru';
  static const String systemAdminId = 'system-admin-1';

  bool isSystemAdmin(String userId) {
    return userId == systemAdminId;
  }

  Future<void> ensureSystemAccounts() async {
    if (_systemAccountsEnsured) {
      return;
    }
    final AppData appData = await _storageService.loadAppData();
    final List<User> users = List<User>.from(appData.users);

    final int adminIndex = users.indexWhere(
      (User user) => user.email.toLowerCase() == systemAdminEmail,
    );
    if (adminIndex == -1) {
      users.add(
        const User(
          id: systemAdminId,
          email: systemAdminEmail,
          password: 'Testuser1',
          role: UserRole.admin,
          fullName: 'System Admin',
        ),
      );
    } else {
      users[adminIndex] = users[adminIndex].copyWith(
        role: UserRole.admin,
        password: 'Testuser1',
      );
    }

    await _storageService.saveAppData(
      AppData(
        users: users,
        players: appData.players,
        lines: appData.lines,
        notes: appData.notes,
      ),
    );
    _systemAccountsEnsured = true;
  }

  /// Первый запуск экрана: гарантируем системные учётки и восстанавливаем сессию без повторного ввода пароля.
  Future<void> bootstrapInitialSession() async {
    await ensureSystemAccounts();
    await tryRestoreSession();
    _bootstrapDone = true;
    notifyListeners();
  }

  Future<void> tryRestoreSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? kind = prefs.getString(_kSessionKind);
    if (kind == null) {
      return;
    }
    if (kind == _sessionKindGuest) {
      _currentUser = User(
        id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@local',
        password: '',
        role: UserRole.guest,
        fullName: 'Guest',
      );
      return;
    }
    if (kind != _sessionKindRegistered) {
      await _clearPersistedSession();
      return;
    }
    final String? userId = prefs.getString(_kSessionUserId);
    if (userId == null || userId.isEmpty) {
      await _clearPersistedSession();
      return;
    }
    final AppData appData = await _storageService.loadAppData();
    User? found;
    for (final User user in appData.users) {
      if (user.id == userId) {
        found = user;
        break;
      }
    }
    if (found == null) {
      await _clearPersistedSession();
      return;
    }
    _currentUser = found;
  }

  /// После импорта JSON: обновить текущего пользователя из файла или выйти, если его больше нет.
  Future<void> reconcileSessionAfterDataChange() async {
    final User? user = _currentUser;
    if (user == null) {
      return;
    }
    if (user.role == UserRole.guest) {
      return;
    }
    final AppData appData = await _storageService.loadAppData();
    User? found;
    for (final User u in appData.users) {
      if (u.id == user.id) {
        found = u;
        break;
      }
    }
    if (found == null) {
      _currentUser = null;
      await _clearPersistedSession();
    } else {
      _currentUser = found;
    }
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final User? user = _currentUser;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_kSessionKind);
      await prefs.remove(_kSessionUserId);
      return;
    }
    if (user.role == UserRole.guest) {
      await prefs.setString(_kSessionKind, _sessionKindGuest);
      await prefs.remove(_kSessionUserId);
      return;
    }
    await prefs.setString(_kSessionKind, _sessionKindRegistered);
    await prefs.setString(_kSessionUserId, user.id);
  }

  Future<void> _clearPersistedSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKind);
    await prefs.remove(_kSessionUserId);
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? emailError = Validators.validateEmail(email);
      if (emailError != null) {
        return emailError;
      }
      final AppData appData = await _storageService.loadAppData();
      final User? found = _findByEmail(appData.users, email);

      if (found == null || found.password != password) {
        return 'Неверный email или пароль';
      }
      _currentUser = found;
      await _persistSession();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? emailError = Validators.validateEmail(email);
      if (emailError != null) {
        return emailError;
      }
      final String? passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        return passwordError;
      }
      if (password != confirmPassword) {
        return 'Пароли не совпадают';
      }

      final AppData appData = await _storageService.loadAppData();
      if (_findByEmail(appData.users, email) != null) {
        return 'Пользователь с таким email уже существует';
      }

      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final User user = User(
        id: id,
        email: email,
        password: password,
        role: UserRole.coach,
        fullName: fullName,
      );

      final AppData updatedData = AppData(
        users: <User>[...appData.users, user],
        players: appData.players,
        lines: appData.lines,
        notes: appData.notes,
      );
      await _storageService.saveAppData(updatedData);
      _currentUser = user;
      await _persistSession();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String? emailError = Validators.validateEmail(email);
      if (emailError != null) {
        return emailError;
      }
      final String? passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        return passwordError;
      }
      if (newPassword != confirmPassword) {
        return 'Пароли не совпадают';
      }

      final AppData appData = await _storageService.loadAppData();
      final int index = appData.users.indexWhere(
        (User user) => user.email.toLowerCase() == email.toLowerCase(),
      );
      if (index == -1) {
        return 'Пользователь не найден';
      }
      final List<User> users = List<User>.from(appData.users);
      users[index] = users[index].copyWith(password: newPassword);
      await _storageService.saveAppData(
        AppData(
          users: users,
          players: appData.players,
          lines: appData.lines,
          notes: appData.notes,
        ),
      );
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> changeCurrentPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final User? user = _currentUser;
    if (user == null) {
      return 'Пользователь не авторизован';
    }
    if (user.password != oldPassword) {
      return 'Старый пароль неверный';
    }
    final String? passwordError = Validators.validatePassword(newPassword);
    if (passwordError != null) {
      return passwordError;
    }

    final AppData appData = await _storageService.loadAppData();
    final List<User> users = appData.users
        .map((User u) => u.id == user.id ? u.copyWith(password: newPassword) : u)
        .toList();

    await _storageService.saveAppData(
      AppData(
        users: users,
        players: appData.players,
        lines: appData.lines,
        notes: appData.notes,
      ),
    );
    _currentUser = _currentUser?.copyWith(password: newPassword);
    notifyListeners();
    return null;
  }

  Future<void> deleteCurrentAccount() async {
    final User? user = _currentUser;
    if (user == null) {
      return;
    }
    final AppData appData = await _storageService.loadAppData();
    final List<User> users = appData.users
        .where((User u) => u.id != user.id)
        .toList();
    await _storageService.saveAppData(
      AppData(
        users: users,
        players: appData.players,
        lines: appData.lines,
        notes: appData.notes,
      ),
    );
    _currentUser = null;
    await _clearPersistedSession();
    notifyListeners();
  }

  Future<String?> deleteUserById(String userId) async {
    final User? currentUser = _currentUser;
    if (currentUser == null || !isAdmin) {
      return 'Недостаточно прав';
    }
    if (isSystemAdmin(userId)) {
      return 'Нельзя удалить системного администратора';
    }
    if (currentUser.id == userId) {
      return 'Нельзя удалить текущего администратора';
    }
    final AppData appData = await _storageService.loadAppData();
    final bool exists = appData.users.any((User user) => user.id == userId);
    if (!exists) {
      return 'Пользователь не найден';
    }
    final List<User> users = appData.users
        .where((User user) => user.id != userId)
        .toList(growable: false);
    await _storageService.saveAppData(
      AppData(
        users: users,
        players: appData.players,
        lines: appData.lines,
        notes: appData.notes,
      ),
    );
    notifyListeners();
    return null;
  }

  Future<String> dataFilePath() async {
    return _storageService.getPrimaryDataFilePath();
  }

  Future<String?> openDataFileLocation() async {
    return _storageService.openPrimaryDataFileLocation();
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _clearPersistedSession();
    notifyListeners();
  }

  Future<void> signInAsGuest() async {
    _currentUser = User(
      id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@local',
      password: '',
      role: UserRole.guest,
      fullName: 'Guest',
    );
    await _persistSession();
    notifyListeners();
  }

  User? _findByEmail(List<User> users, String email) {
    for (final User user in users) {
      if (user.email.toLowerCase() == email.toLowerCase()) {
        return user;
      }
    }
    return null;
  }
}
