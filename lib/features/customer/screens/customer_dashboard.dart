import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:vibration/vibration.dart';

import '../../../providers/customer_dashboard_provider.dart';
import '../../../utils/custom_snackbar.dart';
import 'customer_history_tab.dart';
import 'customer_home_tab.dart';
import 'customer_profile_tab.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerDashboardProvider>().loadInitialData();
    });

    _initPusher();
  }

  @override
  void dispose() {
    pusher.disconnect();
    super.dispose();
  }

  Future<void> _initPusher() async {
    try {
      debugPrint('PUSHER: Memulai inisialisasi...');
      await pusher.init(
        apiKey: '77ba0a71d3a8f2715183',
        cluster: 'ap1',
        onConnectionStateChange: (currentState, previousState) {
          debugPrint('PUSHER STATUS: $currentState');
        },
        onError: (String message, int? code, dynamic e) {
          debugPrint('PUSHER ERROR: $message');
        },
        onEvent: (event) async {
          if (event.eventName != 'queue.updated') return;
          if (!mounted) return;

          final provider = context.read<CustomerDashboardProvider>();
          await provider.fetchDataBackground();

          if (!mounted) return;
          await _showTurnWarningIfNeeded(provider);
        },
      );
      await pusher.subscribe(channelName: 'antriku-live');
      await pusher.connect();
    } catch (e) {
      debugPrint('PUSHER FATAL ERROR: $e');
    }
  }

  Future<void> _showTurnWarningIfNeeded(
    CustomerDashboardProvider provider,
  ) async {
    final storeName = provider.consumeTurnWarningStoreName();
    if (storeName == null) return;

    final hasVib = await Vibration.hasVibrator();
    if (hasVib == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange),
              SizedBox(width: 10),
              Text('Giliran Dekat!'),
            ],
          ),
          content: Text(
            'Bersiaplah! Sisa 1 orang lagi di depan Anda di $storeName.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'OK, SAYA SIAP!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0061FF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _takeQueueAction(int merchantId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );

    try {
      final result = await context.read<CustomerDashboardProvider>().takeQueue(
        merchantId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        CustomSnackBar.show(
          context,
          title: 'Yey! Berhasil ',
          message: result['message'] ?? 'Nomor antreanmu sudah diamankan.',
          type: ContentType.success,
        );
      } else {
        CustomSnackBar.show(
          context,
          title: 'Waduh, Gagal ',
          message: result['message'] ?? 'Terjadi kesalahan sistem.',
          type: ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus',
        message:
            'Gagal menghubungi server. Periksa internet atau server lokalmu.',
        type: ContentType.failure,
      );

      debugPrint('ERROR TAKE QUEUE: $e');
    }
  }

  Future<void> _cancelQueueAction(int ticketId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await context
          .read<CustomerDashboardProvider>()
          .cancelQueue(ticketId);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        CustomSnackBar.show(
          context,
          title: 'Berhasil Dibatalkan ',
          message: 'Antreanmu sudah resmi dibatalkan.',
          type: ContentType.success,
        );
      } else {
        CustomSnackBar.show(
          context,
          title: 'Gagal Membatalkan ',
          message: result['message'] ?? 'Terjadi kesalahan sistem.',
          type: ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus',
        message: 'Gagal membatalkan antrean dari server.',
        type: ContentType.failure,
      );
    }
  }

  Future<void> _scanQRCode() async {
    // ignore: deprecated_member_use
    final res = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        // ignore: deprecated_member_use
        builder: (routeContext) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (!mounted) return;
    if (res == null || res == '-1') return;

    try {
      final key = enc.Key.fromUtf8('AntriKuSecretKey2026PolindraITS!');
      final iv = enc.IV.fromUtf8('AntriKuInitVect!');
      final encrypter = enc.Encrypter(enc.AES(key));
      final decrypted = encrypter.decrypt64(res, iv: iv);

      if (decrypted.startsWith('ANTRIKU-MERCHANT-')) {
        final merchantIdStr = decrypted.replaceAll('ANTRIKU-MERCHANT-', '');
        final merchantId = int.tryParse(merchantIdStr);
        if (merchantId != null) {
          await _takeQueueAction(merchantId);
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Ditolak! QR Code tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<CustomerDashboardProvider>();
    final providerReader = context.read<CustomerDashboardProvider>();

    final pages = [
      CustomerHomeTab(
        merchants: dashboard.merchants,
        promotions: dashboard.promotions,
        activeQueues: dashboard.activeQueues,
        customerProfile: dashboard.customerProfile,
        isLoading: dashboard.isLoading,
        onTakeQueue: _takeQueueAction,
        onCancelQueue: _cancelQueueAction,
      ),
      CustomerHistoryTab(
        historyData: dashboard.history,
        isLoading: dashboard.isLoading,
        onRefreshNeeded: providerReader.fetchData,
      ),
      CustomerProfileTab(
        customerProfile: dashboard.customerProfile,
        onRefreshNeeded: providerReader.fetchData,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: LiquidPullToRefresh(
        onRefresh: providerReader.fetchData,
        color: const Color(0xFF0061FF),
        backgroundColor: Colors.white,
        height: 150,
        animSpeedFactor: 2.0,
        showChildOpacityTransition: false,
        child: pages[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'Scan QR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF0061FF),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withAlpha(20)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              rippleColor: Colors.blueAccent.shade100,
              hoverColor: Colors.blueAccent.shade100,
              gap: 8,
              activeColor: const Color(0xFF0061FF),
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0xFF0061FF).withAlpha(30),
              color: Colors.grey,
              tabs: const [
                GButton(icon: Icons.explore, text: 'Eksplor'),
                GButton(icon: Icons.history, text: 'Riwayat'),
                GButton(icon: Icons.person, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
