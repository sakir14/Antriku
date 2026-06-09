import 'dart:io';
import 'dart:ui' as ui;

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/merchant_dashboard_provider.dart';
import '../../../services/api_service.dart';
import '../../../utils/custom_snackbar.dart';
import '../../auth/screens/login_screen.dart';

class MerchantProfileTab extends StatefulWidget {
  final Map<String, dynamic>? merchantProfile;
  final Future<void> Function() onRefreshNeeded;

  const MerchantProfileTab({
    super.key,
    required this.merchantProfile,
    required this.onRefreshNeeded,
  });

  @override
  State<MerchantProfileTab> createState() => _MerchantProfileTabState();
}

class _MerchantProfileTabState extends State<MerchantProfileTab>
    with AutomaticKeepAliveClientMixin<MerchantProfileTab> {
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

  int? get _merchantId {
    final id = widget.merchantProfile?['id'];

    if (id is int) return id;

    return int.tryParse(id?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadCacheForCurrentMerchant();
  }

  @override
  void didUpdateWidget(covariant MerchantProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIdRaw = oldWidget.merchantProfile?['id'];
    final oldId = oldIdRaw is int
        ? oldIdRaw
        : int.tryParse(oldIdRaw?.toString() ?? '');

    if (oldId != _merchantId) {
      _photoDeletedLocally = false;
      _loadCacheForCurrentMerchant();
    }

    final serverUrl = _fullPhotoUrl;

    if (serverUrl != null && _merchantId != null) {
      _photoUrlCache[_merchantId!] = serverUrl;
    }
  }

  void _loadCacheForCurrentMerchant() {
    final id = _merchantId;

    if (id == null) return;

    _localPreviewImage = _previewCache[id];
    _uploadedPhotoUrl = _photoUrlCache[id];
  }

  String? _normalizePhotoUrl(dynamic value) {
    final path = value?.toString();

    if (path == null || path.trim().isEmpty) return null;

    final cleanedPath = path.trim();

    if (cleanedPath.startsWith('http')) {
      return cleanedPath;
    }

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

    return _normalizePhotoUrl(widget.merchantProfile?['photo_url']);
  }

  String? _extractPhotoUrlFromUploadResult(Map<String, dynamic> result) {
    final directUrl = _normalizePhotoUrl(result['photo_url']);
    if (directUrl != null) return directUrl;

    final directPhoto = _normalizePhotoUrl(result['photo']);
    if (directPhoto != null) return directPhoto;

    final data = result['data'];
    if (data is Map) {
      final dataUrl = _normalizePhotoUrl(data['photo_url']);
      if (dataUrl != null) return dataUrl;

      final dataPhoto = _normalizePhotoUrl(data['photo']);
      if (dataPhoto != null) return dataPhoto;
    }

    final merchant = result['merchant'];
    if (merchant is Map) {
      final merchantUrl = _normalizePhotoUrl(merchant['photo_url']);
      if (merchantUrl != null) return merchantUrl;

      final merchantPhoto = _normalizePhotoUrl(merchant['photo']);
      if (merchantPhoto != null) return merchantPhoto;
    }

    return null;
  }

  File? get _validLocalPreviewImage {
    final file = _localPreviewImage;

    if (file == null) return null;

    if (file.existsSync()) {
      return file;
    }

    return null;
  }

  ImageProvider? get _profileImageProvider {
    final previewImage = _validLocalPreviewImage;

    if (previewImage != null) {
      return FileImage(previewImage);
    }

    final cachedUrl = _uploadedPhotoUrl;
    if (cachedUrl != null) {
      return NetworkImage('$cachedUrl?t=$_cacheBuster');
    }

    final serverUrl = _fullPhotoUrl;
    if (serverUrl != null) {
      return NetworkImage('$serverUrl?t=$_cacheBuster');
    }

    final id = _merchantId;
    if (id != null && _photoUrlCache[id] != null) {
      return NetworkImage('${_photoUrlCache[id]}?t=$_cacheBuster');
    }

    return null;
  }

  bool get _hasProfilePhoto {
    final id = _merchantId;

    return _validLocalPreviewImage != null ||
        _uploadedPhotoUrl != null ||
        _fullPhotoUrl != null ||
        (id != null && _photoUrlCache[id] != null);
  }

  bool get _hasStoreCoordinates {
    final lat = double.tryParse(
      widget.merchantProfile?['latitude']?.toString() ?? '',
    );
    final lng = double.tryParse(
      widget.merchantProfile?['longitude']?.toString() ?? '',
    );

    return lat != null && lng != null;
  }

  Widget _buildReusableAppBar({required String title, IconData? icon}) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF059669),
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
              colors: [Color(0xFF059669), Color(0xFF34D399)],
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
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF059669),
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
                leading: const Icon(Icons.camera_alt, color: Color(0xFF059669)),
                title: const Text('Ambil dari Kamera langsung'),
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

    if (pickedFile == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      },
    );

    try {
      final File imageFile = File(pickedFile.path);
      final result = await _apiService.uploadMerchantPhoto(imageFile);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final uploadedUrl = _extractPhotoUrlFromUploadResult(result);

        final id = _merchantId;

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
          title: 'Berhasil diunggah! 📸',
          message: result['message'] ?? 'Foto tokomu kini tampil keren.',
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
          title: 'Gagal Upload ⚠️',
          message: result['message'] ?? 'Periksa format file Anda.',
          type: ContentType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus 🔌',
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
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      },
    );

    try {
      final result = await _apiService.deleteMerchantPhoto();

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final id = _merchantId;

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
          message: result['message'] ?? 'Foto toko berhasil dihapus.',
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
          message: result['message'] ?? 'Foto toko belum bisa dihapus.',
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

  Future<Position?> _getCurrentStorePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;

      CustomSnackBar.show(
        context,
        title: 'GPS Belum Aktif',
        message: 'Nyalakan lokasi/GPS HP, lalu coba perbarui lagi.',
        type: ContentType.warning,
      );

      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return null;

      CustomSnackBar.show(
        context,
        title: 'Izin Lokasi Ditolak',
        message: 'Izinkan akses lokasi agar titik toko bisa disimpan.',
        type: ContentType.warning,
      );

      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;

      CustomSnackBar.show(
        context,
        title: 'Izin Lokasi Terkunci',
        message: 'Buka pengaturan aplikasi dan aktifkan izin lokasi AntriKu.',
        type: ContentType.warning,
      );

      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      if (!mounted) return null;

      CustomSnackBar.show(
        context,
        title: 'Lokasi Belum Terdeteksi',
        message: 'Coba di area terbuka atau aktifkan mode akurasi tinggi.',
        type: ContentType.warning,
      );

      return null;
    }
  }

  Future<void> _updateStoreLocationAction() async {
    final businessName = widget.merchantProfile?['business_name']?.toString();
    final address = widget.merchantProfile?['address']?.toString();

    if (businessName == null ||
        businessName.trim().isEmpty ||
        address == null ||
        address.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        title: 'Profil Belum Lengkap',
        message: 'Lengkapi nama dan alamat toko terlebih dahulu.',
        type: ContentType.warning,
      );

      return;
    }

    final position = await _getCurrentStorePosition();
    if (position == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      },
    );

    try {
      final result = await _apiService.updateMerchantProfile(
        businessName.trim(),
        address.trim(),
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        CustomSnackBar.show(
          context,
          title: 'Lokasi Toko Disimpan',
          message: 'Pelanggan sekarang bisa melihat jarak toko dengan benar.',
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
          title: 'Gagal Menyimpan Lokasi',
          message: result['message'] ?? 'Server belum menerima titik lokasi.',
          type: ContentType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus',
        message: 'Gagal mengirim lokasi toko ke server.',
        type: ContentType.failure,
      );
    }
  }

  String _encryptQR(String plainText) {
    final key = enc.Key.fromUtf8('AntriKuSecretKey2026PolindraITS!');
    final iv = enc.IV.fromUtf8('AntriKuInitVect!');
    final encrypter = enc.Encrypter(enc.AES(key));

    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  Future<void> _shareQrCodeAction() async {
    if (_merchantId == null) return;

    try {
      final secureData = _encryptQR('ANTRIKU-MERCHANT-$_merchantId');

      final qrValidationResult = QrValidator.validate(
        data: secureData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      final qrCode = qrValidationResult.qrCode;
      if (qrCode == null) return;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1080, 1440);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 1440),
            [const Color(0xFF059669), const Color(0xFF34D399)],
          ),
      );

      canvas.drawRRect(
        RRect.fromLTRBR(100, 200, 980, 1240, const Radius.circular(50)),
        Paint()..color = Colors.white,
      );

      final headerPainter = TextPainter(
        text: const TextSpan(
          text: 'ANTRIKU',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 80,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      headerPainter.paint(canvas, Offset(540 - (headerPainter.width / 2), 280));

      final subHeaderPainter = TextPainter(
        text: const TextSpan(
          text: 'Scan QR ini untuk Antre',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 40,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      subHeaderPainter.paint(
        canvas,
        Offset(540 - (subHeaderPainter.width / 2), 380),
      );

      canvas.save();
      canvas.translate(290, 500);

      QrPainter.withQr(
        qr: qrCode,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        gapless: true,
      ).paint(canvas, const Size(500, 500));

      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final file = await File(
        '${(await getTemporaryDirectory()).path}/Poster_AntriKu_$_merchantId.png',
      ).create();

      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Scan QR ini untuk antre di toko saya!',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      CustomSnackBar.show(
        context,
        title: 'Gagal Membagikan ⚠️',
        message: 'Terjadi kesalahan saat memproses QR Code.',
        type: ContentType.failure,
      );
    }
  }

  void _showQrCodeDialog() {
    if (_merchantId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'QR Code Toko',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 250,
            height: 250,
            child: Center(
              child: QrImageView(
                data: _encryptQR('ANTRIKU-MERCHANT-$_merchantId'),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _shareQrCodeAction();
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Cetak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(
      text: widget.merchantProfile?['business_name'] ?? '',
    );

    final TextEditingController addressController = TextEditingController(
      text: widget.merchantProfile?['address'] ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Profil Toko',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Toko',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  prefixIcon: const Icon(Icons.location_on),
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
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (!mounted) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
                    );
                  },
                );

                try {
                  final result = await _apiService.updateMerchantProfile(
                    nameController.text.trim(),
                    addressController.text.trim(),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (result['success'] == true) {
                    CustomSnackBar.show(
                      context,
                      title: 'Profil Diperbarui! 📝',
                      message:
                          result['message'] ?? 'Data tokomu berhasil disimpan.',
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
                      title: 'Gagal Menyimpan ⚠️',
                      message: result['message'] ?? 'Terjadi kesalahan sistem.',
                      type: ContentType.warning,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);

                  CustomSnackBar.show(
                    context,
                    title: 'Koneksi Terputus 🔌',
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
    final TextEditingController oldPass = TextEditingController();
    final TextEditingController newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (newPass.text.length < 6) {
                  CustomSnackBar.show(
                    context,
                    title: 'Sandi Terlalu Pendek 🔒',
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
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
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
                      title: 'Sandi Diubah! 🔑',
                      message:
                          res['message'] ?? 'Kata sandi berhasil diperbarui.',
                      type: ContentType.success,
                    );
                  } else {
                    CustomSnackBar.show(
                      context,
                      title: 'Gagal Mengubah ⚠️',
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
                    title: 'Koneksi Terputus 🔌',
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

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      },
    );

    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;

      context.read<MerchantDashboardProvider>().reset();
      context.read<BusinessProvider>().reset();

      if (!mounted) return;

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
        title: 'Gagal Keluar ⚠️',
        message: 'Periksa koneksi internet Anda.',
        type: ContentType.failure,
      );
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar Akun',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm == true) {
      await _performLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final profileImageProvider = _profileImageProvider;

    return CustomScrollView(
      slivers: [
        _buildReusableAppBar(title: 'Pengaturan Toko', icon: Icons.store),
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF059669),
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
                              Icons.storefront,
                              size: 60,
                              color: Color(0xFF059669),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.merchantProfile?['business_name'] ?? 'Nama Toko',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 5,
                ),
                child: Text(
                  widget.merchantProfile?['address'] ?? 'Alamat Toko',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2, color: Colors.green),
                      ),
                      title: const Text(
                        'Tampilkan QR Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showQrCodeDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      title: const Text(
                        'Edit Profil Toko',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showEditProfileDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.teal,
                        ),
                      ),
                      title: const Text(
                        'Perbarui Lokasi Toko',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _hasStoreCoordinates
                            ? 'Titik lokasi toko sudah tersimpan'
                            : 'Lokasi toko belum tersedia',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _updateStoreLocationAction,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.purple,
                        ),
                      ),
                      title: const Text(
                        'Ubah Kata Sandi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordDialog,
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
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.red,
                      ),
                      onTap: _showLogoutConfirmation,
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
}
