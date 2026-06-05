import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart'; // Sesuaikan jalur impor ini jika berbeda

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data konten untuk 3 layar perkenalan
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Selamat Datang",
      "desc":
          "Aplikasi revolusioner yang bikin kamu bebas pegal saat antre di UMKM favorit.",
      "icon": Icons.waving_hand_rounded,
      "color": const Color(0xFF0061FF), // Biru
    },
    {
      "title": "Cari Toko Terdekat",
      "desc":
          "Temukan berbagai lapak UMKM di sekitarmu dengan mudah lewat fitur pintar kami.",
      "icon": Icons.storefront_rounded,
      "color": const Color(0xFF059669), // Hijau
    },
    {
      "title": "Antre Praktis",
      "desc":
          "Ambil nomor dari HP, santai dulu, lalu datang tepat saat giliranmu tiba!",
      "icon": Icons.confirmation_num_rounded,
      "color": const Color(0xFFFF9800), // Orange
    },
  ];

  // Fungsi sakti: Simpan memori agar layar ini TIDAK MUNCUL LAGI setelah ditekan "Mulai"
  Future<void> _finishOnboarding() async {
    await context.read<AuthProvider>().markOnboardingSeen();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // TOMBOL LEWATI (Kanan Atas)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Lewati',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // AREA GESER (PAGEVIEW)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lingkaran Ikon Bercahaya (Bisa diganti Lottie nanti kalau mau)
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page['color'].withAlpha(20),
                            boxShadow: [
                              BoxShadow(
                                color: page['color'].withAlpha(40),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            page['icon'],
                            size: 100,
                            color: page['color'],
                          ),
                        ),
                        const SizedBox(height: 50),

                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          page['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // AREA BAWAH (Titik Indikator & Tombol Next)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titik-titik Navigasi (Dots)
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _currentPage == index ? 25 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF0061FF)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),

                  // Tombol Bulat Dinamis (Maju / Mulai)
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == _pages.length - 1) {
                        _finishOnboarding(); // Kalau di halaman terakhir, masuk ke Login
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == _pages.length - 1 ? 120 : 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _currentPage == _pages.length - 1
                            ? const Color(0xFF0061FF)
                            : Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: _currentPage == _pages.length - 1
                            ? const Text(
                                'Mulai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
