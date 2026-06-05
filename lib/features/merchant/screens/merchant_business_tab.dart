import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/business_provider.dart';

class MerchantBusinessTab extends StatefulWidget {
  const MerchantBusinessTab({super.key});

  @override
  State<MerchantBusinessTab> createState() => _MerchantBusinessTabState();
}

class _MerchantBusinessTabState extends State<MerchantBusinessTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BusinessProvider>().loadBusinessData();
      }
    });
  }

  Widget _buildReusableAppBar({required String title, IconData? icon}) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF059669),
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
              colors: [Color(0xFF059669), Color(0xFF34D399)],
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

  String _rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    if (number == 0) return 'Rp0';

    final raw = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp$buffer';
  }

  String _planLabel(String plan) {
    switch (plan) {
      case 'basic':
        return 'Basic UMKM';
      case 'premium':
        return 'Premium UMKM';
      default:
        return 'Gratis';
    }
  }

  void _showMessage(String message, {bool success = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? const Color(0xFF059669) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _activatePlan(String plan) async {
    final result = await context.read<BusinessProvider>().activatePlan(plan);
    _showMessage(
      result['message']?.toString() ?? 'Status paket diperbarui.',
      success: result['success'] == true,
    );
  }

  Future<void> _showPromotionForm({Map<String, dynamic>? promotion}) async {
    final titleController = TextEditingController(
      text: promotion?['title']?.toString() ?? '',
    );
    final discountController = TextEditingController(
      text: promotion?['discount_text']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: promotion?['description']?.toString() ?? '',
    );
    var isActive = promotion?['is_active'] == null
        ? true
        : promotion?['is_active'] == true || promotion?['is_active'] == 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                promotion == null ? 'Promosi Baru' : 'Edit Promosi',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul promosi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountController,
                      decoration: const InputDecoration(
                        labelText: 'Label diskon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      activeThumbColor: const Color(0xFF059669),
                      title: const Text('Aktif'),
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Judul promosi wajib diisi.', success: false);
      return;
    }

    final provider = context.read<BusinessProvider>();
    final result = promotion == null
        ? await provider.createPromotion(
            title: title,
            discountText: discountController.text.trim(),
            description: descriptionController.text.trim(),
          )
        : await provider.updatePromotion(
            id: promotion['id'] as int,
            title: title,
            discountText: discountController.text.trim(),
            description: descriptionController.text.trim(),
            isActive: isActive,
          );

    _showMessage(
      result['message']?.toString() ?? 'Promosi berhasil disimpan.',
      success: result['success'] == true,
    );
  }

  Future<void> _deletePromotion(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus Promosi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Promosi ini akan dihapus dari katalog pelanggan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final result = await context.read<BusinessProvider>().deletePromotion(id);
    _showMessage(
      result['message']?.toString() ?? 'Promosi berhasil dihapus.',
      success: result['success'] == true,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF059669)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionCard(BusinessProvider provider) {
    final subscription = provider.subscription ?? {};
    final plan = subscription['plan']?.toString() ?? 'free';
    final daysRemaining = subscription['days_remaining'];
    final subtitle = plan == 'free'
        ? 'Paket dasar aktif'
        : '$daysRemaining hari tersisa';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withAlpha(35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _planLabel(plan),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(BusinessProvider provider, Map<String, dynamic> plan) {
    final planId = plan['id']?.toString() ?? 'free';
    final isCurrent = provider.subscription?['plan']?.toString() == planId;
    final features = (plan['features'] as List<dynamic>? ?? []);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFF059669) : Colors.grey.shade200,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  plan['name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_rupiah(plan['price'])}/bulan',
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature.toString())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent
                    ? Colors.grey.shade300
                    : const Color(0xFF059669),
                foregroundColor: isCurrent ? Colors.black54 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isCurrent || provider.isSaving
                  ? null
                  : () => _activatePlan(planId),
              child: Text(isCurrent ? 'Paket Aktif' : 'Aktifkan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumReportCard(BusinessProvider provider) {
    final report = provider.premiumReport;

    if (!provider.isPremium) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Laporan statistik pelanggan aktif setelah paket Premium UMKM diaktifkan.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final stats = [
      ['Total Pelanggan', report?['total_customers'] ?? 0],
      ['Pelanggan Berulang', report?['repeat_customers'] ?? 0],
      ['Total Antrean', report?['total_queues'] ?? 0],
      ['Rata-rata Layanan', '${report?['average_service_minutes'] ?? 0} mnt'],
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final itemWidth = constraints.maxWidth < 320
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stats.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 76),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item[1].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item[0].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _promotionCard(Map<String, dynamic> promotion) {
    final isActive =
        promotion['is_active'] == true || promotion['is_active'] == 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  promotion['title']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withAlpha(25)
                      : Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if ((promotion['discount_text'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              promotion['discount_text'].toString(),
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if ((promotion['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              promotion['description'].toString(),
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPromotionForm(promotion: promotion),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _deletePromotion(promotion['id'] as int),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();

    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(title: 'Bisnis UMKM', icon: Icons.business_center),
        if (provider.isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          )
        else ...[
          SliverToBoxAdapter(child: _subscriptionCard(provider)),
          SliverToBoxAdapter(
            child: _sectionTitle('Paket Langganan', Icons.payments),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _planCard(
                provider,
                Map<String, dynamic>.from(provider.plans[index] as Map),
              );
            }, childCount: provider.plans.length),
          ),
          SliverToBoxAdapter(
            child: _sectionTitle('Laporan Premium', Icons.insights),
          ),
          SliverToBoxAdapter(child: _premiumReportCard(provider)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Promosi Usaha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.isPaid && !provider.isSaving
                        ? () => _showPromotionForm()
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!provider.isPaid)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Promosi usaha aktif setelah paket Basic atau Premium UMKM diaktifkan.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (provider.promotions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Belum ada promosi aktif.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _promotionCard(
                  Map<String, dynamic>.from(provider.promotions[index] as Map),
                );
              }, childCount: provider.promotions.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ],
    );
  }
}
