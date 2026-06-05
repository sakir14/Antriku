import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../utils/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart'; // IMPORT SHIMMER

class MerchantHistoryTab extends StatefulWidget {
  final List<dynamic> historyData;
  final bool isLoading; // PARAMETER BARU UNTUK SKELETON
  final VoidCallback onRefreshNeeded;

  const MerchantHistoryTab({
    super.key,
    required this.historyData,
    required this.isLoading, // TAMBAHKAN INI
    required this.onRefreshNeeded,
  });

  @override
  State<MerchantHistoryTab> createState() => _MerchantHistoryTabState();
}

class _MerchantHistoryTabState extends State<MerchantHistoryTab> {
  final ApiService _apiService = ApiService();
  bool _isSelectionMode = false;
  List<int> _selectedHistoryIds = [];

  Widget _buildReusableAppBar({required String title, IconData? icon, List<Widget>? actions}) {
    return SliverAppBar(
      expandedHeight: 140, pinned: true, elevation: 0, backgroundColor: const Color(0xFF059669), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))), actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 15),
        title: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: Colors.amber, size: 18), const SizedBox(width: 8)], Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
        background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))), child: Stack(children: [Positioned(right: -20, top: -20, child: Icon(Icons.circle, size: 100, color: Colors.white.withAlpha(25))), Positioned(left: -30, bottom: -30, child: Icon(Icons.circle, size: 150, color: Colors.white.withAlpha(25)))]))),
    );
  }

  Future<void> _downloadReportAction() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context, firstDate: DateTime(2024), lastDate: DateTime.now(),  
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF059669))), child: child!),
    );
    if (pickedRange == null) return; 

    final String startStr = "${pickedRange.start.year}-${pickedRange.start.month.toString().padLeft(2, '0')}-${pickedRange.start.day.toString().padLeft(2, '0')}";
    final String endStr = "${pickedRange.end.year}-${pickedRange.end.month.toString().padLeft(2, '0')}-${pickedRange.end.day.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiService.baseUrl}/merchant/report/download?token=$token&start_date=$startStr&end_date=$endStr');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return; CustomSnackBar.show(context, title: 'Gagal Unduh ⚠️', message: 'Tidak dapat membuka browser atau file.', type: ContentType.failure);
      } else {
        if (!mounted) return; CustomSnackBar.show(context, title: 'Mengunduh... 📥', message: 'Laporan sedang dibuka di browser Anda.', type: ContentType.success);
      }
    } catch (e) {
      if (!mounted) return; CustomSnackBar.show(context, title: 'Terjadi Kesalahan ⚠️', message: 'Gagal memproses tautan unduhan.', type: ContentType.failure);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedHistoryIds.length == widget.historyData.length) { _selectedHistoryIds.clear(); } 
      else { _selectedHistoryIds = widget.historyData.map<int>((h) => h['id'] as int).toList(); }
    });
  }

  Future<void> _bulkDeleteHistoryAction() async {
    if (_selectedHistoryIds.isEmpty) return;
    final confirm = await showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hapus Riwayat?'), content: Text('Anda yakin ingin menghapus ${_selectedHistoryIds.length} riwayat secara permanen?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus Semua', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))]));
    if (confirm == true) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Color(0xFF059669))));
      try {
        final result = await _apiService.deleteBulkMerchantHistory(_selectedHistoryIds);
        if (!mounted) return; Navigator.pop(context); 
        if (result['success'] == true) {
          CustomSnackBar.show(context, title: 'Riwayat Bersih! 🧹', message: result['message'] ?? 'Riwayat berhasil dihapus.', type: ContentType.success);
          setState(() { _isSelectionMode = false; _selectedHistoryIds.clear(); }); widget.onRefreshNeeded(); 
        } else { CustomSnackBar.show(context, title: 'Gagal Menghapus ⚠️', message: result['message'] ?? 'Terjadi kesalahan sistem.', type: ContentType.warning); }
      } catch (e) {
        if (!mounted) return; Navigator.pop(context); CustomSnackBar.show(context, title: 'Koneksi Terputus 🔌', message: 'Gagal terhubung ke server.', type: ContentType.failure);
      }
    }
  }

  // WIDGET SKELETON
  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
              child: Card(
                elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10, right: 15, top: 5, bottom: 5),
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(height: 15, width: 100, color: Colors.white),
                  subtitle: Container(height: 12, width: 150, color: Colors.white, margin: const EdgeInsets.only(top: 5)),
                  trailing: Container(height: 15, width: 50, color: Colors.white),
                ),
              ),
            );
          },
          childCount: 6, // Tampilkan 6 kartu palsu
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildReusableAppBar(
                title: _isSelectionMode ? '${_selectedHistoryIds.length} Dipilih' : 'Semua Riwayat',
                actions: _isSelectionMode ? [TextButton(onPressed: _toggleSelectAll, child: const Text('Pilih Semua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))] : null,
              ),
              
              if (_isSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 5), child: Row(children: [Expanded(child: OutlinedButton(onPressed: () => setState(() { _isSelectionMode = false; _selectedHistoryIds.clear(); }), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('Batal'))), const SizedBox(width: 10), ElevatedButton(onPressed: _selectedHistoryIds.isEmpty ? null : _bulkDeleteHistoryAction, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Icon(Icons.delete_forever, size: 28))])),
                ),

              // LOGIKA SKELETON
              widget.isLoading 
                ? _buildShimmerLoading() 
                : widget.historyData.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text('Belum ada riwayat.', style: TextStyle(color: Colors.grey))))
                  : SliverPadding(
                      padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final h = widget.historyData[index];
                            final int hId = h['id'];
                            final String customerName = h['customer_name'] ?? 'Pelanggan';
                            final bool isSelected = _selectedHistoryIds.contains(hId);

                            Color statusColor; String statusText; IconData statusIcon;
                            switch (h['status']) {
                              case 'completed': statusColor = Colors.green; statusText = 'Selesai'; statusIcon = Icons.check_circle; break;
                              case 'skipped': statusColor = Colors.orange; statusText = 'Dilewati'; statusIcon = Icons.next_plan; break;
                              case 'cancelled': statusColor = Colors.red; statusText = 'Batal'; statusIcon = Icons.cancel; break;
                              default: statusColor = Colors.grey; statusText = h['status']; statusIcon = Icons.info;
                            }

                            return Card(
                              elevation: 0, color: isSelected ? Colors.red.withAlpha(20) : Colors.white, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(side: BorderSide(color: isSelected ? Colors.redAccent : Colors.grey.shade200, width: isSelected ? 2 : 1), borderRadius: BorderRadius.circular(15)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onLongPress: () { if (!_isSelectionMode) { setState(() { _isSelectionMode = true; _selectedHistoryIds.add(hId); }); } },
                                onTap: _isSelectionMode ? () { setState(() { if (isSelected) { _selectedHistoryIds.remove(hId); } else { _selectedHistoryIds.add(hId); } }); } : null,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.only(left: 10, right: 15, top: 5, bottom: 5),
                                  leading: _isSelectionMode ? Checkbox(value: isSelected, activeColor: Colors.redAccent, onChanged: (bool? value) { setState(() { if (value == true) { _selectedHistoryIds.add(hId); } else { _selectedHistoryIds.remove(hId); } }); }) : CircleAvatar(backgroundColor: statusColor.withAlpha(20), child: Text(h['queue_number'].toString(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18))),
                                  title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${h['updated_at'].toString().substring(0, 16)} WIB'),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, color: statusColor, size: 16), const SizedBox(width: 4), Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12))]),
                                ),
                              ),
                            );
                          },
                          childCount: widget.historyData.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        if (!_isSelectionMode)
          Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF8F9FE), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5))]), child: ElevatedButton.icon(onPressed: _downloadReportAction, icon: const Icon(Icons.calendar_month), label: const Text('UNDUH LAPORAN', style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
      ],
    );
  }
}