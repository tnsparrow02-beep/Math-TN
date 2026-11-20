import 'package:flutter/material.dart';

import 'app_lock.dart';
import 'pin_screen.dart';
import 'widgets.dart';

/// Wraps the whole app (see MaterialApp.builder): while the app is locked, the PIN screen
/// covers every page, including pages opened on top of the dashboard.
///
/// The app locks: when it opens, when you press "lock now", and when you come back after
/// more than 2 minutes away (a file picker or camera does not count as "away").
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  static const Duration _relockAfter = Duration(minutes: 2);

  bool _ready = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The password is optional (off by default): without a PIN the app opens directly.
  Future<void> _init() async {
    final has = await AppLock.hasPin();
    AppLock.enabled.value = has;
    AppLock.locked.value = has;
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final at = _pausedAt;
      _pausedAt = null;
      if (AppLock.enabled.value &&
          at != null &&
          AppLock.busy == 0 &&
          DateTime.now().difference(at) > _relockAfter) {
        AppLock.locked.value = true;
      }
    }
  }

  void _onUnlocked() {
    AppLock.locked.value = false;
  }

  /// Forgot PIN: all data was erased and the password is gone: the app opens directly.
  void _onReset() {
    AppLock.enabled.value = false;
    AppLock.locked.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: AppLock.enabled,
          builder: (context, enabled, _) => ValueListenableBuilder<bool>(
            valueListenable: AppLock.locked,
            builder: (context, locked, _) {
              if (!_ready) {
                return const Positioned.fill(child: ColoredBox(color: AppColors.deepIndigo));
              }
              if (!(enabled && locked)) return const SizedBox.shrink();
              return Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ModalBarrier(dismissible: false, color: AppColors.deepIndigo),
                    PinScreen(
                      mode: PinMode.unlock,
                      onDone: _onUnlocked,
                      onReset: _onReset,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
