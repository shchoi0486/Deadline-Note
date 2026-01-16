import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../services/storage_service.dart';
import '../widgets/ad_placeholder.dart';

enum _VaultTab {
  files,
  memo,
}

class FileVaultScreen extends StatefulWidget {
  const FileVaultScreen({super.key});

  @override
  State<FileVaultScreen> createState() => _FileVaultScreenState();
}

class _FileVaultScreenState extends State<FileVaultScreen> {
  final _storage = StorageService();
  _VaultTab _tab = _VaultTab.files;
  bool _loading = true;
  List<_VaultFile> _files = const <_VaultFile>[];
  List<_MemoNote> _memos = const <_MemoNote>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rawFiles = await _storage.loadVaultFiles();
      final rawMemos = await _storage.loadMemos();
      if (!mounted) return;
      setState(() {
        _files = rawFiles.map(_VaultFile.fromJson).toList(growable: false);
        _memos = rawMemos.map(_MemoNote.fromJson).toList(growable: false);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Directory> _vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}vault');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<void> _addFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final dir = await _vaultDir();
    final now = DateTime.now().microsecondsSinceEpoch;
    final next = _files.toList();

    var i = 0;
    for (final f in result.files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;
      final src = File(path);
      if (!src.existsSync()) continue;
      final ext = f.extension;
      final baseName = (f.name.isNotEmpty ? f.name : '파일').replaceAll(RegExp(r'[\\\\/:*?"<>|]'), '_');
      final fileName = ext == null || ext.isEmpty ? baseName : '$baseName.$ext';
      final destPath = '${dir.path}${Platform.pathSeparator}${now}_${i.toString().padLeft(3, '0')}_$fileName';
      i += 1;
      final copied = await src.copy(destPath);
      next.add(
        _VaultFile(
          id: '${now}_$i',
          title: baseName,
          localPath: copied.path,
          createdAt: DateTime.now(),
        ),
      );
    }

    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _storage.saveVaultFiles(next.map((e) => e.toJson()).toList(growable: false));
    if (!mounted) return;
    setState(() => _files = next);
  }

  Future<void> _deleteFile(_VaultFile file) async {
    final next = _files.where((f) => f.id != file.id).toList(growable: false);
    await _storage.saveVaultFiles(next.map((e) => e.toJson()).toList(growable: false));
    try {
      final f = File(file.localPath);
      if (f.existsSync()) {
        await f.delete();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _files = next);
  }

  Future<void> _openFile(_VaultFile file) async {
    await OpenFilex.open(file.localPath);
  }

  Future<void> _editMemo({_MemoNote? initial}) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    final contentController = TextEditingController(text: initial?.content ?? '');

    final saved = await showModalBottomSheet<_MemoNote>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                initial == null ? '메모 추가' : '메모 편집',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '제목'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '내용'),
                minLines: 6,
                maxLines: 12,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  final now = DateTime.now();
                  final note = _MemoNote(
                    id: initial?.id ?? '${now.microsecondsSinceEpoch}',
                    title: title.isEmpty ? '제목 없음' : title,
                    content: content,
                    updatedAt: now,
                  );
                  Navigator.of(context).pop(note);
                },
                child: const Text('저장'),
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    if (saved == null) return;
    final next = <_MemoNote>[
      for (final m in _memos)
        if (m.id == saved.id) saved else m,
      if (_memos.every((m) => m.id != saved.id)) saved,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _storage.saveMemos(next.map((e) => e.toJson()).toList(growable: false));
    if (!mounted) return;
    setState(() => _memos = next);
  }

  Future<void> _deleteMemo(_MemoNote note) async {
    final next = _memos.where((m) => m.id != note.id).toList(growable: false);
    await _storage.saveMemos(next.map((e) => e.toJson()).toList(growable: false));
    if (!mounted) return;
    setState(() => _memos = next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_tab == _VaultTab.files ? _buildFiles(context) : _buildMemos(context));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 일정/현황 화면과 동일한 커스텀 헤더 구조 적용
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '파일함',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 19,
                                      ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.transparent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : (_tab == _VaultTab.files ? _addFiles : () => _editMemo()),
                    icon: const Icon(Icons.add),
                    tooltip: _tab == _VaultTab.files ? '파일 추가' : '메모 추가',
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.view_list, color: Colors.transparent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // 배너 광고 추가 (일정/현황 화면과 통일)
            const AdPlaceholder(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<_VaultTab>(
                segments: const [
                  ButtonSegment(value: _VaultTab.files, label: Text('파일')),
                  ButtonSegment(value: _VaultTab.memo, label: Text('메모')),
                ],
                selected: <_VaultTab>{_tab},
                onSelectionChanged: (v) => setState(() => _tab = v.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: cs.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '파일/메모는 서버로 전송되지 않고 내 휴대폰에만 저장돼요.\n앱을 삭제하면 데이터가 함께 삭제될 수 있어요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildFiles(BuildContext context) {
    if (_files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '저장된 파일이 없어요.\n오른쪽 위 + 버튼으로 추가해보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final f = _files[index];
        return Card(
          child: ListTile(
            title: Text(f.title, maxLines: 1, overflow: TextOverflow.clip),
            subtitle: Text(
              f.localPath.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'open') await _openFile(f);
                if (value == 'delete') await _deleteFile(f);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'open', child: Text('열기')),
                PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
            onTap: () => _openFile(f),
          ),
        );
      },
    );
  }

  Widget _buildMemos(BuildContext context) {
    if (_memos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '저장된 메모가 없어요.\n오른쪽 위 + 버튼으로 추가해보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _memos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final m = _memos[index];
        return Card(
          child: ListTile(
            title: Text(m.title, maxLines: 1, overflow: TextOverflow.clip),
            subtitle: Text(
              m.content,
              maxLines: 2,
              overflow: TextOverflow.clip,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') await _editMemo(initial: m);
                if (value == 'delete') await _deleteMemo(m);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('편집')),
                PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
            onTap: () => _editMemo(initial: m),
          ),
        );
      },
    );
  }
}

class _VaultFile {
  _VaultFile({
    required this.id,
    required this.title,
    required this.localPath,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String localPath;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'localPath': localPath,
        'createdAt': createdAt.toIso8601String(),
      };

  static _VaultFile fromJson(Map<String, Object?> json) {
    return _VaultFile(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      localPath: (json['localPath'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _MemoNote {
  _MemoNote({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static _MemoNote fromJson(Map<String, Object?> json) {
    return _MemoNote(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
