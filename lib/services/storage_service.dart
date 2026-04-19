import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:hockeyline/models/app_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _prefsDataKey = 'hockeyline_data_json';
  static const String _projectDataFileName = 'hockeyline_data.json';
  static const List<String> _requiredListKeys = <String>[
    'users',
    'players',
    'lines',
    'notes',
  ];
  File? _dataFile;
  bool _usePrefsStorage = false;

  Future<void> initDataFile() async {
    if (kIsWeb) {
      _usePrefsStorage = true;
      await _ensurePrefsInitialized();
      return;
    }
    try {
      _dataFile = await _resolvePrimaryDataFile();
      if (_isIosOrAndroid) {
        await _maybeMigrateLegacyMobileDataFile(_dataFile!);
      }
      if (!await _dataFile!.exists()) {
        await _createInitialDataFile();
      } else if (await _dataFile!.length() == 0) {
        await _createInitialDataFile();
      }
    } on MissingPluginException catch (_) {
      _usePrefsStorage = true;
      await _ensurePrefsInitialized();
    } on UnsupportedError catch (_) {
      _usePrefsStorage = true;
      await _ensurePrefsInitialized();
    }
  }

  Future<Map<String, dynamic>> loadData() async {
    await initDataFile();
    final String raw = _usePrefsStorage
        ? await _readPrefsData()
        : await _dataFile!.readAsString();
    final Object? decoded = jsonDecode(raw);
    final Map<String, dynamic> normalized = _normalizeData(
      (decoded as Map).cast<String, dynamic>(),
    );
    if (jsonEncode(normalized) != raw) {
      await saveData(normalized);
    }
    return normalized;
  }

  Future<void> saveData(Map<String, dynamic> data) async {
    await initDataFile();
    final String encoded = jsonEncode(_normalizeData(data));
    if (_usePrefsStorage) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsDataKey, encoded);
      return;
    }
    await _dataFile!.writeAsString(encoded);
  }

  Future<AppData> loadAppData() async {
    final Map<String, dynamic> raw = await loadData();
    return AppData.fromJson(raw);
  }

  Future<void> saveAppData(AppData data) async {
    await saveData(data.toJson());
  }

  Future<void> seedDemoDataIfEmpty() async {
    final Map<String, dynamic> data = await loadData();
    final List<dynamic> users = data['users'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> players = data['players'] as List<dynamic>? ?? <dynamic>[];
    if (users.isNotEmpty || players.isNotEmpty) {
      return;
    }
    await saveData(_demoDataTemplate());
  }

  Future<String> exportJson() async {
    await initDataFile();
    final String source = _usePrefsStorage
        ? await _readPrefsData()
        : await _dataFile!.readAsString();
    final String fileName = 'hockeyline_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final Uint8List bytes = Uint8List.fromList(utf8.encode(source));
    final Directory preferredDirectory = await getExportDirectory();
    final File exportFile = File('${preferredDirectory.path}/$fileName');
    await exportFile.writeAsBytes(bytes, flush: true);
    return exportFile.path;
  }

  /// Полная замена локальных данных содержимым бэкапа (тот же формат, что и основной файл / экспорт JSON).
  Future<String?> importFullBackupJson(String utf8Text) async {
    try {
      final Object? decoded = jsonDecode(utf8Text.trim());
      if (decoded is! Map<dynamic, dynamic>) {
        return 'Ожидается JSON-объект с полями users, players, lines, notes.';
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      final Map<String, dynamic> normalized = _normalizeData(map);
      AppData.fromJson(normalized);
      await saveData(normalized);
      return null;
    } on FormatException catch (e) {
      return 'Некорректный JSON: ${e.message}';
    } catch (e) {
      return 'Не удалось импортировать данные: $e';
    }
  }

  Future<String> getPrimaryDataFilePath() async {
    await initDataFile();
    if (_usePrefsStorage) {
      return 'web:$_prefsDataKey (аналог hockeyline_data.json в localStorage)';
    }
    return _dataFile?.path ?? '';
  }

  Future<String?> openPrimaryDataFileLocation() async {
    if (kIsWeb) {
      return 'Функция недоступна в веб-режиме';
    }
    await initDataFile();
    final String? path = _dataFile?.path;
    if (path == null || path.isEmpty) {
      return 'Файл данных не найден';
    }
    try {
      await Process.start('explorer.exe', <String>['/select,', path]);
      return null;
    } catch (_) {
      return 'Не удалось открыть проводник';
    }
  }

  Map<String, dynamic> _emptyDataTemplate() {
    return <String, dynamic>{
      'users': <Map<String, dynamic>>[],
      'players': <Map<String, dynamic>>[],
      'lines': <Map<String, dynamic>>[],
      'notes': <Map<String, dynamic>>[],
      'meta': <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  Map<String, dynamic> _demoDataTemplate() {
    return <String, dynamic>{
      'users': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'demo-user-1',
          'email': 'demo@hockeyline.app',
          'password': 'Demo1234',
          'role': 'coach',
          'fullName': 'Demo Coach',
        },
      ],
      'players': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'demo-player-1',
          'firstName': 'Ilya',
          'lastName': 'Ivanov',
          'birthDate': '2001-05-14T00:00:00.000',
          'position': 'forward',
          'number': 17,
          'status': 'active',
          'inRoster': true,
          'isFavorite': false,
          'statistics': <String, dynamic>{
            'games': 20,
            'goals': 11,
            'assists': 9,
            'penaltyMinutes': 8,
            'plusMinus': 5,
          },
        },
      ],
      'lines': <Map<String, dynamic>>[],
      'notes': <Map<String, dynamic>>[],
      'meta': <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> source) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(source);
    for (final String key in _requiredListKeys) {
      final Object? value = data[key];
      if (value is! List<dynamic>) {
        data[key] = <dynamic>[];
      }
    }
    final Map<String, dynamic> meta = data['meta'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['meta'] as Map<String, dynamic>)
        : <String, dynamic>{};
    meta['updatedAt'] = DateTime.now().toIso8601String();
    data['meta'] = meta;
    return data;
  }

  Future<Directory> _resolveDataDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } on MissingPluginException catch (_) {
      return _resolvePersistentFallbackDirectory();
    } on UnsupportedError catch (_) {
      return _resolvePersistentFallbackDirectory();
    }
  }

  bool get _isIosOrAndroid {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// На телефонах данные должны жить в sandbox приложения, а не рядом с
  /// [Directory.current] (там путь непредсказуем; файл мог оказаться вне каталога данных приложения).
  Future<File> _resolvePrimaryDataFile() async {
    if (_isIosOrAndroid) {
      final Directory directory = await _resolveDataDirectory();
      return File('${directory.path}${Platform.pathSeparator}$_projectDataFileName');
    }
    if (!kIsWeb) {
      final File projectFile = File(
        '${Directory.current.path}${Platform.pathSeparator}$_projectDataFileName',
      );
      try {
        final Directory parent = projectFile.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
        if (!await projectFile.exists()) {
          await projectFile.writeAsString(await _readBundledDataJsonOrEmptyTemplate());
        }
        return projectFile;
      } catch (_) {
        // Fall back to app documents directory when project file is unavailable.
      }
    }
    final Directory directory = await _resolveDataDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_projectDataFileName');
  }

  /// Если раньше файл создавался рядом с [Directory.current], переносим в каталог приложения.
  Future<void> _maybeMigrateLegacyMobileDataFile(File canonical) async {
    if (await canonical.exists() && await canonical.length() > 2) {
      return;
    }
    try {
      final File legacy = File(
        '${Directory.current.path}${Platform.pathSeparator}$_projectDataFileName',
      );
      if (await legacy.exists() && await legacy.length() > 2) {
        await legacy.copy(canonical.path);
      }
    } catch (_) {}
  }

  /// Первый запуск: копируем структуру из asset [hockeyline_data.json], иначе шаблон.
  Future<void> _createInitialDataFile() async {
    await _dataFile!.writeAsString(await _readBundledDataJsonOrEmptyTemplate());
  }

  Future<String> _readBundledDataJsonOrEmptyTemplate() async {
    try {
      final String bundled = await rootBundle.loadString(_projectDataFileName);
      final Object? decoded = jsonDecode(bundled);
      if (decoded is Map<String, dynamic>) {
        return jsonEncode(_normalizeData(decoded));
      }
      if (decoded is Map) {
        return jsonEncode(_normalizeData(decoded.cast<String, dynamic>()));
      }
    } catch (_) {
      // Asset отсутствует или невалиден.
    }
    return jsonEncode(_emptyDataTemplate());
  }

  Future<Directory> _resolvePersistentFallbackDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Local file system is not available on web');
    }
    final String? appData = Platform.environment['APPDATA'];
    final Directory fallback = appData != null && appData.isNotEmpty
        ? Directory('$appData/hockeyline')
        : Directory('${Directory.current.path}/.hockeyline_data');
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  /// Публичная папка «Загрузки» (в проводнике: **Внутренний накопитель → Download**),
  /// не каталог приложения `Android/data/<package>/...`.
  static const List<String> _androidPublicDownloadPaths = <String>[
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/sdcard/Download',
    '/mnt/sdcard/Download',
  ];

  Future<bool> _ensureExportDir(Directory directory) async {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return await directory.exists();
    } catch (_) {
      return false;
    }
  }

  /// Экспорт CSV/PDF/JSON: на Android — в публичную **Download**, не в sandbox приложения.
  Future<Directory> getExportDirectory() async {
    if (kIsWeb) {
      return _resolveDataDirectory();
    }

    if (Platform.isAndroid) {
      for (final String path in _androidPublicDownloadPaths) {
        final Directory directory = Directory(path);
        if (await _ensureExportDir(directory)) {
          return directory;
        }
      }
      return _resolveDataDirectory();
    }

    try {
      final Directory? systemDownloads = await getDownloadsDirectory();
      if (systemDownloads != null && await _ensureExportDir(systemDownloads)) {
        return systemDownloads;
      }
    } catch (_) {}

    final String? userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final Directory directory = Directory(
        '$userProfile${Platform.pathSeparator}Downloads',
      );
      if (await _ensureExportDir(directory)) {
        return directory;
      }
    }

    return _resolveDataDirectory();
  }

  Future<void> _ensurePrefsInitialized() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsDataKey)) {
      await prefs.setString(_prefsDataKey, await _readBundledDataJsonOrEmptyTemplate());
    }
  }

  Future<String> _readPrefsData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsDataKey) ?? jsonEncode(_emptyDataTemplate());
  }
}
