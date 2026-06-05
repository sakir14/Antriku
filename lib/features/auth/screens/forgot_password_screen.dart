import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final result = await _apiService.requestPasswordReset(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['success'] == true ? Colors.green : Colors.red));
    
    if (result['success'] == true) {
      setState(() => _isOtpSent = true); // Ubah tampilan layar ke input OTP
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.trim().isEmpty || _passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi OTP dan Sandi baru (minimal 6 karakter)'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['success'] == true ? Colors.green : Colors.red));

    if (result['success'] == true) {
      Navigator.pop(context); // Kembali ke layar Login kalau sukses
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Kata Sandi'), backgroundColor: const Color(0xFF0061FF), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isOtpSent ? 'Langkah 2: Buat Sandi Baru' : 'Langkah 1: Verifikasi Email', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_isOtpSent ? 'Masukkan kode 6 digit yang kami kirimkan ke email Anda beserta kata sandi baru Anda.' : 'Masukkan email Anda yang terdaftar. Kami akan mengirimkan 6 digit kode OTP ke email tersebut.', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // FORM TAHAP 1 (EMAIL)
            if (!_isOtpSent) ...[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Alamat Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0061FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Kode OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],

            // FORM TAHAP 2 (OTP & KATA SANDI BARU)
            if (_isOtpSent) ...[
              TextField(
                controller: _otpController,
                decoration: InputDecoration(labelText: 'Kode OTP 6 Digit', prefixIcon: const Icon(Icons.pin), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Kata Sandi Baru', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Sandi Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}