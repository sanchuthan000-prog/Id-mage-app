import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models/ff_id_model.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/seller_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class AddEditIdScreen extends StatefulWidget {
  final FfId? ffId;
  const AddEditIdScreen({super.key, this.ffId});

  @override
  State<AddEditIdScreen> createState() => _AddEditIdScreenState();
}

class _AddEditIdScreenState extends State<AddEditIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _purchaseDate = AppHelpers.nowColombo();
  String _status = 'available';
  int? _selectedSellerId;
  bool _obscurePass = true;
  List<String> _imagePaths = [];
  bool _isSaving = false;

  bool get isEdit => widget.ffId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final id = widget.ffId!;
      _uidCtrl.text = id.uid;
      _emailCtrl.text = id.loginEmail;
      _passCtrl.text = id.loginPasswordEncrypted; // shown decrypted via provider
      _costCtrl.text = id.purchaseCost.toString();
      _priceCtrl.text = id.sellingPrice.toString();
      _notesCtrl.text = id.notes ?? '';
      _purchaseDate = id.purchaseDate;
      _status = id.status;
      _selectedSellerId = id.sellerId;
      _imagePaths = List.from(id.images.map((img) => img.imagePath));
    }
  }

  @override
  void dispose() {
    _uidCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _costCtrl.dispose(); _priceCtrl.dispose(); _notesCtrl.dispose();
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
        title: Text(isEdit ? 'Edit ID' : 'Add New ID',
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
              _sectionLabel('Account Information'),
              const SizedBox(height: 12),
              _buildField('Free Fire UID *', _uidCtrl, 'e.g. 1234567890',
                  validator: (v) => v!.trim().isEmpty ? 'UID required' : null),
              const SizedBox(height: 12),
              _buildField('Login Email / Username *', _emailCtrl, 'e.g. user@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.trim().isEmpty ? 'Email required' : null),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _sectionLabel('Pricing'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('Purchase Cost (Rs.) *', _costCtrl, '0.00',
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Selling Price (Rs.) *', _priceCtrl, '0.00',
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null)),
              ]),
              const SizedBox(height: 20),
              _sectionLabel('Details'),
              const SizedBox(height: 12),
              _buildSellerDropdown(),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildStatusDropdown(),
              const SizedBox(height: 12),
              _buildField('Notes', _notesCtrl, 'Any additional notes...', maxLines: 3),
              const SizedBox(height: 20),
              _sectionLabel('Screenshots / Images'),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 30),
              PrimaryButton(
                label: isEdit ? 'Update ID' : 'Add ID',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.orbitron(
            color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.cardBg,
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password *', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
          validator: (v) => v!.trim().isEmpty ? 'Password required' : null,
          decoration: InputDecoration(
            hintText: 'Account password',
            hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey.withOpacity(0.5)),
            filled: true, fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: AppColors.textGrey, size: 20),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerDropdown() {
    return Consumer<SellerProvider>(
      builder: (ctx, sp, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedSellerId,
              dropdownColor: AppColors.cardBg,
              style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              hint: Text('Select Seller (optional)',
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey.withOpacity(0.5))),
              items: [
                DropdownMenuItem<int>(value: null,
                    child: Text('No Seller', style: GoogleFonts.rajdhani(color: AppColors.textGrey))),
                ...sp.sellers.map((s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name, style: GoogleFonts.rajdhani(color: AppColors.textWhite)))),
              ],
              onChanged: (v) => setState(() => _selectedSellerId = v),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Purchase Date', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Text(formatDateTime(_purchaseDate),
                    style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15)),
                const Spacer(),
                Icon(Icons.edit_rounded, color: AppColors.textGrey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: AppColors.cardBg),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _purchaseDate = d);
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _status,
          dropdownColor: AppColors.cardBg,
          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15),
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          items: [
            DropdownMenuItem(value: 'available',
                child: Text('Available', style: GoogleFonts.rajdhani(color: AppColors.primary))),
            DropdownMenuItem(value: 'sold',
                child: Text('Sold', style: GoogleFonts.rajdhani(color: AppColors.warning))),
          ],
          onChanged: (v) => setState(() => _status = v!),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_imagePaths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length,
              itemBuilder: (ctx, i) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      image: DecorationImage(
                          image: FileImage(File(_imagePaths[i])), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 14,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePaths.removeAt(i)),
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.secondary.withOpacity(0.4), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded, color: AppColors.secondary, size: 22),
                const SizedBox(width: 10),
                Text('Add Screenshot', style: GoogleFonts.rajdhani(
                    color: AppColors.secondary, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
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
    final dest = p.join(dir.path, 'id_images', '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(xFile.path).copy(dest);
    setState(() => _imagePaths.add(dest));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final prov = context.read<FfIdProvider>();
      if (isEdit) {
        final updated = widget.ffId!.copyWith(
          uid: _uidCtrl.text.trim(),
          loginEmail: _emailCtrl.text.trim(),
          loginPasswordEncrypted: _passCtrl.text,
          purchaseCost: double.parse(_costCtrl.text),
          sellingPrice: double.parse(_priceCtrl.text),
          sellerId: _selectedSellerId,
          purchaseDate: _purchaseDate,
          status: _status,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          updatedAt: AppHelpers.nowColombo(),
        );
        await prov.updateId(updated, _imagePaths);
      } else {
        final newId = FfId(
          uid: _uidCtrl.text.trim(),
          loginEmail: _emailCtrl.text.trim(),
          loginPasswordEncrypted: _passCtrl.text,
          purchaseCost: double.parse(_costCtrl.text),
          sellingPrice: double.parse(_priceCtrl.text),
          sellerId: _selectedSellerId,
          purchaseDate: _purchaseDate,
          status: _status,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          createdAt: AppHelpers.nowColombo(),
          updatedAt: AppHelpers.nowColombo(),
        );
        await prov.addId(newId, _imagePaths);
      }
      if (mounted) Navigator.pop(context);
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
