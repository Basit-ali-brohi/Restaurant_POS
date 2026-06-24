import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _restaurantNameController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  final TextEditingController _headerController = TextEditingController(text: "Neo Dining");
  final TextEditingController _footerController = TextEditingController(text: "Thank you for dining with us!");

  bool _notifications = true;
  bool _autoPrintReceipt = true;
  final String _currency = 'PKR';
  double _serviceCharge = 5.0;
  final String _selectedLanguage = 'English';
  String _defaultOrderType = 'Dine-In';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _restaurantNameController = TextEditingController(text: settings.restaurantName);
    _addressController = TextEditingController(text: settings.address);
    _taxController = TextEditingController(text: settings.taxRate.toString());
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final double? taxRate = double.tryParse(_taxController.text);
    
    if (taxRate != null) {
      ref.read(settingsProvider.notifier).updateTaxRate(taxRate);
    }
    ref.read(settingsProvider.notifier).updateRestaurantName(_restaurantNameController.text);
    ref.read(settingsProvider.notifier).updateAddress(_addressController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Settings Saved Successfully"),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    final isDarkMode = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    final isDarkMode = ref.watch(themeProvider);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
      value: value,
      activeColor: AppColors.accent,
      onChanged: onChanged,
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDarkMode = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    final isDarkMode = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(bool isDarkMode) {
    final settings = ref.watch(settingsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Restaurant Configuration",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage restaurant details, taxes, and hardware.",
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        
        // Restaurant Info
        Text(
          "Restaurant Info",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTextField("Restaurant Name", _restaurantNameController),
        const SizedBox(height: 16),
        _buildTextField("Address", _addressController),
        
        const SizedBox(height: 32),
        Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
        const SizedBox(height: 32),

        // Financial Settings
        Text(
          "Financial Settings",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTextField("Tax / GST Percentage (%)", _taxController, isNumber: true),
        
        const SizedBox(height: 32),
        Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
        const SizedBox(height: 32),

        // Appearance Settings
        Text(
          "Appearance",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text("Dark Mode", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          subtitle: Text("Toggle application theme", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
          value: isDarkMode,
          activeColor: AppColors.accent,
          onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
        ),

        const SizedBox(height: 32),
        Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
        const SizedBox(height: 32),

        // Printer Settings
        Text(
          "Hardware Settings",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          "Connect Printer", 
          settings.isPrinterConnected ? "Printer is connected via Bluetooth/Wi-Fi" : "No printer connected", 
          settings.isPrinterConnected, 
          (val) => ref.read(settingsProvider.notifier).togglePrinter(val)
        ),

        const SizedBox(height: 32),
        Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
        const SizedBox(height: 32),

        // Save Button
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 50),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;
          
          if (isSmallScreen) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                borderRadius: 24,
                color: isDarkMode ? Colors.white : Colors.white,
                opacity: isDarkMode ? 0.3 : 0.8,
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: _buildSettingsContent(isDarkMode),
                ),
              ),
            );
          }

          return Row(
            children: [
              // Sidebar / Section List
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader("General"),
                              _buildSettingItem(Icons.store, "Restaurant Info", "Name, Address, Logo"),
                              _buildSettingItem(Icons.language, "Language", _selectedLanguage),
                              _buildSettingItem(Icons.attach_money, "Currency", _currency),
                              const SizedBox(height: 24),
                              _buildSectionHeader("Appearance"),
                              _buildSettingItem(Icons.dark_mode, "Dark Mode", "Theme Toggle"),
                              const SizedBox(height: 24),
                              _buildSectionHeader("Financial"),
                              _buildSettingItem(Icons.receipt, "Taxes & Charges", "${_taxController.text}% Tax, ${_serviceCharge.toStringAsFixed(1)}% Service"),
                              _buildSettingItem(Icons.payment, "Payment Methods", "Stripe, Cash, Split Bill"),
                              const SizedBox(height: 24),
                              _buildSectionHeader("Devices"),
                              _buildSettingItem(Icons.print, "Printers", "Kitchen & Receipt Printers"),
                              _buildSettingItem(Icons.tablet_mac, "KDS Displays", "Connected Screens"),
                              _buildSettingItem(Icons.payment, "Card Terminals", "Stripe, Square"),
                              const SizedBox(height: 24),
                              _buildSectionHeader("System"),
                              _buildSettingItem(Icons.security, "Security", "PINs & Permissions"),
                              _buildSettingItem(Icons.backup, "Backup & Restore", "Last backup: Today 10:00 AM"),
                              _buildSettingItem(Icons.info, "About", "Version 1.0.0"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Detail / Content Area
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassContainer(
                    borderRadius: 24,
                    color: isDarkMode ? Colors.white : Colors.white,
                    opacity: isDarkMode ? 0.3 : 0.8,
                    border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      child: _buildSettingsContent(isDarkMode),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
