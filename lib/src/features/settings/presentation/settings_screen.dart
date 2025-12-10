import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/providers/theme_provider.dart';
import 'category_management_screen.dart';
import 'google_sheet_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F172A) // Slate 900
          : const Color(0xFFF8FAFC), // Slate 50
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
             pinned: true,
             expandedHeight: 120,
             flexibleSpace: FlexibleSpaceBar(
               title: const Text("Settings"),
               centerTitle: true,
               background: Container(
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
                        Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade900 : Colors.indigo.shade600,
                        Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade900 : Colors.teal.shade400,
                     ],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                 ),
               ),
             ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                 // Section 1: Account & Data
                _buildSectionHeader(context, "Data Management"),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.category_rounded,
                      iconColor: Colors.orange,
                      title: "Manage Categories",
                      subtitle: "Customize your expense types",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
                      },
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.sync_rounded,
                      iconColor: Colors.blue,
                      title: "Google Sheets Sync",
                      subtitle: "Sync data to the cloud",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GoogleSheetSettingsScreen()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Section 2: Appearance
                _buildSectionHeader(context, "Appearance"),
                const SizedBox(height: 12),
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Theme.of(context).cardColor,
                     borderRadius: BorderRadius.circular(24),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.04),
                         blurRadius: 16,
                         offset: const Offset(0, 4),
                       )
                     ]
                   ),
                   child: Column(
                     children: [
                       Consumer(
                          builder: (context, ref, child) {
                            final currentMode = ref.watch(themeModeProvider);
                            return Row(
                              children: [
                                Expanded(child: _ThemeOption(
                                  label: "Auto", 
                                  icon: Icons.brightness_auto_rounded, 
                                  isSelected: currentMode == ThemeMode.system,
                                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
                                )),
                                Expanded(child: _ThemeOption(
                                  label: "Light", 
                                  icon: Icons.light_mode_rounded, 
                                  isSelected: currentMode == ThemeMode.light,
                                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                                )),
                                Expanded(child: _ThemeOption(
                                  label: "Dark", 
                                  icon: Icons.dark_mode_rounded, 
                                  isSelected: currentMode == ThemeMode.dark,
                                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                                )),
                              ],
                            );
                          },
                        ),
                     ],
                   ),
                ),

                const SizedBox(height: 48),
                
                // Footer
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.savings_rounded, size: 48, color: Theme.of(context).primaryColor.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "Digi Expense Tracker",
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          color: Theme.of(context).textTheme.bodySmall?.color
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Version 1.0.0",
                        style: TextStyle(
                          color: Theme.of(context).disabledColor, 
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 16,
             offset: const Offset(0, 4),
           )
        ]
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 70, endIndent: 24, color: Theme.of(context).dividerColor.withOpacity(0.5));
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
           color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
             color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent
           )
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
