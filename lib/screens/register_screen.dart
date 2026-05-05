import 'package:flutter/material.dart';
import 'package:hockeyline/providers/auth_provider.dart';
import 'package:hockeyline/utils/validators.dart';
import 'package:hockeyline/widgets/design_widgets.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) {
      return;
    }
    try {
      final AuthProvider auth = context.read<AuthProvider>();
      final String? error = await auth.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      if (error != null) {
        showAppDialog(
          context: context,
          title: 'Ошибка регистрации',
          message: error,
          isError: true,
        );
        return;
      }
      showAppSnackBar(context, 'Регистрация успешна', success: true);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppDialog(
        context: context,
        title: 'Ошибка регистрации',
        message: 'Ошибка регистрации: $error',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) {
                  return Validators.validateEmail(value ?? '');
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: (String? value) {
                  return Validators.validatePassword(value ?? '');
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Подтвердите пароль'),
                validator: (String? value) {
                  if ((value ?? '') != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'ФИО (опционально)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: Text(
                  isLoading ? 'Регистрация...' : 'Зарегистрироваться',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
