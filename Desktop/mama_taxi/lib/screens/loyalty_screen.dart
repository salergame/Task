import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/loyalty_model.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  LoyaltyModel? _loyaltyData;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loyaltyData = await _supabaseService.getUserLoyalty();
      setState(() {
        _loyaltyData = loyaltyData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных лояльности: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildPointsCard(),
                    _buildLoyaltyLevels(),
                    _buildHowToEarnPoints(),
                    _buildPointsHistory(),
                    _buildFooter(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.8),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/loyalty/arrow_back.svg',
                width: 17.5,
                height: 20,
              ),
            ),
            const SizedBox(width: 15.5),
            const Text(
              'Программа лояльности',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    if (_loyaltyData == null) {
      return const SizedBox.shrink();
    }

    final currentLevel = _loyaltyData!.getCurrentLevel();
    final nextLevel = _loyaltyData!.getNextLevel();
    final progress = _loyaltyData!.getProgressToNextLevel();
    final pointsToNextLevel = _loyaltyData!.getPointsToNextLevel();

    // Ширина прогресс-бара (максимум 310)
    final progressWidth = 310 * progress;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFF654AA), Color(0xFF56CDC4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Opacity(
                    opacity: 0.1,
                    child: SvgPicture.asset(
                      'assets/icons/loyalty/coin.svg',
                      width: 96,
                      height: 96,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Текущий баланс баллов',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${_loyaltyData!.points}',
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Stack(
                        children: [
                          Container(
                            width: 310,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          Container(
                            width: progressWidth,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Text(
                        nextLevel.level == currentLevel.level
                            ? 'Вы достигли максимального уровня!'
                            : 'Еще $pointsToNextLevel баллов – и вы получите ${nextLevel.reward} ${nextLevel.rewardDescription}!',
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: LoyaltyLevels.levels.map((level) {
              final isCurrentLevel = level.level == currentLevel.level;
              return _buildLoyaltyLevelCard(
                icon: level.level == 0
                    ? 'assets/icons/loyalty/coin.svg'
                    : level.level == 1
                        ? 'assets/icons/loyalty/coin.svg'
                        : level.level == 2
                            ? 'assets/icons/loyalty/gift.svg'
                            : 'assets/icons/loyalty/car.svg',
                points: '${level.requiredPoints}',
                reward: level.rewardDescription,
                rewardValue: level.reward,
                isMultiline: level.level == 3,
                isActive: isCurrentLevel,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyLevelCard({
    required String icon,
    required String points,
    required String reward,
    String? rewardValue,
    bool isMultiline = false,
    bool isActive = false,
  }) {
    return Container(
      width: 111,
      height: 134,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981) : const Color(0xFFF3F4F6),
          width: isActive ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            color: isActive ? const Color(0xFF10B981) : Colors.black,
          ),
          const SizedBox(height: 2),
          Text(
            points,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 12,
              color: isActive ? const Color(0xFF10B981) : Colors.black,
            ),
          ),
          Text(
            'баллов',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 12,
              color: isActive ? const Color(0xFF10B981) : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            reward,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 12,
              color:
                  isActive ? const Color(0xFF10B981) : const Color(0xFF4B5563),
            ),
          ),
          if (rewardValue != null)
            Text(
              rewardValue,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF10B981)
                    : const Color(0xFF4B5563),
              ),
            ),
          if (isMultiline && rewardValue == null) const SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _buildHowToEarnPoints() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Как зарабатывать баллы?',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnPointsItem(
            backgroundColor: const Color(0xFFDBEAFE),
            icon: 'assets/icons/loyalty/car.svg',
            title: '1 поездка = 10 баллов',
            subtitle: 'За каждую завершенную поездку',
          ),
          const SizedBox(height: 16),
          _buildEarnPointsItem(
            backgroundColor: const Color(0xFFEDE9FE),
            icon: 'assets/icons/loyalty/gift.svg',
            title: 'Пригласите друга – 20 баллов',
            subtitle: 'За каждого приглашенного друга',
          ),
          const SizedBox(height: 16),
          _buildEarnPointsItem(
            backgroundColor: const Color(0xFFD1FAE5),
            icon: 'assets/icons/loyalty/clock.svg',
            title: 'Предварительный заказ – 5 баллов',
            subtitle: 'За предварительное бронирование',
          ),
        ],
      ),
    );
  }

  Widget _buildEarnPointsItem({
    required Color backgroundColor,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Center(
            child: SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsHistory() {
    if (_loyaltyData == null || _loyaltyData!.history.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 27, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История баллов',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 19),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: const Center(
                child: Text(
                  'История пуста',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 27, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'История баллов',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 19),
          Column(
            children: _loyaltyData!.history.map((historyItem) {
              final dateFormat = DateFormat('dd MMMM, HH:mm', 'ru_RU');
              final formattedDate = dateFormat.format(historyItem.date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          historyItem.type == PointsType.earned
                              ? 'assets/icons/loyalty/plus.svg'
                              : 'assets/icons/loyalty/minus.svg',
                          width: 16,
                          height: 16,
                          color: historyItem.type == PointsType.earned
                              ? const Color(0xFF10B981)
                              : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              historyItem.description,
                              style: const TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 23),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      historyItem.type == PointsType.earned
                          ? '+${historyItem.points}'
                          : '-${historyItem.points}',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 16,
                        color: historyItem.type == PointsType.earned
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_loyaltyData == null) {
      return const SizedBox.shrink();
    }

    final currentLevel = _loyaltyData!.getCurrentLevel();
    final nextLevel = _loyaltyData!.getNextLevel();
    final pointsToNextLevel = _loyaltyData!.getPointsToNextLevel();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      child: Column(
        children: [
          Text(
            'Вы накопили ${_loyaltyData!.points} баллов!',
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            nextLevel.level == currentLevel.level
                ? 'Вы достигли максимального уровня!'
                : 'Еще $pointsToNextLevel баллов, и у вас будет ${nextLevel.reward} ${nextLevel.rewardDescription}!',
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 47),
          GestureDetector(
            onTap: () {
              // Здесь можно добавить логику для заработка баллов
              Navigator.of(context).pop(); // Возвращаемся на экран карты
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF153AD), Color(0xFF61C5C2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Заработать больше баллов',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  SvgPicture.asset(
                    'assets/icons/loyalty/arrow_forward.svg',
                    width: 18,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyLevels() {
    return const SizedBox.shrink();
  }
}
