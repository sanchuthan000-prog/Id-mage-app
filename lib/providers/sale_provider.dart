import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/sale_model.dart';
import 'package:ff_id_manager/models/ff_id_model.dart';
import 'package:ff_id_manager/providers/dashboard_provider.dart';

/// Provider for managing sales operations, sell transactions, and sales history.
class SaleProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<SaleModel> _sales = [];
  List<SaleModel> _filteredSales = [];

  String _searchQuery = '';
  int? _buyerIdFilter;
  String? _fromDateFilter;
  String? _toDateFilter;

  bool _isLoading = false;
  String? _errorMessage;

  // Optional dashboard notifier callback
  VoidCallback? _dashboardNotifier;

  // Getters
  List<SaleModel> get sales => _sales;
  List<SaleModel> get filteredSales => _filteredSales;
  String get searchQuery => _searchQuery;
  int? get buyerIdFilter => _buyerIdFilter;
  String? get fromDateFilter => _fromDateFilter;
  String? get toDateFilter => _toDateFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalRevenue =>
      _sales.fold(0.0, (sum, sale) => sum + sale.sellingPrice);

  double get totalProfit =>
      _sales.fold(0.0, (sum, sale) => sum + sale.profit);

  double get totalUncollectedDue =>
      _sales.fold(0.0, (sum, sale) => sum + sale.remainingBalance);

  /// Registers a global callback to trigger dashboard updates when sales happen.
  void setDashboardNotifier(VoidCallback notifier) {
    _dashboardNotifier = notifier;
  }

  /// Loads all sales records from SQLite with joined ID and buyer metadata.
  Future<void> loadSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sales = await _dbHelper.getAllSales(orderBy: 'sa.id DESC');
      _applyLocalFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load sales: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Performs a complete Free Fire ID sale transaction:
  /// 1. Verifies the ID and calculates profit.
  /// 2. Creates the Sale database record.
  /// 3. Updates FF ID status to 'sold' and sets selling_price.
  /// 4. Updates buyer's total_paid and records transaction (if amountReceived > 0).
  /// 5. Notifies dashboard and refreshes sales list.
  Future<SaleModel?> sellId({
    required int ffIdId,
    required int buyerId,
    required double sellingPrice,
    required String paymentMethod,
    required double amountReceived,
    String? notes,
    String? saleDate,
    String? paymentProofPath,
    DashboardProvider? dashboardProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch ID to determine purchase cost and compute profit
      final FfIdModel? targetId = await _dbHelper.getFfIdById(ffIdId);
      final double purchaseCost = targetId?.purchaseCost ?? 0.0;
      final double calculatedProfit = sellingPrice - purchaseCost;
      final double remainingBalance = (sellingPrice - amountReceived) > 0
          ? (sellingPrice - amountReceived)
          : 0.0;
      final String effectiveDate =
          saleDate ?? DateTime.now().toIso8601String().split('T').first;

      final saleToRecord = SaleModel(
        ffIdId: ffIdId,
        buyerId: buyerId,
        sellingPrice: sellingPrice,
        profit: calculatedProfit,
        paymentMethod: paymentMethod,
        amountReceived: amountReceived,
        remainingBalance: remainingBalance,
        saleDate: effectiveDate,
        notes: notes,
      );

      // 2. Execute atomic database transaction
      final recordedSale = await _dbHelper.recordSale(
        saleToRecord,
        paymentProofPath: paymentProofPath,
      );

      // 3. Reload sales list
      await loadSales();

      // 4. Notify dashboard provider if provided or via registered notifier
      if (dashboardProvider != null) {
        await dashboardProvider.loadDashboardStats();
      } else if (_dashboardNotifier != null) {
        _dashboardNotifier!();
      }

      return recordedSale;
    } catch (e) {
      _errorMessage = 'Failed to process sale: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Direct method to add a raw sale record and trigger dashboard update.
  Future<SaleModel?> addSale(
    SaleModel sale, {
    String? paymentProofPath,
    DashboardProvider? dashboardProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final recorded = await _dbHelper.recordSale(
        sale,
        paymentProofPath: paymentProofPath,
      );

      await loadSales();

      if (dashboardProvider != null) {
        await dashboardProvider.loadDashboardStats();
      } else if (_dashboardNotifier != null) {
        _dashboardNotifier!();
      }

      return recorded;
    } catch (e) {
      _errorMessage = 'Failed to add sale: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Deletes a sale, rolls back the FF ID to 'available', and adjusts balances.
  Future<bool> deleteSale(
    int saleId, {
    DashboardProvider? dashboardProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _dbHelper.deleteSale(saleId);
      if (success) {
        _sales.removeWhere((s) => s.id == saleId);
        _applyLocalFilters();

        if (dashboardProvider != null) {
          await dashboardProvider.loadDashboardStats();
        } else if (_dashboardNotifier != null) {
          _dashboardNotifier!();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete sale: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters sales by query, buyer, and date ranges.
  void filterSales({
    String? query,
    int? buyerId,
    String? fromDate,
    String? toDate,
  }) {
    if (query != null) _searchQuery = query.trim();
    if (buyerId != null) _buyerIdFilter = buyerId;
    if (fromDate != null) _fromDateFilter = fromDate.trim();
    if (toDate != null) _toDateFilter = toDate.trim();

    _applyLocalFilters();
    notifyListeners();
  }

  /// Clears all sales filters.
  void clearFilters() {
    _searchQuery = '';
    _buyerIdFilter = null;
    _fromDateFilter = null;
    _toDateFilter = null;
    _applyLocalFilters();
    notifyListeners();
  }

  /// Retrieves a sale by ID.
  SaleModel? getSaleById(int id) {
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void _applyLocalFilters() {
    List<SaleModel> list = List.from(_sales);

    // Buyer filter
    if (_buyerIdFilter != null) {
      list = list.where((s) => s.buyerId == _buyerIdFilter).toList();
    }

    // From date filter
    if (_fromDateFilter != null && _fromDateFilter!.isNotEmpty) {
      list = list.where((s) => s.saleDate.compareTo(_fromDateFilter!) >= 0).toList();
    }

    // To date filter
    if (_toDateFilter != null && _toDateFilter!.isNotEmpty) {
      list = list.where((s) => s.saleDate.compareTo(_toDateFilter!) <= 0).toList();
    }

    // Search query (FF UID, Buyer name, Phone, Notes)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final matchesUid = s.ffUid != null && s.ffUid!.toLowerCase().contains(q);
        final matchesBuyer =
            s.buyerName != null && s.buyerName!.toLowerCase().contains(q);
        final matchesPhone =
            s.buyerPhone != null && s.buyerPhone!.toLowerCase().contains(q);
        final matchesNotes =
            s.notes != null && s.notes!.toLowerCase().contains(q);
        final matchesMethod = s.paymentMethod.toLowerCase().contains(q);
        return matchesUid ||
            matchesBuyer ||
            matchesPhone ||
            matchesNotes ||
            matchesMethod;
      }).toList();
    }

    _filteredSales = list;
  }
}
