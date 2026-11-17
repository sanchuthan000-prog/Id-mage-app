import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../models/seller_model.dart';
import '../../models/buyer_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/seller_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _personType = 'buyer';
  int? _personId;
  String _txType = 'buyer_payment';
  String _paymentMethod = 'Cash';
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _txDate = AppHelpers.nowColombo();
  String? _proofImagePath;
  bool _isSaving = false;

  String _filterType = 'all'; // all, seller, buyer

  @override
  void dispose() {
    _amountCtrl.dispose(); _refCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text('Money Transactions',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Add Transaction Form
          Expanded(
            flex: 0,
            child: Container(
              color: AppColors.cardBg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Person type toggle
                      Row(children: [
                        _typeToggle('Buyer', 'buyer', AppColors.primary),
                        const SizedBox(width: 10),
                        _typeToggle('Seller', 'seller', AppColors.warning),
                      ]),
                      const SizedBox(height: 12),
                      // Person dropdown
                      _personDropdown(),
                      const SizedBox(height: 12),
                      // Transaction type
                      DropdownButtonFormField<String>(
                        value: _txType,
                        dropdownColor: AppColors.cardBg,
                        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                        decoration: _inputDeco('Transaction Type'),
                        items: _txTypesForPersonType().map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!,
                                style: GoogleFonts.rajdhani(color: AppColors.textWhite)))).toList(),
                        onChanged: (v) => setState(() => _txType = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                          decoration: _inputDeco('Amount (Rs.)'),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          dropdownColor: AppColors.cardBg,
                          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                          decoration: _inputDeco('Method'),
                          items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))).toList(),
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _refCtrl,
                        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                        decoration: _inputDeco('Reference Number (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                        decoration: _inputDeco('Notes (optional)'),
                      ),
                      const SizedBox(height: 12),
                      // Proof image + date row
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 16),
                              const SizedBox(width: 8),
                              Text(formatDate(_txDate),
                                  style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 13)),
                            ]),
                          ),
                        )),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickProofImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _proofImagePath != null
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Icon(
                                _proofImagePath != null
                                    ? Icons.check_circle_rounded
                                    : Icons.attach_file_rounded,
                                color: _proofImagePath != null
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                                size: 20),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      PrimaryButton(label: 'Save Transaction', isLoading: _isSaving, onPressed: _save),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter + Transaction History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('History', style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 13)),
                const Spacer(),
                ...['all', 'buyer', 'seller'].map((f) => GestureDetector(
                  onTap: () => setState(() => _filterType = f),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _filterType == f ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(f.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                            color: _filterType == f ? AppColors.bgDark : AppColors.textGrey,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                )),
              ],
            ),
          ),

          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (ctx, tp, _) {
                var txs = tp.transactions;
                if (_filterType != 'all') {
                  txs = txs.where((t) => t.personType == _filterType).toList();
                }
                if (txs.isEmpty) {
                  return const EmptyState(
                      message: 'No transactions yet', icon: Icons.receipt_long_outlined);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: txs.length,
                  itemBuilder: (ctx, i) => _TxCard(tx: txs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _txTypesForPersonType() {
    if (_personType == 'buyer') {
      return [
        {'value': 'buyer_payment', 'label': 'Buyer Payment'},
        {'value': 'buyer_advance', 'label': 'Buyer Advance'},
        {'value': 'refund', 'label': 'Refund'},
        {'value': 'adjustment', 'label': 'Other Adjustment'},
      ];
    } else {
      return [
        {'value': 'seller_payment', 'label': 'Seller Payment'},
        {'value': 'seller_advance', 'label': 'Seller Advance'},
        {'value': 'refund', 'label': 'Refund'},
        {'value': 'adjustment', 'label': 'Other Adjustment'},
      ];
    }
  }

  Widget _typeToggle(String label, String value, Color color) {
    final selected = _personType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _personType = value;
            _personId = null;
            _txType = value == 'buyer' ? 'buyer_payment' : 'seller_payment';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppColors.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : AppColors.textGrey.withOpacity(0.3), width: selected ? 1.5 : 1),
          ),
          child: Center(child: Text(label,
              style: GoogleFonts.rajdhani(
                  color: selected ? color : AppColors.textGrey,
                  fontWeight: FontWeight.w700, fontSize: 14))),
        ),
      ),
    );
  }

  Widget _personDropdown() {
    if (_personType == 'buyer') {
      return Consumer<BuyerProvider>(builder: (ctx, bp, _) => DropdownButtonFormField<int>(
        value: _personId,
        isExpanded: true,
        dropdownColor: AppColors.cardBg,
        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
        decoration: _inputDeco('Select Buyer'),
        validator: (v) => v == null ? 'Required' : null,
        items: bp.buyers.map((b) => DropdownMenuItem<int>(
            value: b.id, child: Text(b.name, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))).toList(),
        onChanged: (v) => setState(() => _personId = v),
      ));
    } else {
      return Consumer<SellerProvider>(builder: (ctx, sp, _) => DropdownButtonFormField<int>(
        value: _personId,
        isExpanded: true,
        dropdownColor: AppColors.cardBg,
        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
        decoration: _inputDeco('Select Seller'),
        validator: (v) => v == null ? 'Required' : null,
        items: sp.sellers.map((s) => DropdownMenuItem<int>(
            value: s.id, child: Text(s.name, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))).toList(),
        onChanged: (v) => setState(() => _personId = v),
      ));
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey.withOpacity(0.5)),
    filled: true, fillColor: AppColors.bgDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.warning)),
  );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _txDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: AppColors.cardBg),
        ), child: child!,
      ),
    );
    if (d != null) setState(() => _txDate = d);
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'tx_proofs', '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(xFile.path).copy(dest);
    setState(() => _proofImagePath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final tx = TransactionModel(
        type: _txType,
        personType: _personType,
        personId: _personId!,
        amount: double.parse(_amountCtrl.text),
        paymentMethod: _paymentMethod,
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        paymentProofPath: _proofImagePath,
        transactionDate: _txDate,
        createdAt: AppHelpers.nowColombo(),
      );
      await context.read<TransactionProvider>().addTransaction(tx);
      context.read<DashboardProvider>().loadStats();
      if (_personType == 'buyer') context.read<BuyerProvider>().loadBuyers();
      else context.read<SellerProvider>().loadSellers();

      _amountCtrl.clear(); _refCtrl.clear(); _notesCtrl.clear();
      setState(() { _personId = null; _proofImagePath = null; _txDate = AppHelpers.nowColombo(); });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Transaction saved!', style: GoogleFonts.rajdhani(fontSize: 15)),
            backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', style: GoogleFonts.rajdhani()),
            backgroundColor: AppColors.warning));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isBuyer = tx.personType == 'buyer';
    final color = isBuyer ? AppColors.primary : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isBuyer ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.personName ?? 'Unknown',
                    style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${tx.typeDisplayName} • ${tx.paymentMethod}',
                    style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                Text(formatDateTime(tx.transactionDate),
                    style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(tx.amount),
                  style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
              if (tx.paymentProofPath != null)
                Icon(Icons.attach_file_rounded, color: AppColors.secondary, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
