import 'package:flutter/material.dart';
import '../Services/db_service.dart';

class ManageUserAccountScreen extends StatefulWidget {
  final String adminId;

  const ManageUserAccountScreen({super.key, required this.adminId});

  @override
  State<ManageUserAccountScreen> createState() =>
      _ManageUserAccountScreenState();
}

class _ManageUserAccountScreenState extends State<ManageUserAccountScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];

  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);

    final data = await DbService.view('users', {});
    final list = List<Map<String, dynamic>>.from(data);

    final filtered = list.where((u) {
      final role = (u['role'] ?? '').toString().trim().toLowerCase();

      return role == 'user';
    }).toList();

    setState(() {
      users = filtered;
      filteredUsers = filtered;
      isLoading = false;
    });
  }

  void _search(String text) {
    final query = text.trim().toLowerCase();

    setState(() {
      filteredUsers = users.where((user) {
        final name = (user['username'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final email = (user['email'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _detectStatus(Map user) async {
    final newStatus =
    (user['status'] ?? '').toString().trim().toLowerCase() == 'active'
        ? 'inactive'
        : 'active';

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Update"),
        content: Text("Change status to $newStatus ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    await DbService.update(
      'users',
      'id',
      user['id'],
      {'status': newStatus},
    );

    _loadUsers();
  }

  Future<void> _deleteUser(Map user) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    await DbService.update(
      'users',
      'id',
      user['id'],
      {'status': 'deleted'},
    );

    _loadUsers();
  }

  Widget _statusBadge(String status) {
    Color color;

    if (status == 'active') {
      color = Colors.green;
    } else if (status == 'inactive') {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("User Management"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          )
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _search,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search user...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  child: ListTile(
                    title: Text(
                      user['username'] ?? '',
                      style: const TextStyle(color: Colors.black),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['email'] ?? '',
                          style:
                          const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        _statusBadge(user['status'] ?? ''),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sync,
                              color: Colors.orange),
                          onPressed: () => _detectStatus(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}