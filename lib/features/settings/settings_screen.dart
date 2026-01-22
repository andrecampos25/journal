import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/services/offline_service.dart';
import 'package:life_os/services/ota_service.dart';
import 'package:life_os/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.lexend(color: const Color(0xFF1E293B))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
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
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(LucideIcons.lock, color: Color(0xFF64748B)),
            title: Text('Change PIN', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Change coming soon (Edit in pin_screen.dart)')));
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('System'),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(LucideIcons.downloadCloud, color: Color(0xFF64748B)),
            title: Text('Check for Updates', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              ref.read(otaServiceProvider).checkForUpdates(context);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(LucideIcons.info, color: Color(0xFF64748B)),
            title: Text('Version', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Text(_version, style: GoogleFonts.inter(color: Colors.grey)),
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
        color: Colors.white,
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
