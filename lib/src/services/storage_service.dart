import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_deadline.dart';

// Top-level functions for compute
List<JobDeadline> _decodeDeadlines(String raw) {
  if (raw.isEmpty) return <JobDeadline>[];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return <JobDeadline>[];
  return decoded
      .whereType<Map>()
      .map((m) => m.cast<String, Object?>())
      .map(JobDeadline.fromJson)
      .toList(growable: false);
}

String _encodeDeadlines(List<JobDeadline> deadlines) {
  return jsonEncode(deadlines.map((d) => d.toJson()).toList());
}

Map<String, Object?> _decodeSettings(String raw) {
  if (raw.isEmpty) return <String, Object?>{};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return <String, Object?>{};
  return decoded.cast<String, Object?>();
}

class StorageService {
  static const _deadlinesKey = 'deadlines.v1';
  static const _settingsKey = 'settings.v1';
  static const _vaultFilesKey = 'vault_files.v1';
  static const _memosKey = 'memos.v1';

  Future<List<JobDeadline>> loadDeadlines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deadlinesKey);
    if (raw == null || raw.isEmpty) return <JobDeadline>[];
    return compute(_decodeDeadlines, raw);
  }

  Future<void> saveDeadlines(List<JobDeadline> deadlines) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = await compute(_encodeDeadlines, deadlines);
    await prefs.setString(_deadlinesKey, encoded);
  }

  Future<Map<String, Object?>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    return compute(_decodeSettings, raw);
  }

  Future<void> saveSettings(Map<String, Object?> settings) async {
    final prefs = await SharedPreferences.getInstance();
    // Settings are usually small, but for consistency and safety:
    await prefs.setString(_settingsKey, await compute(jsonEncode, settings));
  }

  Future<List<Map<String, Object?>>> loadVaultFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vaultFilesKey);
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, Object?>>[];
    return decoded.whereType<Map>().map((m) => m.cast<String, Object?>()).toList(growable: false);
  }

  Future<void> saveVaultFiles(List<Map<String, Object?>> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vaultFilesKey, jsonEncode(files));
  }

  Future<List<Map<String, Object?>>> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_memosKey);
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, Object?>>[];
    return decoded.whereType<Map>().map((m) => m.cast<String, Object?>()).toList(growable: false);
  }

  Future<void> saveMemos(List<Map<String, Object?>> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memosKey, jsonEncode(memos));
  }
}
