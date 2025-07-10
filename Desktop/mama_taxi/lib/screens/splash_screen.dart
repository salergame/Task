import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mama_taxi/screens/auth/login_screen.dart';
import 'package:mama_taxi/screens/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Даем время для инициализации всех сервисов
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Проверяем, инициализирован ли Supabase
      final client = Supabase.instance.client;

      // Проверяем авторизацию
      final session = client.auth.currentSession;

      if (!mounted) return;

      if (session != null) {
        try {
          // Получаем профиль пользователя, чтобы проверить его роль
          final response = await client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle();

          if (response != null) {
            final role = response['role'] as String;
            debugPrint('Роль пользователя: $role');

            // Перенаправляем на соответствующий экран в зависимости от роли
            if (role == 'driver') {
              // Если водитель, перенаправляем на экран водителя
              Navigator.of(context).pushReplacementNamed('/driver/map');
            } else {
              // Если обычный пользователь, перенаправляем на экран карты
              Navigator.of(context).pushReplacementNamed('/map');
            }
          } else {
            // Если профиль не найден, перенаправляем на экран карты по умолчанию
            Navigator.of(context).pushReplacementNamed('/map');
          }
        } catch (e) {
          debugPrint('Ошибка при проверке роли пользователя: $e');
          // В случае ошибки перенаправляем на экран карты
          Navigator.of(context).pushReplacementNamed('/map');
        }
      } else {
        // Если пользователь не авторизован, перенаправляем на экран входа
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Ошибка при проверке авторизации: $e');
      // В случае ошибки с Supabase перенаправляем на экран входа
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.local_taxi, size: 100);
              },
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
