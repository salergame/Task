import 'package:flutter/foundation.dart';

class LoyaltyModel {
  final String userId;
  final int points;
  final List<PointsHistory> history;
  final int level;

  LoyaltyModel({
    required this.userId,
    required this.points,
    required this.history,
    required this.level,
  });

  // Получить текущий уровень и максимальное количество баллов для него
  LoyaltyLevel getCurrentLevel() {
    return LoyaltyLevels.getLevelByPoints(points);
  }

  // Получить следующий уровень
  LoyaltyLevel getNextLevel() {
    return LoyaltyLevels.getNextLevel(level);
  }

  // Получить прогресс до следующего уровня (от 0 до 1)
  double getProgressToNextLevel() {
    final currentLevel = getCurrentLevel();
    final nextLevel = getNextLevel();

    if (nextLevel.requiredPoints == currentLevel.requiredPoints) {
      return 1.0; // Максимальный уровень
    }

    final pointsForNextLevel =
        nextLevel.requiredPoints - currentLevel.requiredPoints;
    final earnedPoints = points - currentLevel.requiredPoints;

    return earnedPoints / pointsForNextLevel;
  }

  // Количество баллов, оставшихся до следующего уровня
  int getPointsToNextLevel() {
    final nextLevel = getNextLevel();
    return nextLevel.requiredPoints - points;
  }

  // Создать модель из данных Supabase
  factory LoyaltyModel.fromMap(
      Map<String, dynamic> map, List<Map<String, dynamic>> historyData) {
    return LoyaltyModel(
      userId: map['user_id'] ?? '',
      points: map['points'] ?? 0,
      level: map['level'] ?? 0,
      history: historyData.map((item) => PointsHistory.fromMap(item)).toList(),
    );
  }

  // Пустая модель для нового пользователя
  factory LoyaltyModel.empty(String userId) {
    return LoyaltyModel(
      userId: userId,
      points: 0,
      level: 0,
      history: [],
    );
  }
}

class PointsHistory {
  final String id;
  final String userId;
  final int points;
  final String description;
  final DateTime date;
  final PointsType type;

  PointsHistory({
    required this.id,
    required this.userId,
    required this.points,
    required this.description,
    required this.date,
    required this.type,
  });

  factory PointsHistory.fromMap(Map<String, dynamic> map) {
    return PointsHistory(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      points: map['points'] ?? 0,
      description: map['description'] ?? '',
      date:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      type: _parsePointsType(map['type']),
    );
  }

  static PointsType _parsePointsType(String? type) {
    switch (type) {
      case 'earned':
        return PointsType.earned;
      case 'spent':
        return PointsType.spent;
      default:
        return PointsType.earned;
    }
  }
}

enum PointsType {
  earned,
  spent,
}

class LoyaltyLevel {
  final int level;
  final int requiredPoints;
  final String name;
  final String reward;
  final String rewardDescription;

  LoyaltyLevel({
    required this.level,
    required this.requiredPoints,
    required this.name,
    required this.reward,
    required this.rewardDescription,
  });
}

class LoyaltyLevels {
  static final List<LoyaltyLevel> levels = [
    LoyaltyLevel(
      level: 0,
      requiredPoints: 0,
      name: 'Начальный',
      reward: '0%',
      rewardDescription: 'скидка',
    ),
    LoyaltyLevel(
      level: 1,
      requiredPoints: 5000,
      name: 'Бронзовый',
      reward: '10%',
      rewardDescription: 'скидка',
    ),
    LoyaltyLevel(
      level: 2,
      requiredPoints: 10000,
      name: 'Серебряный',
      reward: '15%',
      rewardDescription: 'скидка',
    ),
    LoyaltyLevel(
      level: 3,
      requiredPoints: 20000,
      name: 'Золотой',
      reward: '1',
      rewardDescription: 'бесплатная\nпоездка',
    ),
  ];

  static LoyaltyLevel getLevelByPoints(int points) {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].requiredPoints) {
        return levels[i];
      }
    }
    return levels[0];
  }

  static LoyaltyLevel getNextLevel(int currentLevel) {
    if (currentLevel >= levels.length - 1) {
      return levels[levels.length - 1];
    }
    return levels[currentLevel + 1];
  }
}
