import 'package:flutter/material.dart';

import 'models/user.dart';
import 'models/admin.dart';
import 'services/user_service.dart';
import 'services/admin_service.dart';

void main() {
  runApp(const MyApp());
}

// ============================================================
// ROOT APP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User & Admin Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainTabScreen(),
    );
  }
}

// ============================================================
// MAIN TAB — User | Admin
// ============================================================

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User & Admin Manager'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Users'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserListScreen(),
            AdminListScreen(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PAGE 1 — USER LIST
// ============================================================

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<User>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _futureUsers = UserService.getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorWidget(
            message: snapshot.error.toString(),
            onRetry: _load,
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('Tidak ada data User.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              // Header button — POST new user
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah User (POST — ID 1644)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showPostDialog(context),
                  ),
                );
              }

              final user = users[index - 1];
              return _UserCard(user: user, onRefresh: _load);
            },
          ),
        );
      },
    );
  }

  void _showPostDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah User Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'Kota'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = await UserService.createUser(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                );
                if (context.mounted) {
                  _showResult(context, 'POST Berhasil', user.toJson());
                  _load();
                }
              } catch (e) {
                if (context.mounted) _showError(context, e.toString());
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onRefresh;

  const _UserCard({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${user.email}\n📍 ${user.city}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(userId: user.id, onRefresh: onRefresh),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PAGE 2 — USER DETAIL  (GET / PUT / PATCH / DELETE)
// ============================================================

class UserDetailScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onRefresh;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.onRefresh,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<User> _futureUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _futureUser = UserService.getUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail User #${widget.userId}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorWidget(
              message: snapshot.error.toString(),
              onRetry: _load,
            );
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Card ────────────────────────────
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.indigo.shade200,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'ID', value: '${user.id}'),
                        _InfoRow(label: 'Nama', value: user.name),
                        _InfoRow(label: 'Email', value: user.email),
                        _InfoRow(label: 'Kota', value: user.city),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Operasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ── PUT button ───────────────────────────
                _ActionButton(
                  label: 'PUT — Perbarui Nama & Email',
                  color: Colors.orange,
                  icon: Icons.edit,
                  onTap: () => _showPutDialog(context, user),
                ),

                const SizedBox(height: 10),

                // ── PATCH button ─────────────────────────
                _ActionButton(
                  label: 'PATCH — Tambah "- Flutter Developer"',
                  color: Colors.teal,
                  icon: Icons.edit_note,
                  onTap: () async {
                    try {
                      final updated = await UserService.patchUser(
                        id: user.id,
                        currentName: user.name,
                      );
                      if (context.mounted) {
                        _showResult(context, 'PATCH Berhasil', updated.toJson());
                        _load();
                      }
                    } catch (e) {
                      if (context.mounted) _showError(context, e.toString());
                    }
                  },
                ),

                const SizedBox(height: 10),

                // ── DELETE button ────────────────────────
                _ActionButton(
                  label: 'DELETE — Hapus User #${user.id}',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => _confirmDelete(context, user.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPutDialog(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final cityCtrl = TextEditingController(text: user.city);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PUT — Perbarui User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'Kota'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updated = await UserService.updateUser(
                  id: user.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                );
                if (context.mounted) {
                  _showResult(context, 'PUT Berhasil', updated.toJson());
                  _load();
                }
              } catch (e) {
                if (context.mounted) _showError(context, e.toString());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User?'),
        content: Text('User ID $id akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await UserService.deleteUser(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User ID $id berhasil dihapus.')),
                  );
                  widget.onRefresh();
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) _showError(context, e.toString());
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGE 3 — ADMIN LIST
// ============================================================

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  late Future<List<Admin>> _futureAdmins;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _futureAdmins = AdminService.getAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Admin>>(
      future: _futureAdmins,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorWidget(
            message: snapshot.error.toString(),
            onRetry: _load,
          );
        }

        final admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return const Center(child: Text('Tidak ada data Admin.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      admin.name.isNotEmpty ? admin.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    admin.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${admin.email}\n🏢 ${admin.department}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDetailScreen(
                        adminId: admin.id,
                        onRefresh: _load,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// PAGE 4 — ADMIN DETAIL  (GET / DELETE)
// ============================================================

class AdminDetailScreen extends StatefulWidget {
  final int adminId;
  final VoidCallback onRefresh;

  const AdminDetailScreen({
    super.key,
    required this.adminId,
    required this.onRefresh,
  });

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  late Future<Admin> _futureAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _futureAdmin = AdminService.getAdmin(widget.adminId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Admin #${widget.adminId}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Admin>(
        future: _futureAdmin,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorWidget(
              message: snapshot.error.toString(),
              onRetry: _load,
            );
          }

          final admin = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Card ────────────────────────────
                Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.deepPurple.shade200,
                          child: Text(
                            admin.name.isNotEmpty ? admin.name[0] : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'ID', value: '${admin.id}'),
                        _InfoRow(label: 'Nama', value: admin.name),
                        _InfoRow(label: 'Email', value: admin.email),
                        _InfoRow(label: 'Departemen', value: admin.department),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── DELETE Admin ─────────────────────────
                _ActionButton(
                  label: 'DELETE — Hapus Admin #${admin.id}',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => _confirmDelete(context, admin.id),
                ),

                // ── Info ID NIM ──────────────────────────
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple.shade100),
                  ),
                  child: Text(
                    'ID Admin berdasarkan NIM:\n'
                    '792 + 145 (3 digit terakhir NIM) = ${AdminService.nimAdminId}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Admin?'),
        content: Text('Admin ID $id akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdminService.deleteAdmin(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Admin ID $id berhasil dihapus.')),
                  );
                  widget.onRefresh();
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) _showError(context, e.toString());
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS — dialog result & error
// ============================================================

void _showResult(BuildContext context, String title, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: data.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${e.value}'),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $message'),
      backgroundColor: Colors.red,
    ),
  );
}
