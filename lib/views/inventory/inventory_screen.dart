import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isSaving = false;
  String _searchQuery = "";
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _suggestedItems = [
    {"name": "Maize", "category": "Crops"},
    {"name": "Rice", "category": "Crops"},
    {"name": "NPK Fertilizer", "category": "Chemicals"},
    {"name": "Seedlings", "category": "Seeds"},
    {"name": "Poultry Feed", "category": "Feed"},
    {"name": "Pesticide", "category": "Chemicals"},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().fetchInventory());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'crops': return Icons.agriculture_rounded;
      case 'seeds': return Icons.grass_rounded;
      case 'chemicals': return Icons.science_rounded;
      case 'feed': return Icons.bakery_dining_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'crops': return const Color(0xFF2E7D32);
      case 'seeds': return const Color(0xFF558B2F);
      case 'chemicals': return const Color(0xFF6A1B9A);
      case 'feed': return const Color(0xFFE65100);
      default: return const Color(0xFF1565C0);
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 16,
          ),
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final filteredItems = inventory.inventoryItems
        .where((item) =>
        item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final lowStockCount =
        inventory.inventoryItems.where((i) => i.quantity <= i.minThreshold).length;
    final totalItems = inventory.inventoryItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: _buildAppBar(context, inventory),
      body: inventory.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
        onRefresh: () => inventory.fetchInventory(),
        color: AppTheme.primaryGreen,
        child: Column(
          children: [
            _buildTopSection(lowStockCount, totalItems),
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _buildList(filteredItems, inventory),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, inventory),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, InventoryProvider inventory) {
    return AppBar(
      backgroundColor: const Color(0xFF2D7A0A),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        "Stock Inventory",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white, letterSpacing: -0.2),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            if (inventory.inventoryItems.isNotEmpty) {
              ReportService.generateInventoryReport(inventory.inventoryItems);
            } else {
              _showSnackbar("No inventory data to export.", isError: false);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // ── Top Section ───────────────────────────────────────────────────────────
  Widget _buildTopSection(int lowStockCount, int totalItems) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search stock...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.inventory_2_rounded,
                label: "$totalItems Items",
                bgColor: Colors.white.withOpacity(0.2),
                textColor: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                icon: lowStockCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                label: lowStockCount > 0 ? "$lowStockCount Low Stock" : "All Stocked",
                bgColor: lowStockCount > 0 ? const Color(0xFFFFEBEE) : Colors.white.withOpacity(0.2),
                textColor: lowStockCount > 0 ? const Color(0xFFD32F2F) : Colors.white,
                iconColor: lowStockCount > 0 ? const Color(0xFFD32F2F) : Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color bgColor, required Color textColor, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? textColor, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, InventoryProvider provider) {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primaryGreen,
      elevation: 4,
      onPressed: () => _showAddItemDialog(context, provider),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text("New Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _buildList(List<InventoryModel> items, InventoryProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isLow = item.quantity <= item.minThreshold;
        return _buildInventoryCard(item, isLow, provider);
      },
    );
  }

  Widget _buildInventoryCard(InventoryModel item, bool isLow, InventoryProvider provider) {
    final double stockPercent = (item.quantity / (item.minThreshold * 3)).clamp(0.0, 1.0);
    final Color catColor = _getCategoryColor(item.category);
    final IconData catIcon = _getCategoryIcon(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text("Delete", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context, item.itemName),
      onDismissed: (_) => provider.deleteInventoryItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          border: isLow ? Border.all(color: const Color(0xFFFFCDD2), width: 1.2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isLow ? const Color(0xFFFFEBEE) : catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(isLow ? Icons.warning_amber_rounded : catIcon, color: isLow ? const Color(0xFFD32F2F) : catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: catColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text(item.category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                            Text("${item.quantity} ${item.unit}", style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStockBadge(isLow),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stockPercent,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(isLow ? const Color(0xFFD32F2F) : AppTheme.primaryGreen),
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Min threshold: ${item.minThreshold} ${item.unit}", style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF4F4F4), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _actionButton("Sell / Use", Icons.remove_circle_outline_rounded, const Color(0xFFD32F2F), const Color(0xFFFFEBEE), () => _showUpdateStockDialog(context, item, false))),
                  const SizedBox(width: 10),
                  Expanded(child: _actionButton("Restock", Icons.add_circle_outline_rounded, AppTheme.primaryGreen, const Color(0xFFEAF4DE), () => _showUpdateStockDialog(context, item, true))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(bool isLow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFEAF4DE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(isLow ? "Low" : "Stable", style: TextStyle(color: isLow ? const Color(0xFFD32F2F) : AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, Color bgColor, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ───────────────────────────────────────────────────
  Future<bool?> _confirmDelete(BuildContext context, String itemName) {
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
              const Text("Delete Item?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text("Remove \"$itemName\" from inventory? This cannot be undone.", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 13, height: 1.5)),
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

  // ── Update Stock Dialog (with validation) ─────────────────────────────────
  void _showUpdateStockDialog(BuildContext context, InventoryModel item, bool isRestock) {
    final amountController = TextEditingController();
    final Color accentColor = isRestock ? AppTheme.primaryGreen : const Color(0xFFD32F2F);
    final Color bgColor = isRestock ? const Color(0xFFEAF4DE) : const Color(0xFFFFEBEE);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(isRestock ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isRestock ? "Restock Item" : "Sell / Use Stock", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1A1A))),
                        Text(item.itemName, style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Current stock: ${item.quantity} ${item.unit}", style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: "Amount (${item.unit})",
                  hintText: "e.g. 10",
                  prefixIcon: Icon(isRestock ? Icons.add_rounded : Icons.remove_rounded, color: accentColor, size: 20),
                  filled: true,
                  fillColor: bgColor.withOpacity(0.5),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7A7A7A), side: const BorderSide(color: Color(0xFFE0E0E0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // ── VALIDATION ──
                        final text = amountController.text.trim();
                        if (text.isEmpty) {
                          _showSnackbar("Please enter an amount.");
                          return;
                        }
                        final double? amount = double.tryParse(text);
                        if (amount == null || amount <= 0) {
                          _showSnackbar("Enter a valid amount greater than 0.");
                          return;
                        }
                        if (!isRestock && amount > item.quantity) {
                          _showSnackbar("Cannot use more than available stock (${item.quantity} ${item.unit}).");
                          return;
                        }
                        context.read<InventoryProvider>().updateStockLevel(item.id, amount, isRestock: isRestock);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: Text(isRestock ? "Restock" : "Confirm", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

  // ── Add Item Dialog (with validation) ─────────────────────────────────────
  void _showAddItemDialog(BuildContext context, InventoryProvider provider) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: "Bags");
    final thresholdController = TextEditingController(text: "5.0");
    String selectedCategory = "General";
    setState(() => _isSaving = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFEAF4DE), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text("New Stock Entry", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1A1A1A))),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Select
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Quick Select",
                    labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
                    prefixIcon: const Icon(Icons.flash_on_rounded, color: AppTheme.primaryGreen, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF9FCF5),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGreen),
                  items: _suggestedItems.map((item) => DropdownMenuItem<String>(value: item['name'], child: Text(item['name'] as String))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      nameController.text = val;
                      selectedCategory = _suggestedItems.firstWhere((e) => e['name'] == val)['category'];
                    }
                  },
                ),
                const SizedBox(height: 14),

                _dialogFieldLettersOnly(nameController, "Item Name *", Icons.label_outline_rounded),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _dialogField(qtyController, "Quantity *", Icons.numbers_rounded, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _dialogField(unitController, "Unit *", Icons.straighten_rounded)),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7A7A7A), side: const BorderSide(color: Color(0xFFE0E0E0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 13)),
                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                          // ── VALIDATION ──
                          final name = nameController.text.trim();
                          final qtyText = qtyController.text.trim();
                          final unit = unitController.text.trim();

                          if (name.isEmpty) {
                            _showSnackbar("Item name is required.");
                            return;
                          }
                          if (name.length < 2) {
                            _showSnackbar("Item name must be at least 2 characters.");
                            return;
                          }
                          if (RegExp(r'[0-9]').hasMatch(name)) {
                            _showSnackbar("Item name must not contain numbers.");
                            return;
                          }
                          if (!RegExp(r'^[a-zA-Z\s\(\)\-\/]+\$').hasMatch(name)) {
                            _showSnackbar("Item name must contain letters only.");
                            return;
                          }
                          if (qtyText.isEmpty) {
                            _showSnackbar("Quantity is required.");
                            return;
                          }
                          final double? qty = double.tryParse(qtyText);
                          if (qty == null || qty < 0) {
                            _showSnackbar("Enter a valid quantity (0 or more).");
                            return;
                          }
                          if (unit.isEmpty) {
                            _showSnackbar("Unit is required (e.g. Bags, Kg, Litres).");
                            return;
                          }

                          setDialogState(() => _isSaving = true);
                          final newItem = InventoryModel(
                            id: '',
                            itemName: name,
                            quantity: qty,
                            unit: unit,
                            minThreshold: double.tryParse(thresholdController.text) ?? 5.0,
                            category: selectedCategory,
                          );
                          await provider.addInventoryItem(newItem);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FCF5),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }

  // ── Letters-only field (blocks number input in real time) ────────────────
  Widget _dialogFieldLettersOnly(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.name,
      inputFormatters: [
        // Blocks digits as the user types — no numbers can be entered at all
        FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
      ],
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 18),
        hintText: "e.g. Maize, NPK Fertilizer",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF9FCF5),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final bool isSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(color: Color(0xFFEAF4DE), shape: BoxShape.circle),
              child: Icon(isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined, size: 40, color: AppTheme.primaryGreen.withOpacity(0.45)),
            ),
            const SizedBox(height: 20),
            Text(isSearch ? "No results found" : "No stock items yet", style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              isSearch ? "Try a different search term." : "Tap '+ New Entry' to add your first stock item.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}