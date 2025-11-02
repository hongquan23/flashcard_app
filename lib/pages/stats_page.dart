// pages/stats_page.dart - ĐÃ SỬA HOÀN CHỈNH
import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final service = FlashcardService();
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await service.getStats();
    setState(() {
      stats = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = stats['totalCards'] as int;
    final studied = stats['todayStudied'] as int;
    final remaining = total - studied;

    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê")),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard("Tổng bộ", "${stats['totalSets']}", Icons.folder, Colors.blue),
              _buildStatCard("Tổng thẻ", "${stats['totalCards']}", Icons.credit_card, Colors.purple),
              _buildStatCard("Học hôm nay", "$studied thẻ", Icons.today, Colors.green),
              _buildStatCard("Tỷ lệ nhớ", "${stats['rememberRate']}%", Icons.trending_up, Colors.orange),
              _buildStatCard("Streak", "${stats['streak']} ngày", Icons.local_fire_department, Colors.red), // SỬA: local_fire_department
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Tiến độ hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: studied.toDouble(),
                                color: Colors.green,
                                title: '$studied',
                                radius: 60,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              PieChartSectionData(
                                value: remaining.toDouble(),
                                color: Colors.grey.shade300,
                                title: '$remaining',
                                radius: 50,
                              ),
                            ],
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SỬA: CHỈ 4 THAM SỐ
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}