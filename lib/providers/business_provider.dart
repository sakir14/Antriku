import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class BusinessProvider extends ChangeNotifier {
  final ApiService _apiService;

  BusinessProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _premiumReport;
  List<dynamic> _plans = [];
  List<dynamic> _promotions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  Map<String, dynamic>? get subscription => _subscription;
  Map<String, dynamic>? get premiumReport => _premiumReport;
  List<dynamic> get plans => _plans;
  List<dynamic> get promotions => _promotions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get isPaid => _subscription?['is_paid'] == true;
  bool get isPremium => _subscription?['is_premium'] == true;

  Future<void> loadBusinessData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final subscriptionResult = await _apiService.getMerchantSubscription();
      if (subscriptionResult['success'] == true) {
        _subscription = subscriptionResult['data'];
        _plans = subscriptionResult['plans'] ?? [];
      } else {
        _errorMessage = subscriptionResult['message']?.toString();
      }

      _promotions = await _apiService.getMerchantPromotions();

      if (isPremium) {
        final reportResult = await _apiService.getPremiumReport();
        _premiumReport = reportResult['success'] == true
            ? reportResult['data']
            : null;
      } else {
        _premiumReport = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> activatePlan(String plan) async {
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _apiService.activateMerchantSubscription(plan);
      if (result['success'] == true) {
        await loadBusinessData();
      }
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPromotion({
    required String title,
    required String description,
    required String discountText,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _apiService.createMerchantPromotion(
        title: title,
        description: description,
        discountText: discountText,
      );
      if (result['success'] == true) {
        _promotions = await _apiService.getMerchantPromotions();
      }
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updatePromotion({
    required int id,
    required String title,
    required String description,
    required String discountText,
    required bool isActive,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _apiService.updateMerchantPromotion(
        id,
        title: title,
        description: description,
        discountText: discountText,
        isActive: isActive,
      );
      if (result['success'] == true) {
        _promotions = await _apiService.getMerchantPromotions();
      }
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deletePromotion(int id) async {
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _apiService.deleteMerchantPromotion(id);
      if (result['success'] == true) {
        _promotions = await _apiService.getMerchantPromotions();
      }
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _subscription = null;
    _premiumReport = null;
    _plans = [];
    _promotions = [];
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }
}
