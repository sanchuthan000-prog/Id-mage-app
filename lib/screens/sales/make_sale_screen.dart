import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ff_id_model.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class MakeSaleScreen extends StatefulWidget {
  final FfId? preselectedId;
  const MakeSaleScreen({super.key, this.preselectedId});

  @override
  State<MakeSaleScreen> createState() => _MakeSaleScreenState();
}

class _MakeSaleScreenState extends State<MakeSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  FfId? _selectedId;
  int? _selectedBuyerId;
  final _sellingPriceCtrl = TextEditingController();
  final _amountReceivedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  DateTime _saleDate = AppHelpers.nowColombo();
  bool _isSaving = false;

  double get _sellingPrice => double.tryParse(_sellingPriceCtrl.text) ?? 0;
  double get _amountReceived => double.tryParse(_amountReceivedCtrl.text) ?? 0;
  double get _remaining => _sellingPrice - _amountReceived;
  double get _profit => _sellingPrice - (_selectedId?.purchaseCost ?? 0);

  @override
  void initState() {
    super.initState();
    if (widget.preselectedId != null) {
      _selectedId = widget.preselectedId;
      _sellingPriceCtrl.text = _selectedId!.sellingPrice.toString();
    }
    _sellingPriceCtrl.addListener(() => setState(() {}));
    _amountReceivedCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sellingPriceCtrl.dispose();
    _amountReceivedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('Make Sale',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select ID
              _label('Select Free Fire ID *'),
              const SizedBox(height: 8),
              Consumer<FfIdProvider>(
                builder: (ctx, prov, _) {
                  final available = prov.ids.where((id) => id.isAvailable).toList();
                  return DropdownButtonFormField<FfId>(
                    value: _selectedId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBg,
                    style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                    decoration: _inputDeco('Choose available ID'),
                    validator: (v) => v == null ? 'Please select an ID' : null,
                    items: available.map((id) => DropdownMenuItem<FfId>(
                      value: id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(id.uid, style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textWhite)),
                          Text('Price: ${formatCurrency(id.sellingPrice)}',
                              style: GoogleFonts.rajdhani(color: AppColors.secondary, fontSize: 12)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedId = id;
                        if (id != null) _sellingPriceCtrl.text = id.sellingPrice.toString();
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Select Buyer
              _label('Select Buyer *'),
              const SizedBox(height: 8),
              Consumer<BuyerProvider>(
                builder: (ctx, bp, _) => DropdownButtonFormField<int>(
                  value: _selectedBuyerId,
                  isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                  decoration: _inputDeco('Choose buyer'),
                  validator: (v) => v == null ? 'Please select a buyer' : null,
                  items: bp.buyers.map((b) => DropdownMenuItem<int>(
                    value: b.id,
                    child: Text(b.name, style: GoogleFonts.rajdhani(color: AppColors.textWhite)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedBuyerId = v),
                ),
              ),
              const SizedBox(height: 16),

              // Selling Price
              _label('Selling Price (Rs.) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sellingPriceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                decoration: _inputDeco('0.00'),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null,
              ),
              const SizedBox(height: 16),

              // Payment method
              _label('Payment Method'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: AppColors.cardBg,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                decoration: _inputDeco(''),
                items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(
                    value: m, child: Text(m, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),

              // Amount received
              _label('Amount Received (Rs.)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountReceivedCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                decoration: _inputDeco('0.00'),
              ),
              const SizedBox(height: 16),

              // Sale date
              _label('Sale Date & Time'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    Text(formatDateTime(_saleDate),
                        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15)),
                    const Spacer(),
                    Icon(Icons.edit_rounded, color: AppColors.textGrey, size: 16),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              _label('Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                decoration: _inputDeco('Sale notes...'),
              ),
              const SizedBox(height: 20),

              // Calculation Summary
              _buildCalcSummary(),
              const SizedBox(height: 24),

              // Confirm Button
              PrimaryButton(
                label: '✅ Confirm Sale',
                isLoading: _isSaving,
                onPressed: _confirmSale,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sale Summary',
              style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _summaryRow('Purchase Cost', formatCurrency(_selectedId?.purchaseCost ?? 0), AppColors.warning),
          _summaryRow('Selling Price', formatCurrency(_sellingPrice), AppColors.secondary),
          _summaryRow('Amount Received', formatCurrency(_amountReceived), AppColors.textWhite),
          Divider(color: AppColors.primary.withOpacity(0.2)),
          _summaryRow('Remaining Balance', formatCurrency(_remaining.clamp(0, double.infinity)),
              _remaining > 0 ? AppColors.warning : AppColors.textGrey),
          _summaryRow('Profit', formatCurrency(_profit.clamp(0, double.infinity)), AppColors.primary),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
          Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey.withOpacity(0.5)),
    filled: true, fillColor: AppColors.cardBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.warning)),
  );

  Widget _label(String text) => Text(text,
      style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: AppColors.cardBg),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _saleDate = d);
  }

  Future<void> _confirmSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedId == null || _selectedBuyerId == null) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Sale', style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${_selectedId!.uid}', style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14)),
            Text('Price: ${formatCurrency(_sellingPrice)}', style: GoogleFonts.rajdhani(color: AppColors.secondary, fontSize: 14)),
            Text('Profit: ${formatCurrency(_profit)}', style: GoogleFonts.rajdhani(color: AppColors.primary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('⚠️ This cannot be undone easily.',
                style: GoogleFonts.rajdhani(color: AppColors.warning, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.rajdhani(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Confirm', style: GoogleFonts.rajdhani(
                color: AppColors.bgDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSaving = true);

    try {
      await context.read<SaleProvider>().sellId(
        ffIdId: _selectedId!.id!,
        buyerId: _selectedBuyerId!,
        sellingPrice: _sellingPrice,
        profit: _profit,
        paymentMethod: _paymentMethod,
        amountReceived: _amountReceived,
        remainingBalance: _remaining.clamp(0, double.infinity),
        saleDate: _saleDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      context.read<DashboardProvider>().loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Sale recorded successfully!', style: GoogleFonts.rajdhani(fontSize: 15)),
            backgroundColor: AppColors.primary));
        Navigator.pop(context);
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
