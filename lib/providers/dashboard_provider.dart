import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/dashboard_stats_model.dart';

/// Provider for managing and supplying dashboard analytic statistics.
class DashboardProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DashboardStatsModel _stats = const DashboardStatsModel();
  List<Map<String, dynamic>> _paymentMethodBreakdown = [];
  List<Map<String, dynamic>> _topBuyers = [];
  List<Map<String, dynamic>> _topSellers = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardStatsModel get stats => _stats;
  List<Map<String, dynamic>> get paymentMethodBreakdown => _paymentMethodBreakdown;
  List<Map<String, dynamic>> get topBuyers => _topBuyers;
  List<Map<String, dynamic>> get topSellers => _topSellers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Direct numeric getters
  int get totalIds => _stats.totalIds;
  int get availableIds => _stats.availableIds;
  int get soldIds => _stats.soldIds;
  double get totalInvestment => _stats.totalInvestment;
  double get totalSales => _stats.totalSales;
  double get totalProfit => _stats.totalProfit;
  double get profitMargin => _stats.profitMargin;
  double get totalSellerPayments => _stats.totalSellerPayments;
  double get totalBuyerPayments => _stats.totalBuyerPayments;
  double get totalOutstandingBalance => _stats.totalOutstandingBalance;
  double get totalPayableToSellers => _stats.totalPayableToSellers;
  double get deoTotal => _stats.deoTotal;
  double get deoPaid => _stats.deoPaid;
  double get deoRemaining => _stats.deoRemaining;
  List<MonthlyStat> get monthlyStats => _stats.monthlyStats;

  /// Loads aggregated dashboard statistics and analytics from SQLite.
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dbHelper.getDashboardStats(),
        _dbHelper.getPaymentMethodBreakdown(),
        _dbHelper.getTopBuyers(limit: 5),
        _dbHelper.getTopSellers(limit: 5),
      ]);

      _stats = results[0] as DashboardStatsModel;
      _paymentMethodBreakdown = results[1] as List<Map<String, dynamic>>;
      _topBuyers = results[2] as List<Map<String, dynamic>>;
      _topSellers = results[3] as List<Map<String, dynamic>>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard statistics: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convenience alias for reloading dashboard metrics.
  Future<void> refresh() async {
    await loadDashboardStats();
  }

  /// Manually triggers a reload when other modules (Sales, Inventory, DEO) perform changes.
  void notifyDataChanged() {
    loadDashboardStats();
  }
}
