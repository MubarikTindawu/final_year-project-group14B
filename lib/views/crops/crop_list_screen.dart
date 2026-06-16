import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/crop_provider.dart';
import '../../models/crop_model.dart';
import 'add_crop_screen.dart';
import 'crop_detail_screen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({super.key});

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.microtask(() => context.read<CropProvider>().fetchCrops());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateCropStats(CropModel crop) => {
    'progress': crop.calculatedProgress,
    'daysLeft': crop.daysRemaining,
    'stage': crop.growthStage,
  };

  Future<bool?> _confirmDelete(BuildContext context, String cropName) {
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
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFD32F2F), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                "Delete Crop?",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              Text(
                "Remove $cropName from your farm records? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF6A6A6A), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7A7A7A),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Delete",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
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

  @override
  Widget build(BuildContext context) {
    final cropProvider = Provider.of<CropProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, cropProvider, innerBoxIsScrolled),
        ],
        body: cropProvider.isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : TabBarView(
          controller: _tabController,
          children: [
            _buildCropList(
                cropProvider.crops, "No active crops growing"),
            _buildCropList(
                cropProvider.harvestedCrops, "No harvest records yet"),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(
      BuildContext context, CropProvider cropProvider, bool innerBoxIsScrolled) {
    final activeCrops = cropProvider.crops.length;
    final harvestedCrops = cropProvider.harvestedCrops.length;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => cropProvider.fetchCrops(),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Farm Management",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Ghana Best Hub",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickStat(
                          "$activeCrops", "Active", Icons.eco_rounded),
                      const SizedBox(width: 12),
                      _buildQuickStat("$harvestedCrops", "Harvested",
                          Icons.task_alt_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.primaryGreen,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grass_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text("Active (${cropProvider.crops.length})"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text("History (${cropProvider.harvestedCrops.length})"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            "$value $label",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primaryGreen,
      elevation: 4,
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddCropScreen())),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        "New Crop",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  // ── Crop List ─────────────────────────────────────────────────────────────
  Widget _buildCropList(List<CropModel> list, String emptyMessage) {
    if (list.isEmpty) return _buildEmptyState(emptyMessage);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final crop = list[index];
        final stats = _calculateCropStats(crop);
        final String cropIcon =
            CropData.standards[crop.name]?['icon'] ?? '🌱';

        return Dismissible(
          key: Key(crop.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _confirmDelete(context, crop.name),
          onDismissed: (direction) =>
              Provider.of<CropProvider>(context, listen: false)
                  .deleteCrop(crop.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text("Delete",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          child: _buildCropCard(context, crop, stats, cropIcon),
        );
      },
    );
  }

  // ── Crop Card ─────────────────────────────────────────────────────────────
  Widget _buildCropCard(BuildContext context, CropModel crop,
      Map<String, dynamic> stats, String cropIcon) {
    final double progress = stats['progress'] as double;
    final int daysLeft = stats['daysLeft'] as int;
    final String stage = stats['stage'] as String;
    final bool isOverdue = daysLeft < 0 && !crop.isHarvested;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CropDetailScreen(crop: crop))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row ──
              Row(
                children: [
                  // Emoji icon in a coloured chip
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4DE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(cropIcon,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          crop.variety,
                          style: const TextStyle(
                              color: Color(0xFF9A9A9A), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStageBadge(stage, crop.isHarvested),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF4F4F4), height: 1),
              const SizedBox(height: 14),

              // ── Progress ──
              _buildProgressSection(progress, crop.isHarvested),

              const SizedBox(height: 14),

              // ── Bottom Stats Row ──
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.map_outlined,
                    label: "${crop.area} ac",
                    color: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  if (crop.isHarvested)
                    _buildStatChip(
                      icon: Icons.inventory_2_outlined,
                      label: crop.yieldAmount,
                      color: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFF57C00),
                    )
                  else
                    _buildStatChip(
                      icon: isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.timer_outlined,
                      label: isOverdue
                          ? "${daysLeft.abs()} days overdue"
                          : "$daysLeft days left",
                      color: isOverdue
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFEAF4DE),
                      iconColor: isOverdue
                          ? const Color(0xFFD32F2F)
                          : AppTheme.primaryGreen,
                    ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFCCCCCC), size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageBadge(String stage, bool isHarvested) {
    final Color bg = isHarvested
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFEAF4DE);
    final Color fg = isHarvested
        ? const Color(0xFFF57C00)
        : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        stage,
        style: TextStyle(
            color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _buildProgressSection(double progress, bool isHarvested) {
    final Color barColor =
    isHarvested ? const Color(0xFFF57C00) : AppTheme.primaryGreen;
    final int pct = (progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isHarvested ? "Cycle Complete" : "Growth Progress",
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A9A9A),
                  fontWeight: FontWeight.w500),
            ),
            Text(
              "$pct%",
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFFF0F0F0),
            color: barColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    final bool isActive = message.contains("active");
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4DE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.grass_rounded : Icons.history_rounded,
                size: 44,
                color: AppTheme.primaryGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF5A5A5A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? "Tap '+ New Crop' to start tracking your first crop."
                  : "Completed harvests will appear here.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}