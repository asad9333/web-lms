import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChosenFile {
  final String path;
  final String name;
  final int size;

  const ChosenFile({required this.path, required this.name, required this.size});
}

/// Stores uploaded files inside the app's private documents folder so the
/// app works fully offline (no web server / public storage folder needed).
class FileStore {
  FileStore._();

  static const int maxBytes = 20 * 1024 * 1024; // 20 MB, same as the web app

  static Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'lms_files'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<ChosenFile?> pick(List<String> allowedExtensions) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;
    final path = f.path;
    if (path == null) return null;
    return ChosenFile(path: path, name: f.name, size: f.size);
  }

  /// Copies [sourcePath] into app storage and returns the relative path
  /// (always with forward slashes) that is saved in the database.
  static Future<String> saveCopy(String sourcePath, String subFolder) async {
    final root = await _root();
    final parts = subFolder.split('/');
    final dir = Directory(p.joinAll(<String>[root.path, ...parts]));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final cleanName =
        p.basename(sourcePath).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    await File(sourcePath).copy(p.join(dir.path, fileName));
    return '$subFolder/$fileName';
  }

  static Future<File> resolve(String relativePath) async {
    final root = await _root();
    return File(p.joinAll(<String>[root.path, ...relativePath.split('/')]));
  }

  static Future<void> delete(String relativePath) async {
    try {
      final f = await resolve(relativePath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  /// Opens the file with an installed app. Returns an error message or null.
  static Future<String?> open(String relativePath) async {
    final f = await resolve(relativePath);
    if (!await f.exists()) {
      return 'File not found on this device.';
    }
    final result = await OpenFilex.open(f.path);
    if (result.type == ResultType.done) return null;
    return result.message.isEmpty
        ? 'No app found to open this file.'
        : result.message;
  }
}
