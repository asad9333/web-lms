import 'dart:io';

/// Adds INTERNET permission (needed for AI features in release builds)
/// and sets the app name shown under the launcher icon.
void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln(
        'AndroidManifest.xml not found. Run: flutter create --platforms=android . first');
    exit(1);
  }
  var text = file.readAsStringSync();

  if (!text.contains('android.permission.INTERNET')) {
    text = text.replaceFirst(
      '<application',
      '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
    );
  }

  text = text.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="Course LMS"',
  );

  file.writeAsStringSync(text);
  stdout.writeln('AndroidManifest.xml updated (INTERNET permission + app name).');
}
