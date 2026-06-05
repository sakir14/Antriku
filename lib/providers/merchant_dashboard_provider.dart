import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class MerchantDashboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  MerchantDashboardProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  List<dynamic> _queues = [];
  List<dynamic> _history = [];
  Map<String, dynamic>? _merchantProfile;
  bool _isLoading = true;
  bool _isOpen = true;

  List<dynamic> get queues => _queues;
  List<dynamic> get history => _history;
  Map<String, dynamic>? get merchantProfile => _merchantProfile;
  bool get isLoading => _isLoading;
  bool get isOpen => _isOpen;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final queuesData = await _apiService.getMerchantQueues();
      final historyData = await _apiService.getMerchantHistory();
      final profileData = await _apiService.getMerchantProfile();

      _queues = queuesData;
      _history = historyData;

      if (profileData != null && profileData['success'] == true) {
        _merchantProfile = profileData['data'];
        _isOpen =
            _merchantProfile?['is_open'] == 1 ||
            _merchantProfile?['is_open'] == true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDataBackground() async {
    _queues = await _apiService.getMerchantQueues();
    _history = await _apiService.getMerchantHistory();
    notifyListeners();
  }

  void setOpenStatus(bool value) {
    _isOpen = value;
    notifyListeners();
  }

  void reset() {
    _queues = [];
    _history = [];
    _merchantProfile = null;
    _isLoading = true;
    _isOpen = true;
    notifyListeners();
  }
}
