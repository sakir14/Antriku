import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../utils/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart'; // IMPORT SHIMMER

class CustomerHistoryTab extends StatefulWidget {
  final List<dynamic> historyData;
  final bool isLoading; // PARAMETER BARU
  final VoidCallback onRefreshNeeded;

  const CustomerHistoryTab({
    super.key,
    required this.historyData,
    required this.isLoading, // TAMBAHKAN INI
    required this.onRefreshNeeded,
  });

  @override
  State<CustomerHistoryTab> createState() => _CustomerHistoryTabState();
}

class _CustomerHistoryTabState extends State<CustomerHistoryTab> {
  final ApiService _apiService = ApiService();
  bool _isSelectionMode = false;
  List<int> _selectedHistoryIds = [];

  Widget _buildReusableAppBar({required String title, IconData? icon, List<Widget>? actions}) {
    return SliverAppBar(expandedHeight: 140, pinned: true, elevation: 0, backgroundColor: const Color(0xFF0061FF), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))), actions: actions, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 15), title: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: Colors.amber, size: 18), const SizedBox(width: 8)], Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]), background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0061FF), Color(0xFF60EFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))), child: Stack(children: [Positioned(right: -20, top: -20, child: Icon(Icons.circle, size: 100, color: Colors.white.withAlpha(25))), Positioned(left: -30, bottom: -30, child: Icon(Icons.circle, size: 150, color: Colors.white.withAlpha(25)))]))));
  }

  void _toggleSelectAll() { setState(() { if (_selectedHistoryIds.length == widget.historyData.length) { _selectedHistoryIds.clear(); } else { _selectedHistoryIds = widget.historyData.map<int>((h) => h['id'] as int).toList(); } }); }

  Future<void> _bulkDeleteHistoryAction() async {
    if (_selectedHistoryIds.isEmpty) return;
    final confirm = await showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hapus Riwayat?'), content: Text('Anda yakin ingin menghapus ${_selectedHistoryIds.length} riwayat secara permanen?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus Semua', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))]));
    if (confirm == true) {
      if (!mounted) return; showDialog(context: context, barrierDismissible: false, builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Colors.white)));
      try {
        final result = await _apiService.deleteBulkCustomerHistory(_selectedHistoryIds); 
        if (!mounted) return; Navigator.pop(context); 
        if (result['success'] == true) { CustomSnackBar.show(context, title: 'Riwayat Bersih! 🧹', message: result['message'] ?? 'Berhasil dihapus.', type: ContentType.success); setState(() { _isSelectionMode = false; _selectedHistoryIds.clear(); }); widget.onRefreshNeeded(); } 
        else { CustomSnackBar.show(context, title: 'Gagal Menghapus ⚠️', message: result['message'] ?? 'Terjadi kesalahan.', type: ContentType.warning); }
      } catch (e) {
        if (!mounted) return; Navigator.pop(context); CustomSnackBar.show(context, title: 'Koneksi Terputus 🔌', message: 'Gagal terhubung ke server.', type: ContentType.failure);
      }
    }
  }

  void _showRatingDialog(int queueId, {int? currentRating, String? currentComment}) {
    int selectedStars = currentRating ?? 5; final TextEditingController commentController = TextEditingController(text: currentComment ?? '');
    showDialog(context: context, builder: (dialogContext) { return StatefulBuilder(builder: (sbContext, setDialogState) { return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Ulasan Toko', style: TextStyle(fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Bagaimana pengalaman Anda?'), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) { return GestureDetector(onTap: () => setDialogState(() => selectedStars = index + 1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Icon(Icons.star, size: 36, color: index < selectedStars ? Colors.amber : Colors.grey.shade300))); })), const SizedBox(height: 15), TextField(controller: commentController, maxLines: 3, decoration: InputDecoration(hintText: 'Tulis komentar...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.grey))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0061FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { Navigator.pop(dialogContext); if (!mounted) return; showDialog(context: context, barrierDismissible: false, builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Colors.white))); try { final res = await _apiService.rateQueue(queueId, selectedStars, commentController.text.trim()); if (!mounted) return; Navigator.pop(context); if (res['success'] == true) { CustomSnackBar.show(context, title: 'Terima Kasih! 🌟', message: res['message'] ?? 'Ulasan dikirim.', type: ContentType.success); widget.onRefreshNeeded(); } else { CustomSnackBar.show(context, title: 'Gagal Mengirim ⚠️', message: res['message'] ?? 'Terjadi kesalahan.', type: ContentType.warning); } } catch (e) { if (!mounted) return; Navigator.pop(context); CustomSnackBar.show(context, title: 'Koneksi Terputus 🔌', message: 'Gagal terhubung ke server.', type: ContentType.failure); } }, child: const Text('Kirim'))]); }); });
  }

  // WIDGET SKELETON
  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.all(15),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
              child: Card(
                elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    leading: const CircleAvatar(backgroundColor: Colors.white),
                    title: Container(height: 15, width: 100, color: Colors.white),
                    subtitle: Container(height: 12, width: 150, color: Colors.white, margin: const EdgeInsets.only(top: 5)),
                    trailing: Container(height: 15, width: 50, color: Colors.white),
                  ),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(title: _isSelectionMode ? '${_selectedHistoryIds.length} Dipilih' : 'Riwayat Antrean', actions: _isSelectionMode ? [TextButton(onPressed: _toggleSelectAll, child: const Text('Pilih Semua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))] : null),
        if (_isSelectionMode) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 5), child: Row(children: [Expanded(child: OutlinedButton(onPressed: () => setState(() { _isSelectionMode = false; _selectedHistoryIds.clear(); }), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('Batal'))), const SizedBox(width: 10), ElevatedButton(onPressed: _selectedHistoryIds.isEmpty ? null : _bulkDeleteHistoryAction, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Icon(Icons.delete_forever, size: 28))]))),

        // LOGIKA SKELETON
        widget.isLoading
          ? _buildShimmerLoading()
          : widget.historyData.isEmpty
            ? const SliverFillRemaining(child: Center(child: Text('Belum ada riwayat.', style: TextStyle(color: Colors.grey))))
            : SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final h = widget.historyData[index]; final int hId = h['id']; final bool isSelected = _selectedHistoryIds.contains(hId);
                      Color statusColor; String statusText; IconData statusIcon;
                      switch (h['status']) { case 'completed': statusColor = Colors.green; statusText = 'Selesai'; statusIcon = Icons.check_circle; break; case 'skipped': statusColor = Colors.orange; statusText = 'Dilewati'; statusIcon = Icons.next_plan; break; case 'cancelled': statusColor = Colors.red; statusText = 'Dibatalkan'; statusIcon = Icons.cancel; break; default: statusColor = Colors.grey; statusText = h['status']; statusIcon = Icons.info; }
                      return Card(
                        elevation: 0, color: isSelected ? Colors.red.withAlpha(20) : Colors.white, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(side: BorderSide(color: isSelected ? Colors.redAccent : Colors.grey.shade200, width: isSelected ? 2 : 1), borderRadius: BorderRadius.circular(15)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15), onLongPress: () { if (!_isSelectionMode) { setState(() { _isSelectionMode = true; _selectedHistoryIds.add(hId); }); } }, onTap: _isSelectionMode ? () { setState(() { if (isSelected) { _selectedHistoryIds.remove(hId); } else { _selectedHistoryIds.add(hId); } }); } : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              leading: _isSelectionMode ? Checkbox(value: isSelected, activeColor: Colors.redAccent, onChanged: (bool? value) { setState(() { if (value == true) { _selectedHistoryIds.add(hId); } else { _selectedHistoryIds.remove(hId); } }); }) : CircleAvatar(backgroundColor: statusColor.withAlpha(20), child: Icon(statusIcon, color: statusColor)),
                              title: Text(h['business_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nomor: ${h['queue_number']} • ${h['updated_at'].toString().substring(0, 10)}'), const SizedBox(height: 5), if (h['status'] == 'completed' && !_isSelectionMode) h['rating'] != null ? GestureDetector(onTap: () => _showRatingDialog(hId, currentRating: h['rating'], currentComment: h['comment']), child: Row(children: [...List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < h['rating'] ? Colors.amber : Colors.grey.shade300)), const SizedBox(width: 8), const Text('Edit', style: TextStyle(color: Colors.grey, fontSize: 12)), const Icon(Icons.edit, size: 12, color: Colors.grey)])) : GestureDetector(onTap: () => _showRatingDialog(hId), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Beri Ulasan ', style: TextStyle(color: Color(0xFF0061FF), fontWeight: FontWeight.bold, fontSize: 13)), Icon(Icons.star_border, color: Color(0xFF0061FF), size: 16)]))]),
                              trailing: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                    }, childCount: widget.historyData.length,
                  ),
                ),
              ),
      ],
    );
  }
}