import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/transaction_model.dart';

/// Provider for financial cash flow tracking, money transactions, and person ledgers.
class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];

  String? _personTypeFilter;
  int? _personIdFilter;
  String _typeFilter = 'all';
  String? _startDateFilter;
  String? _endDateFilter;
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  String? get personTypeFilter => _personTypeFilter;
  int? get personIdFilter => _personIdFilter;
  String get typeFilter => _typeFilter;
  String? get startDateFilter => _startDateFilter;
  String? get endDateFilter => _endDateFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total money received from buyers in loaded transactions.
  double get totalIncome {
    double total = 0.0;
    for (final t in _filteredTransactions) {
      if (t.isBuyerTransaction) {
        if (t.type == 'buyer_payment' || t.type == 'buyer_advance') {
          total += t.amount;
        } else if (t.type == 'refund') {
          total -= t.amount;
        }
      }
    }
    return total;
  }

  /// Total money paid out to sellers in loaded transactions.
  double get totalExpense {
    double total = 0.0;
    for (final t in _filteredTransactions) {
      if (t.isSellerTransaction) {
        if (t.type == 'seller_payment' || t.type == 'seller_advance') {
          total += t.amount;
        } else if (t.type == 'refund') {
          total -= t.amount;
        }
      }
    }
    return total;
  }

  /// Net cash flow (Income - Expense).
  double get netCashFlow => totalIncome - totalExpense;

  /// Loads all transactions from SQLite.
  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions =
          await _dbHelper.getAllTransactions(orderBy: 't.transaction_date DESC, t.id DESC');
      _applyLocalFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load transactions: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads transactions specifically for a given person (seller or buyer).
  Future<void> loadByPerson(String personType, int personId) async {
    _isLoading = true;
    _errorMessage = null;
    _personTypeFilter = personType.toLowerCase();
    _personIdFilter = personId;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getAllTransactions(
        personType: personType,
        personId: personId,
        orderBy: 't.transaction_date DESC, t.id DESC',
      );
      _applyLocalFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load transactions for person: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new transaction and applies balance adjustments.
  Future<int?> addTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedId = await _dbHelper.insertTransaction(transaction);
      if (_personIdFilter != null && _personTypeFilter != null) {
        await loadByPerson(_personTypeFilter!, _personIdFilter!);
      } else {
        await loadTransactions();
      }
      return insertedId;
    } catch (e) {
      _errorMessage = 'Failed to add transaction: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Deletes a transaction by ID.
  Future<bool> deleteTransaction(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteTransaction(id);
      if (count > 0) {
        _transactions.removeWhere((t) => t.id == id);
        _applyLocalFilters();
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete transaction: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters transactions by date range and type ('seller_payment', 'buyer_payment', 'all', etc.).
  List<TransactionModel> getFilteredTransactions(
    dynamic startDate,
    dynamic endDate,
    String? type,
  ) {
    String? startStr;
    if (startDate != null) {
      if (startDate is DateTime) {
        startStr = startDate.toIso8601String().split('T').first;
      } else {
        startStr = startDate.toString();
      }
    }

    String? endStr;
    if (endDate != null) {
      if (endDate is DateTime) {
        endStr = endDate.toIso8601String().split('T').first;
      } else {
        endStr = endDate.toString();
      }
    }

    _startDateFilter = startStr;
    _endDateFilter = endStr;
    _typeFilter = (type != null && type.isNotEmpty) ? type.toLowerCase() : 'all';

    _applyLocalFilters();
    notifyListeners();
    return _filteredTransactions;
  }

  /// Sets text search filter (matches notes, reference, person name, payment method).
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyLocalFilters();
    notifyListeners();
  }

  /// Clears active filters and restores full transactions list.
  void clearFilters() {
    _personTypeFilter = null;
    _personIdFilter = null;
    _typeFilter = 'all';
    _startDateFilter = null;
    _endDateFilter = null;
    _searchQuery = '';
    _applyLocalFilters();
    notifyListeners();
  }

  void _applyLocalFilters() {
    List<TransactionModel> list = List.from(_transactions);

    // Person Type Filter
    if (_personTypeFilter != null && _personTypeFilter!.isNotEmpty) {
      list = list
          .where((t) => t.personType.toLowerCase() == _personTypeFilter)
          .toList();
    }

    // Person ID Filter
    if (_personIdFilter != null) {
      list = list.where((t) => t.personId == _personIdFilter).toList();
    }

    // Transaction Type Filter
    if (_typeFilter != 'all' && _typeFilter.isNotEmpty) {
      list = list.where((t) => t.type.toLowerCase() == _typeFilter).toList();
    }

    // Date Range Filters
    if (_startDateFilter != null && _startDateFilter!.isNotEmpty) {
      list = list
          .where((t) => t.transactionDate.compareTo(_startDateFilter!) >= 0)
          .toList();
    }

    if (_endDateFilter != null && _endDateFilter!.isNotEmpty) {
      list = list
          .where((t) => t.transactionDate.compareTo(_endDateFilter!) <= 0)
          .toList();
    }

    // Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final matchesPerson =
            t.personName != null && t.personName!.toLowerCase().contains(q);
        final matchesNotes =
            t.notes != null && t.notes!.toLowerCase().contains(q);
        final matchesRef = t.referenceNumber != null &&
            t.referenceNumber!.toLowerCase().contains(q);
        final matchesMethod = t.paymentMethod.toLowerCase().contains(q);
        final matchesType = t.typeDisplayName.toLowerCase().contains(q);
        return matchesPerson ||
            matchesNotes ||
            matchesRef ||
            matchesMethod ||
            matchesType;
      }).toList();
    }

    _filteredTransactions = list;
  }
}
