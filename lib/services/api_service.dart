import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl =
      'https://antriku-backend-production.up.railway.app/api';
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['data']['role']);
        return {'success': true, 'role': data['data']['role']};
      } else {
        return {'success': false, 'message': 'Email atau password salah'};
      }
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Server terlalu lama merespons. Cek apakah backend Laravel sedang jalan.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server. Pastikan internet aktif.',
      };
    } on HttpException {
      return {'success': false, 'message': 'Koneksi ke server bermasalah.'};
    } on FormatException {
      return {'success': false, 'message': 'Respon server tidak valid.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Server tidak merespons. Coba lagi beberapa saat.',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String role,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/google'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'id_token': idToken, 'role': role}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['data']['role']);
        return {
          'success': true,
          'role': data['data']['role'],
          'message': data['message'] ?? 'Login Google berhasil',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login Google gagal.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Server terlalu lama merespons. Cek apakah backend Laravel sedang jalan.',
      };
    } on SocketException {
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Pastikan HP dan laptop satu WiFi.',
      };
    } on FormatException {
      return {'success': false, 'message': 'Respon server tidak valid.'};
    } catch (e) {
      return {'success': false, 'message': 'Login Google gagal diproses.'};
    }
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data, {
    double? lat,
    double? lng,
  }) async {
    if (lat != null && lng != null) {
      data['latitude'] = lat;
      data['longitude'] = lng;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Registrasi berhasil!',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Gagal mendaftar.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<List<dynamic>> getMerchants({double? lat, double? lng}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url = '$baseUrl/merchants';
    if (lat != null && lng != null) url += '?lat=$lat&lng=$lng';

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fungsi untuk pelanggan mengambil antrean
  Future<Map<String, dynamic>> takeQueue(int merchantId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/queues/take',
            ), // <--- Pastikan URL ini sesuai dengan api.php
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: {'merchant_id': merchantId.toString()},
          )
          .timeout(_requestTimeout);

      // --- TAMENG ANTI-SPAM BEKERJA DI SINI ---
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message':
              'Terlalu banyak permintaan! Aktivitas spam terdeteksi. Tunggu 1 menit.',
        };
      }
      // ----------------------------------------

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Berhasil antre',
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal antre'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<List<dynamic>> getMerchantQueues() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/queues'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> completeQueue(int queueId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchant/queues/$queueId/complete'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Antrean selesai!'};
      }
      return {'success': false, 'message': 'Gagal memproses antrean'};
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> skipQueue(int queueId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchant/queues/$queueId/skip'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      // 👇 DECODE BODY BIAR BISA BACA PESAN ASLI DARI LARAVEL 👇
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Antrean dilewati',
        };
      }

      // 👇 KIRIM PESAN ASLI DARI SERVER KE SNACKBAR, BUKAN CODES HARDCODE 👇
      return {
        'success': false,
        'message':
            responseData['message'] ??
            'Gagal memproses (Status: ${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>?> getActiveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/customer/active-queue'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> toggleMerchantStatus(bool isOpen) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchant/toggle-status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'is_open': isOpen}),
          )
          .timeout(_requestTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> cancelQueue(int queueId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/queues/$queueId/cancel'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<List<dynamic>> getMerchantHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/history'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) return jsonResponse['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // FUNGSI BARU: Ambil Riwayat Pelanggan
  // ==========================================
  // AMBIL RIWAYAT PELANGGAN
  // ==========================================
  Future<List<dynamic>> getCustomerHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/customer/history',
            ), // <--- Pastikan endpoint-nya /customer/history
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // FUNGSI BARU: Ambil Profil UMKM (Untuk mendapatkan ID Toko)
  Future<Map<String, dynamic>?> getMerchantProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/profile'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // AMBIL PROFIL PELANGGAN
  // ==========================================
  Future<Map<String, dynamic>?> getCustomerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http
          .get(
            Uri.parse('$baseUrl/customer/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // UPDATE PROFIL PELANGGAN
  // ==========================================
  Future<Map<String, dynamic>> updateCustomerProfile(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/customer/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json', // Wajib ada untuk request PUT
        },
        body: json.encode({'name': name}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // UPDATE PROFIL UMKM
  // ==========================================
  Future<Map<String, dynamic>> updateMerchantProfile(
    String name,
    String address,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/merchant/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json', // Wajib untuk request PUT
        },
        body: json.encode({'business_name': name, 'address': address}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // HAPUS RIWAYAT UMKM
  // ==========================================
  Future<Map<String, dynamic>> deleteMerchantHistory(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/merchant/history/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // HAPUS RIWAYAT UMKM SECARA MASSAL
  // ==========================================
  Future<Map<String, dynamic>> deleteBulkMerchantHistory(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/merchant/history/bulk-delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ids': ids,
        }), // Kirim list ID dalam bentuk array JSON
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // HAPUS RIWAYAT PELANGGAN
  // ==========================================
  Future<Map<String, dynamic>> deleteCustomerHistory(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/customer/history/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // HAPUS RIWAYAT PELANGGAN SECARA MASSAL
  // ==========================================
  Future<Map<String, dynamic>> deleteBulkCustomerHistory(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/customer/history/bulk-delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'ids': ids}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // KIRIM RATING DARI PELANGGAN
  // ==========================================
  Future<Map<String, dynamic>> rateQueue(
    int queueId,
    int rating,
    String comment,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/customer/history/$queueId/rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'rating': rating, 'comment': comment}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // ==========================================
  // AMBIL DATA STATISTIK UNTUK UMKM
  // ==========================================
  Future<Map<String, dynamic>?> getMerchantStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/merchant/statistics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // AMBIL DAFTAR ULASAN UMKM
  // ==========================================
  Future<List<dynamic>> getMerchantReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/merchant/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // FITUR: REQUEST OTP LUPA KATA SANDI
  // ==========================================
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // ==========================================
  // FITUR: VERIFIKASI OTP & UBAH SANDI BARU
  // ==========================================
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
          'password': newPassword,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPass,
    String newPass,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'old_password': oldPass,
          'new_password': newPass,
          'new_password_confirmation': newPass,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }
  // Pastikan ada impor dart:io di paling atas file

  Future<Map<String, dynamic>> uploadMerchantPhoto(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Buat request khusus kirim file (Multipart)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/merchant/profile/photo'),
      );

      // Pasang Header Keamanan Token
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Masukkan file gambar ke dalam key 'photo' (harus sama dengan validasi Laravel)
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      // Kirim ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> uploadCustomerPhoto(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/customer/profile/photo'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> deleteMerchantPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/merchant/profile/photo'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> deleteCustomerPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customer/profile/photo'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'fcm_token': fcmToken}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal sinkron token'};
    }
  }

  Future<Map<String, dynamic>> getMerchantSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/subscription'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil data langganan'};
    }
  }

  Future<Map<String, dynamic>> activateMerchantSubscription(
    String plan, {
    int months = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchant/subscription/activate'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'plan': plan, 'months': months}),
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengaktifkan langganan'};
    }
  }

  Future<Map<String, dynamic>> getPremiumReport() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/premium-report'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil laporan premium'};
    }
  }

  Future<List<dynamic>> getMerchantPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchant/promotions'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) return decoded['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createMerchantPromotion({
    required String title,
    required String description,
    required String discountText,
    bool isActive = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchant/promotions'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'title': title,
              'description': description,
              'discount_text': discountText,
              'is_active': isActive,
            }),
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat promosi'};
    }
  }

  Future<Map<String, dynamic>> updateMerchantPromotion(
    int id, {
    required String title,
    required String description,
    required String discountText,
    required bool isActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/merchant/promotions/$id'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'title': title,
              'description': description,
              'discount_text': discountText,
              'is_active': isActive,
            }),
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui promosi'};
    }
  }

  Future<Map<String, dynamic>> deleteMerchantPromotion(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/merchant/promotions/$id'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus promosi'};
    }
  }

  Future<List<dynamic>> getActivePromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/promotions'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) return decoded['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
