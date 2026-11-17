import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models/buyer_model.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('Buyers',
            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.rajdhani(color: AppColors.textWhite),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search buyers...',
                hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
                filled: true, fillColor: AppColors.cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: Consumer<BuyerProvider>(
              builder: (ctx, bp, _) {
                final buyers = bp.buyers
                    .where((b) => b.name.toLowerCase().contains(_query) || b.phone.contains(_query))
                    .toList();
                if (buyers.isEmpty) {
                  return const EmptyState(message: 'No buyers found.\nTap + to add.', icon: Icons.person_outline);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: buyers.length,
                  itemBuilder: (ctx, i) => _BuyerCard(
                    buyer: buyers[i],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => BuyerProfileScreen(buyer: buyers[i])))
                        .then((_) => bp.loadBuyers()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEditBuyerScreen()))
            .then((_) => context.read<BuyerProvider>().loadBuyers()),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add Buyer', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BuyerCard extends StatelessWidget {
  final Buyer buyer;
  final VoidCallback onTap;
  const _BuyerCard({required this.buyer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            PersonAvatar(name: buyer.name, imagePath: buyer.profileImagePath),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(buyer.name, style: GoogleFonts.orbitron(
                      color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w700)),
                  if (buyer.phone.isNotEmpty)
                    Text(buyer.phone, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                  Text('IDs: ${buyer.totalIdsPurchased ?? 0}',
                      style: GoogleFonts.rajdhani(color: AppColors.secondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Due', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                Text(formatCurrency(buyer.remainingDue ?? 0),
                    style: GoogleFonts.orbitron(
                        color: (buyer.remainingDue ?? 0) > 0 ? AppColors.warning : AppColors.primary,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD/EDIT BUYER
// ============================================================
class AddEditBuyerScreen extends StatefulWidget {
  final Buyer? buyer;
  const AddEditBuyerScreen({super.key, this.buyer});

  @override
  State<AddEditBuyerScreen> createState() => _AddEditBuyerScreenState();
}

class _AddEditBuyerScreenState extends State<AddEditBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _profileImagePath;
  bool _isSaving = false;

  bool get isEdit => widget.buyer != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final b = widget.buyer!;
      _nameCtrl.text = b.name;
      _phoneCtrl.text = b.phone;
      _whatsappCtrl.text = b.whatsapp ?? '';
      _addressCtrl.text = b.address ?? '';
      _notesCtrl.text = b.notes ?? '';
      _profileImagePath = b.profileImagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _whatsappCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
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
        title: Text(isEdit ? 'Edit Buyer' : 'Add Buyer',
            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileImage(),
              const SizedBox(height: 24),
              _buildField('Name *', _nameCtrl, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              _buildField('Phone Number', _phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField('WhatsApp Number', _whatsappCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField('Address', _addressCtrl),
              const SizedBox(height: 14),
              _buildField('Notes', _notesCtrl, maxLines: 3),
              const SizedBox(height: 28),
              PrimaryButton(label: isEdit ? 'Update Buyer' : 'Add Buyer',
                  isLoading: _isSaving, onPressed: _save),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(children: [
        CircleAvatar(
          radius: 50, backgroundColor: AppColors.cardBg,
          backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
              ? FileImage(File(_profileImagePath!)) : null,
          child: _profileImagePath == null
              ? Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'B',
                  style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 28)) : null,
        ),
        Positioned(bottom: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(Icons.camera_alt_rounded, color: AppColors.bgDark, size: 16),
          )),
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'profiles', '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(xFile.path).copy(dest);
    setState(() => _profileImagePath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final prov = context.read<BuyerProvider>();
      if (isEdit) {
        await prov.updateBuyer(widget.buyer!.copyWith(
          name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
          whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          profileImagePath: _profileImagePath,
        ));
      } else {
        await prov.addBuyer(Buyer(
          name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
          whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          profileImagePath: _profileImagePath,
          totalPaid: 0, createdAt: AppHelpers.nowColombo(),
        ));
      }
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
// BUYER PROFILE
// ============================================================
class BuyerProfileScreen extends StatelessWidget {
  final Buyer buyer;
  const BuyerProfileScreen({super.key, required this.buyer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('Buyer Profile',
            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.secondary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddEditBuyerScreen(buyer: buyer)))
                .then((_) => context.read<BuyerProvider>().loadBuyers()),
          ),
          if (buyer.phone.isNotEmpty)
            IconButton(
              icon: Icon(Icons.message_rounded, color: AppColors.primary),
              onPressed: () => AppHelpers.openWhatsApp(buyer.whatsapp ?? buyer.phone, ''),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(children: [
                PersonAvatar(name: buyer.name, imagePath: buyer.profileImagePath, radius: 50),
                const SizedBox(height: 12),
                Text(buyer.name, style: GoogleFonts.orbitron(
                    color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
                if (buyer.phone.isNotEmpty)
                  Text(buyer.phone, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Total IDs', '${buyer.totalIdsPurchased ?? 0}', AppColors.secondary),
                _stat('Total Value', formatCurrency(buyer.totalPurchaseValue ?? 0), AppColors.secondary),
                _stat('Paid', formatCurrency(buyer.totalPaid), AppColors.primary),
                _stat('Due', formatCurrency(buyer.remainingDue ?? 0),
                    (buyer.remainingDue ?? 0) > 0 ? AppColors.warning : AppColors.textGrey),
              ]),
            ),
            const SizedBox(height: 20),
            // Purchase history
            Consumer<SaleProvider>(builder: (ctx, sp, _) {
              final sales = sp.sales.where((s) => s.buyerId == buyer.id).toList();
              if (sales.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchase History', style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  ...sales.map((sale) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15))),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sale.ffUid ?? 'ID #${sale.ffIdId}',
                            style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 13)),
                        Text(formatDate(sale.saleDate),
                            style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatCurrency(sale.sellingPrice),
                            style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w700)),
                        if (sale.remainingBalance > 0)
                          Text('Due: ${formatCurrency(sale.remainingBalance)}',
                              style: GoogleFonts.rajdhani(color: AppColors.warning, fontSize: 11)),
                      ]),
                    ]),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            }),
            // Payment history
            Consumer<TransactionProvider>(builder: (ctx, tp, _) {
              final txs = tp.transactions.where((t) =>
                  t.personType == 'buyer' && t.personId == buyer.id).toList();
              if (txs.isEmpty) return const EmptyState(message: 'No payments yet', icon: Icons.receipt_outlined);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment History', style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  ...txs.map((tx) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tx.typeDisplayName, style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${tx.paymentMethod} • ${formatDate(tx.transactionDate)}',
                            style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                      ])),
                      Text(formatCurrency(tx.amount),
                          style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}
