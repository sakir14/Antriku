import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/api_service.dart';

class MerchantAnalyticsTab extends StatefulWidget {
  const MerchantAnalyticsTab({super.key});

  @override
  State<MerchantAnalyticsTab> createState() => _MerchantAnalyticsTabState();
}

class _MerchantAnalyticsTabState extends State<MerchantAnalyticsTab> {
  final ApiService _apiService = ApiService();

  // ==========================================
  // HELPER: BUILD KEPALA APPBAR 
  // ==========================================
  Widget _buildReusableAppBar({required String title, IconData? icon}) {
    return SliverAppBar(
      expandedHeight: 140, 
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF059669), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 15),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.amber, size: 18), const SizedBox(width: 8)],
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
          child: Stack(
            children: [
              Positioned(right: -20, top: -20, child: Icon(Icons.circle, size: 100, color: Colors.white.withAlpha(25))),
              Positioned(left: -30, bottom: -30, child: Icon(Icons.circle, size: 150, color: Colors.white.withAlpha(25))),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEET: ULASAN PELANGGAN
  // ==========================================
  void _showReviewsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 30),
                  SizedBox(width: 15),
                  Text('Ulasan Pelanggan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _apiService.getMerchantReviews(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Toko Anda belum memiliki ulasan.', style: TextStyle(color: Colors.grey)));
                    }
                    final reviews = snapshot.data!;
                    return ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final r = reviews[index];
                        final rating = r['rating'] as int;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundColor: Colors.amber.withAlpha(20), child: Text('$rating', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                          title: Text(r['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < rating ? Colors.amber : Colors.grey.shade300))),
                              const SizedBox(height: 5),
                              if (r['comment'] != null && r['comment'].toString().trim().isNotEmpty)
                                Text('"${r['comment']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(r['updated_at'].toString().substring(0, 10), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HELPER: MINI STAT (BAWAH GRAFIK)
  // ==========================================
  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _apiService.getMerchantStatistics(),
      builder: (context, snapshot) {
        Map<String, dynamic> stats = {
          'completed': 0, 'skipped': 0, 'cancelled': 0, 'avg_rating': 0.0, 'busy_hours': {}
        };

        if (snapshot.hasData && snapshot.data?['success'] == true) {
          stats = snapshot.data?['data'];
        }

        Map<dynamic, dynamic> busyHoursRaw = stats['busy_hours'] != null ? Map<dynamic, dynamic>.from(stats['busy_hours']) : {};
        List<BarChartGroupData> barGroups = [];
        double maxY = 5.0; 

        busyHoursRaw.forEach((hourStr, countDyn) {
          int hour = int.parse(hourStr.toString());
          double count = double.parse(countDyn.toString());
          if (count > maxY) maxY = count;

          barGroups.add(
            BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: count,
                  color: const Color(0xFF059669),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY + 2, color: Colors.grey.shade200),
                ),
              ],
            ),
          );
        });

        return CustomScrollView(
          slivers: [
            _buildReusableAppBar(title: 'Analitik Toko', icon: Icons.analytics),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grafik Jam Sibuk (Hari Ini)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Icon(Icons.bar_chart, color: Color(0xFF059669)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            height: 200, 
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY + 2,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.black87,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem('${rod.toY.toInt()} Antrean\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), children: [TextSpan(text: 'Pukul ${group.x}:00', style: const TextStyle(color: Colors.yellow, fontSize: 12))]);
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() % 2 != 0) return const SizedBox.shrink();
                                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${value.toInt()}:00', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)));
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: barGroups,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMiniStat('Selesai', stats['completed'], Colors.green),
                              _buildMiniStat('Dilewati', stats['skipped'], Colors.orange),
                              _buildMiniStat('Batal', stats['cancelled'], Colors.red),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: _showReviewsBottomSheet, 
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.orange.withAlpha(50), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 32),
                                SizedBox(width: 15),
                                Text('Baca Ulasan Pelanggan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        );
      }
    );
  }
}