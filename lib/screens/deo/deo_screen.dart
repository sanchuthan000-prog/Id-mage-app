import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../models/deo_model.dart';
import '../../models/buyer_model.dart';
import '../../providers/deo_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class DeoScreen extends StatefulWidget {
  const DeoScreen({super.key});

  @override
  State<DeoScreen> createState() => _DeoScreenState();
}

class _DeoScreenState extends State<DeoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('DEO Management',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textGrey),
            onPressed: () => context.read<DeoProvider>().loadAccounts(),
          ),
        ],
      ),
      body: Consumer<DeoProvider>(
        builder: (ctx, dp, _) {
          if (dp.isLoading) return const Center(child: CircularProgressIndicator());
          final accounts = dp.accounts;
          if (accounts.isEmpty) {
            return const EmptyState(
                message: 'No DEO accounts yet.\nTap + to add.', icon: Icons.assignment_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (ctx, i) => _DeoCard(
              account: accounts[i],
              onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DeoDetailScreen(account: accounts[i])))
                  .then((_) {
                context.read<DeoProvider>().loadAccounts();
                context.read<DashboardProvider>().loadStats();
              }),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddDeoAccountScreen()))
            .then((_) {
          context.read<DeoProvider>().loadAccounts();
          context.read<DashboardProvider>().loadStats();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add DEO', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _DeoCard extends StatelessWidget {
  final DeoAccount account;
  final VoidCallback onTap;
  const _DeoCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = account.progressPercentage.clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.assignment_rounded, color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(account.name,
                    style: GoogleFonts.orbitron(
                        color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w700)),
                if (account.buyerName != null)
                  Text('Buyer: ${account.buyerName}',
                      style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                if (account.ffUid != null)
                  Text('ID: ${account.ffUid}',
                      style: GoogleFonts.rajdhani(color: AppColors.secondary, fontSize: 12)),
              ])),
              account.isFullyPaid
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary)),
                      child: Text('PAID',
                          style: GoogleFonts.orbitron(
                              color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)))
                  : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Remaining', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                      Text(formatCurrency(account.remainingAmount),
                          style: GoogleFonts.orbitron(
                              color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total: ${formatCurrency(account.totalAmount)}',
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
              Text('Paid: ${formatCurrency(account.paidAmount)}',
                  style: GoogleFonts.rajdhani(color: AppColors.primary, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bgDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                    account.isFullyPaid ? AppColors.primary : AppColors.secondary),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD DEO ACCOUNT
// ============================================================
class AddDeoAccountScreen extends StatefulWidget {
  const AddDeoAccountScreen({super.key});

  @override
  State<AddDeoAccountScreen> createState() => _AddDeoAccountScreenState();
}

class _AddDeoAccountScreenState extends State<AddDeoAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _buyerId;
  int? _ffIdId;
  bool _isSaving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _totalCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('Add DEO Account',
            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _field('DEO Account Name *', _nameCtrl, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _field('Total DEO Amount (Rs.) *', _totalCtrl,
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null),
            const SizedBox(height: 14),
            Consumer<BuyerProvider>(builder: (ctx, bp, _) =>
                DropdownButtonFormField<int>(
                  value: _buyerId, isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                  decoration: _deco('Select Buyer (optional)'),
                  items: [
                    DropdownMenuItem<int>(value: null, child: Text('No Buyer', style: GoogleFonts.rajdhani(color: AppColors.textGrey))),
                    ...bp.buyers.map((b) => DropdownMenuItem<int>(value: b.id,
                        child: Text(b.name, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))),
                  ],
                  onChanged: (v) => setState(() => _buyerId = v),
                )),
            const SizedBox(height: 14),
            Consumer<FfIdProvider>(builder: (ctx, ip, _) =>
                DropdownButtonFormField<int>(
                  value: _ffIdId, isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14),
                  decoration: _deco('Related FF ID (optional)'),
                  items: [
                    DropdownMenuItem<int>(value: null, child: Text('No ID', style: GoogleFonts.rajdhani(color: AppColors.textGrey))),
                    ...ip.ids.map((id) => DropdownMenuItem<int>(value: id.id,
                        child: Text(id.uid, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))),
                  ],
                  onChanged: (v) => setState(() => _ffIdId = v),
                )),
            const SizedBox(height: 14),
            _field('Notes', _notesCtrl, maxLines: 3),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Create DEO Account', isLoading: _isSaving, onPressed: _save),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
      const SizedBox(height: 6),
      TextFormField(controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
        style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
        validator: validator,
        decoration: _deco(''),
      ),
    ]);
  }

  InputDecoration _deco(String hint) => InputDecoration(
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await context.read<DeoProvider>().addAccount(DeoAccount(
        name: _nameCtrl.text.trim(),
        buyerId: _buyerId,
        relatedFfIdId: _ffIdId,
        totalAmount: double.parse(_totalCtrl.text),
        paidAmount: 0,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: AppHelpers.nowColombo(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.rajdhani()), backgroundColor: AppColors.warning));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ============================================================
// DEO DETAIL SCREEN
// ============================================================
class DeoDetailScreen extends StatefulWidget {
  final DeoAccount account;
  const DeoDetailScreen({super.key, required this.account});

  @override
  State<DeoDetailScreen> createState() => _DeoDetailScreenState();
}

class _DeoDetailScreenState extends State<DeoDetailScreen> {
  late DeoAccount _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeoProvider>().loadPaymentsForAccount(_account.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('DEO Detail',
            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Consumer<DeoProvider>(
        builder: (ctx, dp, _) {
          final payments = dp.getPaymentsForAccount(_account.id!);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.assignment_rounded, color: AppColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_account.name, style: GoogleFonts.orbitron(
                          color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                      if (_account.buyerName != null)
                        Text('Buyer: ${_account.buyerName}',
                            style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
                      if (_account.ffUid != null)
                        Text('ID: ${_account.ffUid}',
                            style: GoogleFonts.rajdhani(color: AppColors.secondary, fontSize: 13)),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _stat('Total', formatCurrency(_account.totalAmount), AppColors.secondary),
                    _stat('Paid', formatCurrency(_account.paidAmount), AppColors.primary),
                    _stat('Remaining', formatCurrency(_account.remainingAmount), AppColors.warning),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _account.progressPercentage.clamp(0.0, 1.0),
                      backgroundColor: AppColors.bgDark,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              if (!_account.isFullyPaid) ...[
                PrimaryButton(
                  label: '+ Add Payment',
                  onPressed: () => _showAddPaymentDialog(context, dp),
                ),
                const SizedBox(height: 16),
              ],

              // Payment history
              Text('Payment History',
                  style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              if (payments.isEmpty)
                const EmptyState(message: 'No payments yet', icon: Icons.receipt_outlined)
              else
                ...payments.map((pmt) => _PaymentCard(payment: pmt, account: _account)),
            ]),
          );
        },
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, DeoProvider dp) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime payDate = AppHelpers.nowColombo();
    String? proofPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add DEO Payment',
                  style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Remaining: ${formatCurrency(_account.remainingAmount)}',
                  style: GoogleFonts.rajdhani(color: AppColors.warning, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                decoration: _inputDeco('Amount (Rs.)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
                decoration: _inputDeco('Notes (optional)'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context, initialDate: payDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(
                            primary: AppColors.primary, surface: AppColors.cardBg)), child: child!),
                    );
                    if (d != null) setS(() => payDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 8),
                      Text(formatDate(payDate),
                          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 13)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (f == null) return;
                    final dir = await getApplicationDocumentsDirectory();
                    final dest = p.join(dir.path, 'deo_proofs', '${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await Directory(p.dirname(dest)).create(recursive: true);
                    await File(f.path).copy(dest);
                    setS(() => proofPath = dest);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: proofPath != null ? AppColors.primary : AppColors.primary.withOpacity(0.2))),
                    child: Icon(proofPath != null ? Icons.check_circle_rounded : Icons.attach_file_rounded,
                        color: proofPath != null ? AppColors.primary : AppColors.textGrey, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;
                    final payment = DeoPayment(
                      deoAccountId: _account.id!,
                      amount: amount,
                      paymentProofPath: proofPath,
                      paymentDate: payDate,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      createdAt: AppHelpers.nowColombo(),
                    );
                    await dp.addPayment(payment);
                    // Update local account
                    setState(() {
                      _account = _account.copyWith(
                          paidAmount: _account.paidAmount + amount);
                    });
                    context.read<DashboardProvider>().loadStats();
                    if (mounted) {
                      Navigator.pop(ctx);
                      // Show WhatsApp option
                      _showWhatsAppDialog(context, payment, amount);
                    }
                  },
                  child: Text('Save Payment',
                      style: GoogleFonts.rajdhani(
                          color: AppColors.bgDark, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWhatsAppDialog(BuildContext context, DeoPayment payment, double amount) {
    final remaining = _account.remainingAmount;
    final totalPaid = _account.paidAmount;
    final buyer = _account.buyerName ?? 'Customer';
    var msg =
        'Dear $buyer,\n\nDEO Payment Confirmation:\n'
        'Account: ${_account.name}\n'
        'Total DEO: ${formatCurrency(_account.totalAmount)}\n'
        'Paid This Time: ${formatCurrency(amount)}\n'
        'Total Paid: ${formatCurrency(totalPaid)}\n'
        'Remaining: ${formatCurrency(remaining)}\n'
        'Date: ${formatDateTime(payment.paymentDate)}\n\n'
        'Thank you! 🙏';

    final msgCtrl = TextEditingController(text: msg);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.message_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('Send WhatsApp', style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 14)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: msgCtrl,
            maxLines: 8,
            style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 13),
            decoration: InputDecoration(
              filled: true, fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Skip', style: GoogleFonts.rajdhani(color: AppColors.textGrey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text('Send', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
            onPressed: () {
              final phone = _account.buyerName != null ? '' : '';
              AppHelpers.openWhatsApp('', msgCtrl.text);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
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
  );

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _PaymentCard extends StatelessWidget {
  final DeoPayment payment;
  final DeoAccount account;
  const _PaymentCard({required this.payment, required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(formatCurrency(payment.amount),
              style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
          Text(formatDateTime(payment.paymentDate),
              style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
          if (payment.notes != null)
            Text(payment.notes!, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
        ])),
        if (payment.paymentProofPath != null)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.file(File(payment.paymentProofPath!)),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.image_rounded, color: AppColors.secondary, size: 18),
            ),
          ),
      ]),
    );
  }
}
