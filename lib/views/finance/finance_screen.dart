
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/finance_provider.dart';
import '../../providers/crop_provider.dart';
import '../../models/transaction_model.dart';
import '../../services/report_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Seeds';
  bool _isIncome = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FinanceProvider>().fetchTransactions());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? const Color(0xFFD32F2F) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── PDF ───────────────────────────────────────────────────────────────────
  void _generatePDF(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final crops = Provider.of<CropProvider>(context, listen: false).crops;
    _showSnackbar("Generating Farm Report PDF...", isError: false);
    ReportService.generateFarmReport(
      transactions: finance.transactions,
      crops: crops,
      totalIncome: finance.totalIncome,
      totalExpense: finance.totalExpenses,
    );
  }

  // ── Delete Dialog ─────────────────────────────────────────────────────────
  Future<bool?> _showDeleteDialog(TransactionModel transaction) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 28),
              ),
              const SizedBox(height: 16),
              const Text("Delete Record?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(
                "Remove GHS ${transaction.amount.toStringAsFixed(2)} from records? This cannot be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7A7A7A), side: const BorderSide(color: Color(0xFFE0E0E0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Transaction Sheet ─────────────────────────────────────────────────────
  void _showTransactionSheet({TransactionModel? existingTransaction}) {
    final bool isEditing = existingTransaction != null;

    if (isEditing) {
      _amountController.text = existingTransaction.amount.toString();
      _noteController.text = existingTransaction.note;
      _isIncome = existingTransaction.isIncome;
      _selectedCategory = existingTransaction.category;
    } else {
      _amountController.clear();
      _noteController.clear();
      _isIncome = false;
      _selectedCategory = 'Seeds';
    }
    _isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEditing ? const Color(0xFFE3F2FD) : const Color(0xFFEAF4DE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_chart_rounded,
                      color: isEditing ? const Color(0xFF1565C0) : AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? "Update Transaction" : "New Record",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type Toggle
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _buildTypeToggle("Expense", !_isIncome, const Color(0xFFD32F2F), const Color(0xFFFFEBEE), () => setSheetState(() { _isIncome = false; _selectedCategory = 'Seeds'; })),
                      _buildTypeToggle("Income", _isIncome, AppTheme.primaryGreen, const Color(0xFFEAF4DE), () => setSheetState(() { _isIncome = true; _selectedCategory = 'Crop Sale'; })),
                    ],
                  ),
                ),
              if (!isEditing) const SizedBox(height: 18),

              // Amount field — letters blocked in real time
              _amountField(
                accentColor: _isIncome ? AppTheme.primaryGreen : const Color(0xFFD32F2F),
              ),
              const SizedBox(height: 14),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGreen),
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
                  prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryGreen, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF9FCF5),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: (_isIncome ? ['Crop Sale', 'Service', 'Subsidy'] : ['Seeds', 'Fertilizer', 'Labor', 'Tools', 'Transport'])
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setSheetState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 14),

              // Note
              _sheetField(controller: _noteController, label: "Description / Note", icon: Icons.notes_rounded, accentColor: AppTheme.primaryGreen),
              const SizedBox(height: 22),

              // Save Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : () async {
                    // ── VALIDATION ──
                    final amountText = _amountController.text.trim();

                    if (amountText.isEmpty) {
                      _showSnackbar("Amount is required.");
                      return;
                    }
                    // Extra guard — reject if any letter slipped through
                    if (RegExp(r'[a-zA-Z]').hasMatch(amountText)) {
                      _showSnackbar("Amount must contain numbers only. No letters allowed.");
                      return;
                    }
                    final double? amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      _showSnackbar("Enter a valid amount greater than 0.");
                      return;
                    }
                    if (amount > 9999999) {
                      _showSnackbar("Amount seems too large. Please verify.");
                      return;
                    }

                    setSheetState(() => _isSaving = true);
                    final transaction = TransactionModel(
                      id: isEditing ? existingTransaction.id : '',
                      category: _selectedCategory,
                      amount: amount,
                      date: isEditing ? existingTransaction.date : DateTime.now(),
                      note: _noteController.text,
                      isIncome: _isIncome,
                    );
                    if (isEditing) {
                      await context.read<FinanceProvider>().updateTransaction(transaction);
                    } else {
                      await context.read<FinanceProvider>().addTransaction(transaction);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.check_rounded : Icons.save_alt_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(isEditing ? "Update Record" : "Save Record", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amount field — blocks letters in real time ────────────────────────────
  Widget _amountField({required Color accentColor}) {
    return TextField(
      controller: _amountController,
      // Only allow digits and a single decimal point — letters physically cannot be typed
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Block any character that is not a digit or a dot
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        // Custom formatter to allow only one decimal point
        _SingleDecimalFormatter(),
      ],
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: "Amount (GHS) *",
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
        hintText: "e.g. 250.00",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(Icons.payments_rounded, color: accentColor, size: 18),
        prefixText: "GHS  ",
        prefixStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FCF5),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
        prefixIcon: Icon(icon, color: accentColor, size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FCF5),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTypeToggle(String label, bool isSelected, Color activeColor, Color activeBg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(label == "Income" ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isSelected ? activeColor : const Color(0xFFAAAAAA), size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isSelected ? activeColor : const Color(0xFFAAAAAA), fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 4,
        onPressed: () => _showTransactionSheet(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSummary(finance),
          _buildSectionHeader(),
          Expanded(
            child: finance.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : finance.transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: finance.transactions.length,
              itemBuilder: (context, index) => _buildTransactionCard(finance.transactions[index]),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2D7A0A),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text("Farm Finances", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white, letterSpacing: -0.2)),
      actions: [
        GestureDetector(
          onTap: () => _generatePDF(context),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(FinanceProvider finance) {
    final bool isProfit = finance.netProfit >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text("NET PROFIT", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text("GHS ${finance.netProfit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMiniStat("Total Income", finance.totalIncome, Icons.arrow_upward_rounded, Colors.greenAccent.shade100)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _buildMiniStat("Total Expenses", finance.totalExpenses, Icons.arrow_downward_rounded, Colors.red.shade200, alignRight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, IconData icon, Color iconColor, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignRight) ...[Icon(icon, color: iconColor, size: 13), const SizedBox(width: 4)],
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w600)),
            if (alignRight) ...[const SizedBox(width: 4), Icon(icon, color: iconColor, size: 13)],
          ],
        ),
        const SizedBox(height: 4),
        Text("GHS ${value.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFEAF4DE), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 10),
          const Text("Transaction History", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D5016), letterSpacing: -0.2)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel item) {
    final bool isIncome = item.isIncome;
    final Color accentColor = isIncome ? AppTheme.primaryGreen : const Color(0xFFD32F2F);
    final Color bgColor = isIncome ? const Color(0xFFEAF4DE) : const Color(0xFFFFEBEE);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteDialog(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text("Delete", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => context.read<FinanceProvider>().deleteTransaction(item.id),
      child: GestureDetector(
        onTap: () => _showTransactionSheet(existingTransaction: item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(_getCategoryIcon(item.category), color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A))),
                        Text("${isIncome ? '+' : '-'} GHS ${item.amount.toStringAsFixed(2)}", style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(item.date), style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(isIncome ? "Income" : "Expense", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.note, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Seeds': return Icons.grass_rounded;
      case 'Fertilizer': return Icons.science_rounded;
      case 'Labor': return Icons.engineering_rounded;
      case 'Crop Sale': return Icons.payments_rounded;
      case 'Tools': return Icons.handyman_rounded;
      case 'Transport': return Icons.local_shipping_rounded;
      case 'Service': return Icons.miscellaneous_services_rounded;
      case 'Subsidy': return Icons.volunteer_activism_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(color: Color(0xFFEAF4DE), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_rounded, size: 40, color: AppTheme.primaryGreen.withOpacity(0.45)),
            ),
            const SizedBox(height: 20),
            const Text("No records yet", style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text("Tap '+ New Record' to log your first income or expense.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Custom formatter — allows only one decimal point ─────────────────────────
class _SingleDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    // Block if more than one decimal point
    if ('.'.allMatches(text).length > 1) return oldValue;
    // Block if more than 2 decimal places
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts[1].length > 2) return oldValue;
    }
    return newValue;
  }
}