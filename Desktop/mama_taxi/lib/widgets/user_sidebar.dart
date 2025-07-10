import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/supabase_service.dart';
import 'add_child_modal.dart';
import '../screens/user_profile_screen.dart';
import '../screens/loyalty_screen.dart';
import '../screens/support_screen.dart';
import '../models/loyalty_model.dart';

class UserSidebar extends StatefulWidget {
  final String userName;
  final String userRating;
  final String? userImageUrl;
  final VoidCallback onClose;

  const UserSidebar({
    super.key,
    required this.userName,
    this.userRating = '0.0',
    this.userImageUrl,
    required this.onClose,
  });

  @override
  State<UserSidebar> createState() => _UserSidebarState();
}

class _UserSidebarState extends State<UserSidebar> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Child> _children = [];
  bool _isLoading = true;
  bool _isLoadingLoyalty = true;
  LoyaltyModel? _loyaltyData;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _loadLoyaltyData();
    _loadUserProfile();
  }

  // Загрузка списка детей из Supabase
  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final children = await _supabaseService.getChildren();
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки списка детей: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Загрузка данных программы лояльности
  Future<void> _loadLoyaltyData() async {
    setState(() {
      _isLoadingLoyalty = true;
    });

    try {
      final loyaltyData = await _supabaseService.getUserLoyalty();
      setState(() {
        _loyaltyData = loyaltyData;
        _isLoadingLoyalty = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных лояльности: $e');
      setState(() {
        _isLoadingLoyalty = false;
      });
    }
  }

  // Загрузка данных профиля пользователя
  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _supabaseService.getCurrentUser();
      if (userProfile != null && mounted) {
        setState(() {
          // Если userProfile содержит данные, обновляем их в виджете
          // Обычно мы бы обновляли локальные переменные, но здесь мы можем
          // просто использовать данные из widget, так как они передаются при создании
          debugPrint('Профиль пользователя загружен: ${userProfile.fullName}');
          debugPrint('Аватар пользователя: ${userProfile.avatarUrl}');
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля пользователя: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Профиль пользователя
          _buildUserProfile(),

          // Секция "Мои дети"
          _buildChildrenSection(),

          // Навигационные пункты
          _buildNavItems(),

          const Spacer(),

          // Кнопка выхода
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // Профиль пользователя
  Widget _buildUserProfile() {
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
              // Аватар пользователя
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  ).then((_) {
                    // Обновляем данные при возврате с экрана профиля
                    _loadUserProfile();
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: widget.userImageUrl != null &&
                          widget.userImageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.network(
                            widget.userImageUrl!,
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Ошибка загрузки аватарки: $error');
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
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
                        widget.userRating,
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
                        _supabaseService.currentUser?.email ??
                            "Email не указан",
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
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

  // Секция "Мои дети"
  Widget _buildChildrenSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Мои дети',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),

          // Список детей или индикатор загрузки
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_children.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Нет добавленных детей',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 100, // Фиксированная высота
              child: ListView.builder(
                itemCount: _children.length,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final child = _children[index];
                  return Container(
                    height: 50, // Уменьшенная высота элемента
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Аватар ребенка
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: (child.photoFile != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    child.photoFile!,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  ),
                                )
                              : (child.photoUrl != null &&
                                      child.photoUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        child.photoUrl!,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          debugPrint(
                                              'Ошибка загрузки фото ребенка: $error');
                                          return Center(
                                            child: Text(
                                              child.name.isNotEmpty
                                                  ? child.name[0]
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        child.name.isNotEmpty
                                            ? child.name[0]
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            '${child.name}, ${child.age} лет',
                            style: const TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          TextButton.icon(
            onPressed: _showAddChildModal,
            icon: const Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
            label: const Text(
              'Добавить ребенка',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2563EB),
              ),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Открыть модальное окно добавления ребенка
  void _showAddChildModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChildModal(
          onAdd: (Child child) async {
            // Добавляем ребенка в Supabase
            final childId = await _supabaseService.addChild(child);
            if (childId != null) {
              // Обновляем список детей
              _loadChildren();
            }
          },
        );
      },
    );
  }

  // Навигационные пункты
  Widget _buildNavItems() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          _buildNavItem(
            'Мои поездки',
            Icons.directions_car_outlined,
            isActive: true,
          ),
          _buildNavItem('Оплата и счета', Icons.credit_card, onTap: () {
            Navigator.pushNamed(context, '/payment');
          }),
          _buildLoyaltyItem(
            'Программа лояльности',
            Icons.card_giftcard,
            _isLoadingLoyalty ? '...' : '${_loyaltyData?.points ?? 0}',
            'баллов',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoyaltyScreen(),
                ),
              );
            },
          ),
          _buildNavItem('Настройки', Icons.settings_outlined, onTap: () {
            Navigator.pushNamed(context, '/settings');
          }),
          _buildNavItem('Поддержка и помощь', Icons.help_outline, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportScreen(),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Навигационный элемент
  Widget _buildNavItem(String title, IconData icon,
      {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 288,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isActive ? const Color(0xFF1D4ED8) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Элемент программы лояльности с бейджем
  Widget _buildLoyaltyItem(
      String title, IconData icon, String points, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 288,
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4),
              ),
              width: 70,
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    points,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF047857),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // Кнопка выхода
  Widget _buildLogoutButton() {
    return Container(
      height: 81,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      child: TextButton.icon(
        onPressed: () async {
          await _supabaseService.signOut();
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
    );
  }
}
