import 'dart:io';

void main() async {
  final libDir = Directory('f:/flutter-bike-shop/bike_shop/lib');
  
  // 2. Update import paths in all .dart files
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    var content = await file.readAsString();
    bool changed = false;
    
    if (content.contains('package:bike_shop/screens/')) {
      content = content.replaceAll('package:bike_shop/screens/', 'package:bike_shop/views/');
      changed = true;
    }
    
    if (content.contains('package:bike_shop/service/')) {
      content = content.replaceAll('package:bike_shop/service/', 'package:bike_shop/services/');
      changed = true;
    }

    if (content.contains('package:bike_shop/providers/')) {
      content = content.replaceAll('package:bike_shop/providers/', 'package:bike_shop/viewmodels/');
      changed = true;
    }
    
    if (changed) {
      await file.writeAsString(content);
      print('Updated imports in: ${file.path}');
    }
  }
}
