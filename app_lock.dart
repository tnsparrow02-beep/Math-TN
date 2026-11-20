import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'database_helper.dart';

/// Result of a PIN check.
class VerifyResult {
  final bool ok;

  /// > 0 when too many wrong attempts: the app refuses new tries for this many seconds.
  final int lockedSeconds;

  const VerifyResult({required this.ok, this.lockedSeconds = 0});
}

/// PIN lock: the PIN is never stored, only a salted SHA-256 hash (in the local database).
class AppLock {
  AppLock._();

  /// True when the user has chosen to protect the app with a PIN (off by default).
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// True while the lock screen must be shown (only meaningful when [enabled]).
  static final ValueNotifier<bool> locked = ValueNotifier<bool>(false);

  /// > 0 while a file picker / camera is open: the app must not re-lock because it was paused.
  static int busy = 0;

  static const int _rounds = 8000;
  static const int minLength = 4;
  static const int maxLength = 8;

  static String _hash(String salt, String pin) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < _rounds; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  static String _newSalt() {
    final rng = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => rng.nextInt(256)));
  }

  static Future<bool> hasPin() async {
    final h = await DatabaseHelper.instance.getSetting('pin_hash');
    return h != null && h.isNotEmpty;
  }

  static Future<int> pinLength() async {
    final v = await DatabaseHelper.instance.getSetting('pin_len');
    return int.tryParse(v ?? '') ?? minLength;
  }

  static Future<void> setPin(String pin) async {
    final db = DatabaseHelper.instance;
    final salt = _newSalt();
    await db.setSetting('pin_salt', salt);
    await db.setSetting('pin_hash', _hash(salt, pin));
    await db.setSetting('pin_len', '${pin.length}');
    await db.setSetting('pin_fails', '0');
    await db.setSetting('pin_until', '0');
  }

  /// Turns the password off: the app opens directly again.
  static Future<void> removePin() async {
    final db = DatabaseHelper.instance;
    await db.setSetting('pin_hash', '');
    await db.setSetting('pin_salt', '');
    await db.setSetting('pin_fails', '0');
    await db.setSetting('pin_until', '0');
  }

  /// Seconds left before a new try is allowed (0 = allowed now).
  static Future<int> lockoutSeconds() async {
    final until = int.tryParse(await DatabaseHelper.instance.getSetting('pin_until') ?? '') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return until > now ? ((until - now) / 1000).ceil() : 0;
  }

  static Future<VerifyResult> verify(String pin) async {
    final db = DatabaseHelper.instance;
    final waiting = await lockoutSeconds();
    if (waiting > 0) return VerifyResult(ok: false, lockedSeconds: waiting);

    final salt = await db.getSetting('pin_salt') ?? '';
    final hash = await db.getSetting('pin_hash') ?? '';
    if (hash.isNotEmpty && _hash(salt, pin) == hash) {
      await db.setSetting('pin_fails', '0');
      await db.setSetting('pin_until', '0');
      return const VerifyResult(ok: true);
    }

    // Wrong PIN: after every 5 failures the app waits (30 s, 60 s, 120 s ... up to 10 minutes).
    final fails = (int.tryParse(await db.getSetting('pin_fails') ?? '') ?? 0) + 1;
    await db.setSetting('pin_fails', '$fails');
    var wait = 0;
    if (fails % 5 == 0) {
      final step = min((fails ~/ 5) - 1, 5);
      wait = min(600, 30 * (1 << step));
      final until = DateTime.now().millisecondsSinceEpoch + wait * 1000;
      await db.setSetting('pin_until', '$until');
    }
    return VerifyResult(ok: false, lockedSeconds: wait);
  }
}
