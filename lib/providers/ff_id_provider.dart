import 'package:flutter/foundation.dart';
import 'package:ff_id_manager/database/database_helper.dart';
import 'package:ff_id_manager/models/ff_id_model.dart';

/// Provider for managing Free Fire ID inventory, filters, and image attachments.
class FfIdProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<FfIdModel> _ids = [];
  List<FfIdModel> _filteredIds = [];

  String _currentStatus = 'all'; // 'all', 'available', 'sold'
  String _searchQuery = '';
  int? _sellerIdFilter;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FfIdModel> get ids => _ids;
  List<FfIdModel> get filteredIds => _filteredIds;
  String get currentStatus => _currentStatus;
  String get searchQuery => _searchQuery;
  int? get sellerIdFilter => _sellerIdFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get availableCount =>
      _ids.where((item) => item.status.toLowerCase() == 'available').length;
  int get soldCount =>
      _ids.where((item) => item.status.toLowerCase() == 'sold').length;

  /// Loads all Free Fire IDs from the database.
  Future<void> loadIds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ids = await _dbHelper.getAllFfIds(orderBy: 'f.id DESC');
      _applyLocalFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load Free Fire IDs: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new Free Fire ID listing with optional plaintext password and images.
  Future<int?> addId(
    FfIdModel idModel, {
    List<String>? imagePaths,
    String? plainPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedId = await _dbHelper.insertFfId(
        idModel,
        imagePaths: imagePaths,
        plainPassword: plainPassword,
      );

      // Reload full inventory to keep joined fields intact
      await loadIds();
      return insertedId;
    } catch (e) {
      _errorMessage = 'Failed to add Free Fire ID: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing Free Fire ID listing.
  Future<bool> updateId(
    FfIdModel idModel, {
    List<String>? newImagePaths,
    String? plainPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rowsAffected = await _dbHelper.updateFfId(
        idModel,
        newImagePaths: newImagePaths,
        plainPassword: plainPassword,
      );

      await loadIds();
      return rowsAffected > 0;
    } catch (e) {
      _errorMessage = 'Failed to update Free Fire ID: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a Free Fire ID and associated attachments.
  Future<bool> deleteId(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _dbHelper.deleteFfId(id);
      if (count > 0) {
        _ids.removeWhere((item) => item.id == id);
        _applyLocalFilters();
      }
      return count > 0;
    } catch (e) {
      _errorMessage = 'Failed to delete Free Fire ID: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates status ('available' or 'sold') and optional selling price.
  Future<bool> updateIdStatus(
    int id,
    String status, {
    double? sellingPrice,
  }) async {
    try {
      final count = await _dbHelper.updateFfIdStatus(
        id,
        status,
        sellingPrice: sellingPrice,
      );

      if (count > 0) {
        await loadIds();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update ID status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Filters ID listings by status: 'all', 'available', or 'sold'.
  void filterByStatus(String status) {
    _currentStatus = status.trim().toLowerCase();
    _applyLocalFilters();
    notifyListeners();
  }

  /// Filters ID listings by UID, login email, seller, or notes.
  void searchByUid(String query) {
    _searchQuery = query.trim();
    _applyLocalFilters();
    notifyListeners();
  }

  /// Filters ID listings by specific seller ID.
  void filterBySeller(int? sellerId) {
    _sellerIdFilter = sellerId;
    _applyLocalFilters();
    notifyListeners();
  }

  /// Clears all active filters.
  void clearFilters() {
    _currentStatus = 'all';
    _searchQuery = '';
    _sellerIdFilter = null;
    _applyLocalFilters();
    notifyListeners();
  }

  /// Retrieves an ID by its database primary key.
  FfIdModel? getById(int id) {
    try {
      return _ids.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Loads image file paths associated with a given Free Fire ID.
  Future<List<String>> loadIdImages(int idId) async {
    try {
      return await _dbHelper.getImagesForFfId(idId);
    } catch (e) {
      _errorMessage = 'Failed to load ID images: ${e.toString()}';
      return [];
    }
  }

  /// Decrypts encrypted login password for display to authorized user.
  Future<String> decryptPassword(String cipherText) async {
    try {
      return await _dbHelper.decryptPassword(cipherText);
    } catch (_) {
      return cipherText;
    }
  }

  /// Applies in-memory filters for ultra-fast, smooth search and tabs.
  void _applyLocalFilters() {
    List<FfIdModel> list = List.from(_ids);

    // 1. Status Filter
    if (_currentStatus != 'all' && _currentStatus.isNotEmpty) {
      list = list
          .where((item) => item.status.toLowerCase() == _currentStatus)
          .toList();
    }

    // 2. Seller ID Filter
    if (_sellerIdFilter != null) {
      list = list.where((item) => item.sellerId == _sellerIdFilter).toList();
    }

    // 3. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final matchesUid = item.uid.toLowerCase().contains(q);
        final matchesEmail =
            item.loginEmail != null && item.loginEmail!.toLowerCase().contains(q);
        final matchesSeller =
            item.sellerName != null && item.sellerName!.toLowerCase().contains(q);
        final matchesNotes =
            item.notes != null && item.notes!.toLowerCase().contains(q);
        return matchesUid || matchesEmail || matchesSeller || matchesNotes;
      }).toList();
    }

    _filteredIds = list;
  }
}
