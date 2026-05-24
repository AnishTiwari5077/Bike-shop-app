import 'dart:io';

void main() async {
  final dir = Directory('f:/flutter-bike-shop/bike_shop/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    if (file.path.contains('config\\theme.dart') || file.path.contains('config/theme.dart')) continue;
    
    var content = await file.readAsString();
    bool changed = false;
    
    // Scaffold background
    if (content.contains('backgroundColor: AppTheme.primaryBackground')) {
      content = content.replaceAll('backgroundColor: AppTheme.primaryBackground,', '');
      content = content.replaceAll('backgroundColor: AppTheme.primaryBackground', '');
      changed = true;
    }
    
    if (content.contains('AppTheme.primaryBackground')) {
      content = content.replaceAll('AppTheme.primaryBackground', 'Theme.of(context).scaffoldBackgroundColor');
      changed = true;
    }
    
    if (content.contains('AppTheme.cardBackground')) {
      content = content.replaceAll('AppTheme.cardBackground', 'Theme.of(context).cardColor');
      changed = true;
    }
    
    if (content.contains('AppTheme.secondaryBackground')) {
      content = content.replaceAll('AppTheme.secondaryBackground', 'Theme.of(context).colorScheme.surface');
      changed = true;
    }
    
    if (content.contains('AppTheme.textPrimary')) {
      content = content.replaceAll('AppTheme.textPrimary', 'Theme.of(context).colorScheme.onSurface');
      changed = true;
    }
    
    if (content.contains('AppTheme.textSecondary')) {
      content = content.replaceAll('AppTheme.textSecondary', 'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)');
      changed = true;
    }
    
    if (changed) {
      await file.writeAsString(content);
      print('Updated: ${file.path}');
    }
  }
}
