import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isLoading = false;

  Future<void> _changePassword() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = context.read<AuthService>();
              try {
                await authService.sendPasswordResetEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: \${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppConstants.errorColor)),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor, foregroundColor: Colors.white),
            onPressed: () async {
              final authService = context.read<AuthService>();
              setState(() => _isLoading = true);
              try {
                await authService.deleteAccount();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: \${e.toString()}')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSecurityTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Send a password reset link to your email',
                onTap: _changePassword,
              ),
              _buildSecurityTile(
                icon: Icons.phonelink_lock_rounded,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security (Coming Soon)',
                onTap: () {},
                enabled: false,
              ),
              _buildSecurityTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face ID (Coming Soon)',
                onTap: () {},
                enabled: false,
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              _buildSecurityTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                textColor: AppConstants.errorColor,
                iconColor: AppConstants.errorColor,
                onTap: _deleteAccount,
              ),
            ],
          ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppConstants.primaryColor),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enabled ? (textColor ?? Colors.black) : Colors.grey,
          )
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: enabled ? Colors.grey.shade600 : Colors.grey.shade400)),
        trailing: enabled ? const Icon(Icons.chevron_right_rounded, size: 20) : null,
        onTap: enabled ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
