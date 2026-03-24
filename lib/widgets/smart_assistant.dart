import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/assistant_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/energy_provider.dart';
import '../providers/water_provider.dart';
import '../models/energy_models.dart';
import '../theme/app_theme.dart';
import 'typing_indicator.dart';
import 'voice_visualizer.dart';

class SmartAssistantWidget extends StatefulWidget {
  final EnergyMetrics energyData;

  const SmartAssistantWidget({super.key, required this.energyData});

  @override
  State<SmartAssistantWidget> createState() => _SmartAssistantWidgetState();
}

class _SmartAssistantWidgetState extends State<SmartAssistantWidget> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _chipPool = [
    {"label": "Current Usage", "query": "What is my current power usage?"},
    {"label": "Check Bill", "query": "What is my expected bill?"},
    {"label": "Energy Tips", "query": "Give me some energy saving tips."},
    {"label": "Daily Compare", "query": "Compare today versus yesterday."},
    {"label": "Highest Room", "query": "Which room consumes the most right now?"},
    {"label": "Peak Time", "query": "When is my peak hour?"},
    {"label": "Monthly Units", "query": "How many units have I used this month?"},
    {"label": "Dark Mode", "query": "Change theme to dark mode."},
  ];

  List<Map<String, String>> _currentChips = [];

  @override
  void initState() {
    super.initState();
    _shuffleChips();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _shuffleChips() {
    final pool = List<Map<String, String>>.from(_chipPool);
    pool.shuffle();
    _currentChips = pool.take(3).toList();
  }

  void _handleChipClick(String query) {
    final provider = Provider.of<AssistantProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final energyProvider = Provider.of<EnergyDataProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterDataProvider>(context, listen: false);
    provider.processQuery(query, energyProvider, waterProvider, themeProvider);
  }

  void _toggleAssistant() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) _shuffleChips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) _buildChatWindow(context),
        if (_isOpen) const SizedBox(height: 16),
        GestureDetector(
          onTap: _toggleAssistant,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: appColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricGreen.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(_isOpen ? LucideIcons.x : LucideIcons.zap, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildChatWindow(BuildContext context) {
    final appColors = context.appColors;
    final provider = Provider.of<AssistantProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 350,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.deepBlue : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appColors.secondary.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: appColors.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.electricGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.zap, size: 20, color: AppTheme.electricGreen),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EcoTrack AI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: appColors.foreground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.electricGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Intelligent Assistant",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: appColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                shrinkWrap: true,
                children: [
                   const SizedBox(height: 12),
                  if (provider.messages.isEmpty) ...[
                    Center(
                      child: Text(
                        "How can I help you save energy?",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: appColors.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _currentChips.map((chip) => ActionChip(
                        label: Text(chip['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () => _handleChipClick(chip['query']!),
                        backgroundColor: appColors.secondary,
                        labelStyle: TextStyle(color: appColors.foreground),
                        side: BorderSide(color: appColors.border.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      )).toList(),
                    ),
                  ] else ...[
                    for (final msg in provider.messages) _buildMessage(msg, context),
                  ],
                  if (provider.state == 'listening' && provider.lastTranscript.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          provider.lastTranscript,
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: appColors.mutedForeground),
                        )
                      ),
                    ),
                  if (provider.state == 'listening')
                    const Align(alignment: Alignment.centerLeft, child: VoiceVisualizer()),
                  if (provider.state == 'processing')
                    const Align(alignment: Alignment.centerLeft, child: TypingIndicator()),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appColors.card,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: appColors.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: appColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      provider.state == 'listening' 
                        ? (provider.lastTranscript.isEmpty ? "Listening..." : "Keep speaking...") 
                        : "Tap the mic to talk...",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: appColors.mutedForeground),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    final energyProvider = Provider.of<EnergyDataProvider>(context, listen: false);
                    final waterProvider = Provider.of<WaterDataProvider>(context, listen: false);
                    if (provider.state == 'listening') {
                      provider.stopListening(energyProvider, waterProvider, themeProvider);
                    } else {
                      provider.startListening(energyProvider, waterProvider, themeProvider);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: provider.state == 'listening' ? Colors.red : AppTheme.electricGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (provider.state == 'listening' ? Colors.red : AppTheme.electricGreen).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      provider.state == 'listening' ? LucideIcons.micOff : LucideIcons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, BuildContext context) {
    final isUser = msg.sender == 'user';
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isUser ? Theme.of(context).primaryColor : appColors.secondary.withOpacity(0.8),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                 BoxShadow(
                   color: isUser ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                   blurRadius: 10,
                   offset: const Offset(0, 4),
                 )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          if (!isUser && msg.responseMeta?.suggestions != null && msg.responseMeta!.suggestions.isNotEmpty)
            ...msg.responseMeta!.suggestions.map((sug) => Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxWidth: 240),
                decoration: BoxDecoration(
                  color: appColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appColors.border.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(sug, style: TextStyle(fontSize: 11, color: appColors.mutedForeground))),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}
