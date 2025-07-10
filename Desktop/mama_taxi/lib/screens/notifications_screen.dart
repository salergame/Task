import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  // Настройки уведомлений
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = true;
  bool _promotionalEnabled = false;
  bool _tripUpdatesEnabled = true;
  bool _paymentUpdatesEnabled = true;
  bool _systemUpdatesEnabled = true;

  late SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _supabaseService = Provider.of<SupabaseService>(context, listen: false);
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _supabaseService.getNotificationSettings();
      if (settings != null) {
        setState(() {
          _pushEnabled = settings['push_enabled'] ?? true;
          _emailEnabled = settings['email_enabled'] ?? false;
          _smsEnabled = settings['sms_enabled'] ?? true;
          _promotionalEnabled = settings['promotional_enabled'] ?? false;
          _tripUpdatesEnabled = settings['trip_updates_enabled'] ?? true;
          _paymentUpdatesEnabled = settings['payment_updates_enabled'] ?? true;
          _systemUpdatesEnabled = settings['system_updates_enabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки настроек уведомлений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить настройки уведомлений'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.saveNotificationSettings(
        pushEnabled: _pushEnabled,
        emailEnabled: _emailEnabled,
        smsEnabled: _smsEnabled,
        promotionalEnabled: _promotionalEnabled,
        tripUpdatesEnabled: _tripUpdatesEnabled,
        paymentUpdatesEnabled: _paymentUpdatesEnabled,
        systemUpdatesEnabled: _systemUpdatesEnabled,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки уведомлений сохранены'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Ошибка сохранения настроек уведомлений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить настройки уведомлений'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNotificationSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/arrow_back.svg',
                width: 12.5,
                height: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Уведомления',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Каналы уведомлений'),
          _buildChannelSettings(),
          const SizedBox(height: 16),
          _buildSectionHeader('Типы уведомлений'),
          _buildNotificationTypeSettings(),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildChannelSettings() {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          _buildSwitchItem(
            title: 'Push-уведомления',
            subtitle: 'Уведомления в приложении',
            value: _pushEnabled,
            onChanged: (value) {
              setState(() {
                _pushEnabled = value;
              });
            },
          ),
          _buildSwitchItem(
            title: 'Email-уведомления',
            subtitle: 'Уведомления на электронную почту',
            value: _emailEnabled,
            onChanged: (value) {
              setState(() {
                _emailEnabled = value;
              });
            },
          ),
          _buildSwitchItem(
            title: 'SMS-уведомления',
            subtitle: 'Уведомления по SMS',
            value: _smsEnabled,
            onChanged: (value) {
              setState(() {
                _smsEnabled = value;
              });
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeSettings() {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          _buildSwitchItem(
            title: 'Рекламные предложения',
            subtitle: 'Акции, скидки и специальные предложения',
            value: _promotionalEnabled,
            onChanged: (value) {
              setState(() {
                _promotionalEnabled = value;
              });
            },
          ),
          _buildSwitchItem(
            title: 'Обновления поездок',
            subtitle: 'Статус заказа, информация о водителе',
            value: _tripUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _tripUpdatesEnabled = value;
              });
            },
          ),
          _buildSwitchItem(
            title: 'Платежи и транзакции',
            subtitle: 'Информация о платежах и списаниях',
            value: _paymentUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _paymentUpdatesEnabled = value;
              });
            },
          ),
          _buildSwitchItem(
            title: 'Системные уведомления',
            subtitle: 'Обновления приложения и важные сообщения',
            value: _systemUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _systemUpdatesEnabled = value;
              });
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.lighterGrey,
                  width: 1,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.secondary,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.lightGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveNotificationSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Сохранить настройки',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
