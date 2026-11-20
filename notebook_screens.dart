import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_lock.dart';
import 'database_helper.dart';
import 'digits.dart';
import 'nb_files.dart';
import 'sections.dart';
import 'strings.dart';
import 'widgets.dart';

// ───────────────────────── Helpers for Section Lookup ─────────────────────────

SectionInfo _getSectionInfo(String key) {
  for (final s in kSections) {
    if (s.key == key) return s;
  }
  return kSections.first;
}

bool _isControlSection(String key) =>
    key == 'control' || key == 'ctrl' || (kSections.isNotEmpty && key == kSections.first.key);

bool _isSynthesisSection(String key) =>
    key == 'synthesis' || key == 'synth' || (kSections.length > 1 && key == kSections[1].key);

// ───────────────────────── Top of the "مكتبتي" tab ─────────────────────────

/// "دفتر الأستاذ": a search bar and big sections stacked vertically.
class NotebookHome extends StatefulWidget {
  const NotebookHome({super.key});

  @override
  State<NotebookHome> createState() => _NotebookHomeState();
}

class _NotebookHomeState extends State<NotebookHome> {
  Map<String, SectionStats> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await DatabaseHelper.instance.nbSectionStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
          child: Row(
            children: [
              const Icon(Icons.folder_copy_rounded, color: AppColors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('nbHeading'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        SoftCard(
          onTap: () => _go(const NotebookSearchScreen()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('searchAll'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        for (final section in kSections)
          _SectionCard(
            info: section,
            stats: _stats[section.key] ?? const SectionStats(0, 0),
            onTap: () => _go(
              NotebookFolderScreen(
                section: section.key,
                parentId: null,
                title: section.title(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SectionInfo info;
  final SectionStats stats;
  final VoidCallback onTap;

  const _SectionCard({required this.info, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = info.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.28)!],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 7)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.folders} ${context.t('foldersCount')}  ·  ${stats.files} ${context.t('filesCount')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Folder content ─────────────────────────

/// Content of a section (parentId == null) or of one of its folders.
/// Create folders and subfolders, add any file, take photos, rename, delete, filter by name.
class NotebookFolderScreen extends StatefulWidget {
  final String section;
  final int? parentId;
  final String title;

  const NotebookFolderScreen({
    super.key,
    required this.section,
    required this.parentId,
    required this.title,
  });

  @override
  State<NotebookFolderScreen> createState() => _NotebookFolderScreenState();
}

class _NotebookFolderScreenState extends State<NotebookFolderScreen> {
  final _db = DatabaseHelper.instance;
  final _filterCtrl = TextEditingController();

  List<NbNode> _items = [];
  Map<int, int> _counts = {};
  String _trail = '';
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;
  String _filter = '';

  SectionInfo get _info => _getSectionInfo(widget.section);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _db.nbChildren(widget.section, widget.parentId);
    final counts = await _db.nbChildCounts(widget.section);
    List<NbNode> chain = [];
    if (widget.parentId != null) chain = await _db.nbPathTo(widget.parentId!);
    if (!mounted) return;
    var trail = '';
    if (widget.parentId != null) {
      final parents = chain.length > 1 ? chain.sublist(0, chain.length - 1) : <NbNode>[];
      trail = [_info.title(context), ...parents.map((n) => n.name)].join('  ›  ');
    }
    setState(() {
      _items = items;
      _counts = counts;
      _trail = trail;
      _loading = false;
    });
  }

  // ───────── actions ─────────
  Future<void> _newFolder() async {
    final name = await promptText(
      context,
      title: context.t('newFolder'),
      label: context.t('folderName'),
      hint: context.t('folderHint'),
    );
    if (name == null || name.isEmpty) return;
    await _db.nbInsertFolder(widget.section, widget.parentId, name);
    _load();
  }

  Future<void> _addFiles() async {
    setState(() => _busy = true);
    AppLock.busy++;
    try {
      final picked = await openFiles();
      for (final f in picked) {
        final stored = await FileStore.save(widget.section, f, f.name);
        await _db.nbInsertFile(
          widget.section,
          widget.parentId,
          name: f.name,
          path: stored.path,
          ext: stored.ext,
          size: stored.size,
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, context.t('fileAddFail'));
    } finally {
      AppLock.busy--;
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  String _photoName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'IMG_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}.jpg';
  }

  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    AppLock.busy++;
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2600,
      );
      if (shot != null) {
        final name = _photoName();
        final stored = await FileStore.save(widget.section, shot, name);
        await _db.nbInsertFile(
          widget.section,
          widget.parentId,
          name: name,
          path: stored.path,
          ext: stored.ext,
          size: stored.size,
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, context.t('fileAddFail'));
    } finally {
      AppLock.busy--;
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _openItem(NbNode n) async {
    if (n.isFolder) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NotebookFolderScreen(section: widget.section, parentId: n.id, title: n.name),
        ),
      );
