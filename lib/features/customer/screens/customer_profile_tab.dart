import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/customer_dashboard_provider.dart';
import '../../../services/api_service.dart';
import '../../../utils/custom_snackbar.dart';
import '../../auth/screens/login_screen.dart';

class CustomerProfileTab extends StatefulWidget {
  final Map<String, dynamic>? customerProfile;
  final Future<void> Function() onRefreshNeeded;

  const CustomerProfileTab({
    super.key,
    required this.customerProfile,
    required this.onRefreshNeeded,
  });

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab>
    with AutomaticKeepAliveClientMixin<CustomerProfileTab> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  static final Map<int, File> _previewCache = {};
  static final Map<int, String> _photoUrlCache = {};

  File? _localPreviewImage;
  String? _uploadedPhotoUrl;
  bool _photoDeletedLocally = false;
  int _cacheBuster = DateTime.now().millisecondsSinceEpoch;

  @override
  bool get wantKeepAlive => true;

  int? get _customerId {
    final id = widget.customerProfile?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadCacheForCurrentCustomer();
  }

  @override
  void didUpdateWidget(covariant CustomerProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIdRaw = oldWidget.customerProfile?['id'];
    final oldId = oldIdRaw is int
        ? oldIdRaw
        : int.tryParse(oldIdRaw?.toString() ?? '');

    if (oldId != _customerId) {
      _photoDeletedLocally = false;
      _loadCacheForCurrentCustomer();
    }

    final serverUrl = _fullPhotoUrl;
    if (serverUrl != null && _customerId != null) {
      _photoUrlCache[_customerId!] = serverUrl;
    }
  }

  void _loadCacheForCurrentCustomer() {
    final id = _customerId;
    if (id == null) return;

    _localPreviewImage = _previewCache[id];
    _uploadedPhotoUrl = _photoUrlCache[id];
  }

  String? _normalizePhotoUrl(dynamic value) {
    final path = value?.toString();
    if (path == null || path.trim().isEmpty) return null;

    final cleanedPath = path.trim();
    if (cleanedPath.startsWith('http')) return cleanedPath;

    final host = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanHost = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;
    final cleanPath = cleanedPath.startsWith('/')
        ? cleanedPath.substring(1)
        : cleanedPath;

    return '$cleanHost/$cleanPath';
  }

  String? get _fullPhotoUrl {
    if (_photoDeletedLocally) return null;

    return _normalizePhotoUrl(widget.customerProfile?['photo_url']);
  }

  String? _extractPhotoUrlFromUploadResult(Map<String, dynamic> result) {
    final directUrl = _normalizePhotoUrl(result['photo_url']);
    if (directUrl != null) return directUrl;

    final data = result['data'];
    if (data is Map) {
      final dataUrl = _normalizePhotoUrl(data['photo_url']);
      if (dataUrl != null) return dataUrl;
    }

    return null;
  }

  File? get _validLocalPreviewImage {
    final file = _localPreviewImage;
    if (file == null) return null;
    return file.existsSync() ? file : null;
  }

  ImageProvider? get _profileImageProvider {
    final previewImage = _validLocalPreviewImage;
    if (previewImage != null) return FileImage(previewImage);

    if (_uploadedPhotoUrl != null) {
      return NetworkImage('$_uploadedPhotoUrl?t=$_cacheBuster');
    }

    final serverUrl = _fullPhotoUrl;
    if (serverUrl != null) {
      return NetworkImage('$serverUrl?t=$_cacheBuster');
    }

    final id = _customerId;
    if (id != null && _photoUrlCache[id] != null) {
      return NetworkImage('${_photoUrlCache[id]}?t=$_cacheBuster');
    }

    return null;
  }

  bool get _hasProfilePhoto {
    final id = _customerId;

    return _validLocalPreviewImage != null ||
        _uploadedPhotoUrl != null ||
        _fullPhotoUrl != null ||
        (id != null && _photoUrlCache[id] != null);
  }

  Widget _buildReusableAppBar({required String title, IconData? icon}) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0061FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 15),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.circle,
                  size: 100,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Icon(
                  Icons.circle,
                  size: 150,
                  color: Colors.white.withAlpha(25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImageAction() async {
    final pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0061FF),
                ),
                title: const Text('Ambil dari Galeri'),
                onTap: () async {
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0061FF)),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, file);
                },
              ),
              if (_hasProfilePhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deletePhotoAction();
                  },
                ),
            ],
          ),
        );
      },
    );

    if (pickedFile == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0061FF)),
        );
      },
    );

    try {
      final imageFile = File(pickedFile.path);
      final result = await _apiService.uploadCustomerPhoto(imageFile);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final uploadedUrl = _extractPhotoUrlFromUploadResult(result);
        final id = _customerId;

        if (id != null) {
          _previewCache[id] = imageFile;
          if (uploadedUrl != null) {
            _photoUrlCache[id] = uploadedUrl;
          }
        }

        setState(() {
          _photoDeletedLocally = false;
          _localPreviewImage = imageFile;
          _uploadedPhotoUrl = uploadedUrl ?? _uploadedPhotoUrl;
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });

        CustomSnackBar.show(
          context,
          title: 'Foto Diperbarui',
          message: result['message'] ?? 'Foto profil berhasil disimpan.',
          type: ContentType.success,
        );

        await widget.onRefreshNeeded();

        if (!mounted) return;

        final refreshedUrl = _fullPhotoUrl;
        if (refreshedUrl != null && id != null) {
          _photoUrlCache[id] = refreshedUrl;
        }

        setState(() {
          if (refreshedUrl != null) {
            _uploadedPhotoUrl = refreshedUrl;
          }
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });
      } else {
        CustomSnackBar.show(
          context,
          title: 'Gagal Upload',
          message: result['message'] ?? 'Periksa format file Anda.',
          type: ContentType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus',
        message: 'Gagal mengirim gambar ke server.',
        type: ContentType.failure,
      );
    }
  }

  Future<void> _deletePhotoAction() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0061FF)),
        );
      },
    );

    try {
      final result = await _apiService.deleteCustomerPhoto();

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final id = _customerId;

        if (id != null) {
          _previewCache.remove(id);
          _photoUrlCache.remove(id);
        }

        setState(() {
          _photoDeletedLocally = true;
          _localPreviewImage = null;
          _uploadedPhotoUrl = null;
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });

        CustomSnackBar.show(
          context,
          title: 'Foto Dihapus',
          message: result['message'] ?? 'Foto profil berhasil dihapus.',
          type: ContentType.success,
        );

        await widget.onRefreshNeeded();

        if (!mounted) return;

        setState(() {
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });
      } else {
        CustomSnackBar.show(
          context,
          title: 'Gagal Hapus Foto',
          message: result['message'] ?? 'Foto profil belum bisa dihapus.',
          type: ContentType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus',
        message: 'Gagal menghapus foto dari server.',
        type: ContentType.failure,
      );
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: widget.customerProfile?['name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ubah nama yang akan ditampilkan ke toko:'),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0061FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0061FF),
                      ),
                    );
                  },
                );

                try {
                  final result = await _apiService.updateCustomerProfile(
                    nameController.text.trim(),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (result['success'] == true) {
                    CustomSnackBar.show(
                      context,
                      title: 'Profil Diperbarui',
                      message: result['message'] ?? 'Nama berhasil diubah.',
                      type: ContentType.success,
                    );
                    await widget.onRefreshNeeded();
                  } else {
                    CustomSnackBar.show(
                      context,
                      title: 'Gagal Menyimpan',
                      message: result['message'] ?? 'Terjadi kesalahan sistem.',
                      type: ContentType.warning,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  CustomSnackBar.show(
                    context,
                    title: 'Koneksi Terputus',
                    message: 'Gagal terhubung ke server.',
                    type: ContentType.failure,
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Lama',
                prefixIcon: const Icon(Icons.lock_clock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Baru',
                prefixIcon: const Icon(Icons.lock_reset),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 5),
              child: Text(
                'Minimal 6 karakter.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0061FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (newPass.text.length < 6) {
                CustomSnackBar.show(
                  context,
                  title: 'Sandi Terlalu Pendek',
                  message: 'Kata sandi baru minimal 6 karakter!',
                  type: ContentType.warning,
                );
                return;
              }

              Navigator.pop(dialogContext);

              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0061FF)),
                  );
                },
              );

              try {
                final res = await _apiService.changePassword(
                  oldPass.text,
                  newPass.text,
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (res['success'] == true) {
                  CustomSnackBar.show(
                    context,
                    title: 'Sandi Diubah',
                    message:
                        res['message'] ?? 'Kata sandi berhasil diperbarui.',
                    type: ContentType.success,
                  );
                } else {
                  CustomSnackBar.show(
                    context,
                    title: 'Gagal Mengubah',
                    message:
                        res['message'] ??
                        'Sandi lama salah atau terjadi kesalahan.',
                    type: ContentType.warning,
                  );
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  title: 'Koneksi Terputus',
                  message: 'Gagal terhubung ke server.',
                  type: ContentType.failure,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange, size: 30),
                  SizedBox(width: 15),
                  Text(
                    'Pusat Bantuan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem(
                      'Bagaimana cara mengambil antrean?',
                      'Cari toko yang sedang buka di menu Eksplor, klik tokonya, lalu tekan tombol "Ambil Antrean". Pastikan jarak Anda kurang dari 3 KM.',
                    ),
                    _buildFaqItem(
                      'Bisakah saya menghapus riwayat yang sudah selesai?',
                      'Tentu. Buka menu Riwayat, lalu tekan dan tahan salah satu riwayat untuk memunculkan mode hapus.',
                    ),
                    _buildFaqItem(
                      'Apa yang terjadi jika saya melewatkan panggilan?',
                      'Toko memiliki hak untuk melewati nomor Anda. Silakan lapor ke kasir jika Anda terlewat.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Butuh bantuan lebih lanjut?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Hubungi CS AntriKu: support@antriku.com',
                            style: TextStyle(color: Color(0xFF0061FF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0061FF)),
        );
      },
    );

    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;

      context.read<CustomerDashboardProvider>().reset();
      context.read<BusinessProvider>().reset();

      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      CustomSnackBar.show(
        context,
        title: 'Gagal Keluar',
        message: 'Periksa koneksi internet Anda.',
        type: ContentType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileImageProvider = _profileImageProvider;

    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(title: 'Profil Saya', icon: Icons.person_pin),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _pickAndUploadImageAction,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF0061FF),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: profileImageProvider != null
                            ? DecorationImage(
                                image: profileImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profileImageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 54,
                              color: Color(0xFF0061FF),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0061FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.customerProfile?['name'] ?? 'Memuat Nama...',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.customerProfile?['email'] ?? 'Memuat Email...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMenuTile(
                      color: Colors.blue,
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      onTap: _showEditProfileDialog,
                    ),
                    const Divider(),
                    _buildMenuTile(
                      color: Colors.purple,
                      icon: Icons.lock_reset,
                      title: 'Ubah Kata Sandi',
                      onTap: _showChangePasswordDialog,
                    ),
                    const Divider(),
                    _buildMenuTile(
                      color: Colors.orange,
                      icon: Icons.help_outline,
                      title: 'Pusat Bantuan',
                      onTap: _showHelpCenter,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text(
                        'Keluar Akun',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('Keluar'),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text(
                                    'Keluar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (!mounted) return;
                        if (confirm == true) _performLogout();
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required Color color,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
