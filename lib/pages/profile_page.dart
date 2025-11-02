// pages/profile_page.dart - TRANG CÁ NHÂN HOÀN CHỈNH
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../services/auth_service.dart';
import '../../main.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlashcardService service = FlashcardService();
  final AuthService authService = AuthService();
  String userName = "Người dùng";
  int dailyGoal = 20;
  bool darkMode = false;
  Map<String, dynamic> stats = {};
  String userEmail = "";
  String joinDate = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await service.getUserName();
      final goal = await service.getDailyGoal();
      final isDark = await service.isDarkMode();
      final data = await service.getStats();

      // Load thông tin user từ auth
      final currentUser = await authService.getCurrentUser();

      if (mounted) {
        setState(() {
          userName = name;
          dailyGoal = goal;
          darkMode = isDark;
          stats = data;
          userEmail = currentUser?.email ?? "Chưa đăng nhập";
          joinDate = currentUser?.createdAt != null
              ? "${currentUser!.createdAt.day}/${currentUser.createdAt.month}/${currentUser.createdAt.year}"
              : "---";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Lỗi tải profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = double.tryParse(stats['progress']?.toString() ?? '0') ?? 0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLoggedIn = userEmail != "Chưa đăng nhập";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cá nhân"),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _showLogoutDialog,
              tooltip: "Đăng xuất",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // THÔNG TIN CÁ NHÂN
            _buildProfileCard(isLoggedIn),
            const SizedBox(height: 20),

            // Thông báo nếu chưa đăng nhập
            if (!isLoggedIn) _buildLoginPrompt(),

            // MỤC TIÊU VÀ TIẾN ĐỘ
            _buildGoalCard(),
            _buildProgressCard(progress),
            const SizedBox(height: 20),

            // CÀI ĐẶT
            _buildSettingsSection(themeProvider, isLoggedIn),
            const SizedBox(height: 20),

            _buildAppVersion(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isLoggedIn) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: isLoggedIn ? Colors.purple : Colors.grey,
              child: Icon(
                  isLoggedIn ? Icons.person : Icons.person_outline,
                  size: 60,
                  color: Colors.white
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Hiển thị email và ngày tham gia
            if (isLoggedIn) ...[
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "Tham gia: $joinDate",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                "Chưa đăng nhập",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  "${stats['streak'] ?? 0} ngày liên tục",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Thông báo đăng nhập
  Widget _buildLoginPrompt() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Đăng nhập để đồng bộ dữ liệu",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Dữ liệu hiện tại chỉ được lưu cục bộ trên thiết bị này",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag, color: Colors.green),
        title: const Text("Mục tiêu hàng ngày"),
        subtitle: Text("$dailyGoal thẻ/ngày"),
        trailing: const Icon(Icons.edit),
        onTap: _showGoalDialog,
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.show_chart, color: Colors.blue),
        title: const Text("Tiến độ hôm nay"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${stats['todayStudied'] ?? 0} / $dailyGoal thẻ"),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeProvider themeProvider, bool isLoggedIn) {
    return Column(
      children: [
        _buildSettingItem(
          Icons.dark_mode,
          "Chế độ tối",
          Switch(
            value: darkMode,
            onChanged: (value) => _toggleDarkMode(value, themeProvider),
          ),
        ),
        // ĐÃ BỎ: Mục "Đổi tên"
        if (isLoggedIn)
          _buildSettingItem(
            Icons.logout,
            "Đăng xuất",
            null,
            onTap: _showLogoutDialog,
            color: Colors.orange,
          ),
        // ĐÃ BỎ: Mục "Xóa tất cả dữ liệu"
      ],
    );
  }

  Widget _buildSettingItem(
      IconData icon,
      String title,
      Widget? trailing, {
        VoidCallback? onTap,
        Color? color,
      }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.purple),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppVersion() {
    return Text(
      "Phiên bản 1.0.0",
      style: TextStyle(color: Colors.grey[600]),
    );
  }

  void _toggleDarkMode(bool value, ThemeProvider themeProvider) {
    setState(() {
      darkMode = value;
    });

    themeProvider.toggleTheme(value);
    service.setDarkMode(value);
  }

  void _showGoalDialog() {
    final TextEditingController controller = TextEditingController(text: dailyGoal.toString());
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (_) => AlertDialog(
        title: const Text("Mục tiêu hàng ngày"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Số thẻ/ngày"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(currentContext),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              final int? goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                await service.setDailyGoal(goal);
                if (mounted) {
                  await _loadProfile();
                  Navigator.pop(currentContext);
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Hàm đăng xuất
  void _showLogoutDialog() {
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(currentContext),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(currentContext);
              await authService.logout();
              await service.switchUserData();

              // Sử dụng ThemeProvider để logout
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.logout();

              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text("Đã đăng xuất!")),
              );
            },
            child: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}