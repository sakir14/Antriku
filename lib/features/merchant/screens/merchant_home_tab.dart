import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../utils/custom_snackbar.dart';

class MerchantHomeTab extends StatefulWidget {
  final List<dynamic> queues;
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onRefreshNeeded;
  final ValueChanged<bool> onStatusChanged;

  const MerchantHomeTab({
    super.key,
    required this.queues,
    required this.isOpen,
    required this.isLoading,
    required this.onRefreshNeeded,
    required this.onStatusChanged,
  });

  @override
  State<MerchantHomeTab> createState() => _MerchantHomeTabState();
}

class _MerchantHomeTabState extends State<MerchantHomeTab> {
  final ApiService _apiService = ApiService(); 

  // ==========================================
  // MODAL SHEET: PUSAT BANTUAN TOKO
  // ==========================================
  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange, size: 30),
                  SizedBox(width: 15),
                  Text('Pusat Bantuan Toko', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem('Bagaimana cara mencetak QR Code?', 'Buka menu Toko > Tampilkan QR Code, lalu klik tombol Cetak untuk menyimpan poster QR Code ke perangkat Anda.'),
                    _buildFaqItem('Apa bedanya Selesai dan Lewati?', 'Tombol "Selesai" menandakan pelanggan telah sukses dilayani. Tombol "Lewati" digunakan jika pelanggan tidak hadir saat dipanggil.'),
                    _buildFaqItem('Bagaimana cara menutup toko?', 'Gunakan tombol switch BUKA/TUTUP di bagian atas menu Antrean. Jika ditutup, pelanggan tidak bisa mengambil nomor antrean baru.'),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(15)),
                      child: const Column(
                        children: [
                          Text('Butuh bantuan lebih lanjut?', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('Hubungi Tim Support: support@antriku.com', style: TextStyle(color: Color(0xFF059669))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [Padding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 15), child: Text(answer, style: const TextStyle(color: Colors.grey)))],
    );
  }

  // ==========================================
  // HELPER: BUILD KEPALA APPBAR 
  // ==========================================
  Widget _buildReusableAppBar({required String title, IconData? icon, List<Widget>? actions}) {
    return SliverAppBar(
      expandedHeight: 140, 
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF059669), 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
      actions: actions,
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
  // AKSI: SELESAI / LEWATI ANTREAN (ANTI-FREEZE)
  // ==========================================
  Future<void> _processQueueAction(int id, String action) async {
    showDialog(context: context, barrierDismissible: false, builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Color(0xFF059669))));
    
    try {
      final result = action == 'complete' ? await _apiService.completeQueue(id) : await _apiService.skipQueue(id);
      
      if (!mounted) return; 
      Navigator.pop(context); // Tutup loading

      if (result['success'] == true) {
        CustomSnackBar.show(
          context, 
          title: action == 'complete' ? 'Selesai! ' : 'Dilewati ', 
          message: result['message'] ?? 'Status antrean berhasil diubah.', 
          type: ContentType.success
        );
        widget.onRefreshNeeded();
      } else {
        CustomSnackBar.show(
          context, 
          title: 'Gagal Memproses ', 
          message: result['message'] ?? 'Terjadi kesalahan sistem.', 
          type: ContentType.warning
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      CustomSnackBar.show(context, title: 'Koneksi Terputus 🔌', message: 'Gagal terhubung ke server.', type: ContentType.failure);
    }
  }

  // ==========================================
  // AKSI: BUKA / TUTUP TOKO (ANTI-FREEZE)
  // ==========================================
  Future<void> _toggleStatusAction(bool value) async {
    showDialog(context: context, barrierDismissible: false, builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Color(0xFF059669))));
    
    try {
      final result = await _apiService.toggleMerchantStatus(value);
      
      if (!mounted) return; 
      Navigator.pop(context); // Tutup loading
      
      if (result['success'] == true) {
        widget.onStatusChanged(value); // Ubah status switch di layar
        CustomSnackBar.show(
          context, 
          title: value ? 'Toko Buka! ' : 'Toko Tutup ', 
          message: value ? 'Pelanggan sekarang bisa mengambil antrean.' : 'Toko sedang ditutup sementara.', 
          type: value ? ContentType.success : ContentType.warning
        );
      } else {
        CustomSnackBar.show(
          context, 
          title: 'Gagal Update Status ', 
          message: result['message'] ?? 'Terjadi kesalahan.', 
          type: ContentType.failure
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      CustomSnackBar.show(context, title: 'Koneksi Terputus 🔌', message: 'Gagal menghubungi server.', type: ContentType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(
          title: 'Dasbor UMKM',
          icon: Icons.storefront,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: _showHelpCenter,
              tooltip: 'Pusat Bantuan',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 5),
              child: Row(
                children: [
                  Text(widget.isOpen ? 'BUKA' : 'TUTUP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Switch(value: widget.isOpen, activeThumbColor: Colors.white, activeTrackColor: Colors.greenAccent.shade100, onChanged: _toggleStatusAction),
                ],
              ),
            ),
          ],
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Antrean Aktif', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF059669).withAlpha(20), borderRadius: BorderRadius.circular(20)), child: Text('${widget.queues.length} Orang', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)))
              ],
            ),
          ),
        ),

        widget.isLoading
          ? _buildShimmerLoading()
          : widget.queues.isEmpty
         ? SliverFillRemaining(
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Lottie.asset(
                        'assets/empty.json', 
                        height: 250,
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                   const SizedBox(height: 10),
                   const Text('Belum ada antrean, santai dulu!', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 5),
                   const Text('Tarik layar ke bawah untuk memuat ulang', style: TextStyle(color: Colors.grey, fontSize: 12)),
                 ],
               ),
             ),
           )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final q = widget.queues[index];
                    final isFirst = index == 0; 
                    final String customerName = q['customer_name'] ?? 'Pelanggan Setia';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0xFF059669) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isFirst ? 30 : 10), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isFirst ? 'SEDANG DILAYANI' : 'NOMOR ANTREAN', style: TextStyle(color: isFirst ? Colors.greenAccent : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      Text(q['queue_number'].toString(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isFirst ? Colors.white : const Color(0xFF059669))),
                                    ],
                                  ),
                                  Icon(Icons.person, size: 40, color: isFirst ? Colors.white24 : Colors.grey.shade200)
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: isFirst ? Colors.white.withAlpha(30) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.account_circle, size: 16, color: isFirst ? Colors.white : Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(customerName, style: TextStyle(color: isFirst ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: isFirst ? Colors.white : Colors.red, side: BorderSide(color: isFirst ? Colors.white54 : Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () => _processQueueAction(q['id'], 'skip'), child: const Text('Lewati'))),
                                  const SizedBox(width: 15),
                                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isFirst ? Colors.white : const Color(0xFF059669), foregroundColor: isFirst ? const Color(0xFF059669) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0), onPressed: () => _processQueueAction(q['id'], 'complete'), child: const Text('Selesai'))),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: widget.queues.length,
                ),
              ),
      ],
    );
  }
  
  Widget _buildShimmerLoading() {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 200, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 12, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(width: 60, height: 40, color: Colors.white),
                        ],
                      ),
                      const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(width: 140, height: 25, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: Container(height: 45, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(width: 15),
                      Expanded(child: Container(height: 45, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      childCount: 3, 
    ),
  );
  }
}