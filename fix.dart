import 'dart:io';

void main() {
  final files = [
    'lib/screens/money_management_screen.dart',
    'lib/screens/analytics_screen.dart',
    'lib/screens/home_screen.dart', // Just in case
    'lib/widgets/bill_card.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Replace incorrectly escaped dollar signs
    content = content.replaceAll(r'\$', r'$');
    
    // Special fix for one typo in money_management_screen.dart where it was \$( rather than \${
    content = content.replaceAll(r'Slab $(_getCurrentSlab', r'Slab ${_getCurrentSlab');
    
    file.writeAsStringSync(content);
    print('Fixed $path');
  }
}
