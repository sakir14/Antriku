import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';

class CustomerDashboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  CustomerDashboardProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  List<dynamic> _merchants = [];
  List<dynamic> _activeQueues = [];
  List<dynamic> _history = [];
  List<dynamic> _promotions = [];
  Map<String, dynamic>? _customerProfile;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasVibrated = false;
  String? _pendingTurnWarningStoreName;

  List<dynamic> get merchants => _merchants;
  List<dynamic> get activeQueues => _activeQueues;
  List<dynamic> get history => _history;
  List<dynamic> get promotions => _promotions;
  Map<String, dynamic>? get customerProfile => _customerProfile;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    await fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _determinePosition();
      await _loadData(includeProfile: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDataBackground() async {
    await _loadData(includeProfile: false);
    _updateTurnWarningState();
    notifyListeners();
  }

  Future<Map<String, dynamic>> takeQueue(int merchantId) async {
    final result = await _apiService.takeQueue(merchantId);

    if (result['success'] == true) {
      _hasVibrated = false;
      await fetchData();
    }

    return result;
  }

  Future<Map<String, dynamic>> cancelQueue(int ticketId) async {
    final result = await _apiService.cancelQueue(ticketId);

    if (result['success'] == true) {
      await fetchData();
    }

    return result;
  }

  String? consumeTurnWarningStoreName() {
    final storeName = _pendingTurnWarningStoreName;
    _pendingTurnWarningStoreName = null;
    return storeName;
  }

  void reset() {
    _merchants = [];
    _activeQueues = [];
    _history = [];
    _promotions = [];
    _customerProfile = null;
    _currentPosition = null;
    _isLoading = true;
    _hasVibrated = false;
    _pendingTurnWarningStoreName = null;
    notifyListeners();
  }

  Future<void> _loadData({required bool includeProfile}) async {
    final merchantsData = await _apiService.getMerchants(
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    );
    final queueData = await _apiService.getActiveQueue();
    final historyData = await _apiService.getCustomerHistory();
    final promotionsData = await _apiService.getActivePromotions();
    Map<String, dynamic>? profileData;

    if (includeProfile) {
      profileData = await _apiService.getCustomerProfile();
    }

    _merchants = merchantsData;
    _history = historyData;
    _promotions = promotionsData;
    _activeQueues = queueData != null && queueData['success'] == true
        ? queueData['data']
        : [];

    if (profileData != null && profileData['success'] == true) {
      _customerProfile = profileData['data'];
    }
  }

  Future<void> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Lokasi dilewati karena lambat/tidak tersedia: $e');
    }
  }

  void _updateTurnWarningState() {
    if (_activeQueues.isEmpty) return;

    final ticket = _activeQueues.first;
    final peopleInFront = ticket['people_in_front'] ?? 0;

    if (peopleInFront == 1 && !_hasVibrated) {
      _pendingTurnWarningStoreName = ticket['business_name']?.toString();
      _hasVibrated = true;
    } else if (peopleInFront != 1) {
      _hasVibrated = false;
    }
  }
}
