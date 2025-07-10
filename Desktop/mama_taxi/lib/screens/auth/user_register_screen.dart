import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../models/user_model.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Начало регистрации пользователя');
      // Регистрация пользователя
      final supabaseService = SupabaseService();
      final response = await supabaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        UserRole.user,
      );

      debugPrint(
        'Ответ от сервера получен: ${response?.user != null ? 'Успешно' : 'Неудачно'}',
      );

      if (response?.user != null) {
        debugPrint('Обновление профиля пользователя');
        // Обновление профиля пользователя
        try {
          final firstName = _fullNameController.text.trim().split(' ').first;
          final lastName = _fullNameController.text
              .trim()
              .split(' ')
              .skip(1)
              .join(' ');

          final updatedUser = UserModel(
            id: response?.user?.id,
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: 'user',
          );

          await supabaseService.updateUserProfile(updatedUser);
          debugPrint('Профиль пользователя обновлен');
        } catch (e) {
          debugPrint('Ошибка при обновлении профиля: $e');
          // Продолжаем выполнение, так как основная регистрация прошла успешно
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Регистрация успешна. Проверьте почту для подтверждения аккаунта.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        debugPrint('Пользователь не создан, но ошибки нет');
        setState(() {
          _errorMessage = 'Не удалось завершить регистрацию. Попробуйте позже.';
        });
      }
    } on AuthException catch (e) {
      debugPrint('AuthException при регистрации: ${e.message}');
      setState(() {
        if (e.message.contains('already registered') ||
            e.message.contains('already exists')) {
          _errorMessage = 'Пользователь с таким email уже зарегистрирован';
        } else if (e.message.contains('password')) {
          _errorMessage = 'Ошибка в пароле: ${e.message}';
        } else if (e.message.contains('email')) {
          _errorMessage = 'Ошибка в email: ${e.message}';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      debugPrint('Неизвестная ошибка при регистрации: $e');
      setState(() {
        _errorMessage = 'Ошибка при регистрации: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.userRegistration,
          style: AppTextStyles.heading,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Личные данные',
                  child: Column(
                    children: [
                      InputField(
                        label: 'Полное имя',
                        controller: _fullNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите ваше имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                        label: AppStrings.phoneNumber,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('+7', style: AppTextStyles.body),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите номер телефона';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Введите корректный номер телефона';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Безопасность',
                  child: Column(
                    children: [
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
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Подтверждение пароля',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Подтвердите пароль';
                          }
                          if (value != _passwordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Информация о приложении',
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.infoBackground,
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.infoText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.appInfo,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.infoText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.infoBackground,
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: AppColors.infoText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.driverVerification,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.infoText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                PrimaryButton(
                  text: AppStrings.register,
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.link,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subheading),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
