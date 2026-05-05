import 'package:flutter/material.dart';
import 'package:hockeyline/providers/auth_provider.dart';
import 'package:hockeyline/utils/validators.dart';
import 'package:hockeyline/widgets/design_widgets.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String? error = await context.read<AuthProvider>().resetPassword(
      email: _emailController.text.trim(),
      newPassword: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      showAppDialog(
        context: context,
        title: 'Ошибка сброса пароля',
        message: error,
        isError: true,
      );
      return;
    }
    showAppSnackBar(context, 'Пароль успешно обновлён', success: true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) => Validators.validateEmail(value ?? ''),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (String? value) => Validators.validatePassword(value ?? ''),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Подтверждение пароля'),
                validator: (String? value) {
                  if ((value ?? '') != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
