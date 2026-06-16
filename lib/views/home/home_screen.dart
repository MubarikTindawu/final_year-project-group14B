import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crop_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/navigation_provider.dart';
import '../crops/add_crop_screen.dart';
import '../crops/crop_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAllData());
  }

  void _refreshAllData() {
    context.read<CropProvider>().fetchCrops();
    context.read<FinanceProvider>().fetchTransactions();
    context.read<InventoryProvider>().fetchInventory();
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cropProvider = Provider.of<CropProvider>(context);
    final financeProvider = Provider.of<FinanceProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    final int activeCrops = cropProvider.crops.length;
    final double totalAcres =
    cropProvider.crops.fold(0.0, (sum, item) => sum + item.area);
    final bool hasLowStock = inventoryProvider.inventoryItems
        .any((item) => item.quantity <= item.minThreshold);
    final String firstName =
        (auth.user?.displayName ?? 'Farmer').split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      // Plain AppBar — one title, one bell, no FlexibleSpace, no overlap ever
      appBar: _buildAppBar(context, firstName, hasLowStock, inventoryProvider),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAllData(),
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient hero sits flush under the AppBar
              _buildHeaderHero(firstName),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherCard(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(activeCrops, totalAcres, financeProvider,
                        cropProvider.isLoading),
                    const SizedBox(height: 16),
                    _buildInventoryAlerts(inventoryProvider),
                    _buildAddCropCTA(),
                    const SizedBox(height: 28),
                    _buildSectionHeader("Active Crops", "$activeCrops growing"),
                    const SizedBox(height: 12),
                    cropProvider.isLoading
                        ? _buildLoadingShimmer()
                        : (activeCrops == 0
                        ? _buildEmptyPrompt()
                        : _buildMiniCropList(cropProvider)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, String firstName,
      bool hasLowStock, InventoryProvider inventoryProvider) {
    return AppBar(
      backgroundColor: const Color(0xFF2D7A0A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Farm Manager",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () =>
              _showNotificationsBottomSheet(context, inventoryProvider),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 20),
              ),
              if (hasLowStock)
                Positioned(
                  right: 14,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header Hero ───────────────────────────────────────────────────────────
  Widget _buildHeaderHero(String firstName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good ${_timeGreeting()} 👋",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 3),
          Text(
            "Ghana Best Hub",
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Notifications Bottom Sheet ────────────────────────────────────────────
  void _showNotificationsBottomSheet(
      BuildContext context, InventoryProvider provider) {
    final lowStockItems = provider.inventoryItems
        .where((item) => item.quantity <= item.minThreshold)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Notifications",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 16),
            if (lowStockItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 44,
                          color: AppTheme.primaryGreen.withOpacity(0.4)),
                      const SizedBox(height: 10),
                      const Text("All clear! No alerts right now.",
                          style: TextStyle(
                              color: Color(0xFF9A9A9A), fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  context.read<NavigationProvider>().setIndex(2);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFFFCDD2), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFD32F2F), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${lowStockItems.length} Low Stock Item${lowStockItems.length > 1 ? 's' : ''}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF7A0000)),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Tap to go to Stock Management",
                              style: TextStyle(
                                  color: Color(0xFFD32F2F), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: Color(0xFFD32F2F)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Weather Card ──────────────────────────────────────────────────────────
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Accra, Ghana",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "29°C",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Sunny · Good day for fieldwork",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.wb_sunny_rounded,
                  color: Colors.amber, size: 52),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Live",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary Row ───────────────────────────────────────────────────────────
  Widget _buildSummaryRow(int activeCrops, double totalAcres,
      FinanceProvider financeProvider, bool isLoading) {
    final double net = financeProvider.netProfit;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Active Crops",
            value: "$activeCrops",
            icon: Icons.eco_rounded,
            color: AppTheme.primaryGreen,
            bgColor: const Color(0xFFEAF4DE),
            loading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: "Total Land",
            value: "${totalAcres.toStringAsFixed(1)} ac",
            icon: Icons.landscape_rounded,
            color: const Color(0xFFF57C00),
            bgColor: const Color(0xFFFFF3E0),
            loading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: "Net Balance",
            value: "GHS ${net.toStringAsFixed(0)}",
            icon: Icons.account_balance_wallet_rounded,
            color: net >= 0
                ? const Color(0xFF1565C0)
                : const Color(0xFFD32F2F),
            bgColor: net >= 0
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFFFEBEE),
            loading: financeProvider.isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool loading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          loading
              ? Container(
            height: 18,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(6),
            ),
          )
              : Text(
            value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Inventory Alert ───────────────────────────────────────────────────────
  Widget _buildInventoryAlerts(InventoryProvider provider) {
    final lowStockItems = provider.inventoryItems
        .where((item) => item.quantity <= item.minThreshold)
        .toList();
    if (lowStockItems.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        context.read<NavigationProvider>().setIndex(2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text("Opening Stock Management..."),
            ]),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFD32F2F), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stock Warnings (${lowStockItems.length})",
                    style: const TextStyle(
                        color: Color(0xFF7A0000),
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  ...lowStockItems.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "• ${item.itemName}: ${item.quantity} ${item.unit} left",
                      style: const TextStyle(
                          color: Color(0xFFD32F2F), fontSize: 12),
                    ),
                  )),
                  if (lowStockItems.length > 2)
                    Text(
                      "+${lowStockItems.length - 2} more items",
                      style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }

  // ── Add Crop CTA ──────────────────────────────────────────────────────────
  Widget _buildAddCropCTA() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddCropScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_task_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Register New Crop",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Start tracking a new planting cycle",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D5016),
              letterSpacing: -0.2),
        ),
        Text(
          subtitle,
          style: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Loading Shimmer ───────────────────────────────────────────────────────
  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(
        3,
            (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 13,
                        width: 120,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 7),
                    Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty Prompt ──────────────────────────────────────────────────────────
  Widget _buildEmptyPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4DE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco_outlined,
                size: 36,
                color: AppTheme.primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          const Text(
            "No active crops yet",
            style: TextStyle(
                color: Color(0xFF4A4A4A),
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap 'Register New Crop' above to start\ntracking your farm.",
            textAlign: TextAlign.center,
            style:
            TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Mini Crop List ────────────────────────────────────────────────────────
  Widget _buildMiniCropList(CropProvider provider) {
    final topCrops = provider.crops.take(3).toList();
    return Column(
      children: topCrops.map((crop) {
        final double progress = crop.calculatedProgress;
        final int pct = (progress * 100).clamp(0, 100).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CropDetailScreen(crop: crop))),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4DE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.eco_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  color: AppTheme.primaryGreen,
                                  backgroundColor: const Color(0xFFF0F0F0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$pct%",
                              style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}