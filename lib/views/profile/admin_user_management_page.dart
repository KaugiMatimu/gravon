import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppConstants.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: authService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];
                final filteredUsers = users.where((u) {
                  return u.fullName.toLowerCase().contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(context, user, authService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, AuthService authService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
          backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
          child: user.profileImageUrl == null ? const Icon(Icons.person, color: AppConstants.primaryColor) : null,
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(user.role.toString().split('.').last.toUpperCase(), Colors.blue),
                if (user.isAdmin) ...[
                  const SizedBox(width: 8),
                  _buildBadge('ADMIN', Colors.red),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, user, value, authService),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'toggle_admin', child: Text('Toggle Admin Status')),
            const PopupMenuItem(value: 'make_landlord', child: Text('Set as Landlord')),
            const PopupMenuItem(value: 'make_tenant', child: Text('Set as Tenant')),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, UserModel user, String action, AuthService authService) async {
    try {
      switch (action) {
        case 'toggle_admin':
          await authService.adminUpdateUser(user.uid, {'isAdmin': !user.isAdmin});
          break;
        case 'make_landlord':
          await authService.adminUpdateUser(user.uid, {'role': 'landlord'});
          break;
        case 'make_tenant':
          await authService.adminUpdateUser(user.uid, {'role': 'tenant'});
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
