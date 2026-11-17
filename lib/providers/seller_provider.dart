import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/seller_model.dart';

/// Provider for managing sellers, IDs supplied, payments owed, and balances.
class SellerProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<SellerModel> _sellers = [];
  List<SellerModel> _filteredSellers = [];
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SellerModel> get sellers => _sellers;
  List<SellerModel> get filteredSellers => _filteredSellers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total amount currently owed to all sellers.
  double get totalOwedToAllSellers {
    double total = 0.0;
    for (final s in _sellers) {
      final bal = s.totalPurchaseValue - s.totalPaid;
      if (bal > 0) total += bal;
    }
    return total;
  }

  /// Loads all sellers from SQLite with computed totals.
  Future<void> loadSellers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sellers = await _dbHelper.getAllSellers(orderBy: 's.name ASC');
      _applyFilter();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load sellers: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new seller.
  Future<int?> addSeller(SellerModel seller) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedId = await _dbHelper.insertSeller(seller);
      await loadSellers();
      return insertedId;
    } catch (e) {
      _errorMessage = 'Failed to add seller: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing seller.
  Future<bool> updateSeller(SellerModel seller) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.updateSeller(seller);
      await loadSellers();
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to update seller: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a seller and nullifies seller_id on their supplied IDs.
  Future<bool> deleteSeller(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteSeller(id);
      if (count > 0) {
        _sellers.removeWhere((s) => s.id == id);
        _applyFilter();
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete seller: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieves a seller by primary key, either from cached list or database.
  SellerModel? getSellerById(int id) {
    try {
      return _sellers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Calculates the current balance owed to a seller: (total_amount_owed - total_paid).
  double getSellerBalance(int id) {
    final seller = getSellerById(id);
    if (seller == null) return 0.0;
    final balance = seller.totalPurchaseValue - seller.totalPaid;
    return balance > 0 ? balance : 0.0;
  }

  /// Recalculates seller's total paid in database and updates state.
  Future<void> recalculateSellerBalance(int sellerId) async {
    try {
      await _dbHelper.recalculateSellerTotalPaid(sellerId);
      final refreshed = await _dbHelper.getSellerById(sellerId);
      if (refreshed != null) {
        final index = _sellers.indexWhere((s) => s.id == sellerId);
        if (index != -1) {
          _sellers[index] = refreshed;
          _applyFilter();
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to recalculate seller balance: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Filters sellers list by search string (name, phone, whatsapp, address).
  void searchSellers(String query) {
    _searchQuery = query.trim();
    _applyFilter();
    notifyListeners();
  }

  /// Clears active search filter.
  void clearFilter() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSellers = List.from(_sellers);
      return;
    }

    final q = _searchQuery.toLowerCase();
    _filteredSellers = _sellers.where((s) {
      final matchesName = s.name.toLowerCase().contains(q);
      final matchesPhone = s.phone != null && s.phone!.toLowerCase().contains(q);
      final matchesWhatsApp =
          s.whatsapp != null && s.whatsapp!.toLowerCase().contains(q);
      final matchesAddress =
          s.address != null && s.address!.toLowerCase().contains(q);
      return matchesName || matchesPhone || matchesWhatsApp || matchesAddress;
    }).toList();
  }
}
