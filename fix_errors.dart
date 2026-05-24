import 'dart:io';

void main() async {
  final libDir = Directory('f:/flutter-bike-shop/bike_shop/lib');
  
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    var content = await file.readAsString();
    bool changed = false;
    
    // Replace const keywords before Theme.of(...)
    // A common case is "const SizedBox(child: Container(color: Theme.of(context)..."
    // Since dart regex is hard for nested consts, let's just do simple string replacements for the most common ones:
    final targets = [
      'const Center(\n        child: Text(\n          \'Notification settings will be here\',\n          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),\n        ),\n      )',
      'const Center(\n        child: Text(\n          \'Privacy & security options will be here\',\n          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),\n        ),\n      )',
      'const Center(\n        child: Text(\n          \'FAQ and support options will be here\',\n          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),\n        ),\n      )',
    ];
    
    // Replace 'const Text(... Theme.of(...)' with 'Text(... Theme.of(...)'
    final regexConstTheme = RegExp(r'const\s+([A-Za-z0-9_]+)\([^)]*Theme\.of\(context\)');
    while (regexConstTheme.hasMatch(content)) {
      final match = regexConstTheme.firstMatch(content)!;
      final start = match.start;
      content = content.substring(0, start) + content.substring(start + 5); // remove 'const'
      changed = true;
    }

    final regexConstTheme2 = RegExp(r'const\s+([A-Za-z0-9_]+)\([^)]*Theme\.of\(context\)[^)]*\)');
    if (content.contains('const TextStyle(color: Theme.of(context)')) {
      content = content.replaceAll('const TextStyle(color: Theme.of(context)', 'TextStyle(color: Theme.of(context)');
      changed = true;
    }
    if (content.contains('const BoxDecoration(\n                      color: Theme.of(context)')) {
      content = content.replaceAll('const BoxDecoration(\n                      color: Theme.of(context)', 'BoxDecoration(\n                      color: Theme.of(context)');
      changed = true;
    }
    if (content.contains('const BoxDecoration(color: Theme.of(context)')) {
      content = content.replaceAll('const BoxDecoration(color: Theme.of(context)', 'BoxDecoration(color: Theme.of(context)');
      changed = true;
    }

    // Replace withOpacity with withValues
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(RegExp(r'\.withOpacity\((.*?)\)'), (m) => '.withValues(alpha: ${m[1]})');
      changed = true;
    }
    
    if (content.contains('const Icon(Icons.search_off, size: 64, color: Theme.of(context)')) {
      content = content.replaceAll('const Icon(Icons.search_off, size: 64, color: Theme.of(context)', 'Icon(Icons.search_off, size: 64, color: Theme.of(context)');
      changed = true;
    }

    if (content.contains('const CircularProgressIndicator(color: Theme.of(context)')) {
      content = content.replaceAll('const CircularProgressIndicator(color: Theme.of(context)', 'CircularProgressIndicator(color: Theme.of(context)');
      changed = true;
    }

    if (changed) {
      await file.writeAsString(content);
      print('Fixed errors in: ${file.path}');
    }
  }
}
