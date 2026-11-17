import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ff_id_model.dart';
import '../models/seller_model.dart';
import '../models/buyer_model.dart';
import '../models/sale_model.dart';
import '../models/transaction_model.dart';
import '../models/deo_model.dart';
import '../models/dashboard_stats_model.dart';

/// DatabaseHelper manages SQLite database operations, schema creation,
/// transactions, complex analytic queries, and password encryption/decryption.
class DatabaseHelper {
  static const String _databaseName = 'ff_id_manager.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableFfIds = 'ff_ids';
  static const String tableSellers = 'sellers';
  static const String tableBuyers = 'buyers';
  static const String tableSales = 'sales';
  static const String tableTransactions = 'transactions';
  static const String tableDeoAccounts = 'deo_accounts';
  static const String tableDeoPayments = 'deo_payments';
  static const String tableIdImages = 'id_images';

  // Encryption preference key
  static const String _prefKeySecret = 'ff_id_manager_enc_key_v1';
  static String? _cachedSecretKey;

  // Singleton instance
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  /// Initializes the SQLite database.
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // Warm up encryption key
    await _getOrInitSecretKey();

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  /// Enables SQLite foreign keys support.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Creates database tables and performance indices.
  Future<void> _createDB(Database db, int version) async {
    // 1. Sellers Table
    await db.execute('''
      CREATE TABLE $tableSellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        whatsapp TEXT,
        address TEXT,
        profile_image_path TEXT,
        notes TEXT,
        total_paid REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. Buyers Table
    await db.execute('''
      CREATE TABLE $tableBuyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        whatsapp TEXT,
        address TEXT,
        profile_image_path TEXT,
        notes TEXT,
        total_paid REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      );
    ''');

    // 3. Free Fire IDs Table
    await db.execute('''
      CREATE TABLE $tableFfIds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        login_email TEXT,
        login_password_encrypted TEXT,
        purchase_cost REAL NOT NULL,
        selling_price REAL,
        seller_id INTEGER,
        status TEXT NOT NULL DEFAULT 'available',
        purchase_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (seller_id) REFERENCES $tableSellers (id) ON DELETE SET NULL
      );
    ''');

    // 4. Sales Table
    await db.execute('''
      CREATE TABLE $tableSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ff_id_id INTEGER NOT NULL,
        buyer_id INTEGER NOT NULL,
        selling_price REAL NOT NULL,
        profit REAL NOT NULL,
        payment_method TEXT NOT NULL,
        amount_received REAL NOT NULL,
        remaining_balance REAL NOT NULL,
        sale_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ff_id_id) REFERENCES $tableFfIds (id) ON DELETE CASCADE,
        FOREIGN KEY (buyer_id) REFERENCES $tableBuyers (id) ON DELETE CASCADE
      );
    ''');

    // 5. Transactions Table
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        person_type TEXT NOT NULL,
        person_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        reference_number TEXT,
        notes TEXT,
        payment_proof_path TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // 6. DEO Accounts Table
    await db.execute('''
      CREATE TABLE $tableDeoAccounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buyer_id INTEGER,
        related_ff_id_id INTEGER,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (buyer_id) REFERENCES $tableBuyers (id) ON DELETE SET NULL,
        FOREIGN KEY (related_ff_id_id) REFERENCES $tableFfIds (id) ON DELETE SET NULL
      );
    ''');

    // 7. DEO Payments Table
    await db.execute('''
      CREATE TABLE $tableDeoPayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deo_account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_proof_path TEXT,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (deo_account_id) REFERENCES $tableDeoAccounts (id) ON DELETE CASCADE
      );
    ''');

    // 8. ID Images Table
    await db.execute('''
      CREATE TABLE $tableIdImages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ff_id_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ff_id_id) REFERENCES $tableFfIds (id) ON DELETE CASCADE
      );
    ''');

    // Performance Indices
    await db.execute('CREATE INDEX idx_ff_ids_uid ON $tableFfIds (uid);');
    await db.execute('CREATE INDEX idx_ff_ids_status ON $tableFfIds (status);');
    await db.execute('CREATE INDEX idx_ff_ids_seller ON $tableFfIds (seller_id);');
    await db.execute('CREATE INDEX idx_sales_buyer ON $tableSales (buyer_id);');
    await db.execute('CREATE INDEX idx_sales_ff_id ON $tableSales (ff_id_id);');
    await db.execute('CREATE INDEX idx_transactions_person ON $tableTransactions (person_type, person_id);');
    await db.execute('CREATE INDEX idx_transactions_date ON $tableTransactions (transaction_date);');
    await db.execute('CREATE INDEX idx_deo_payments_acc ON $tableDeoPayments (deo_account_id);');
    await db.execute('CREATE INDEX idx_id_images_ff ON $tableIdImages (ff_id_id);');
  }

  // ==========================================
  // ENCRYPTION & DECRYPTION (AES-like XOR with stored key)
  // ==========================================

  /// Retrieves or generates a 32-character persistent secret key in SharedPreferences.
  static Future<String> _getOrInitSecretKey() async {
    if (_cachedSecretKey != null && _cachedSecretKey!.isNotEmpty) {
      return _cachedSecretKey!;
    }
    final prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString(_prefKeySecret);
    if (key == null || key.isEmpty) {
      // Generate key based on timestamp and entropy
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      key = 'FF_SECURE_KEY_${timestamp}_x99AlphaMaster!';
      await prefs.setString(_prefKeySecret, key);
    }
    _cachedSecretKey = key;
    return key;
  }

  /// Encrypts plain text using XOR cipher with key stored in SharedPreferences,
  /// then encodes as Base64 string.
  Future<String> encryptPassword(String plainText) async {
    if (plainText.isEmpty) return '';
    final key = await _getOrInitSecretKey();
    return _xorProcess(plainText, key, isEncrypt: true);
  }

  /// Decrypts Base64 XOR cipher text using key stored in SharedPreferences.
  Future<String> decryptPassword(String cipherText) async {
    if (cipherText.isEmpty) return '';
    final key = await _getOrInitSecretKey();
    return _xorProcess(cipherText, key, isEncrypt: false);
  }

  /// Synchronous encryption using cached key (fallback to default if not yet initialized).
  String encryptPasswordSync(String plainText) {
    if (plainText.isEmpty) return '';
    final key = _cachedSecretKey ?? 'FF_DEFAULT_FALLBACK_KEY_32_CHARS!';
    return _xorProcess(plainText, key, isEncrypt: true);
  }

  /// Synchronous decryption using cached key.
  String decryptPasswordSync(String cipherText) {
    if (cipherText.isEmpty) return '';
    final key = _cachedSecretKey ?? 'FF_DEFAULT_FALLBACK_KEY_32_CHARS!';
    return _xorProcess(cipherText, key, isEncrypt: false);
  }

  static String _xorProcess(String input, String key, {required bool isEncrypt}) {
    try {
      final keyBytes = utf8.encode(key);
      if (isEncrypt) {
        final textBytes = utf8.encode(input);
        final resultBytes = Uint8List(textBytes.length);
        for (int i = 0; i < textBytes.length; i++) {
          resultBytes[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
        }
        return base64.encode(resultBytes);
      } else {
        final cipherBytes = base64.decode(input);
        final resultBytes = Uint8List(cipherBytes.length);
        for (int i = 0; i < cipherBytes.length; i++) {
          resultBytes[i] = cipherBytes[i] ^ keyBytes[i % keyBytes.length];
        }
        return utf8.decode(resultBytes);
      }
    } catch (_) {
      // In case of invalid base64 or legacy plaintext, return as-is
      return input;
    }
  }

  // ==========================================
  // FREE FIRE IDS CRUD & QUERIES
  // ==========================================

  /// Inserts a new Free Fire ID listing, optional plaintext password encryption,
  /// and associated images in a single transaction.
  Future<int> insertFfId(
    FfId ffId, {
    List<String>? imagePaths,
    String? plainPassword,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      String? encryptedPassword = ffId.loginPasswordEncrypted;
      if (plainPassword != null && plainPassword.isNotEmpty) {
        encryptedPassword = await encryptPassword(plainPassword);
      } else if (encryptedPassword != null && encryptedPassword.isNotEmpty) {
        // If passed as plain in loginPasswordEncrypted, make sure it's encrypted
        encryptedPassword = await encryptPassword(encryptedPassword);
      }

      final itemToInsert = ffId.copyWith(
        loginPasswordEncrypted: encryptedPassword,
        status: ffId.status.isEmpty ? 'available' : ffId.status,
      );

      final id = await txn.insert(
        tableFfIds,
        itemToInsert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final images = imagePaths ?? ffId.images;
      if (images.isNotEmpty) {
        for (final imgPath in images) {
          if (imgPath.trim().isNotEmpty) {
            await txn.insert(tableIdImages, {
              'ff_id_id': id,
              'image_path': imgPath.trim(),
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }
      return id;
    });
  }

  /// Updates an existing Free Fire ID listing, optionally updating images and password.
  Future<int> updateFfId(
    FfId ffId, {
    List<String>? newImagePaths,
    String? plainPassword,
  }) async {
    final db = await database;
    if (ffId.id == null) return 0;

    return await db.transaction((txn) async {
      String? encryptedPassword = ffId.loginPasswordEncrypted;
      if (plainPassword != null && plainPassword.isNotEmpty) {
        encryptedPassword = await encryptPassword(plainPassword);
      }

      final updatedFfId = ffId.copyWith(
        loginPasswordEncrypted: encryptedPassword,
        updatedAt: DateTime.now().toIso8601String(),
      );

      final count = await txn.update(
        tableFfIds,
        updatedFfId.toMap(),
        where: 'id = ?',
        whereArgs: [ffId.id],
      );

      if (newImagePaths != null) {
        await txn.delete(
          tableIdImages,
          where: 'ff_id_id = ?',
          whereArgs: [ffId.id],
        );
        for (final path in newImagePaths) {
          if (path.trim().isNotEmpty) {
            await txn.insert(tableIdImages, {
              'ff_id_id': ffId.id,
              'image_path': path.trim(),
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      return count;
    });
  }

  /// Deletes a Free Fire ID and all associated images.
  Future<int> deleteFfId(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableIdImages,
        where: 'ff_id_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        tableFfIds,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Retrieves a Free Fire ID by primary key with seller name and image paths.
  Future<FfId?> getFfIdById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT f.*, s.name AS seller_name,
        (SELECT GROUP_CONCAT(image_path, '||') FROM $tableIdImages WHERE ff_id_id = f.id) AS image_paths
      FROM $tableFfIds f
      LEFT JOIN $tableSellers s ON f.seller_id = s.id
      WHERE f.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return FfId.fromMap(results.first);
  }

  /// Retrieves an ID listing by in-game UID.
  Future<FfId?> getFfIdByUid(String uid) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT f.*, s.name AS seller_name,
        (SELECT GROUP_CONCAT(image_path, '||') FROM $tableIdImages WHERE ff_id_id = f.id) AS image_paths
      FROM $tableFfIds f
      LEFT JOIN $tableSellers s ON f.seller_id = s.id
      WHERE f.uid = ?
      LIMIT 1
    ''', [uid.trim()]);

    if (results.isEmpty) return null;
    return FfId.fromMap(results.first);
  }

  /// Retrieves all Free Fire IDs with optional filters:
  /// [status]: 'available', 'sold', or null for all.
  /// [searchQuery]: filters across UID, email, notes, or seller name.
  /// [sellerId]: filters by specific seller.
  /// [orderBy]: default is 'f.id DESC'.
  Future<List<FfId>> getAllFfIds({
    String? status,
    String? searchQuery,
    int? sellerId,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      whereClauses.add('LOWER(f.status) = ?');
      whereArgs.add(status.toLowerCase());
    }

    if (sellerId != null) {
      whereClauses.add('f.seller_id = ?');
      whereArgs.add(sellerId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (f.uid LIKE ? OR f.login_email LIKE ? OR f.notes LIKE ? OR s.name LIKE ?)
      ''');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 'f.id DESC';

    final results = await db.rawQuery('''
      SELECT f.*, s.name AS seller_name,
        (SELECT GROUP_CONCAT(image_path, '||') FROM $tableIdImages WHERE ff_id_id = f.id) AS image_paths
      FROM $tableFfIds f
      LEFT JOIN $tableSellers s ON f.seller_id = s.id
      $whereSql
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => FfId.fromMap(map)).toList();
  }

  /// Shortcut to retrieve all available IDs.
  Future<List<FfId>> getAvailableFfIds() async {
    return getAllFfIds(status: 'available');
  }

  /// Shortcut to retrieve all sold IDs.
  Future<List<FfId>> getSoldFfIds() async {
    return getAllFfIds(status: 'sold');
  }

  /// Updates status and optionally selling price of an ID.
  Future<int> updateFfIdStatus(
    int id,
    String status, {
    double? sellingPrice,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (sellingPrice != null) {
      values['selling_price'] = sellingPrice;
    }
    return await db.update(
      tableFfIds,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // ID IMAGES OPERATIONS
  // ==========================================

  Future<int> insertIdImage(int ffIdId, String imagePath) async {
    final db = await database;
    return await db.insert(tableIdImages, {
      'ff_id_id': ffIdId,
      'image_path': imagePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> insertIdImages(int ffIdId, List<String> imagePaths) async {
    final db = await database;
    final batch = db.batch();
    for (final path in imagePaths) {
      if (path.trim().isNotEmpty) {
        batch.insert(tableIdImages, {
          'ff_id_id': ffIdId,
          'image_path': path.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getImagesForFfId(int ffIdId) async {
    final db = await database;
    final results = await db.query(
      tableIdImages,
      columns: ['image_path'],
      where: 'ff_id_id = ?',
      whereArgs: [ffIdId],
      orderBy: 'id ASC',
    );
    return results.map((row) => row['image_path'] as String).toList();
  }

  Future<int> deleteIdImage(int id) async {
    final db = await database;
    return await db.delete(
      tableIdImages,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteImagesForFfId(int ffIdId) async {
    final db = await database;
    return await db.delete(
      tableIdImages,
      where: 'ff_id_id = ?',
      whereArgs: [ffIdId],
    );
  }

  // ==========================================
  // SELLERS CRUD & BALANCES
  // ==========================================

  Future<int> insertSeller(Seller seller) async {
    final db = await database;
    return await db.insert(tableSellers, seller.toMap());
  }

  Future<int> updateSeller(Seller seller) async {
    final db = await database;
    if (seller.id == null) return 0;
    return await db.update(
      tableSellers,
      seller.toMap(),
      where: 'id = ?',
      whereArgs: [seller.id],
    );
  }

  Future<int> deleteSeller(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Nullify seller_id on associated ff_ids
      await txn.update(
        tableFfIds,
        {'seller_id': null},
        where: 'seller_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        tableSellers,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Retrieves a seller with computed total IDs supplied and purchase value.
  Future<Seller?> getSellerById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT s.*,
        COUNT(f.id) AS total_ids_supplied,
        COALESCE(SUM(f.purchase_cost), 0.0) AS total_purchase_value
      FROM $tableSellers s
      LEFT JOIN $tableFfIds f ON s.id = f.seller_id
      WHERE s.id = ?
      GROUP BY s.id
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return Seller.fromMap(results.first);
  }

  /// Retrieves all sellers with computed stats and search filter.
  Future<List<Seller>> getAllSellers({
    String? searchQuery,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (s.name LIKE ? OR s.phone LIKE ? OR s.whatsapp LIKE ? OR s.address LIKE ?)
      ''');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 's.id DESC';

    final results = await db.rawQuery('''
      SELECT s.*,
        COUNT(f.id) AS total_ids_supplied,
        COALESCE(SUM(f.purchase_cost), 0.0) AS total_purchase_value
      FROM $tableSellers s
      LEFT JOIN $tableFfIds f ON s.id = f.seller_id
      $whereSql
      GROUP BY s.id
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => Seller.fromMap(map)).toList();
  }

  /// Recalculates total paid to seller by aggregating transactions.
  Future<void> recalculateSellerTotalPaid(int sellerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE
            WHEN type IN ('seller_payment', 'seller_advance') THEN amount
            WHEN type = 'refund' THEN -amount
            ELSE 0
          END
        ), 0.0) AS total_paid
      FROM $tableTransactions
      WHERE person_type = 'seller' AND person_id = ?
    ''', [sellerId]);

    final totalPaid =
        (result.first['total_paid'] as num?)?.toDouble() ?? 0.0;

    await db.update(
      tableSellers,
      {'total_paid': totalPaid},
      where: 'id = ?',
      whereArgs: [sellerId],
    );
  }

  // ==========================================
  // BUYERS CRUD & BALANCES
  // ==========================================

  Future<int> insertBuyer(Buyer buyer) async {
    final db = await database;
    return await db.insert(tableBuyers, buyer.toMap());
  }

  Future<int> updateBuyer(Buyer buyer) async {
    final db = await database;
    if (buyer.id == null) return 0;
    return await db.update(
      tableBuyers,
      buyer.toMap(),
      where: 'id = ?',
      whereArgs: [buyer.id],
    );
  }

  Future<int> deleteBuyer(int id) async {
    final db = await database;
    return await db.delete(
      tableBuyers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieves a buyer with computed total IDs purchased, sales value, and remaining balance.
  Future<Buyer?> getBuyerById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT b.*,
        COUNT(sa.id) AS total_ids_purchased,
        COALESCE(SUM(sa.selling_price), 0.0) AS total_purchase_value,
        COALESCE(SUM(sa.remaining_balance), 0.0) AS remaining_due
      FROM $tableBuyers b
      LEFT JOIN $tableSales sa ON b.id = sa.buyer_id
      WHERE b.id = ?
      GROUP BY b.id
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return Buyer.fromMap(results.first);
  }

  /// Retrieves all buyers with computed stats and search filter.
  Future<List<Buyer>> getAllBuyers({
    String? searchQuery,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (b.name LIKE ? OR b.phone LIKE ? OR b.whatsapp LIKE ? OR b.address LIKE ?)
      ''');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 'b.id DESC';

    final results = await db.rawQuery('''
      SELECT b.*,
        COUNT(sa.id) AS total_ids_purchased,
        COALESCE(SUM(sa.selling_price), 0.0) AS total_purchase_value,
        COALESCE(SUM(sa.remaining_balance), 0.0) AS remaining_due
      FROM $tableBuyers b
      LEFT JOIN $tableSales sa ON b.id = sa.buyer_id
      $whereSql
      GROUP BY b.id
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => Buyer.fromMap(map)).toList();
  }

  /// Recalculates total paid by buyer from sales down-payments and buyer payment transactions.
  Future<void> recalculateBuyerTotalPaid(int buyerId) async {
    final db = await database;

    // 1. Initial down-payments in sales
    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_received), 0.0) AS total_from_sales
      FROM $tableSales
      WHERE buyer_id = ?
    ''', [buyerId]);
    final totalFromSales =
        (salesResult.first['total_from_sales'] as num?)?.toDouble() ?? 0.0;

    // 2. Subsequent payments from transactions
    final txnResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE
            WHEN type IN ('buyer_payment', 'buyer_advance') THEN amount
            WHEN type = 'refund' THEN -amount
            ELSE 0
          END
        ), 0.0) AS total_from_txns
      FROM $tableTransactions
      WHERE person_type = 'buyer' AND person_id = ?
    ''', [buyerId]);
    final totalFromTxns =
        (txnResult.first['total_from_txns'] as num?)?.toDouble() ?? 0.0;

    final totalPaid = totalFromSales + totalFromTxns;

    await db.update(
      tableBuyers,
      {'total_paid': totalPaid},
      where: 'id = ?',
      whereArgs: [buyerId],
    );
  }

  // ==========================================
  // SALES OPERATIONS
  // ==========================================

  /// Records a new sale in a single atomic database transaction:
  /// 1. Inserts the sale record.
  /// 2. Updates the Free Fire ID status to 'sold' and sets its selling_price.
  /// 3. If amountReceived > 0, records a transaction entry.
  /// 4. Updates buyer's total_paid.
  Future<Sale> recordSale(Sale sale, {String? paymentProofPath}) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Insert sale record
      final saleId = await txn.insert(tableSales, sale.toMap());

      // 2. Mark FF ID as sold
      await txn.update(
        tableFfIds,
        {
          'status': 'sold',
          'selling_price': sale.sellingPrice,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sale.ffIdId],
      );

      // 3. If down-payment was received, record transaction
      if (sale.amountReceived > 0) {
        await txn.insert(tableTransactions, {
          'type': 'buyer_payment',
          'person_type': 'buyer',
          'person_id': sale.buyerId,
          'amount': sale.amountReceived,
          'payment_method': sale.paymentMethod,
          'reference_number': 'SALE-#$saleId',
          'notes': 'Sale payment for ID #${sale.ffIdId} (Sale #$saleId)',
          'payment_proof_path': paymentProofPath,
          'transaction_date': sale.saleDate,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Update buyer total_paid
      await txn.rawUpdate('''
        UPDATE $tableBuyers
        SET total_paid = total_paid + ?
        WHERE id = ?
      ''', [sale.amountReceived, sale.buyerId]);

      return sale.copyWith(id: saleId);
    });
  }

  /// Retrieves a sale by ID with joined FF UID and buyer details.
  Future<Sale?> getSaleById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT sa.*, f.uid AS ff_uid, f.purchase_cost AS purchase_cost,
             b.name AS buyer_name, b.phone AS buyer_phone
      FROM $tableSales sa
      JOIN $tableFfIds f ON sa.ff_id_id = f.id
      JOIN $tableBuyers b ON sa.buyer_id = b.id
      WHERE sa.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  /// Retrieves all sales with optional filters (search, buyer, date range).
  Future<List<Sale>> getAllSales({
    String? searchQuery,
    int? buyerId,
    String? fromDate,
    String? toDate,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (buyerId != null) {
      whereClauses.add('sa.buyer_id = ?');
      whereArgs.add(buyerId);
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      whereClauses.add('sa.sale_date >= ?');
      whereArgs.add(fromDate);
    }

    if (toDate != null && toDate.isNotEmpty) {
      whereClauses.add('sa.sale_date <= ?');
      whereArgs.add(toDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (f.uid LIKE ? OR b.name LIKE ? OR b.phone LIKE ? OR sa.notes LIKE ?)
      ''');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 'sa.id DESC';

    final results = await db.rawQuery('''
      SELECT sa.*, f.uid AS ff_uid, f.purchase_cost AS purchase_cost,
             b.name AS buyer_name, b.phone AS buyer_phone
      FROM $tableSales sa
      JOIN $tableFfIds f ON sa.ff_id_id = f.id
      JOIN $tableBuyers b ON sa.buyer_id = b.id
      $whereSql
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => Sale.fromMap(map)).toList();
  }

  /// Deletes a sale, rolls back FF ID status to 'available', and adjusts buyer payments.
  Future<bool> deleteSale(int saleId) async {
    final db = await database;
    return await db.transaction((txn) async {
      final sales = await txn.query(
        tableSales,
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (sales.isEmpty) return false;

      final sale = Sale.fromMap(sales.first);

      // Revert FF ID to available
      await txn.update(
        tableFfIds,
        {
          'status': 'available',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sale.ffIdId],
      );

      // Revert buyer total_paid
      if (sale.amountReceived > 0) {
        await txn.rawUpdate('''
          UPDATE $tableBuyers
          SET total_paid = MAX(0.0, total_paid - ?)
          WHERE id = ?
        ''', [sale.amountReceived, sale.buyerId]);

        // Remove linked transaction if present
        await txn.delete(
          tableTransactions,
          where: 'reference_number = ?',
          whereArgs: ['SALE-#$saleId'],
        );
      }

      // Delete sale row
      await txn.delete(
        tableSales,
        where: 'id = ?',
        whereArgs: [saleId],
      );

      return true;
    });
  }

  // ==========================================
  // TRANSACTIONS OPERATIONS
  // ==========================================

  /// Inserts a transaction and atomically updates corresponding buyer/seller balances.
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;

    return await db.transaction((txn) async {
      final id = await txn.insert(tableTransactions, transaction.toMap());

      // Update person total_paid
      if (transaction.isSellerTransaction) {
        double delta = 0.0;
        if (transaction.type == 'seller_payment' ||
            transaction.type == 'seller_advance') {
          delta = transaction.amount;
        } else if (transaction.type == 'refund') {
          delta = -transaction.amount;
        }
        if (delta != 0) {
          await txn.rawUpdate('''
            UPDATE $tableSellers
            SET total_paid = MAX(0.0, total_paid + ?)
            WHERE id = ?
          ''', [delta, transaction.personId]);
        }
      } else if (transaction.isBuyerTransaction) {
        double delta = 0.0;
        if (transaction.type == 'buyer_payment' ||
            transaction.type == 'buyer_advance') {
          delta = transaction.amount;
          // Apply payment to unpaid sales if available
          await _applyBuyerPaymentToOutstandingSalesTxn(
            txn,
            transaction.personId,
            transaction.amount,
          );
        } else if (transaction.type == 'refund') {
          delta = -transaction.amount;
        }
        if (delta != 0) {
          await txn.rawUpdate('''
            UPDATE $tableBuyers
            SET total_paid = MAX(0.0, total_paid + ?)
            WHERE id = ?
          ''', [delta, transaction.personId]);
        }
      }

      return id;
    });
  }

  /// Helper to apply incoming buyer payment toward unpaid sales balances.
  Future<void> _applyBuyerPaymentToOutstandingSalesTxn(
    Transaction txn,
    int buyerId,
    double paymentAmount,
  ) async {
    if (paymentAmount <= 0) return;

    final unpaidSales = await txn.query(
      tableSales,
      where: 'buyer_id = ? AND remaining_balance > 0.001',
      orderBy: 'id ASC',
    );

    double remainingToDeduct = paymentAmount;
    for (final saleRow in unpaidSales) {
      if (remainingToDeduct <= 0) break;
      final saleId = saleRow['id'] as int;
      final currentBalance = (saleRow['remaining_balance'] as num).toDouble();
      final currentReceived = (saleRow['amount_received'] as num).toDouble();

      final deduction =
          remainingToDeduct >= currentBalance ? currentBalance : remainingToDeduct;
      final newBalance = currentBalance - deduction;
      final newReceived = currentReceived + deduction;

      await txn.update(
        tableSales,
        {
          'remaining_balance': newBalance,
          'amount_received': newReceived,
        },
        where: 'id = ?',
        whereArgs: [saleId],
      );

      remainingToDeduct -= deduction;
    }
  }

  /// Retrieves a transaction by ID with joined person name.
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT t.*,
        CASE
          WHEN t.person_type = 'seller' THEN (SELECT name FROM $tableSellers WHERE id = t.person_id)
          WHEN t.person_type = 'buyer' THEN (SELECT name FROM $tableBuyers WHERE id = t.person_id)
          ELSE NULL
        END AS person_name,
        CASE
          WHEN t.person_type = 'seller' THEN (SELECT phone FROM $tableSellers WHERE id = t.person_id)
          WHEN t.person_type = 'buyer' THEN (SELECT phone FROM $tableBuyers WHERE id = t.person_id)
          ELSE NULL
        END AS person_phone
      FROM $tableTransactions t
      WHERE t.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return TransactionModel.fromMap(results.first);
  }

  /// Retrieves all transactions with optional filtering and joined person details.
  Future<List<TransactionModel>> getAllTransactions({
    String? personType,
    int? personId,
    String? type,
    String? fromDate,
    String? toDate,
    String? searchQuery,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (personType != null && personType.isNotEmpty) {
      whereClauses.add('LOWER(t.person_type) = ?');
      whereArgs.add(personType.toLowerCase());
    }

    if (personId != null) {
      whereClauses.add('t.person_id = ?');
      whereArgs.add(personId);
    }

    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      whereClauses.add('LOWER(t.type) = ?');
      whereArgs.add(type.toLowerCase());
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      whereClauses.add('t.transaction_date >= ?');
      whereArgs.add(fromDate);
    }

    if (toDate != null && toDate.isNotEmpty) {
      whereClauses.add('t.transaction_date <= ?');
      whereArgs.add(toDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (t.notes LIKE ? OR t.reference_number LIKE ? OR t.payment_method LIKE ?)
      ''');
      whereArgs.addAll([query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 't.id DESC';

    final results = await db.rawQuery('''
      SELECT t.*,
        CASE
          WHEN t.person_type = 'seller' THEN (SELECT name FROM $tableSellers WHERE id = t.person_id)
          WHEN t.person_type = 'buyer' THEN (SELECT name FROM $tableBuyers WHERE id = t.person_id)
          ELSE NULL
        END AS person_name,
        CASE
          WHEN t.person_type = 'seller' THEN (SELECT phone FROM $tableSellers WHERE id = t.person_id)
          WHEN t.person_type = 'buyer' THEN (SELECT phone FROM $tableBuyers WHERE id = t.person_id)
          ELSE NULL
        END AS person_phone
      FROM $tableTransactions t
      $whereSql
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Deletes a transaction and recalculates corresponding balances.
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final list = await txn.query(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (list.isEmpty) return 0;
      final transaction = TransactionModel.fromMap(list.first);

      final count = await txn.delete(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Recalculate balances
      if (transaction.isSellerTransaction) {
        await recalculateSellerTotalPaid(transaction.personId);
      } else if (transaction.isBuyerTransaction) {
        await recalculateBuyerTotalPaid(transaction.personId);
      }

      return count;
    });
  }

  // ==========================================
  // DEO ACCOUNTS & PAYMENTS CRUD
  // ==========================================

  Future<int> insertDeoAccount(DeoAccount account) async {
    final db = await database;
    return await db.insert(tableDeoAccounts, account.toMap());
  }

  Future<int> updateDeoAccount(DeoAccount account) async {
    final db = await database;
    if (account.id == null) return 0;
    return await db.update(
      tableDeoAccounts,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteDeoAccount(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableDeoPayments,
        where: 'deo_account_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        tableDeoAccounts,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Retrieves a DEO account by ID with payments list and joined details.
  Future<DeoAccount?> getDeoAccountById(int id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT d.*, b.name AS buyer_name, b.phone AS buyer_phone, f.uid AS ff_uid
      FROM $tableDeoAccounts d
      LEFT JOIN $tableBuyers b ON d.buyer_id = b.id
      LEFT JOIN $tableFfIds f ON d.related_ff_id_id = f.id
      WHERE d.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;

    final payments = await getPaymentsForDeoAccount(id);
    return DeoAccount.fromMap(results.first, payments: payments);
  }

  /// Retrieves all DEO accounts with buyer/FF details and search filters.
  Future<List<DeoAccount>> getAllDeoAccounts({
    String? searchQuery,
    bool? onlyUnpaid,
    String? orderBy,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (onlyUnpaid == true) {
      whereClauses.add('(d.total_amount - d.paid_amount) > 0.001');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('''
        (d.name LIKE ? OR b.name LIKE ? OR f.uid LIKE ? OR d.notes LIKE ?)
      ''');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = orderBy ?? 'd.id DESC';

    final results = await db.rawQuery('''
      SELECT d.*, b.name AS buyer_name, b.phone AS buyer_phone, f.uid AS ff_uid
      FROM $tableDeoAccounts d
      LEFT JOIN $tableBuyers b ON d.buyer_id = b.id
      LEFT JOIN $tableFfIds f ON d.related_ff_id_id = f.id
      $whereSql
      ORDER BY $orderSql
    ''', whereArgs);

    return results.map((map) => DeoAccount.fromMap(map)).toList();
  }

  /// Records a DEO payment and updates account paid_amount.
  Future<DeoPayment> recordDeoPayment(
    DeoPayment payment, {
    bool recordAsBuyerTransaction = false,
  }) async {
    final db = await database;

    return await db.transaction((txn) async {
      final id = await txn.insert(tableDeoPayments, payment.toMap());

      // Update paid_amount on DEO account
      await txn.rawUpdate('''
        UPDATE $tableDeoAccounts
        SET paid_amount = paid_amount + ?
        WHERE id = ?
      ''', [payment.amount, payment.deoAccountId]);

      // If linked to a buyer and requested, record a transaction
      if (recordAsBuyerTransaction) {
        final accounts = await txn.query(
          tableDeoAccounts,
          where: 'id = ?',
          whereArgs: [payment.deoAccountId],
          limit: 1,
        );
        if (accounts.isNotEmpty && accounts.first['buyer_id'] != null) {
          final buyerId = accounts.first['buyer_id'] as int;
          await txn.insert(tableTransactions, {
            'type': 'buyer_payment',
            'person_type': 'buyer',
            'person_id': buyerId,
            'amount': payment.amount,
            'payment_method': 'Cash/DEO',
            'reference_number': 'DEO-#$id',
            'notes': 'DEO Installment payment for Account #${payment.deoAccountId}',
            'payment_proof_path': payment.paymentProofPath,
            'transaction_date': payment.paymentDate,
            'created_at': DateTime.now().toIso8601String(),
          });
          await txn.rawUpdate('''
            UPDATE $tableBuyers
            SET total_paid = total_paid + ?
            WHERE id = ?
          ''', [payment.amount, buyerId]);
        }
      }

      return payment.copyWith(id: id);
    });
  }

  /// Retrieves all payments for a DEO account.
  Future<List<DeoPayment>> getPaymentsForDeoAccount(int deoAccountId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT p.*, d.name AS account_name
      FROM $tableDeoPayments p
      JOIN $tableDeoAccounts d ON p.deo_account_id = d.id
      WHERE p.deo_account_id = ?
      ORDER BY p.id DESC
    ''', [deoAccountId]);

    return results.map((map) => DeoPayment.fromMap(map)).toList();
  }

  /// Deletes a DEO payment and deducts it from the account's paid_amount.
  Future<int> deleteDeoPayment(int paymentId) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query(
        tableDeoPayments,
        where: 'id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );
      if (rows.isEmpty) return 0;

      final payment = DeoPayment.fromMap(rows.first);

      await txn.rawUpdate('''
        UPDATE $tableDeoAccounts
        SET paid_amount = MAX(0.0, paid_amount - ?)
        WHERE id = ?
      ''', [payment.amount, payment.deoAccountId]);

      return await txn.delete(
        tableDeoPayments,
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    });
  }

  // ==========================================
  // DASHBOARD STATS & ANALYTICS QUERIES
  // ==========================================

  /// Computes comprehensive dashboard statistics including inventory counts,
  /// sales totals, profit, receivables, payables, and DEO balances.
  Future<DashboardStats> getDashboardStats() async {
    final db = await database;

    // 1. Inventory counts
    final inventoryResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_ids,
        SUM(CASE WHEN LOWER(status) = 'available' THEN 1 ELSE 0 END) AS available_ids,
        SUM(CASE WHEN LOWER(status) = 'sold' THEN 1 ELSE 0 END) AS sold_ids,
        COALESCE(SUM(purchase_cost), 0.0) AS total_investment
      FROM $tableFfIds
    ''');
    final invRow = inventoryResult.first;
    final totalIds = (invRow['total_ids'] as num?)?.toInt() ?? 0;
    final availableIds = (invRow['available_ids'] as num?)?.toInt() ?? 0;
    final soldIds = (invRow['sold_ids'] as num?)?.toInt() ?? 0;
    final totalInvestment =
        (invRow['total_investment'] as num?)?.toDouble() ?? 0.0;

    // 2. Sales and profit totals
    final salesResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(selling_price), 0.0) AS total_sales,
        COALESCE(SUM(profit), 0.0) AS total_profit,
        COALESCE(SUM(remaining_balance), 0.0) AS total_outstanding_balance
      FROM $tableSales
    ''');
    final salesRow = salesResult.first;
    final totalSales = (salesRow['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = (salesRow['total_profit'] as num?)?.toDouble() ?? 0.0;
    final totalOutstandingBalance =
        (salesRow['total_outstanding_balance'] as num?)?.toDouble() ?? 0.0;

    // 3. Transactions payments breakdown
    final txnResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE
            WHEN person_type = 'seller' AND type IN ('seller_payment', 'seller_advance') THEN amount
            WHEN person_type = 'seller' AND type = 'refund' THEN -amount
            ELSE 0
          END
        ), 0.0) AS total_seller_payments,
        COALESCE(SUM(
          CASE
            WHEN person_type = 'buyer' AND type IN ('buyer_payment', 'buyer_advance') THEN amount
            WHEN person_type = 'buyer' AND type = 'refund' THEN -amount
            ELSE 0
          END
        ), 0.0) AS total_buyer_txn_payments
      FROM $tableTransactions
    ''');
    final txnRow = txnResult.first;
    final totalSellerPayments =
        (txnRow['total_seller_payments'] as num?)?.toDouble() ?? 0.0;

    // Add sales down-payments to total buyer payments
    final salesDownPaymentsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_received), 0.0) AS total_down_payments FROM $tableSales
    ''');
    final totalDownPayments =
        (salesDownPaymentsResult.first['total_down_payments'] as num?)
                ?.toDouble() ??
            0.0;
    final totalBuyerPayments =
        ((txnRow['total_buyer_txn_payments'] as num?)?.toDouble() ?? 0.0) +
            totalDownPayments;

    // 4. Total payable to sellers (Supplied ID costs - Total seller payments)
    final sellerSuppliedCostResult = await db.rawQuery('''
      SELECT COALESCE(SUM(purchase_cost), 0.0) AS total_supplied_cost
      FROM $tableFfIds
      WHERE seller_id IS NOT NULL
    ''');
    final totalSuppliedCost =
        (sellerSuppliedCostResult.first['total_supplied_cost'] as num?)
                ?.toDouble() ??
            0.0;
    final totalPayableToSellers =
        (totalSuppliedCost - totalSellerPayments) > 0
            ? (totalSuppliedCost - totalSellerPayments)
            : 0.0;

    // 5. DEO Accounts stats
    final deoResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total_amount), 0.0) AS deo_total,
        COALESCE(SUM(paid_amount), 0.0) AS deo_paid
      FROM $tableDeoAccounts
    ''');
    final deoRow = deoResult.first;
    final deoTotal = (deoRow['deo_total'] as num?)?.toDouble() ?? 0.0;
    final deoPaid = (deoRow['deo_paid'] as num?)?.toDouble() ?? 0.0;
    final deoRemaining = (deoTotal - deoPaid) > 0 ? (deoTotal - deoPaid) : 0.0;

    // 6. Monthly chart analytics (last 6-12 months)
    final monthlyResult = await db.rawQuery('''
      SELECT
        SUBSTR(sale_date, 1, 7) AS month,
        COALESCE(SUM(selling_price), 0.0) AS sales,
        COALESCE(SUM(profit), 0.0) AS profit,
        COUNT(id) AS count
      FROM $tableSales
      GROUP BY SUBSTR(sale_date, 1, 7)
      ORDER BY month ASC
      LIMIT 12
    ''');
    final monthlyStats =
        monthlyResult.map((m) => MonthlyStat.fromMap(m)).toList();

    return DashboardStats(
      totalIds: totalIds,
      availableIds: availableIds,
      soldIds: soldIds,
      totalInvestment: totalInvestment,
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalSellerPayments: totalSellerPayments,
      totalBuyerPayments: totalBuyerPayments,
      totalOutstandingBalance: totalOutstandingBalance,
      totalPayableToSellers: totalPayableToSellers,
      deoTotal: deoTotal,
      deoPaid: deoPaid,
      deoRemaining: deoRemaining,
      monthlyStats: monthlyStats,
    );
  }

  /// Retrieves breakdown of sales categorized by payment method.
  Future<List<Map<String, dynamic>>> getPaymentMethodBreakdown() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        payment_method,
        COUNT(*) AS total_sales_count,
        COALESCE(SUM(selling_price), 0.0) AS total_amount
      FROM $tableSales
      GROUP BY payment_method
      ORDER BY total_amount DESC
    ''');
  }

  /// Retrieves top buyers by purchase volume.
  Future<List<Map<String, dynamic>>> getTopBuyers({int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.id, b.name, b.phone,
        COUNT(sa.id) AS total_ids,
        COALESCE(SUM(sa.selling_price), 0.0) AS total_spent,
        COALESCE(SUM(sa.remaining_balance), 0.0) AS remaining_due
      FROM $tableBuyers b
      JOIN $tableSales sa ON b.id = sa.buyer_id
      GROUP BY b.id
      ORDER BY total_spent DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Retrieves top sellers by IDs supplied.
  Future<List<Map<String, dynamic>>> getTopSellers({int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.id, s.name, s.phone,
        COUNT(f.id) AS total_ids,
        COALESCE(SUM(f.purchase_cost), 0.0) AS total_cost
      FROM $tableSellers s
      JOIN $tableFfIds f ON s.id = f.seller_id
      GROUP BY s.id
      ORDER BY total_cost DESC
      LIMIT ?
    ''', [limit]);
  }

  // ==========================================
  // MAINTENANCE & UTILITIES
  // ==========================================

  /// Closes database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clears all table records (useful for debugging or data reset).
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableIdImages);
      await txn.delete(tableSales);
      await txn.delete(tableDeoPayments);
      await txn.delete(tableDeoAccounts);
      await txn.delete(tableTransactions);
      await txn.delete(tableFfIds);
      await txn.delete(tableBuyers);
      await txn.delete(tableSellers);
    });
  }
}
