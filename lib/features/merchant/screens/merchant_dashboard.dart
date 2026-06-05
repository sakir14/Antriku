import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../providers/business_provider.dart';
import '../../../providers/merchant_dashboard_provider.dart';
import 'merchant_analytics_tab.dart';
import 'merchant_business_tab.dart';
import 'merchant_history_tab.dart';
import 'merchant_home_tab.dart';
import 'merchant_profile_tab.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _selectedIndex = 0;
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MerchantDashboardProvider>().fetchData();
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
      await pusher.init(
        apiKey: '77ba0a71d3a8f2715183',
        cluster: 'ap1',
        onEvent: (event) {
          final isQueueEvent =
              event.eventName == 'queue.updated' ||
              event.eventName == 'QueueCreated';

          if (isQueueEvent && mounted) {
            context.read<MerchantDashboardProvider>().fetchDataBackground();
          }
        },
      );
      await pusher.subscribe(channelName: 'antriku-live');
      await pusher.connect();
    } catch (e) {
      debugPrint('PUSHER ERROR: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<MerchantDashboardProvider>();
    final providerReader = context.read<MerchantDashboardProvider>();

    final pages = [
      MerchantHomeTab(
        queues: dashboard.queues,
        isOpen: dashboard.isOpen,
        isLoading: dashboard.isLoading,
        onRefreshNeeded: providerReader.fetchData,
        onStatusChanged: providerReader.setOpenStatus,
      ),
      MerchantHistoryTab(
        historyData: dashboard.history,
        isLoading: dashboard.isLoading,
        onRefreshNeeded: providerReader.fetchData,
      ),
      const MerchantAnalyticsTab(),
      const MerchantBusinessTab(),
      MerchantProfileTab(
        merchantProfile: dashboard.merchantProfile,
        onRefreshNeeded: providerReader.fetchData,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: LiquidPullToRefresh(
        onRefresh: () => _selectedIndex == 3
            ? context.read<BusinessProvider>().loadBusinessData()
            : providerReader.fetchData(),
        color: const Color(0xFF059669),
        backgroundColor: Colors.white,
        height: 150,
        animSpeedFactor: 2.0,
        showChildOpacityTransition: false,
        child: pages[_selectedIndex],
      ),
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
              rippleColor: Colors.greenAccent.shade100,
              hoverColor: Colors.greenAccent.shade100,
              gap: 6,
              activeColor: const Color(0xFF059669),
              iconSize: 23,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0xFF059669).withAlpha(30),
              color: Colors.grey,
              tabs: const [
                GButton(icon: Icons.people_alt, text: 'Antrean'),
                GButton(icon: Icons.history, text: 'Riwayat'),
                GButton(icon: Icons.analytics, text: 'Analitik'),
                GButton(icon: Icons.business_center, text: 'Bisnis'),
                GButton(icon: Icons.store, text: 'Toko'),
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
