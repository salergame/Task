import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/order_service.dart';
import 'services/user_schedule_service.dart';
import 'services/driver_schedule_service.dart';
import 'services/driver_earnings_service.dart';
import 'services/verification_service.dart';
import 'services/map_service.dart';
import 'utils/constants.dart';
import 'utils/theme_provider.dart';
import 'utils/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/user_register_screen.dart';
import 'screens/auth/driver_register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/driver_map_screen.dart';
import 'screens/driver_verification_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/driver_schedule_screen.dart';
import 'screens/driver_active_orders_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/driver_loyalty_screen.dart';
import 'screens/driver_order_history_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/user_schedule_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/support_screen.dart';
import 'screens/loyalty_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/security_screen.dart';
import 'screens/notifications_screen.dart';
import 'models/user_model.dart';

// Константы для Supabase
const String supabaseUrl = 'https://pshoujaaainxxkjzjukz.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzaG91amFhYWlueHhranpqdWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3MDgzODYsImV4cCI6MjA2NDI4NDM4Nn0.M6AoM5lehMQ1LXvGmMzqdipE9FynMSNY7UM6ZWQrsjw';
const String yandexMapkitApiKey = '18fb32f9-5ace-46c2-a283-8c60c38131a0';

// Глобальная переменная для отслеживания статуса инициализации
bool isSupabaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    isSupabaseInitialized = true;
    debugPrint('Supabase успешно инициализирован');
  } catch (e) {
    debugPrint('Ошибка инициализации Supabase: $e');
  }

  // Создаем экземпляр SupabaseService
  final supabaseService = SupabaseService();

  // Инициализация провайдеров
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => supabaseService),
        Provider<OrderService>(
          create: (_) => OrderService(supabaseService: supabaseService),
        ),
        Provider<UserScheduleService>(
          create: (_) => UserScheduleService(supabaseService: supabaseService),
        ),
        Provider<DriverScheduleService>(
          create: (_) =>
              DriverScheduleService(supabaseService: supabaseService),
        ),
        Provider<DriverEarningsService>(
          create: (_) =>
              DriverEarningsService(supabaseService: supabaseService),
        ),
        Provider<VerificationService>(
          create: (_) => VerificationService(supabaseService: supabaseService),
        ),
        Provider<MapService>(
          create: (_) => MapService(),
        ),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Mama Taxi',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF5EC7C3),
          secondary: const Color(0xFF2563EB),
        ),
        brightness: Brightness.dark,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register/user': (context) => const UserRegisterScreen(),
        '/register/driver': (context) => const DriverRegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/driver/map': (context) => const DriverMapScreen(),
        '/driver/verification': (context) => const DriverVerificationScreen(),
        '/driver/profile': (context) => const DriverProfileScreen(),
        '/driver/schedule': (context) => const DriverScheduleScreen(),
        '/driver/active_orders': (context) => const DriverActiveOrdersScreen(),
        '/driver/earnings': (context) => const DriverEarningsScreen(),
        '/driver/loyalty': (context) => const DriverLoyaltyScreen(),
        '/driver/order_history': (context) => const DriverOrderHistoryScreen(),
        '/user/profile': (context) => const UserProfileScreen(),
        '/user/schedule': (context) => const UserScheduleScreen(),
        '/admin': (context) => const AdminScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/support': (context) => const SupportScreen(),
        '/loyalty': (context) => const LoyaltyScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/security': (context) => const SecurityScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      // Используем onGenerateRoute для маршрутов с параметрами
      onGenerateRoute: (settings) {
        if (settings.name == '/edit_profile') {
          final UserModel? userProfile = settings.arguments as UserModel?;
          return MaterialPageRoute(
            builder: (context) => EditProfileScreen(userProfile: userProfile),
          );
        }
        return null;
      },
    );
  }
}
