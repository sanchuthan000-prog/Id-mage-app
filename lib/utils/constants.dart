/// Application-wide constants for Free Fire ID Sale Manager.

class AppConstants {
  // App Metadata
  static const String appName = 'FF ID Manager';
  static const String appSubTitle = 'Free Fire ID & Sales Ledger';
  static const String appVersion = '1.0.0';

  // Geographic & Timezone
  static const String timeZoneColombo = 'Asia/Colombo';
  static const Duration colomboUtcOffset = Duration(hours: 5, minutes: 30);

  // Currency
  static const String defaultCurrencySymbol = 'Rs.';
  static const String defaultCurrencyCode = 'LKR';

  // SQLite Database
  static const String databaseName = 'ff_id_manager.db';
  static const int databaseVersion = 1;
}

/// Payment Methods supported across all transactions and sales.
class PaymentMethods {
  static const String cash = 'Cash';
  static const String bankTransfer = 'Bank Transfer';
  static const String ezCash = 'EzCash';
  static const String mCash = 'mCash';
  static const String binanceCrypto = 'Binance / Crypto';
  static const String other = 'Other';

  static const List<String> all = [
    cash,
    bankTransfer,
    ezCash,
    mCash,
    binanceCrypto,
    other,
  ];
}

/// Transaction Types for financial records.
class TransactionTypes {
  static const String sellerPayment = 'seller_payment';
  static const String buyerPayment = 'buyer_payment';
  static const String sellerAdvance = 'seller_advance';
  static const String buyerAdvance = 'buyer_advance';
  static const String refund = 'refund';
  static const String adjustment = 'adjustment';

  static const List<String> all = [
    sellerPayment,
    buyerPayment,
    sellerAdvance,
    buyerAdvance,
    refund,
    adjustment,
  ];

  static const List<String> sellerTypes = [
    sellerPayment,
    sellerAdvance,
    adjustment,
  ];

  static const List<String> buyerTypes = [
    buyerPayment,
    buyerAdvance,
    refund,
    adjustment,
  ];

  static String getDisplayName(String type) {
    switch (type.toLowerCase()) {
      case sellerPayment:
        return 'Seller Payment';
      case buyerPayment:
        return 'Buyer Payment';
      case sellerAdvance:
        return 'Seller Advance';
      case buyerAdvance:
        return 'Buyer Advance';
      case refund:
        return 'Refund';
      case adjustment:
        return 'Balance Adjustment';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  static bool isCredit(String type) {
    // Money received by the business
    return type == buyerPayment || type == buyerAdvance;
  }

  static bool isDebit(String type) {
    // Money paid out by the business
    return type == sellerPayment || type == sellerAdvance || type == refund;
  }
}

/// Free Fire ID Inventory Statuses
class IdStatuses {
  static const String available = 'available';
  static const String sold = 'sold';

  static const List<String> all = [
    available,
    sold,
  ];
}

/// Person types used in transactions and contacts
class PersonTypes {
  static const String seller = 'seller';
  static const String buyer = 'buyer';

  static const List<String> all = [
    seller,
    buyer,
  ];
}

/// Payment Statuses
class PaymentStatuses {
  static const String paid = 'paid';
  static const String partial = 'partial';
  static const String unpaid = 'unpaid';

  static const List<String> all = [
    paid,
    partial,
    unpaid,
  ];
}

/// Common Account Platforms used for Free Fire login credentials
class AccountLoginPlatforms {
  static const String google = 'Google';
  static const String facebook = 'Facebook';
  static const String vk = 'VK';
  static const String twitter = 'Twitter / X';
  static const String appleId = 'Apple ID';
  static const String guest = 'Guest';
  static const String other = 'Other';

  static const List<String> all = [
    google,
    facebook,
    vk,
    twitter,
    appleId,
    guest,
    other,
  ];
}

/// Shared Preferences Keys
class PrefKeys {
  static const String defaultEncryptionKey = 'ff_secret_cipher_key_2026';
  static const String userPin = 'user_security_pin';
  static const String isPinEnabled = 'is_pin_lock_enabled';
  static const String currencySymbol = 'pref_currency_symbol';
  static const String lastBackupDate = 'pref_last_backup_date';
  static const String deoWhatsAppTemplate = 'pref_deo_whatsapp_template';
  static const String saleWhatsAppTemplate = 'pref_sale_whatsapp_template';
}

/// Default Message Templates
class MessageTemplates {
  static const String defaultDeoReceipt =
      'Dear {buyer_name},\n\n'
      'Receipt from Free Fire ID Manager:\n'
      'Account: {account_name}\n'
      'Total Amount: Rs. {total_amount}\n'
      'Amount Paid Now: Rs. {paid_amount}\n'
      'Total Paid: Rs. {total_paid}\n'
      'Remaining Balance: Rs. {remaining_balance}\n'
      'Date: {date}\n\n'
      'Thank you for your payment!';

  static const String defaultSaleReceipt =
      'Dear {buyer_name},\n\n'
      'Free Fire ID Purchase Invoice:\n'
      'Account UID: {uid}\n'
      'Selling Price: Rs. {price}\n'
      'Amount Received: Rs. {amount_received}\n'
      'Remaining Balance: Rs. {remaining_balance}\n'
      'Date: {date}\n\n'
      'Thank you for purchasing with us!';
}

/// Report Periods
class ReportPeriodConstants {
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String allTime = 'All Time';
  static const String custom = 'Custom Range';

  static const List<String> all = [
    today,
    thisWeek,
    thisMonth,
    allTime,
    custom,
  ];
}
