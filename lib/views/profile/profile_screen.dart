import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

const String _imgbbApiKey = 'f71df090fc754ab4b27cfbfb7bf0402a';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isUploading = false;
  bool _isSaving = false;

  String? _localPhotoUrl;

  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.user?.displayName ?? "Farmer Name";
    _farmNameController.text = "Green Valley Farm";
    _locationController.text = "Greater Accra, Ghana";
    _localPhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Image Upload via ImgBB ────────────────────────────────────────────────
  Future<void> _handleImageSelection(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
      );
      if (image == null) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String imageUrl = data['data']['url'];

        final user = FirebaseAuth.instance.currentUser;
        await user?.updatePhotoURL(imageUrl);
        await FirebaseAuth.instance.currentUser?.reload();

        if (mounted) {
          setState(() {
            _isUploading = false;
            _localPhotoUrl = imageUrl;
          });
          _showSnackbar("Profile photo updated!", isError: false);
        }
      } else {
        throw Exception("ImgBB upload failed: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackbar("Upload failed: ${e.toString()}", isError: true);
      }
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor:
        isError ? const Color(0xFFD32F2F) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Image Picker Bottom Sheet ─────────────────────────────────────────────
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Update Profile Photo",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  color: const Color(0xFF1565C0),
                  bgColor: const Color(0xFFE3F2FD),
                  onTap: () {
                    Navigator.pop(context);
                    _handleImageSelection(ImageSource.camera);
                  },
                ),
                const SizedBox(width: 24),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  color: const Color(0xFFF57C00),
                  bgColor: const Color(0xFFFFF3E0),
                  onTap: () {
                    Navigator.pop(context);
                    _handleImageSelection(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF4A4A4A))),
        ],
      ),
    );
  }

  // ── Save Profile ──────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(_nameController.text.trim());
      await FirebaseAuth.instance.currentUser?.reload();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        _showSnackbar("Profile saved successfully!", isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackbar("Failed to save. Try again.", isError: true);
      }
    }
  }

  // ── Logout Confirmation ───────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFD32F2F), size: 28),
              ),
              const SizedBox(height: 16),
              const Text("Log Out?",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              const Text(
                "You will be signed out of your Farm Manager account.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6A6A6A), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7A7A7A),
                        side:
                        const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Cancel",
                          style:
                          TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authProvider.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Log Out",
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: _buildAppBar(user),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHero(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  _buildSectionLabel(
                      "Personal Info", Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildFieldTile(
                      label: "Full Name",
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    _buildDivider(),
                    _buildFieldTile(
                      label: "Email Address",
                      controller:
                      TextEditingController(text: user?.email ?? ''),
                      icon: Icons.alternate_email_rounded,
                      isEditable: false,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionLabel(
                      "Farm Details", Icons.agriculture_rounded),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildFieldTile(
                      label: "Farm Name",
                      controller: _farmNameController,
                      icon: Icons.eco_rounded,
                    ),
                    _buildDivider(),
                    _buildFieldTile(
                      label: "Location",
                      controller: _locationController,
                      icon: Icons.location_on_outlined,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, authProvider),
                  const SizedBox(height: 12),
                  const Text(
                    "Ghana Best Hub · Farm Manager v1.0",
                    style: TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(User? user) {
    return AppBar(
      backgroundColor: const Color(0xFF2D7A0A),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        "My Profile",
        style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
            letterSpacing: -0.2),
      ),
      actions: [
        GestureDetector(
          onTap: () async {
            if (_isEditing) {
              await _saveProfile();
            } else {
              setState(() => _isEditing = true);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _isSaving
                ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing
                      ? Icons.check_rounded
                      : Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _isEditing ? "Save" : "Edit",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Profile Hero ──────────────────────────────────────────────────────────
  Widget _buildProfileHero(User? user) {
    final String? photoUrl = _localPhotoUrl ?? user?.photoURL;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D7A0A), Color(0xFF5AA518)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipOval(
                  child: _isUploading
                      ? Container(
                    color: const Color(0xFFEAF4DE),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    ),
                  )
                      : (photoUrl != null
                      ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    key: ValueKey(photoUrl),
                    errorBuilder: (_, __, ___) =>
                        _avatarPlaceholder(),
                  )
                      : _avatarPlaceholder()),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _showImagePickerOptions,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppTheme.primaryGreen, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : "Farmer",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.white60, size: 13),
              const SizedBox(width: 3),
              Text(
                _locationController.text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeroChip(
                  Icons.agriculture_rounded, _farmNameController.text),
              const SizedBox(width: 10),
              _buildHeroChip(Icons.eco_rounded, "Active Farmer"),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: const Color(0xFFEAF4DE),
      child: Icon(Icons.person_rounded,
          size: 54, color: AppTheme.primaryGreen.withOpacity(0.5)),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4DE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 15),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D5016),
                letterSpacing: -0.2)),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF4F4F4)),
    );
  }

  Widget _buildFieldTile({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEditable = true,
  }) {
    final bool canEdit = _isEditing && isEditable;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canEdit
                  ? const Color(0xFFEAF4DE)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: canEdit
                    ? AppTheme.primaryGreen
                    : const Color(0xFFAAAAAA),
                size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2)),
                const SizedBox(height: 3),
                canEdit
                    ? TextField(
                  controller: controller,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A)),
                  decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "Enter value..."),
                  autofocus: label == "Full Name",
                )
                    : ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, child) => Text(
                    controller.text,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
              ],
            ),
          ),
          if (!isEditable)
            const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFCCCCCC), size: 14),
          if (isEditable && _isEditing)
            const Icon(Icons.edit_rounded,
                color: AppTheme.primaryGreen, size: 14),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, authProvider),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD32F2F),
          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
          backgroundColor: const Color(0xFFFFEBEE),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text("Log Out",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}