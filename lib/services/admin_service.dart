import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin.dart';

/// AdminService — Read & Delete ke JSONPlaceholder
/// ID Admin berdasarkan NIM: 792 + 145 = 937
///
/// JSONPlaceholder tidak menyediakan endpoint /admins, sehingga
/// data Admin diambil dari /users lalu dimapping ke model Admin
/// (field 'department' dipetakan dari 'company.name').
class AdminService {
  static const String _base = 'https://jsonplaceholder.typicode.com';

  /// ID khusus sesuai NIM (3 digit terakhir = 145)
  static const int nimAdminId = 937;

  // ── GET all admins ─────────────────────────────────────────
  static Future<List<Admin>> getAdmins() async {
    final response = await http.get(Uri.parse('$_base/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Admin.fromJson(json)).toList();
    }
    throw Exception('Gagal mengambil daftar Admin (${response.statusCode})');
  }

  // ── GET single admin by ID ─────────────────────────────────
  static Future<Admin> getAdmin(int id) async {
    final response = await http.get(Uri.parse('$_base/users/$id'));

    if (response.statusCode == 200) {
      return Admin.fromJson(jsonDecode(response.body));
    }
    throw Exception('Admin ID $id tidak ditemukan (${response.statusCode})');
  }

  // ── DELETE admin by ID ─────────────────────────────────────
  static Future<void> deleteAdmin(int id) async {
    final response = await http.delete(Uri.parse('$_base/users/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus Admin ID $id (${response.statusCode})');
    }
  }
}
