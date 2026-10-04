import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class Passwords {
  Passwords._();

  static const String _chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static String _randomString(int len) {
    final r = Random.secure();
    return List<String>.generate(len, (_) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  static String _derive(String salt, String plain) {
    List<int> h = utf8.encode('$salt:$plain');
    for (var i = 0; i < 2000; i++) {
      h = sha256.convert(h).bytes;
    }
    return base64Encode(h);
  }

  /// Returns "salt:derivedHash".
  static String hash(String plain) {
    final salt = _randomString(16);
    return '$salt:${_derive(salt, plain)}';
  }

  static bool verify(String plain, String stored) {
    final i = stored.indexOf(':');
    if (i < 0) return false;
    final salt = stored.substring(0, i);
    final expected = stored.substring(i + 1);
    return _derive(salt, plain) == expected;
  }

  /// Random placeholder password (used when admin creates / resets a user).
  static String randomPassword([int len = 32]) => _randomString(len);
}
