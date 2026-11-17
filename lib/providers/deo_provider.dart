import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/deo_model.dart';
import 'package:ff_id_manager/models/buyer_model.dart';

/// Provider for managing DEO (Debt/Credit installment accounts), payment logs,
/// and automated customer WhatsApp receipt messaging.
class DeoProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<DeoAccountModel> _accounts = [];
  List<DeoAccountModel> _filteredAccounts = [];
  final Map<int, List<DeoPaymentModel>> _accountPayments = {};

  String _searchQuery = '';
  bool _onlyUnpaid = false;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DeoAccountModel> get accounts => _accounts;
  List<DeoAccountModel> get filteredAccounts => _filteredAccounts;
  Map<int, List<DeoPaymentModel>> get accountPayments => _accountPayments;
  String get searchQuery => _searchQuery;
  bool get onlyUnpaid => _onlyUnpaid;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total amount of all DEO accounts combined.
  double get totalDeoAmount =>
      _accounts.fold(0.0, (sum, a) => sum + a.totalAmount);

  /// Total amount collected so far across all DEO accounts.
  double get totalDeoPaid =>
      _accounts.fold(0.0, (sum, a) => sum + a.paidAmount);

  /// Total outstanding remaining debt across all DEO accounts.
  double get totalDeoRemaining =>
      _accounts.fold(0.0, (sum, a) => sum + a.remainingAmount);

  /// Loads all DEO accounts from SQLite.
  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accounts = await _dbHelper.getAllDeoAccounts(orderBy: 'd.id DESC');
      _applyLocalFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load DEO accounts: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new DEO installment account.
  Future<int?> addAccount(DeoAccountModel account) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedId = await _dbHelper.insertDeoAccount(account);
      await loadAccounts();
      return insertedId;
    } catch (e) {
      _errorMessage = 'Failed to add DEO account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing DEO account.
  Future<bool> updateAccount(DeoAccountModel account) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.updateDeoAccount(account);
      await loadAccounts();
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to update DEO account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a DEO account and its payment history.
  Future<bool> deleteAccount(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteDeoAccount(id);
      if (count > 0) {
        _accounts.removeWhere((a) => a.id == id);
        _accountPayments.remove(id);
        _applyLocalFilters();
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete DEO account: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Records a payment installment towards a DEO account.
  Future<DeoPaymentModel?> addDeoPayment(
    DeoPaymentModel payment, {
    bool recordAsBuyerTransaction = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final recordedPayment = await _dbHelper.recordDeoPayment(
        payment,
        recordAsBuyerTransaction: recordAsBuyerTransaction,
      );

      // Refresh payments cache for this account
      await loadPaymentsForAccount(payment.deoAccountId);

      // Refresh the accounts list to update paid_amount & remaining balance
      final updatedAccount =
          await _dbHelper.getDeoAccountById(payment.deoAccountId);
      if (updatedAccount != null) {
        final index =
            _accounts.indexWhere((a) => a.id == payment.deoAccountId);
        if (index != -1) {
          _accounts[index] = updatedAccount;
        } else {
          _accounts.insert(0, updatedAccount);
        }
        _applyLocalFilters();
      }

      _errorMessage = null;
      return recordedPayment;
    } catch (e) {
      _errorMessage = 'Failed to record DEO payment: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads payment entries for a given DEO account from the database.
  Future<List<DeoPaymentModel>> loadPaymentsForAccount(int accountId) async {
    try {
      final payments = await _dbHelper.getPaymentsForDeoAccount(accountId);
      _accountPayments[accountId] = payments;
      notifyListeners();
      return payments;
    } catch (e) {
      _errorMessage = 'Failed to load payments for account #$accountId: ${e.toString()}';
      return [];
    }
  }

  /// Returns payments for an account from memory cache or account model.
  List<DeoPaymentModel> getPaymentsForAccount(int accountId) {
    if (_accountPayments.containsKey(accountId)) {
      return _accountPayments[accountId]!;
    }
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      return account.payments;
    } catch (_) {
      return [];
    }
  }

  /// Deletes a payment installment and recalculates DEO account paid_amount.
  Future<bool> deleteDeoPayment(int paymentId, int accountId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteDeoPayment(paymentId);
      if (count > 0) {
        await loadPaymentsForAccount(accountId);
        final refreshed = await _dbHelper.getDeoAccountById(accountId);
        if (refreshed != null) {
          final index = _accounts.indexWhere((a) => a.id == accountId);
          if (index != -1) {
            _accounts[index] = refreshed;
            _applyLocalFilters();
          }
        }
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete payment: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a clean, professional receipt message formatted for WhatsApp.
  String generateWhatsAppMessage(
    DeoPaymentModel payment,
    DeoAccountModel account,
    BuyerModel buyer,
  ) {
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedAmount = numberFormat.format(payment.amount);
    final formattedTotal = numberFormat.format(account.totalAmount);
    final newPaidAmount = account.paidAmount +
        (payment.id == null || !_paymentExists(account.id, payment.id)
            ? payment.amount
            : 0.0);
    final formattedPaid = numberFormat.format(newPaidAmount);
    final remaining = (account.totalAmount - newPaidAmount) > 0
        ? (account.totalAmount - newPaidAmount)
        : 0.0;
    final formattedRemaining = numberFormat.format(remaining);

    final statusText = remaining <= 0.01
        ? '✅ FULLY PAID / COMPLETED'
        : '⏳ REMAINING DUE: Rs. $formattedRemaining';

    final buffer = StringBuffer();
    buffer.writeln('🎮 *FREE FIRE ID PAYMENT RECEIPT* 🎮');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Customer:* ${buyer.name}');
    if (buyer.phone != null && buyer.phone!.trim().isNotEmpty) {
      buffer.writeln('📞 *Contact:* ${buyer.phone}');
    }
    buffer.writeln('🏷️ *Account / Deal:* ${account.name}');
    if (account.ffUid != null && account.ffUid!.trim().isNotEmpty) {
      buffer.writeln('🆔 *FF UID:* ${account.ffUid}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 *Payment Received:* Rs. $formattedAmount');
    buffer.writeln('📅 *Payment Date:* ${payment.paymentDate}');
    if (payment.notes != null && payment.notes!.trim().isNotEmpty) {
      buffer.writeln('📝 *Notes:* ${payment.notes}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Total Deal Value:* Rs. $formattedTotal');
    buffer.writeln('📥 *Total Paid to Date:* Rs. $formattedPaid');
    buffer.writeln('📊 *Status:* $statusText');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✨ Thank you for your business! ✨');
    buffer.writeln('_Generated by FF ID Manager_');

    return buffer.toString();
  }

  bool _paymentExists(int? accountId, int? paymentId) {
    if (accountId == null || paymentId == null) return false;
    final list = _accountPayments[accountId];
    if (list == null) return false;
    return list.any((p) => p.id == paymentId);
  }

  /// Filters accounts by text search (deal name, buyer, UID, notes).
  void searchAccounts(String query) {
    _searchQuery = query.trim();
    _applyLocalFilters();
    notifyListeners();
  }

  /// Toggles filtering only accounts with remaining due balance.
  void filterUnpaidOnly(bool unpaidOnly) {
    _onlyUnpaid = unpaidOnly;
    _applyLocalFilters();
    notifyListeners();
  }

  /// Clears active search and unpaid filter.
  void clearFilters() {
    _searchQuery = '';
    _onlyUnpaid = false;
    _applyLocalFilters();
    notifyListeners();
  }

  void _applyLocalFilters() {
    List<DeoAccountModel> list = List.from(_accounts);

    // Unpaid only filter
    if (_onlyUnpaid) {
      list = list.where((a) => !a.isFullyPaid).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final matchesName = a.name.toLowerCase().contains(q);
        final matchesBuyer =
            a.buyerName != null && a.buyerName!.toLowerCase().contains(q);
        final matchesUid =
            a.ffUid != null && a.ffUid!.toLowerCase().contains(q);
        final matchesNotes =
            a.notes != null && a.notes!.toLowerCase().contains(q);
        return matchesName || matchesBuyer || matchesUid || matchesNotes;
      }).toList();
    }

    _filteredAccounts = list;
  }
}
