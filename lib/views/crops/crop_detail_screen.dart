import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import 'package:intl/intl.dart';

class CropDetailScreen extends StatelessWidget {
  final CropModel crop;

  const CropDetailScreen({super.key, required this.crop});

  // ── Harvest Dialog ────────────────────────────────────────────────────────
  void _showHarvestDialog(BuildContext context) {
    final TextEditingController yieldController = TextEditingController();
    final cropProvider = Provider.of<CropProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture_rounded,
                        color: Color(0xFFF57C00), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Record Harvest",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A)),
                        ),
                        Text(
                          crop.name,
                          style: const TextStyle(
                              color: Color(0xFF7A7A7A), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter the final yield collected from this harvest.",
                style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yieldController,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: "Yield Amount",
                  hintText: "e.g. 45 Bags, 2 Tons",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFFF57C00), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFFFFBF5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFFFE0B2), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFF57C00), width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7A7A7A),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (yieldController.text.isNotEmpty) {
                          await cropProvider.completeHarvest(
                              crop.id, yieldController.text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text("Harvest recorded successfully!"),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFF57C00),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Complete",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double progress = crop.calculatedProgress;
    final int daysLeft = crop.daysRemaining;
    final String stage = crop.growthStage;
    final bool isReady = progress >= 1.0 && !crop.isHarvested;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(progress, daysLeft, stage),
            const SizedBox(height: 16),
            _buildProgressCard(context, progress, daysLeft, isReady),
            const SizedBox(height: 16),

            if (crop.isHarvested) ...[
              _buildHarvestResultCard(),
              const SizedBox(height: 16),
            ],

            _buildSectionLabel("Growth Timeline"),
            const SizedBox(height: 10),
            _buildTimeline(),
            const SizedBox(height: 16),

            _buildSectionLabel("Crop Details"),
            const SizedBox(height: 10),
            _buildInfoGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Color(0xFF2D5016)),
        ),
      ),
      title: Column(
        children: [
          Text(
            crop.name,
            style: const TextStyle(
                color: Color(0xFF2D5016),
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3),
          ),
          Text(
            crop.variety,
            style: const TextStyle(color: Color(0xFF7A9A5A), fontSize: 12),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  // ── Status Banner (top strip) ─────────────────────────────────────────────
  Widget _buildStatusBanner(double progress, int daysLeft, String stage) {
    final bool isOverdue = daysLeft < 0 && !crop.isHarvested;
    Color bgColor;
    Color textColor;
    IconData icon;
    String message;

    if (crop.isHarvested) {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFF57C00);
      icon = Icons.task_alt_rounded;
      message = "This crop cycle is complete";
    } else if (isOverdue) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFD32F2F);
      icon = Icons.warning_amber_rounded;
      message = "Harvest is overdue by ${daysLeft.abs()} days";
    } else if (daysLeft == 0) {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFF57C00);
      icon = Icons.notifications_active_rounded;
      message = "Expected harvest is today!";
    } else {
      bgColor = const Color(0xFFEAF4DE);
      textColor = const Color(0xFF2D7A0A);
      icon = Icons.eco_rounded;
      message = "$daysLeft days until expected harvest · $stage";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────────────────
  Widget _buildProgressCard(
      BuildContext context, double progress, int daysLeft, bool isReady) {
    final Color accentColor =
    crop.isHarvested ? const Color(0xFFF57C00) : AppTheme.primaryGreen;
    final int pct = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Big percentage / harvested label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.isHarvested ? "Harvested" : "Growth Progress",
                      style: const TextStyle(
                          color: Color(0xFF7A7A7A),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crop.isHarvested ? "100%" : "$pct%",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              // Circle icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  crop.isHarvested
                      ? Icons.task_alt_rounded
                      : Icons.local_florist_rounded,
                  color: accentColor,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress bar with percentage label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 14,
                  color: accentColor,
                  backgroundColor: const Color(0xFFF0F0F0),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Planted: ${DateFormat('MMM dd').format(crop.plantedDate)}",
                    style: const TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 11),
                  ),
                  Text(
                    "Harvest: ${DateFormat('MMM dd').format(crop.expectedHarvestDate)}",
                    style: const TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Harvest button
          if (isReady) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showHarvestDialog(context),
                icon: const Icon(Icons.agriculture_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  "Record Harvest",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Harvest Result Card ───────────────────────────────────────────────────
  Widget _buildHarvestResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.stars_rounded,
                color: Color(0xFFF57C00), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Harvest Summary",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF7A3800)),
                ),
                const SizedBox(height: 4),
                Text(
                  crop.yieldAmount,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A2200)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D5016),
          letterSpacing: -0.2),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────
  Widget _buildTimeline() {
    final now = DateTime.now();
    final bool harvestPassed =
        crop.isHarvested || now.isAfter(crop.expectedHarvestDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          _timelineRow(
            icon: Icons.wb_sunny_rounded,
            title: "Planted",
            date: crop.plantedDate,
            isPast: true,
            isFirst: true,
          ),
          _timelineConnector(filled: true),
          _timelineRow(
            icon: crop.isHarvested
                ? Icons.check_circle_rounded
                : Icons.today_rounded,
            title: crop.isHarvested ? "Harvested" : "Today",
            date: now,
            isPast: true,
          ),
          _timelineConnector(filled: harvestPassed),
          _timelineRow(
            icon: Icons.agriculture_rounded,
            title: "Expected Harvest",
            date: crop.expectedHarvestDate,
            isPast: harvestPassed,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String title,
    required DateTime date,
    required bool isPast,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final Color active = AppTheme.primaryGreen;
    final Color inactive = const Color(0xFFCCCCCC);

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPast
                    ? active.withOpacity(0.12)
                    : inactive.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isPast ? active : inactive, size: 20),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isPast
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM dd, yyyy').format(date),
                style: const TextStyle(
                    color: Color(0xFF9A9A9A), fontSize: 12),
              ),
            ],
          ),
        ),
        if (isPast)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4DE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.primaryGreen, size: 14),
          ),
      ],
    );
  }

  Widget _timelineConnector({required bool filled}) {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      height: 28,
      width: 2,
      decoration: BoxDecoration(
        color: filled
            ? AppTheme.primaryGreen.withOpacity(0.4)
            : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Info Grid ─────────────────────────────────────────────────────────────
  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _infoTile(
            label: "Variety",
            value: crop.variety,
            icon: Icons.spa_outlined,
            color: const Color(0xFFEAF4DE),
            iconColor: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _infoTile(
            label: "Farm Size",
            value: "${crop.area} Acres",
            icon: Icons.map_outlined,
            color: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A1A)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}