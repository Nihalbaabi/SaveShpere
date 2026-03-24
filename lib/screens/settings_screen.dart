import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/billing_calculator.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;
  bool _saved = false;

  final Map<String, TextEditingController> _roomControllers = {
    'bedroom': TextEditingController(text: 'Bedroom'),
    'livingRoom': TextEditingController(text: 'Living Room'),
    'kitchen': TextEditingController(text: 'Kitchen'),
  };

  final Map<String, TextEditingController> _tariffControllers = {
    'slab1': TextEditingController(),
    'slab2': TextEditingController(),
    'slab3': TextEditingController(),
    'slab4': TextEditingController(),
    'slab5': TextEditingController(),
    'slab6': TextEditingController(),
    'fixedCharge': TextEditingController(),
    'dutyPercent': TextEditingController(),
    'surcharge': TextEditingController(),
  };

  final Map<String, TextEditingController> _waterTariffControllers = {
    's1': TextEditingController(),
    's2': TextEditingController(),
    's3': TextEditingController(),
    's4': TextEditingController(),
    's5': TextEditingController(),
    's6': TextEditingController(),
    's7': TextEditingController(),
    's8': TextEditingController(),
    's9': TextEditingController(),
    'minCharge': TextEditingController(),
  };

  bool _isWaterTariffMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _roomControllers['bedroom']?.text = prefs.getString('room_bedroom') ?? 'Bedroom';
    _roomControllers['livingRoom']?.text = prefs.getString('room_livingRoom') ?? 'Living Room';
    _roomControllers['kitchen']?.text = prefs.getString('room_kitchen') ?? 'Kitchen';

    _tariffControllers['slab1']?.text = (prefs.getDouble('tariff_slab1') ?? defaultTariff.slab1).toStringAsFixed(2);
    _tariffControllers['slab2']?.text = (prefs.getDouble('tariff_slab2') ?? defaultTariff.slab2).toStringAsFixed(2);
    _tariffControllers['slab3']?.text = (prefs.getDouble('tariff_slab3') ?? defaultTariff.slab3).toStringAsFixed(2);
    _tariffControllers['slab4']?.text = (prefs.getDouble('tariff_slab4') ?? defaultTariff.slab4).toStringAsFixed(2);
    _tariffControllers['slab5']?.text = (prefs.getDouble('tariff_slab5') ?? defaultTariff.slab5).toStringAsFixed(2);
    _tariffControllers['slab6']?.text = (prefs.getDouble('tariff_slab6') ?? defaultTariff.slab6).toStringAsFixed(2);
    _tariffControllers['fixedCharge']?.text = (prefs.getDouble('tariff_fixedCharge') ?? defaultTariff.fixedCharge).toStringAsFixed(2);
    _tariffControllers['dutyPercent']?.text = (prefs.getDouble('tariff_dutyPercent') ?? defaultTariff.dutyPercent).toStringAsFixed(2);
    _tariffControllers['surcharge']?.text = (prefs.getDouble('tariff_surcharge') ?? defaultTariff.surcharge).toStringAsFixed(2);

    _waterTariffControllers['s1']?.text = (prefs.getDouble('water_tariff_s1') ?? defaultWaterTariff.s1).toStringAsFixed(2);
    _waterTariffControllers['s2']?.text = (prefs.getDouble('water_tariff_s2') ?? defaultWaterTariff.s2).toStringAsFixed(2);
    _waterTariffControllers['s3']?.text = (prefs.getDouble('water_tariff_s3') ?? defaultWaterTariff.s3).toStringAsFixed(2);
    _waterTariffControllers['s4']?.text = (prefs.getDouble('water_tariff_s4') ?? defaultWaterTariff.s4).toStringAsFixed(2);
    _waterTariffControllers['s5']?.text = (prefs.getDouble('water_tariff_s5') ?? defaultWaterTariff.s5).toStringAsFixed(2);
    _waterTariffControllers['s6']?.text = (prefs.getDouble('water_tariff_s6') ?? defaultWaterTariff.s6).toStringAsFixed(2);
    _waterTariffControllers['s7']?.text = (prefs.getDouble('water_tariff_s7') ?? defaultWaterTariff.s7).toStringAsFixed(2);
    _waterTariffControllers['s8']?.text = (prefs.getDouble('water_tariff_s8') ?? defaultWaterTariff.s8).toStringAsFixed(2);
    _waterTariffControllers['s9']?.text = (prefs.getDouble('water_tariff_s9') ?? defaultWaterTariff.s9).toStringAsFixed(2);
    _waterTariffControllers['minCharge']?.text = (prefs.getDouble('water_tariff_minCharge') ?? defaultWaterTariff.minCharge).toStringAsFixed(2);

    setState(() {});
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('room_bedroom', _roomControllers['bedroom']!.text);
    await prefs.setString('room_livingRoom', _roomControllers['livingRoom']!.text);
    await prefs.setString('room_kitchen', _roomControllers['kitchen']!.text);

    await prefs.setDouble('tariff_slab1', double.tryParse(_tariffControllers['slab1']!.text) ?? defaultTariff.slab1);
    await prefs.setDouble('tariff_slab2', double.tryParse(_tariffControllers['slab2']!.text) ?? defaultTariff.slab2);
    await prefs.setDouble('tariff_slab3', double.tryParse(_tariffControllers['slab3']!.text) ?? defaultTariff.slab3);
    await prefs.setDouble('tariff_slab4', double.tryParse(_tariffControllers['slab4']!.text) ?? defaultTariff.slab4);
    await prefs.setDouble('tariff_slab5', double.tryParse(_tariffControllers['slab5']!.text) ?? defaultTariff.slab5);
    await prefs.setDouble('tariff_slab6', double.tryParse(_tariffControllers['slab6']!.text) ?? defaultTariff.slab6);
    await prefs.setDouble('tariff_fixedCharge', double.tryParse(_tariffControllers['fixedCharge']!.text) ?? defaultTariff.fixedCharge);
    await prefs.setDouble('tariff_dutyPercent', double.tryParse(_tariffControllers['dutyPercent']!.text) ?? defaultTariff.dutyPercent);
    await prefs.setDouble('tariff_surcharge', double.tryParse(_tariffControllers['surcharge']!.text) ?? defaultTariff.surcharge);

    await prefs.setDouble('water_tariff_s1', double.tryParse(_waterTariffControllers['s1']!.text) ?? defaultWaterTariff.s1);
    await prefs.setDouble('water_tariff_s2', double.tryParse(_waterTariffControllers['s2']!.text) ?? defaultWaterTariff.s2);
    await prefs.setDouble('water_tariff_s3', double.tryParse(_waterTariffControllers['s3']!.text) ?? defaultWaterTariff.s3);
    await prefs.setDouble('water_tariff_s4', double.tryParse(_waterTariffControllers['s4']!.text) ?? defaultWaterTariff.s4);
    await prefs.setDouble('water_tariff_s5', double.tryParse(_waterTariffControllers['s5']!.text) ?? defaultWaterTariff.s5);
    await prefs.setDouble('water_tariff_s6', double.tryParse(_waterTariffControllers['s6']!.text) ?? defaultWaterTariff.s6);
    await prefs.setDouble('water_tariff_s7', double.tryParse(_waterTariffControllers['s7']!.text) ?? defaultWaterTariff.s7);
    await prefs.setDouble('water_tariff_s8', double.tryParse(_waterTariffControllers['s8']!.text) ?? defaultWaterTariff.s8);
    await prefs.setDouble('water_tariff_s9', double.tryParse(_waterTariffControllers['s9']!.text) ?? defaultWaterTariff.s9);
    await prefs.setDouble('water_tariff_minCharge', double.tryParse(_waterTariffControllers['minCharge']!.text) ?? defaultWaterTariff.minCharge);

    setState(() {
      _saving = false;
      _saved = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    for (var c in _roomControllers.values) { c.dispose(); }
    for (var c in _tariffControllers.values) { c.dispose(); }
    for (var c in _waterTariffControllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: appColors.foreground,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Configure your SaveSphere dashboard",
              style: TextStyle(fontSize: 14, color: appColors.mutedForeground, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Theme Setting
            _buildCard(
              context,
              icon: themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
              iconColor: themeProvider.isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFFBBF24),
              title: "Visual Theme",
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => themeProvider.setTheme(ThemeMode.light),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !themeProvider.isDarkMode ? AppTheme.electricGreen : appColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !themeProvider.isDarkMode ? [BoxShadow(color: AppTheme.electricGreen.withOpacity(0.2), blurRadius: 10)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Light",
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: !themeProvider.isDarkMode ? Colors.white : appColors.mutedForeground
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => themeProvider.setTheme(ThemeMode.dark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? AppTheme.electricGreen : appColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: themeProvider.isDarkMode ? [BoxShadow(color: AppTheme.electricGreen.withOpacity(0.2), blurRadius: 10)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Dark",
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: themeProvider.isDarkMode ? Colors.white : appColors.mutedForeground
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Room Names
            _buildCard(
              context,
              icon: LucideIcons.home,
              iconColor: Theme.of(context).primaryColor,
              title: "Room Names",
              child: Column(
                children: [
                  _buildRoomRow(context, "Bedroom", _roomControllers['bedroom']!),
                  const SizedBox(height: 12),
                  _buildRoomRow(context, "Living Room", _roomControllers['livingRoom']!),
                  const SizedBox(height: 12),
                  _buildRoomRow(context, "Kitchen", _roomControllers['kitchen']!),
                ],
              ),
            ),

            // Tariff Rates Toggle Header
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: appColors.card,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWaterTariffMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isWaterTariffMode ? AppTheme.electricGreen.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.zap, size: 16, color: !_isWaterTariffMode ? AppTheme.electricGreen : appColors.mutedForeground),
                            const SizedBox(width: 8),
                            Text("Electricity (KSEB)", style: TextStyle(
                              fontSize: 13, fontWeight: !_isWaterTariffMode ? FontWeight.bold : FontWeight.w600,
                              color: !_isWaterTariffMode ? AppTheme.electricGreen : appColors.mutedForeground,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isWaterTariffMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isWaterTariffMode ? Colors.lightBlue.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.droplets, size: 16, color: _isWaterTariffMode ? Colors.lightBlue : appColors.mutedForeground),
                            const SizedBox(width: 8),
                            Text("Water (KWA)", style: TextStyle(
                              fontSize: 13, fontWeight: _isWaterTariffMode ? FontWeight.bold : FontWeight.w600,
                              color: _isWaterTariffMode ? Colors.lightBlue : appColors.mutedForeground,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tariff Rates Data
            if (!_isWaterTariffMode) ...[
              _buildCard(
                context,
                icon: LucideIcons.indianRupee,
                iconColor: const Color(0xFFF59E0B), // Amber/Yellow
                title: "KSEB Tariff Rates",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "0-50 units", _tariffControllers['slab1']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "51-100 units", _tariffControllers['slab2']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "101-150 units", _tariffControllers['slab3']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "151-200 units", _tariffControllers['slab4']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "201-250 units", _tariffControllers['slab5']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, ">250 units", _tariffControllers['slab6']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Fixed Charge", _tariffControllers['fixedCharge']!, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "Duty %", _tariffControllers['dutyPercent']!, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Surcharge (₹/unit)", _tariffControllers['surcharge']!, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: Container()), 
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                context,
                icon: LucideIcons.info,
                iconColor: const Color(0xFF0D9488), // Teal
                title: "KSEB Slab System",
                child: Text(
                  "Kerala State Electricity Board (KSEB) uses a progressive slab system. You pay different rates for each block of units consumed. "
                  "The first 50 units are charged at the lowest rate, and subsequent blocks are charged at increasing rates. "
                  "A fixed charge and 15% electricity duty are added to the total.",
                  style: TextStyle(fontSize: 12, height: 1.5, color: appColors.mutedForeground),
                ),
              ),
            ] else ...[
              _buildCard(
                context,
                icon: LucideIcons.droplets,
                iconColor: Colors.lightBlue,
                title: "KWA Tariff Rates (per KL)",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "0-5 KL", _waterTariffControllers['s1']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "5-10 KL", _waterTariffControllers['s2']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "10-15 KL", _waterTariffControllers['s3']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "15-20 KL", _waterTariffControllers['s4']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "20-25 KL", _waterTariffControllers['s5']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "25-30 KL", _waterTariffControllers['s6']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "30-40 KL", _waterTariffControllers['s7']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "40-50 KL", _waterTariffControllers['s8']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, ">50 KL", _waterTariffControllers['s9']!, isNumber: true, prefix: "₹ ")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField(context, "Min Charge", _waterTariffControllers['minCharge']!, isNumber: true, prefix: "₹ ")),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                context,
                icon: LucideIcons.info,
                iconColor: Colors.lightBlue,
                title: "KWA Slab System",
                child: Text(
                  "Kerala Water Authority uses a mixed progressive-flat algorithm based on KL (1,000 Liters). "
                  "Rates are calculated progressively up logic bounds (e.g., 0-5, 5-10, 10-15), while intermediate consumption (15-50 KL) triggers fixed-tier multiplication for entire usage volumes over the min charges.",
                  style: TextStyle(fontSize: 12, height: 1.5, color: appColors.mutedForeground),
                ),
              ),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _saveSettings,
                icon: const Icon(LucideIcons.save, size: 20),
                label: Text(
                  _saving ? "Persisting Changes..." : _saved ? "Settings Updated ✓" : "Commit All Changes",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await AuthService.instance.logout();
                },
                icon: const Icon(LucideIcons.logOut, size: 20),
                label: const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required Widget child}) {
    final appColors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildRoomRow(BuildContext context, String label, TextEditingController controller) {
    final appColors = context.appColors;
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: appColors.mutedForeground))),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appColors.foreground),
            decoration: InputDecoration(
              filled: true,
              fillColor: appColors.secondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.electricGreen, width: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, String label, TextEditingController controller, {bool isNumber = false, String? prefix}) {
    final appColors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appColors.mutedForeground)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: isNumber ? 'JetBrains Mono' : null, color: appColors.foreground),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appColors.mutedForeground),
            filled: true,
            fillColor: appColors.secondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.electricGreen, width: 2)),
          ),
        ),
      ],
    );
  }
}
