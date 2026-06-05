import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _selectedRole = 'customer'; // Default awal

  void _handleRegister() async {
    // Validasi sederhana
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    double? lat;
    double? lng;

    // JIKA ROLE MERCAHNT: Eksekusi pencarian GPS sebelum menembak API
    if (_selectedRole == 'merchant') {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
         try {
            // Perbaikan 1: Menggunakan locationSettings (Format terbaru)
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            
            lat = position.latitude;
            lng = position.longitude;
          } catch (e) {
            // Perbaikan 2: Menggunakan debugPrint agar lebih profesional
            debugPrint("Gagal mendapat lokasi akurat: $e");
          }
        }
      }
    }

    // Siapkan data sesuai role yang dipilih
    Map<String, dynamic> data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
    };

    if (_selectedRole == 'merchant') {
      data['business_name'] = _businessNameController.text;
      data['address'] = _addressController.text;
    }

    // Tembak API Register (Bawa lat & lng yang baru didapat)
    final result = await _apiService.register(data, lat: lat, lng: lng);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Jika sukses, kembali ke halaman Login
    if (result['success']) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Text('Daftar Akun', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 10),
                  const Text('Pilih jenis akun yang ingin Anda buat', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  
                  // TAB PILIHAN ROLE
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
                    child: TabBar(
                      onTap: (index) {
                        setState(() {
                          _selectedRole = index == 0 ? 'customer' : 'merchant';
                        });
                      },
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(color: const Color(0xFF0061FF), borderRadius: BorderRadius.circular(15)),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Pelanggan'),
                        Tab(text: 'Pemilik UMKM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // FORM BERSAMA (Nama, Email, Password)
                  _buildTextField(controller: _nameController, hint: 'Nama Lengkap', icon: Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _passwordController, hint: 'Password (Min. 6 Karakter)', icon: Icons.lock_outline, isPassword: true),
                  
                  // FORM TAMBAHAN KHUSUS UMKM
                  if (_selectedRole == 'merchant') ...[
                    const SizedBox(height: 15),
                    _buildTextField(controller: _businessNameController, hint: 'Nama Toko / Bisnis', icon: Icons.storefront),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _addressController, hint: 'Alamat Toko', icon: Icons.location_on_outlined),
                  ],

                  const SizedBox(height: 40),
                  
                  // TOMBOL DAFTAR
                  GestureDetector(
                    onTap: _isLoading ? null : _handleRegister,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0061FF), Color(0xFF60EFFF)]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.blue.withAlpha(76), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('DAFTAR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi bantuan untuk membuat TextField agar kode lebih rapi
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F6F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        prefixIcon: Icon(icon),
      ),
    );
  }
}