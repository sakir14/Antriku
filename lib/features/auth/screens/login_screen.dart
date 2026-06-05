import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/google_auth_service.dart';
import '../../customer/screens/customer_dashboard.dart';
import '../../merchant/screens/merchant_dashboard.dart';
import 'register_screen.dart'; // Import halaman register
import 'forgot_password_screen.dart'; // Import halaman Lupa Sandi yang baru dibuat
import '../../../utils/custom_snackbar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String _selectedRole = 'customer'; // Default Tab Login

  bool get _isBusy => _isLoading || _isGoogleLoading;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        // PENJAGA PINTU KETAT: Cek apakah role dari server SAMA dengan tab yang dipilih
        if (result['role'] != _selectedRole) {
          // 1. Hapus token yang terlanjur tersimpan di ApiService
          await context.read<AuthProvider>().clearSession();

          if (!mounted) return;

          // 2. Terjemahkan role asli untuk pesan error
          String roleAsli = result['role'] == 'merchant'
              ? 'Pemilik UMKM'
              : 'Pelanggan';

          // 3. Tampilkan pesan peringatan Awesome SnackBar
          CustomSnackBar.show(
            context,
            title: 'Akses Ditolak! ',
            message:
                'Akun Anda terdaftar sebagai $roleAsli. Silakan login di tab yang sesuai.',
            type: ContentType.warning, // Pakai warna kuning/orange (Warning)
          );

          return; // <--- HENTIKAN PROSES DI SINI (Jangan pindah halaman)
        }

        // Tampilkan pesan Sukses sebelum pindah halaman
        CustomSnackBar.show(
          context,
          title: 'Login Berhasil! ',
          message: 'Selamat datang kembali di AntriKu.',
          type: ContentType.success,
        );

        await context.read<AuthProvider>().refreshAfterLogin();
        if (!mounted) return;

        // Kalau role SAMA dengan tab, silakan masuk ke Dasbor!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => result['role'] == 'merchant'
                ? const MerchantDashboard()
                : const CustomerDashboard(),
          ),
        );
      } else {
        // Jika email/password salah dari server
        CustomSnackBar.show(
          context,
          title: 'Login Gagal ',
          message: result['message'] ?? 'Email atau password salah.',
          type: ContentType.failure,
        );
      }
    } catch (e) {
      // PELINDUNG ANTI-FREEZE JIKA SERVER MATI
      if (!mounted) return;
      setState(() => _isLoading = false);

      CustomSnackBar.show(
        context,
        title: 'Koneksi Terputus 🔌',
        message:
            'Gagal terhubung ke server. Periksa koneksi internet atau server lokal.',
        type: ContentType.failure,
      );
      debugPrint("ERROR LOGIN: $e");
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      final idToken = await GoogleAuthService.signInAndGetIdToken();

      if (!mounted) return;

      if (idToken == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final result = await _apiService.loginWithGoogle(
        idToken: idToken,
        role: _selectedRole,
      );

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (result['success'] == true) {
        CustomSnackBar.show(
          context,
          title: 'Login Berhasil! ',
          message: result['message'] ?? 'Selamat datang kembali di AntriKu.',
          type: ContentType.success,
        );

        await context.read<AuthProvider>().refreshAfterLogin();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => result['role'] == 'merchant'
                ? const MerchantDashboard()
                : const CustomerDashboard(),
          ),
        );
      } else {
        CustomSnackBar.show(
          context,
          title: 'Login Google Gagal ',
          message: result['message'] ?? 'Tidak dapat login dengan Google.',
          type: ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      CustomSnackBar.show(
        context,
        title: 'Google Sign-In Gagal ',
        message:
            'Cek konfigurasi Google Client ID dan pastikan akun Google tersedia di perangkat.',
        type: ContentType.failure,
      );
      debugPrint('ERROR GOOGLE LOGIN: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 80,
                      color: Color(0xFF0061FF),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Text(
                    'Masuk ke akun AntriKu Anda',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // TAB PILIHAN LOGIN
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      onTap: (index) {
                        setState(() {
                          _selectedRole = index == 0 ? 'customer' : 'merchant';
                        });
                      },
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0061FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
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

                  // INPUT EMAIL & PASSWORD
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFFF5F6F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: const Color(0xFFF5F6F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),

                  // TOMBOL LUPA KATA SANDI
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          color: Color(0xFF0061FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL MASUK
                  GestureDetector(
                    onTap: _isBusy ? null : _handleLogin,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(76),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'MASUK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                      label: Text(
                        _selectedRole == 'merchant'
                            ? 'Masuk UMKM dengan Google'
                            : 'Masuk dengan Google',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TOMBOL KE HALAMAN DAFTAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar di sini',
                          style: TextStyle(
                            color: Color(0xFF0061FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
