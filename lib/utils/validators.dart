class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );
  static final RegExp _nameRegex = RegExp(r'^[A-Za-zА-Яа-яЁё]{1,30}$');
  static final RegExp _urlRegex = RegExp(r'^(https?:\/\/).+');

  static String? validateEmail(String value) {
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (!_passwordRegex.hasMatch(value)) {
      return 'Минимум 8 символов, A-z и цифра';
    }
    return null;
  }

  static String? validateName(String value, String field) {
    if (!_nameRegex.hasMatch(value.trim())) {
      return '$field: только буквы, 1-30 символов';
    }
    return null;
  }

  static String? validateNumber(int value) {
    if (value < 1 || value > 99) {
      return 'Номер должен быть от 1 до 99';
    }
    return null;
  }

  static String? validateHeight(int? value) {
    if (value == null) {
      return null;
    }
    if (value < 100 || value > 230) {
      return 'Рост: 100-230 см';
    }
    return null;
  }

  static String? validateWeight(int? value) {
    if (value == null) {
      return null;
    }
    if (value < 40 || value > 150) {
      return 'Вес: 40-150 кг';
    }
    return null;
  }

  static String? validateBirthDate(DateTime value) {
    final DateTime now = DateTime.now();
    if (value.isAfter(now)) {
      return 'Дата рождения не может быть в будущем';
    }
    int age = now.year - value.year;
    final bool hadBirthday =
        now.month > value.month ||
        (now.month == value.month && now.day >= value.day);
    if (!hadBirthday) {
      age--;
    }
    if (age < 14 || age > 60) {
      return 'Возраст должен быть от 14 до 60 лет';
    }
    return null;
  }

  static String? validatePhotoUrl(String value) {
    if (value.isEmpty) {
      return null;
    }
    final String trimmed = value.trim();
    if (_urlRegex.hasMatch(trimmed)) {
      return null;
    }
    final bool looksLikeLocalPath =
        trimmed.contains(r'\') ||
        trimmed.contains('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(trimmed);
    if (!looksLikeLocalPath) {
      return 'Укажите URL или путь к локальному фото';
    }
    return null;
  }
}
