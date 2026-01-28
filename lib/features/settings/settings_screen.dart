import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/services/offline_service.dart';
import 'package:life_os/services/ota_service.dart';
import 'package:life_os/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:life_os/services/secret_service.dart';
import 'package:life_os/services/ai_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineService = ref.watch(offlineServiceProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.lexend(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Sync & Data'),
          _buildSyncTile(offlineService),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeProvider);
              final isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                secondary: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, color: Theme.of(context).iconTheme.color),
                title: Text('Dark Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                value: isDark,
                onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Security'),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(LucideIcons.lock, color: Theme.of(context).colorScheme.secondary),
            title: Text('Change PIN', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary),
            onTap: () {
              HapticFeedback.lightImpact();
              _showChangePinDialog(context);
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('AI Configuration'),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(LucideIcons.sparkles, color: Theme.of(context).colorScheme.secondary),
            title: Text('Gemini API Key', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary),
            onTap: () => _showApiKeyDialog(context),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('System'),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(LucideIcons.downloadCloud, color: Theme.of(context).colorScheme.secondary),
            title: Text('Check for Updates', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary),
            onTap: () {
              ref.read(otaServiceProvider).checkForUpdates(context);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(LucideIcons.info, color: Theme.of(context).colorScheme.secondary),
            title: Text('Version', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Text(_version, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final secretService = ref.read(secretServiceProvider);
    final currentKey = await secretService.getGeminiKey();
    final controller = TextEditingController(text: currentKey);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Gemini API Key', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your Gemini API key to enable AI features. The key is stored securely on your device.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  hintText: 'AIza...',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final aiService = ref.read(aiServiceProvider);
                final result = await aiService.testConnection();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('AI Diagnostic Result', style: GoogleFonts.lexend()),
                      content: Text(result, style: GoogleFonts.robotoMono(fontSize: 12)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                      ],
                    ),
                  );
                }
              },
              child: Text('Test Connection', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary)),
            ),
            FilledButton(
              onPressed: () async {
                await secretService.saveGeminiKey(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key saved securely')),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  void _showChangePinDialog(BuildContext context) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final offlineService = ref.read(offlineServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change PIN', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              decoration: const InputDecoration(labelText: 'Current PIN', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(labelText: 'New 4-Digit PIN', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(labelText: 'Confirm New PIN', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              final current = currentPinController.text;
              final next = newPinController.text;
              final confirm = confirmPinController.text;

              if (current != offlineService.vaultPin) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect current PIN')));
                 return;
              }
              if (next.length != 4) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
                 return;
              }
              if (next != confirm) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New PINs do not match')));
                 return;
              }

              await offlineService.setVaultPin(next);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lexend(
          fontSize: 12, 
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8), 
          letterSpacing: 1.0
        ),
      ),
    );
  }

  Widget _buildSyncTile(OfflineService offlineService) {
    final queueLength = offlineService.getQueue().length;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              LucideIcons.cloud, 
              color: queueLength > 0 ? Colors.orange : Colors.green
            ),
            title: Text('Sync Status', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            subtitle: Text(
              queueLength > 0 ? '$queueLength items pending sync' : 'All synced',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            trailing: _isSyncing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(LucideIcons.refreshCw),
                  onPressed: () async {
                    setState(() => _isSyncing = true);
                    await ref.read(supabaseServiceProvider).syncPendingMutations();
                    // Force refresh of queue display? offlineService.getQueue() is sync but Provider<OfflineService> doesn't notify.
                    // We need to setState to rebuild or use a StreamProvider/StateNotifier for queue.
                    // For MVP setState is checking the service again in build.
                    setState(() => _isSyncing = false);
                  },
                ),
          ),
        ],
      ),
    );
  }
}
