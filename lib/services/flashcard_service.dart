import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  final AuthService _authService = AuthService();
  final List<FlashcardSet> _sets = [];
  List<FlashcardSet> get sets => List.unmodifiable(_sets);

  // === KEYS ===
  Future<String> get _keyData async => 'flashcard_data_${await _getCurrentUserId()}';
  Future<String> get _keyLastStudy async => 'last_study_date_${await _getCurrentUserId()}';
  Future<String> get _keyStreak async => 'study_streak_${await _getCurrentUserId()}';
  Future<String> get _keyTotalStudied async => 'total_studied_today_${await _getCurrentUserId()}';
  Future<String> get _keyUserName async => 'user_name_${await _getCurrentUserId()}';
  Future<String> get _keyDailyGoal async => 'daily_goal_${await _getCurrentUserId()}';
  Future<String> get _keyDarkMode async => 'dark_mode_${await _getCurrentUserId()}';

  // Lấy user ID hiện tại
  Future<String> _getCurrentUserId() async {
    final currentUser = await _authService.getCurrentUser();
    return currentUser?.id ?? 'anonymous';
  }

  // === TẢI DỮ LIỆU ===
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _keyData;
    final data = prefs.getString(key);

    _sets.clear();

    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _sets.addAll(jsonList.map((e) => FlashcardSet.fromJson(e)).toList());
      } catch (e) {
        // THAY THẾ PRINT BẰNG debugPrint
        debugPrint('Lỗi tải dữ liệu: $e');
        await _addSampleData();
        await _saveData();
      }
    } else {
      await _addSampleData();
      await _saveData();
    }
  }

  // === LƯU DỮ LIỆU ===
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _keyData;
    final jsonList = _sets.map((set) => set.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  // === GHI NHẬN HỌC ===
  Future<void> recordStudySession(int cardCount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastStudyKey = await _keyLastStudy;
    final streakKey = await _keyStreak;
    final totalStudiedKey = await _keyTotalStudied;

    final lastDate = prefs.getString(lastStudyKey) ?? '';

    int streak = prefs.getInt(streakKey) ?? 0;
    int todayStudied = prefs.getInt(totalStudiedKey) ?? 0;

    if (lastDate == today) {
      todayStudied += cardCount;
    } else {
      todayStudied = cardCount;
      if (lastDate.isNotEmpty) {
        final last = DateTime.parse(lastDate);
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    await prefs.setString(lastStudyKey, today);
    await prefs.setInt(streakKey, streak);
    await prefs.setInt(totalStudiedKey, todayStudied);
  }

  // === PROFILE ===
  Future<String> getUserName() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      return currentUser.username;
    }

    final prefs = await SharedPreferences.getInstance();
    final userNameKey = await _keyUserName;
    return prefs.getString(userNameKey) ?? "Người dùng"; // ĐÃ SỬA TYP0
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userNameKey = await _keyUserName;
    await prefs.setString(userNameKey, name);
  }

  Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoalKey = await _keyDailyGoal;
    return prefs.getInt(dailyGoalKey) ?? 20;
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoalKey = await _keyDailyGoal;
    await prefs.setInt(dailyGoalKey, goal);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final darkModeKey = await _keyDarkMode;
    return prefs.getBool(darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final darkModeKey = await _keyDarkMode;
    await prefs.setBool(darkModeKey, value);
  }

  // === XÓA DỮ LIỆU ===
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(await _keyData);
    await prefs.remove(await _keyLastStudy);
    await prefs.remove(await _keyStreak);
    await prefs.remove(await _keyTotalStudied);
    await prefs.remove(await _keyUserName);
    await prefs.remove(await _keyDailyGoal);
    await prefs.remove(await _keyDarkMode);

    _sets.clear();
    await _addSampleData();
    await _saveData();
  }

  Future<void> clearAllUsersData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _sets.clear();
    await _addSampleData();
    await _saveData();
  }

  // === THỐNG KÊ ===
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final totalSets = _sets.length;
    final totalCards = _sets.fold(0, (sum, set) => sum + set.cards.length);
    final totalStudiedKey = await _keyTotalStudied;
    final streakKey = await _keyStreak;

    final todayStudied = prefs.getInt(totalStudiedKey) ?? 0;
    final streak = prefs.getInt(streakKey) ?? 0;
    final goal = await getDailyGoal();
    final progress = goal > 0 ? (todayStudied / goal * 100).clamp(0, 100) : 0;

    return {
      'totalSets': totalSets,
      'totalCards': totalCards,
      'todayStudied': todayStudied,
      'streak': streak,
      'dailyGoal': goal,
      'progress': progress.toStringAsFixed(0),
    };
  }

  // === DỮ LIỆU MẪU ===
  Future<void> _addSampleData() async {
    final userId = await _getCurrentUserId();
    // Chỉ thêm dữ liệu mẫu cho user chưa đăng nhập
    if (userId == 'anonymous') {
      final id1 = _generateId();
      final id2 = _generateId();
      _sets.addAll([
        FlashcardSet(
          id: id1,
          userId: userId, // THÊM USER ID
          title: "Động vật",
          cards: [
            Flashcard(term: "cat", meaning: "con mèo", note: "VD: this is my cat"),
            Flashcard(term: "dog", meaning: "con chó", note: "VD: this is my dog"),
          ],
        ),
        FlashcardSet(
          id: id2,
          userId: userId, // THÊM USER ID
          title: "Trái cây",
          cards: [
            Flashcard(term: "Apple", meaning: "Quả táo", note: ""),
            Flashcard(term: "Banana", meaning: "Quả chuối", note: ""),
          ],
        ),
      ]);
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  // === CRUD OPERATIONS - ĐÃ SỬA LỖI USERID ===
  Future<void> addSet(String title) async {
    final userId = await _getCurrentUserId(); // LẤY USER ID
    _sets.add(FlashcardSet(
        id: _generateId(),
        userId: userId, // THÊM USER ID
        title: title,
        cards: []
    ));
    await _saveData();
  }

  Future<void> updateSet(String id, String newTitle) async {
    final index = _sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final userId = await _getCurrentUserId(); // LẤY USER ID
      _sets[index] = FlashcardSet(
          id: id,
          userId: userId, // THÊM USER ID
          title: newTitle,
          cards: _sets[index].cards
      );
      await _saveData();
    }
  }

  Future<void> deleteSet(String id) async {
    _sets.removeWhere((s) => s.id == id);
    await _saveData();
  }

  Future<void> addCard(String setId, Flashcard card) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    set.cards.add(card);
    await _saveData();
  }

  Future<void> updateCard(String setId, String oldTerm, Flashcard newCard) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    final index = set.cards.indexWhere((c) => c.term == oldTerm);
    if (index != -1) {
      set.cards[index] = newCard;
      await _saveData();
    }
  }

  Future<void> deleteCard(String setId, String term) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    final card = set.cards.firstWhere((c) => c.term == term);
    if (card.imagePath != null) {
      final file = File(card.imagePath!);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    set.cards.removeWhere((c) => c.term == term);
    await _saveData();
  }

  // Chuyển đổi dữ liệu khi user đăng nhập/đăng xuất
  Future<void> switchUserData() async {
    await loadData();
  }
}