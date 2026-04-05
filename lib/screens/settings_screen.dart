import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Appearance'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.bgCardLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          settings.themeMode == ThemeMode.dark 
                              ? Icons.dark_mode_rounded 
                              : Icons.light_mode_rounded,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(
                              settings.themeMode == ThemeMode.dark ? 'Amoled Black is active' : 'Light theme is active',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.themeMode == ThemeMode.dark,
                        activeColor: AppTheme.accentColor,
                        onChanged: (isDark) {
                          settings.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Global Sound Settings'),
                const SizedBox(height: 8),
                const Text(
                  'These sounds will be used for all your task alarms and reminders unless you have set a custom sound for a specific existing task.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                
                _buildSoundTile(
                  context,
                  title: 'Default Alarm Sound',
                  subtitle: 'Plays when an Alarm triggers',
                  icon: Icons.alarm,
                  color: AppTheme.alarmColor,
                  soundName: settings.alarmSoundName,
                  onPick: () => _pickSound(context, settings, isAlarm: true),
                  onClear: () => settings.setAlarmSound(null, null),
                ),
                
                const SizedBox(height: 16),
                
                _buildSoundTile(
                  context,
                  title: 'Default Reminder Sound',
                  subtitle: 'Plays when a Reminder triggers',
                  icon: Icons.notifications_active_outlined,
                  color: AppTheme.reminderColor,
                  soundName: settings.reminderSoundName,
                  onPick: () => _pickSound(context, settings, isAlarm: false),
                  onClear: () => settings.setReminderSound(null, null),
                ),
                
                const SizedBox(height: 40),
                _buildSectionHeader('About'),
                const SizedBox(height: 8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('NovaTask v1.1.0', style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text('Custom global sounds enabled', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.accentColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSoundTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String? soundName,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    soundName ?? 'Standard App Sound',
                    style: TextStyle(
                      color: soundName != null ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 13,
                      fontStyle: soundName == null ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (soundName != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.cancel_rounded, size: 18, color: AppTheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text('Choose .mp3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSound(BuildContext context, SettingsProvider settings, {required bool isAlarm}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      final appDir = await getApplicationSupportDirectory();
      final soundsDir = Directory('${appDir.path}/custom_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final newPath = '${soundsDir.path}/global_${isAlarm ? 'alarm' : 'reminder'}_$fileName';
      await file.copy(newPath);

      if (isAlarm) {
        await settings.setAlarmSound(newPath, fileName);
      } else {
        await settings.setReminderSound(newPath, fileName);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isAlarm ? 'Alarm' : 'Reminder'} sound updated to "$fileName"')),
        );
      }
    }
  }
}
