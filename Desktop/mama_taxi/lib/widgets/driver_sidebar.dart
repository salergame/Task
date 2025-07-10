import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/supabase_service.dart';
import '../screens/driver_profile_screen.dart';
import '../screens/driver_loyalty_screen.dart';
import '../screens/support_screen.dart';
import '../screens/driver_schedule_screen.dart';
import '../screens/driver_earnings_screen.dart';
import '../screens/driver_verification_screen.dart';

class DriverSidebar extends StatelessWidget {
  final String driverName;
  final String driverRating;
  final String? driverImageUrl;
  final VoidCallback onClose;
  final bool isOnline;
  final Function(bool)? onStatusChange;

  const DriverSidebar({
    super.key,
    required this.driverName,
    this.driverRating = '0.0',
    this.driverImageUrl,
    required this.onClose,
    this.isOnline = true,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(30, 8),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
          ),
          BoxShadow(
            offset: const Offset(0, 20),
            blurRadius: 25,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Профиль водителя
          _buildDriverProfile(supabaseService, context),

          // Основное меню
          _buildMainMenu(),

          const Spacer(),

          // Кнопка выхода
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // Профиль водителя
  Widget _buildDriverProfile(
    SupabaseService supabaseService,
    BuildContext context,
  ) {
    return Container(
      height: 169,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар водителя
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: driverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(driverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: driverImageUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        driverRating,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Добавляем почту пользователя
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        supabaseService.currentUser?.email ?? "Email не указан",
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Обновленная кнопка редактирования профиля
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Редактировать профиль'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5EC7C3),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // Основное меню
  Widget _buildMainMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Заказы
          _buildMenuSection([
            _buildNavItem('Активные заказы', Icons.local_taxi,
                onTap: (context) {
              Navigator.pushNamed(context, '/driver/orders');
            }),
            _buildNavItem('История заказов', Icons.history, onTap: (context) {
              Navigator.pushNamed(context, '/driver/orders/history');
            }),
          ]),

          // Статус и график
          _buildMenuSection([
            _buildNavItem('График работы', Icons.calendar_today_outlined,
                onTap: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverScheduleScreen(),
                ),
              );
            }),
            _buildOnlineStatusItem(isOnline),
          ]),

          // Финансы и документы
          _buildMenuSection([
            _buildNavItem('Доходы и выплаты', Icons.monetization_on_outlined,
                onTap: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverEarningsScreen(),
                ),
              );
            }),
            _buildNavItem('Документы и верификация', Icons.badge_outlined,
                onTap: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverVerificationScreen(),
                ),
              );
            }),
          ]),

          // Дополнительные функции
          Builder(
            builder: (context) => _buildMenuSection([
              _buildNavItem('Программа лояльности', Icons.card_giftcard,
                  onTap: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverLoyaltyScreen(),
                  ),
                );
              }),
              _buildNavItem('Настройки', Icons.settings_outlined,
                  onTap: (context) {
                Navigator.pushNamed(context, '/settings');
              }),
              _buildNavItem('Поддержка и помощь', Icons.help_outline,
                  onTap: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              }),
            ]),
          ),
        ],
      ),
    );
  }

  // Секция меню
  Widget _buildMenuSection(List<Widget> items) {
    return Column(children: [...items, const SizedBox(height: 8)]);
  }

  // Навигационный элемент
  Widget _buildNavItem(String title, IconData icon,
      {Function(BuildContext)? onTap}) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: onTap != null ? () => onTap(context) : null,
        child: Container(
          width: 288,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 16, color: const Color(0xFF374151)),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Навигационный элемент с бейджем
  Widget _buildNavItemWithBadge(String title, IconData icon, String badgeText) {
    return Container(
      width: 288,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: const Color(0xFF374151)),
          const SizedBox(width: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Center(
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // Статус онлайн/офлайн
  Widget _buildOnlineStatusItem(bool isOnline) {
    return GestureDetector(
      onTap: onStatusChange != null ? () => onStatusChange!(!isOnline) : null,
      child: Container(
        width: 288,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: onStatusChange != null ? Colors.grey.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.circle, size: 18, color: Color(0xFF374151)),
            const SizedBox(width: 20),
            const Text(
              'Статус',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            Text(
              isOnline ? 'Онлайн' : 'Офлайн',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isOnline ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
            if (onStatusChange != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.touch_app,
                size: 14,
                color: Colors.grey,
              ),
            ],
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // Кнопка выхода
  Widget _buildLogoutButton() {
    return Builder(
      builder: (context) => Container(
        height: 81,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        child: TextButton.icon(
          onPressed: () async {
            await SupabaseService().signOut();
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          },
          icon: const Icon(Icons.logout, size: 16, color: Color(0xFFDC2626)),
          label: const Text(
            'Выход из аккаунта',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFFDC2626),
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
