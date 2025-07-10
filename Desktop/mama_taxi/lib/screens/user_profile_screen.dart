import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../widgets/add_child_modal.dart';
import 'edit_profile_screen.dart';
import 'loyalty_screen.dart';
import 'support_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  UserModel? _userProfile;
  bool _isLoading = true;
  List<Child> _children = [];
  bool _isLoadingChildren = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChildren();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _supabaseService.getCurrentUser();
      setState(() {
        _userProfile = user;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChildren() async {
    try {
      final children = await _supabaseService.getChildren();
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки списка детей: $e');
      setState(() {
        _isLoadingChildren = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Личный кабинет',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Профиль пользователя
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Аватар пользователя
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: _userProfile?.avatarUrl != null &&
                                  _userProfile!.avatarUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.network(
                                    _userProfile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'Ошибка загрузки аватарки в профиле: $error');
                                      return const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
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
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?.fullName ?? 'Имя не указано',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userProfile?.phone ?? 'Телефон не указан',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            // Редактирование профиля
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  userProfile: _userProfile,
                                ),
                              ),
                            ).then((result) {
                              // Если профиль был обновлен, перезагружаем данные
                              if (result == true) {
                                _loadUserProfile();
                              }
                            });
                          },
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Раздел действий
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionItem(
                          'Новая поездка',
                          Icons.directions_car,
                          const Color(0xFFDBEAFE),
                          () {
                            Navigator.of(
                              context,
                            ).pop(); // Возврат на экран карты
                          },
                        ),
                        _buildActionItem(
                          'Расписание',
                          Icons.calendar_today,
                          const Color(0xFFEDE9FE),
                          () {
                            // Открыть расписание
                            Navigator.of(context).pushNamed('/user/schedule');
                          },
                        ),
                        _buildActionItem(
                          'Оплата',
                          Icons.payment,
                          const Color(0xFFD1FAE5),
                          () {
                            // Открыть оплату
                          },
                        ),
                        _buildActionItem(
                          'Программа\nлояльности',
                          Icons.card_giftcard,
                          const Color(0xFFD1FAE5),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoyaltyScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Раздел детей
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Дети',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoadingChildren
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _showAddChildModal();
                                      },
                                      child: _buildChildAddItem(),
                                    ),
                                    ..._children.map(
                                      (child) => _buildChildItem(
                                        child.name,
                                        child.photoUrl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),

                  // Раздел недавних поездок
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Недавние поездки',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRideItem(
                          'Школа → Дом',
                          '15 марта, 14:30',
                          '450₽',
                        ),
                        const SizedBox(height: 16),
                        _buildRideItem(
                          'Дом → Бассейн',
                          '14 марта, 10:00',
                          '350₽',
                        ),
                      ],
                    ),
                  ),

                  // Добавление пункта "Поддержка" в меню
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text(
                      'Поддержка',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
    );
  }

  Widget _buildActionItem(
    String title,
    IconData icon,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Icon(icon, size: 24, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChildAddItem() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Icon(Icons.add, size: 24, color: Colors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавить',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(String name, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(9999),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Ошибка загрузки фото ребенка: $error');
                        return Center(
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
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
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideItem(String route, String time, String price) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: const Icon(
            Icons.directions_car,
            size: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          price,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF059669),
          ),
        ),
      ],
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
}
