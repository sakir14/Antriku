import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // <--- IMPORT SHIMMER DITAMBAHKAN DI SINI

class CustomerHomeTab extends StatefulWidget {
  final List<dynamic> merchants;
  final List<dynamic> promotions;
  final List<dynamic> activeQueues;
  final Map<String, dynamic>? customerProfile;
  final bool isLoading;
  final bool hasCurrentLocation;
  final String? locationMessage;
  final Function(int) onTakeQueue;
  final Function(int) onCancelQueue;

  const CustomerHomeTab({
    super.key,
    required this.merchants,
    required this.promotions,
    required this.activeQueues,
    required this.customerProfile,
    required this.isLoading,
    required this.hasCurrentLocation,
    required this.locationMessage,
    required this.onTakeQueue,
    required this.onCancelQueue,
  });

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  String _searchQuery = '';

  String _formatDistance(double? distance) {
    if (distance != null) {
      return distance < 1
          ? 'Jarak: ${(distance * 1000).toInt()} meter'
          : 'Jarak: ${distance.toStringAsFixed(1)} KM';
    }

    if (widget.locationMessage != null) {
      return widget.locationMessage!;
    }

    if (widget.hasCurrentLocation) {
      return 'Lokasi toko belum tersedia';
    }

    return 'Menghitung jarak...';
  }

  Widget _buildReusableAppBar({required String title, IconData? icon}) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0061FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 15),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.circle,
                  size: 100,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Icon(
                  Icons.circle,
                  size: 150,
                  color: Colors.white.withAlpha(25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreDetails(dynamic merchant, double? distance, bool isOpen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0061FF).withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 40,
                      color: Color(0xFF0061FF),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant['business_name'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.withAlpha(20)
                                : Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOpen ? 'Buka Sekarang' : 'Tutup',
                            style: TextStyle(
                              color: isOpen ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'Informasi Toko',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      merchant['address'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDistance(distance),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpen
                        ? const Color(0xFF0061FF)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isOpen
                      ? () {
                          Navigator.pop(sheetContext);
                          if (distance == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.locationMessage ??
                                      (widget.hasCurrentLocation
                                          ? 'Lokasi toko belum tersedia.'
                                          : 'Menunggu lokasi akurat...'),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else if (distance > 3.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Kejauhan bos! Jarak maksimum antre itu 3 KM dari lapak.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } else {
                            widget.onTakeQueue(merchant['id']);
                          }
                        }
                      : null,
                  child: const Text(
                    'Ambil Antrean',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int? _readId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Widget _buildPromotionsSection() {
    if (widget.promotions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: Color(0xFF0061FF)),
                SizedBox(width: 8),
                Text(
                  'Promo UMKM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.promotions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final promo = Map<String, dynamic>.from(
                  widget.promotions[index] as Map,
                );
                final merchant = promo['merchant'] is Map
                    ? Map<String, dynamic>.from(promo['merchant'] as Map)
                    : <String, dynamic>{};
                final merchantId = _readId(merchant['id']);
                final isOpen =
                    merchant['is_open'] == 1 || merchant['is_open'] == true;

                return Container(
                  width: 270,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              merchant['business_name']?.toString() ??
                                  'UMKM AntriKu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              isOpen ? 'Buka' : 'Tutup',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        promo['discount_text']?.toString().isNotEmpty == true
                            ? promo['discount_text'].toString()
                            : promo['title']?.toString() ?? 'Promo Spesial',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        promo['title']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0061FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isOpen && merchantId != null
                              ? () => widget.onTakeQueue(merchantId)
                              : null,
                          child: const Text(
                            'Ambil Antrean',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMerchants = widget.merchants.where((m) {
      final name = m['business_name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    String firstName = 'Pelanggan';
    if (widget.customerProfile?['name'] != null) {
      firstName = widget.customerProfile!['name'].split(' ')[0];
    }

    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(
          title: 'Halo, $firstName!',
          icon: Icons.waving_hand,
        ),

        if (widget.activeQueues.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final ticket = widget.activeQueues[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TIKET SAYA',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Menunggu',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        ticket['business_name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ticket['queue_number'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Menunggu giliran:',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ticket['people_in_front']} Orang di depan',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.greenAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      ticket['estimated_time'] == 0
                                          ? 'Giliran Anda!'
                                          : '~ ${ticket['estimated_time']} Menit',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Batalkan Antrean'),
                          onPressed: () async {
                            final confirm = await showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Batal Antre?'),
                                content: const Text(
                                  'Yakin ingin membatalkan antrean ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Tidak'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text(
                                      'Ya, Batalkan',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              widget.onCancelQueue(ticket['id']);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: widget.activeQueues.length),
          ),

        if (widget.promotions.isNotEmpty)
          SliverToBoxAdapter(child: _buildPromotionsSection()),

        if (widget.locationMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.locationMessage}. Aktifkan lokasi agar jarak toko bisa dihitung.',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toko Sekitarmu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama toko UMKM...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Color(0xFF0061FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // MENGGANTI LOADING LAMA DENGAN SHIMMER KUSTOM
        widget.isLoading
            ? _buildCustomerShimmerLoading()
            : filteredMerchants.isEmpty
            ? const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Toko tidak ditemukan.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final merchant = filteredMerchants[index];
                  final bool isOpen =
                      merchant['is_open'] == 1 || merchant['is_open'] == true;
                  double? distance = merchant['distance'] != null
                      ? double.tryParse(merchant['distance'].toString())
                      : null;
                  final avgRating = merchant['avg_rating'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () =>
                          _showStoreDetails(merchant, distance, isOpen),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.blue.withAlpha(20)
                                  : Colors.grey.withAlpha(30),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.store,
                              color: isOpen
                                  ? const Color(0xFF0061FF)
                                  : Colors.grey,
                              size: 28,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  merchant['business_name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: isOpen
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                merchant['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? Colors.green.withAlpha(20)
                                          : Colors.red.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOpen ? 'Buka' : 'Tutup',
                                      style: TextStyle(
                                        color: isOpen
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (avgRating != null) ...[
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$avgRating',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  if (distance != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          distance < 1
                                              ? '${(distance * 1000).toInt()} m'
                                              : '${distance.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: filteredMerchants.length),
              ),
      ],
    );
  }
}

// ==========================================
// WIDGET SKELETON SHIMMER UNTUK DAFTAR TOKO
// ==========================================
Widget _buildCustomerShimmerLoading() {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 100, // Menyesuaikan tinggi ListTile Toko
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  // Box Ikon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Box Teks (Judul & Subjudul)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(width: 150, height: 12, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Box Icon Chevron Kanan
                  Container(width: 20, height: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
      childCount: 5, // Tampilkan 5 baris daftar toko bohongan saat loading
    ),
  );
}
