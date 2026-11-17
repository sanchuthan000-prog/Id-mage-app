import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../providers/sale_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _dateFilter = 'month'; // today, week, month, custom
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _applyFilter('month');
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _applyFilter(String filter) {
    final now = AppHelpers.nowColombo();
    setState(() {
      _dateFilter = filter;
      switch (filter) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
      }
    });
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
        title: Text('Reports',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.warning),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          labelStyle: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Sales'), Tab(text: 'Transactions'), Tab(text: 'Summary')],
        ),
      ),
      body: Column(
        children: [
          // Date filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              ...['today', 'week', 'month'].map((f) => Expanded(child: GestureDetector(
                onTap: () => _applyFilter(f),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _dateFilter == f ? AppColors.primary : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(
                    {'today': 'Today', 'week': 'Week', 'month': 'Month'}[f]!,
                    style: GoogleFonts.rajdhani(
                        color: _dateFilter == f ? AppColors.bgDark : AppColors.textGrey,
                        fontWeight: FontWeight.w700, fontSize: 13),
                  )),
                ),
              ))),
              GestureDetector(
                onTap: _pickCustomRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _dateFilter == 'custom' ? AppColors.secondary : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.date_range_rounded,
                      color: _dateFilter == 'custom' ? AppColors.bgDark : AppColors.textGrey, size: 20),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, color: AppColors.textGrey, size: 14),
              const SizedBox(width: 6),
              Text('${formatDate(_startDate)} → ${formatDate(_endDate)}',
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SalesReport(start: _startDate, end: _endDate),
                _TransactionsReport(start: _startDate, end: _endDate),
                _SummaryReport(start: _startDate, end: _endDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(
            primary: AppColors.primary, surface: AppColors.cardBg)), child: child!),
    );
    if (range != null) {
      setState(() {
        _dateFilter = 'custom';
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _exportPdf() async {
    final sales = context.read<SaleProvider>().sales
        .where((s) => s.saleDate.isAfter(_startDate) && s.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FF ID Manager - Sales Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Period: ${formatDate(_startDate)} to ${formatDate(_endDate)}'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Date', 'FF UID', 'Buyer', 'Price', 'Profit', 'Method'],
              data: sales.map((s) => [
                formatDate(s.saleDate), s.ffUid ?? 'ID#${s.ffIdId}',
                s.buyerName ?? '-', 'Rs.${s.sellingPrice.toStringAsFixed(0)}',
                'Rs.${s.profit.toStringAsFixed(0)}', s.paymentMethod
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total Sales: Rs.${sales.fold<double>(0, (s, e) => s + e.sellingPrice).toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Total Profit: Rs.${sales.fold<double>(0, (s, e) => s + e.profit).toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

class _SalesReport extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  const _SalesReport({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Consumer<SaleProvider>(builder: (ctx, sp, _) {
      final sales = sp.sales.where((s) =>
          !s.saleDate.isBefore(start) && !s.saleDate.isAfter(end.add(const Duration(days: 1)))).toList();
      final totalSales = sales.fold<double>(0, (sum, s) => sum + s.sellingPrice);
      final totalProfit = sales.fold<double>(0, (sum, s) => sum + s.profit);

      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: _summaryCard('Sales', sales.length.toString(), AppColors.secondary)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Total', formatCurrency(totalSales), AppColors.secondary)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Profit', formatCurrency(totalProfit), AppColors.primary)),
          ]),
        ),
        Expanded(
          child: sales.isEmpty
              ? const EmptyState(message: 'No sales in this period', icon: Icons.sell_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final s = sales[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15))),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.ffUid ?? 'ID #${s.ffIdId}',
                              style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('${s.buyerName ?? '-'} • ${s.paymentMethod}',
                              style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                          Text(formatDateTime(s.saleDate),
                              style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(formatCurrency(s.sellingPrice),
                              style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('Profit: ${formatCurrency(s.profit)}',
                              style: GoogleFonts.rajdhani(color: AppColors.primary, fontSize: 12)),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]);
    });
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _TransactionsReport extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  const _TransactionsReport({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(builder: (ctx, tp, _) {
      final txs = tp.transactions.where((t) =>
          !t.transactionDate.isBefore(start) && !t.transactionDate.isAfter(end.add(const Duration(days: 1)))).toList();
      final totalIn = txs.where((t) => t.personType == 'buyer').fold<double>(0, (s, t) => s + t.amount);
      final totalOut = txs.where((t) => t.personType == 'seller').fold<double>(0, (s, t) => s + t.amount);

      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: _card('Buyer Received', formatCurrency(totalIn), AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _card('Seller Paid', formatCurrency(totalOut), AppColors.warning)),
          ]),
        ),
        Expanded(
          child: txs.isEmpty
              ? const EmptyState(message: 'No transactions', icon: Icons.receipt_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: txs.length,
                  itemBuilder: (ctx, i) {
                    final t = txs[i];
                    final isBuyer = t.personType == 'buyer';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (isBuyer ? AppColors.primary : AppColors.warning).withOpacity(0.2))),
                      child: Row(children: [
                        Icon(isBuyer ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isBuyer ? AppColors.primary : AppColors.warning, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.personName ?? '-', style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${t.typeDisplayName} • ${t.paymentMethod}',
                              style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                          Text(formatDateTime(t.transactionDate),
                              style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                        ])),
                        Text(formatCurrency(t.amount),
                            style: GoogleFonts.orbitron(
                                color: isBuyer ? AppColors.primary : AppColors.warning,
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    );
                  },
                ),
        ),
      ]);
    });
  }

  Widget _card(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _SummaryReport extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  const _SummaryReport({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(builder: (ctx, dp, _) {
      final s = dp.stats;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Total IDs', s.totalIds.toString(), AppColors.secondary),
          _row('Available IDs', s.availableIds.toString(), AppColors.primary),
          _row('Sold IDs', s.soldIds.toString(), AppColors.warning),
          _divider(),
          _row('Total Investment', formatCurrency(s.totalInvestment), AppColors.warning),
          _row('Total Sales', formatCurrency(s.totalSales), AppColors.secondary),
          _row('Total Profit', formatCurrency(s.totalProfit), AppColors.primary),
          _divider(),
          _row('Seller Payments', formatCurrency(s.totalSellerPayments), AppColors.warning),
          _row('Buyer Payments', formatCurrency(s.totalBuyerPayments), AppColors.primary),
          _row('Outstanding Balance', formatCurrency(s.totalOutstandingBalance), AppColors.warning),
          _divider(),
          _row('DEO Total', formatCurrency(s.deoTotal), AppColors.secondary),
          _row('DEO Paid', formatCurrency(s.deoPaid), AppColors.primary),
          _row('DEO Remaining', formatCurrency(s.deoRemaining), AppColors.warning),
        ],
      );
    });
  }

  Widget _row(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 14)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(color: AppColors.primary.withOpacity(0.2)));
}
