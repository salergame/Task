import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import 'driver_register_screen.dart';
import 'user_register_screen.dart';
import '../../services/admin_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordResetSent = false;
  bool _isConfirmationEmailSent = false;
  final _supabaseService = SupabaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.session != null) {
        if (mounted) {
          try {
            // Получаем профиль пользователя, чтобы проверить его роль
            final userProfile = await _supabaseService.getCurrentUser();

            if (userProfile != null) {
              debugPrint('Роль пользователя: ${userProfile.role}');

              // Перенаправляем на соответствующий экран в зависимости от роли
              if (userProfile.role == 'driver') {
                // Если водитель, перенаправляем на экран водителя
                Navigator.pushReplacementNamed(context, '/driver/map');
              } else {
                // Если обычный пользователь, перенаправляем на экран карты
                Navigator.pushReplacementNamed(context, '/map');
              }
            } else {
              // Если профиль не найден, перенаправляем на экран карты по умолчанию
              Navigator.pushReplacementNamed(context, '/map');
            }
          } catch (e) {
            debugPrint('Ошибка при проверке роли пользователя: $e');
            // В случае ошибки перенаправляем на экран карты
            Navigator.pushReplacementNamed(context, '/map');
          }
        }
      } else {
        setState(() {
          _errorMessage =
              'Не удалось войти. Проверьте данные и попробуйте снова.';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка при входе: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty ||
        !RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Введите корректный email для сброса пароля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.resetPassword(_emailController.text.trim());
      setState(() {
        _isPasswordResetSent = true;
      });
      _showPasswordResetDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при отправке запроса на сброс пароля';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendConfirmationEmail() async {
    if (_emailController.text.isEmpty ||
        !RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Введите корректный email для повторной отправки';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.resendEmailConfirmation(
        _emailController.text.trim(),
      );
      setState(() {
        _isConfirmationEmailSent = true;
      });
      _showConfirmEmailDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при повторной отправке письма подтверждения';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: const Text(
          'На указанный email отправлена инструкция по сбросу пароля. '
          'Проверьте вашу почту и следуйте инструкциям в письме.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение email'),
        content: Text(
          _isConfirmationEmailSent
              ? 'Письмо с подтверждением повторно отправлено на указанный email. '
                  'Проверьте вашу почту и следуйте инструкциям в письме.'
              : 'Ваш email не подтвержден. Проверьте вашу почту или запросите '
                  'повторную отправку письма с подтверждением.',
        ),
        actions: [
          if (!_isConfirmationEmailSent)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resendConfirmationEmail();
              },
              child: const Text('Отправить повторно'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authCodeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Вход для администраторов'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: authCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Код авторизации',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              authCodeController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Заполните все поля'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final adminService = AdminService();
                            final success = await adminService.loginAdmin(
                              email: emailController.text,
                              password: passwordController.text,
                              authCode: authCodeController.text,
                            );

                            if (!mounted) return;
                            Navigator.of(context).pop();

                            if (success) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/admin');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ошибка входа. Проверьте учетные данные и код авторизации.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        child: const Text('Войти'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.background,
          ),
          Column(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 17),
                    Container(
                      width: 144,
                      height: 144,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(72),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.borderRadiusExtraLarge),
                      topRight: Radius.circular(
                        AppSizes.borderRadiusExtraLarge,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              AppStrings.login,
                              style: AppTextStyles.heading,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            InputField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Введите корректный email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InputField(
                              label: 'Пароль',
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите пароль';
                                }
                                if (value.length < 6) {
                                  return 'Пароль должен содержать минимум 6 символов';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: 'Войти',
                              onPressed: _login,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                'Забыли пароль?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.link,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _resendConfirmationEmail,
                              child: Text(
                                'Повторно отправить подтверждение email',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.link,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.padding,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/register/driver',
                                      );
                                    },
                                    child: Text(
                                      AppStrings.registerAsDriver,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.link,
                                      ),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/register/user',
                                  );
                                },
                                child: Text(
                                  AppStrings.registerAsUser,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.link,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSocialButton(
                                  onTap: () {},
                                  icon: Icons.apple,
                                ),
                                _buildSocialButton(
                                  onTap: () {},
                                  icon: Icons.g_mobiledata,
                                ),
                                _buildSocialButton(
                                  onTap: () {},
                                  icon: Icons.facebook,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Вы администратор?',
                                  style: AppTextStyles.body,
                                ),
                                TextButton(
                                  onPressed: _showAdminLoginDialog,
                                  child: Text(
                                    'Войти в админ-панель',
                                    style: AppTextStyles.link,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 103,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: Center(child: Icon(icon, color: AppColors.black, size: 24)),
      ),
    );
  }
}
