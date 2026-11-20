import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_lock.dart';
import 'app_state.dart';
import 'nb_files.dart';
import 'strings.dart';
import 'widgets.dart';

enum PinMode { setup, unlock, change, disable }

/// One screen for three jobs:
/// - setup: choose a PIN the first time (4 to 8 digits, typed twice)
/// - unlock: enter the PIN to open the app
/// - change: enter the current PIN, then choose a new one
///
/// NOTE: in "setup" and "unlock" this screen sits above the Navigator (see LockGate),
/// so it must not use tooltips, popup menus or snack bars. Dialogs use [navigatorKey].
class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback onDone;
  final VoidCallback? onReset;

  const PinScreen({super.key, required this.mode, required this.onDone, this.onReset});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  late String _step; // verify | new | confirm
  String _entry = '';
  String _firstNew = '';
  int _pinLen = AppLock.minLength;
  String? _message;
  bool _busy = false;
  int _lockLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == PinMode.setup ? 'new' : 'verify';
    if (widget.mode != PinMode.setup) _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final len = await AppLock.pinLength();
    final wait = await AppLock.lockoutSeconds();
    if (!mounted) return;
    setState(() => _pinLen = len);
    if (wait > 0) _startCountdown(wait);
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _lockLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _lockLeft--);
      if (_lockLeft <= 0) {
        t.cancel();
        setState(() => _lockLeft = 0);
      }
    });
  }

  int get _maxLen {
    if (_step == 'verify') return _pinLen;
    if (_step == 'confirm') return _firstNew.length;
    return AppLock.maxLength;
  }

  String get _title {
    switch (_step) {
      case 'verify':
        return widget.mode == PinMode.unlock ? context.t('pinEnter') : context.t('pinCurrent');
      case 'new':
        return context.t('pinNew');
      default:
        return context.t('pinConfirm');
    }
  }

  String get _hint {
    if (_step == 'new') return context.t('pinHint');
    return '';
  }

  void _press(String digit) {
    if (_busy || _lockLeft > 0 || _entry.length >= _maxLen) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entry += digit;
      _message = null;
    });
    final auto = (_step == 'verify' || _step == 'confirm') && _entry.length == _maxLen;
    if (auto) _submit();
  }

  void _backspace() {
    if (_busy || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final pin = _entry;
    if (_step == 'verify') {
      setState(() => _busy = true);
      final r = await AppLock.verify(pin);
      if (!mounted) return;
      if (r.ok) {
        if (widget.mode == PinMode.change) {
          setState(() {
            _step = 'new';
            _entry = '';
            _message = null;
            _busy = false;
          });
        } else {
          widget.onDone();
        }
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() {
        _entry = '';
        _busy = false;
        _message = r.lockedSeconds > 0 ? null : context.t('pinWrong');
      });
      if (r.lockedSeconds > 0) _startCountdown(r.lockedSeconds);
    } else if (_step == 'new') {
      if (pin.length < AppLock.minLength) return;
      setState(() {
        _firstNew = pin;
        _entry = '';
        _step = 'confirm';
        _message = null;
      });
    } else {
      if (pin == _firstNew) {
        setState(() => _busy = true);
        await AppLock.setPin(pin);
        if (!mounted) return;
        widget.onDone();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _entry = '';
          _firstNew = '';
          _step = 'new';
          _message = context.t('pinMismatch');
        });
      }
    }
  }

  Future<void> _forgot() async {
    final dialogContext = navigatorKey.currentContext ?? context;
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (c) => AlertDialog(
        title: Text(c.t('pinForgot')),
        content: Text(c.t('pinForgotBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.t('pinWipe')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FileStore.wipeEverything();
    AppState.drawnIds.clear();
    AppState.selectedStudent.value = null;
    AppState.activeClassId.value = null;
    AppState.dataEpoch.value++;
    widget.onReset?.call();
  }

  int get _dotCount {
    if (_step == 'new') return _entry.length < AppLock.minLength ? AppLock.minLength : _entry.length;
    return _maxLen;
  }

  @override
  Widget build(BuildContext context) {
    final showConfirmButton = _step == 'new';

    return Scaffold(
      backgroundColor: AppColors.deepIndigo,
      appBar: widget.mode != PinMode.unlock
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepIndigo, AppColors.indigo, Color(0xFF5B21B6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'π',
                        style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.indigo),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.t('appTitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (_hint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_hint, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  const SizedBox(height: 18),
                  // Dots
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _dotCount; i++)
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _entry.length ? AppColors.amber : Colors.transparent,
                              border: Border.all(
                                color: i < _entry.length ? AppColors.amber : Colors.white54,
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: Center(
                      child: _lockLeft > 0
                          ? Text(
                              '${context.t('pinWait')} $_lockLeft ${context.t('seconds')}',
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w700),
                            )
                          : Text(
                              _message ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  // Keypad (digits always left-to-right)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final row in const [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                        ])
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [for (final d in row) _key(label: d, onTap: () => _press(d))],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _key(icon: Icons.backspace_outlined, onTap: _backspace),
                            _key(label: '0', onTap: () => _press('0')),
                            showConfirmButton
                                ? _key(
                                    icon: Icons.check_rounded,
                                    color: _entry.length >= AppLock.minLength
                                        ? AppColors.emerald
                                        : Colors.white24,
                                    onTap: _entry.length >= AppLock.minLength ? _submit : null,
                                  )
                                : const SizedBox(width: 84, height: 84),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.mode == PinMode.unlock)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton(
                        onPressed: _forgot,
                        child: Text(
                          context.t('pinForgot'),
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _key({String? label, IconData? icon, Color? color, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: color ?? Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
              child: label != null
                  ? Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                    )
                  : Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
