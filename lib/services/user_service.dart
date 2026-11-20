import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

/// UserService — CRUD ke JSONPlaceholder
/// ID User berdasarkan NIM: 1499 + 145 = 1644
class UserService {
  static const String _base = 'https://jsonplaceholder.typicode.com';

  /// ID khusus sesuai NIM (3 digit terakhir = 145)
  static const int nimUserId = 1644;

  // ── GET all users ──────────────────────────────────────────
  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$_base/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Gagal mengambil daftar User (${response.statusCode})');
  }

  // ── GET single user by ID ──────────────────────────────────
  static Future<User> getUser(int id) async {
    final response = await http.get(Uri.parse('$_base/users/$id'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('User ID $id tidak ditemukan (${response.statusCode})');
  }

  // ── POST — tambah User baru (ID dari NIM = 1644) ──────────
  static Future<User> createUser({
    required String name,
    required String email,
    required String city,
  }) async {
    final body = jsonEncode({
      'id': nimUserId,
      'name': name,
      'email': email,
      'address': {'city': city},
    });

    final response = await http.post(
      Uri.parse('$_base/users'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // JSONPlaceholder returns id=11; override dengan nimUserId
      json['id'] = nimUserId;
      return User.fromJson(json);
    }
    throw Exception('Gagal menambahkan User (${response.statusCode})');
  }

  // ── PUT — perbarui nama & email User ─────────────────────
  static Future<User> updateUser({
    required int id,
    required String name,
    required String email,
    required String city,
  }) async {
    final body = jsonEncode({
      'id': id,
      'name': name,
      'email': email,
      'address': {'city': city},
    });

    final response = await http.put(
      Uri.parse('$_base/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal memperbarui User ID $id (${response.statusCode})');
  }

  // ── PATCH — tambahkan "- Flutter Developer" ke nama User ──
  static Future<User> patchUser({
    required int id,
    required String currentName,
  }) async {
    final newName = '$currentName - Flutter Developer';
    final body = jsonEncode({'name': newName});

    final response = await http.patch(
      Uri.parse('$_base/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal memperbarui nama User ID $id (${response.statusCode})');
  }

  // ── DELETE — hapus User berdasarkan ID ────────────────────
  static Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$_base/users/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus User ID $id (${response.statusCode})');
    }
  }
}
