import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_lock.dart';
import 'app_state.dart';
import 'database_helper.dart';
import 'pin_screen.dart';
import 'strings.dart';
import 'widgets.dart';

/// Settings: question timer, sound, and a backup you can copy / paste (no internet needed).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _timerChoices = [0, 10, 20, 30, 60];

  Future<void> _backup() async {
    final text = await DatabaseHelper.instance.exportJson();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, context.t('backupCopied'));
  }

  Future<void> _restore() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (!DatabaseHelper.looksLikeBackup(text)) {
      showSnack(context, context.t('restoreFail'));
      return;
    }
    final ok = await confirmDialog(
      context,
      title: context.t('restoreTitle'),
      body: context.t('restoreConfirm'),
      confirmLabel: context.t('restore'),
    );
    if (!ok || !mounted) return;
    try {
      await DatabaseHelper.instance.importJson(text);
      AppState.drawnIds.clear();
      await AppState.selectStudent(null);
      await AppState.setActiveClass(null);
      AppState.dataEpoch.value++;
      if (mounted) showSnack(context, context.t('restoreOk'));
    } catch (_) {
      if (mounted) showSnack(context, context.t('restoreFail'));
    }
  }

  /// Turns the password on: choose a PIN (the app is not locked until the next opening).
  Future<void> _enablePin() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (c) => PinScreen(
          mode: PinMode.setup,
          onDone: () => Navigator.pop(c, true),
        ),
      ),
    );
    if (done == true) {
      AppLock.enabled.value = true;
      AppLock.locked.value = false;
      if (mounted) showSnack(context, context.t('pinEnabledNow'));
    }
  }

  /// Turns the password off (asks for the current PIN first).
  Future<void> _disablePin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (c) => PinScreen(
          mode: PinMode.disable,
          onDone: () => Navigator.pop(c, true),
        ),
      ),
    );
    if (ok == true) {
      await AppLock.removePin();
      AppLock.enabled.value = false;
      AppLock.locked.value = false;
      if (mounted) showSnack(context, context.t('pinDisabledNow'));
    }
  }

  Future<void> _changePin() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (c) => PinScreen(
          mode: PinMode.change,
          onDone: () => Navigator.pop(c, true),
        ),
      ),
    );
    if (changed == true && mounted) showSnack(context, context.t('pinChanged'));
  }

  void _lockNow() {
    Navigator.pop(context); // back to the home screen; the lock screen then covers everything
    AppLock.locked.value = true;
  }

  Widget _title(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Question timer
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(Icons.timer_rounded, context.t('timerTitle'), AppColors.amber),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: AppState.timerSeconds,
                  builder: (context, current, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in _timerChoices)
                        ChoiceChip(
                          label: Text(v == 0 ? context.t('timerOff') : '$v ${context.t('seconds')}'),
                          selected: current == v,
                          onSelected: (_) => AppState.setTimer(v),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sound
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ValueListenableBuilder<bool>(
              valueListenable: AppState.soundOn,
              builder: (context, on, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_rounded, color: AppColors.indigo),
                title: Text(
                  context.t('soundTitle'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(context.t('soundSub')),
                value: on,
                onChanged: AppState.setSound,
              ),
            ),
          ),

          // Security: optional PIN (off by default)
          SoftCard(
            child: ValueListenableBuilder<bool>(
              valueListenable: AppLock.enabled,
              builder: (context, on, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(
                    on ? Icons.lock_rounded : Icons.lock_open_rounded,
                    context.t('securityTitle'),
                    on ? AppColors.emerald : AppColors.indigo,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t(on ? 'pinStatusOn' : 'pinStatusOff'),
                    style: TextStyle(fontWeight: FontWeight.w700, color: on ? AppColors.emerald : Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(context.t('securityNote'), style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  if (!on)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _enablePin,
                        icon: const Icon(Icons.lock_rounded),
                        label: Text(context.t('pinEnable')),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _changePin,
                        icon: const Icon(Icons.password_rounded),
                        label: Text(context.t('pinChange')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _lockNow,
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: Text(context.t('lockNow')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        onPressed: _disablePin,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(context.t('pinDisable')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Backup / restore
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(Icons.shield_rounded, context.t('backupTitle'), AppColors.emerald),
                const SizedBox(height: 8),
                Text(context.t('backupCopySub'), style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
                    onPressed: _backup,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(context.t('backupCopy')),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.t('restoreSub'), style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _restore,
                    icon: const Icon(Icons.paste_rounded),
                    label: Text(context.t('restoreTitle')),
                  ),
                ),
              ],
            ),
          ),

          // About
          SoftCard(
            child: Row(
              children: [
                const Icon(Icons.functions_rounded, color: AppColors.indigo, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('appTitle'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        context.t('aboutText'),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
