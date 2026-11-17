import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/buyer_model.dart';

/// Provider for managing buyers, IDs purchased, receivable debts, and balances.
class BuyerProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<BuyerModel> _buyers = [];
  List<BuyerModel> _filteredBuyers = [];
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BuyerModel> get buyers => _buyers;
  List<BuyerModel> get filteredBuyers => _filteredBuyers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total unpaid balance (receivables) owed by all buyers.
  double get totalReceivablesFromAllBuyers {
    double total = 0.0;
    for (final b in _buyers) {
      if (b.remainingDue > 0) {
        total += b.remainingDue;
      }
    }
    return total;
  }

  /// Loads all buyers from SQLite with aggregated purchase statistics.
  Future<void> loadBuyers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _buyers = await _dbHelper.getAllBuyers(orderBy: 'b.name ASC');
      _applyFilter();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load buyers: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new buyer.
  Future<int?> addBuyer(BuyerModel buyer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedId = await _dbHelper.insertBuyer(buyer);
      await loadBuyers();
      return insertedId;
    } catch (e) {
      _errorMessage = 'Failed to add buyer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing buyer's info.
  Future<bool> updateBuyer(BuyerModel buyer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.updateBuyer(buyer);
      await loadBuyers();
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to update buyer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a buyer record.
  Future<bool> deleteBuyer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteBuyer(id);
      if (count > 0) {
        _buyers.removeWhere((b) => b.id == id);
        _applyFilter();
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete buyer: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieves a buyer by primary key.
  BuyerModel? getBuyerById(int id) {
    try {
      return _buyers.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the remaining outstanding balance owed by a buyer.
  double getBuyerBalance(int id) {
    final buyer = getBuyerById(id);
    if (buyer == null) return 0.0;
    return buyer.remainingDue > 0 ? buyer.remainingDue : 0.0;
  }

  /// Recalculates buyer's total paid in database and refreshes local state.
  Future<void> recalculateBuyerBalance(int buyerId) async {
    try {
      await _dbHelper.recalculateBuyerTotalPaid(buyerId);
      final refreshed = await _dbHelper.getBuyerById(buyerId);
      if (refreshed != null) {
        final index = _buyers.indexWhere((b) => b.id == buyerId);
        if (index != -1) {
          _buyers[index] = refreshed;
          _applyFilter();
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to recalculate buyer balance: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Filters buyers by name, phone, whatsapp, or address.
  void searchBuyers(String query) {
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
      _filteredBuyers = List.from(_buyers);
      return;
    }

    final q = _searchQuery.toLowerCase();
    _filteredBuyers = _buyers.where((b) {
      final matchesName = b.name.toLowerCase().contains(q);
      final matchesPhone = b.phone != null && b.phone!.toLowerCase().contains(q);
      final matchesWhatsApp =
          b.whatsapp != null && b.whatsapp!.toLowerCase().contains(q);
      final matchesAddress =
          b.address != null && b.address!.toLowerCase().contains(q);
      return matchesName || matchesPhone || matchesWhatsApp || matchesAddress;
    }).toList();
  }
}
