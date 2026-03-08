import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

enum InterviewRound {
  unknown,
  screening,
  first,
  second,
  finalRound,
}

extension InterviewRoundX on InterviewRound {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case InterviewRound.screening:
        return l10n.roundScreening;
      case InterviewRound.first:
        return l10n.roundFirst;
      case InterviewRound.second:
        return l10n.roundSecond;
      case InterviewRound.finalRound:
        return l10n.roundFinal;
      case InterviewRound.unknown:
        return l10n.roundUnknown;
    }
  }
}

enum ReviewState {
  needsReview, // 🟡 복습 필요
  completed,   // 🔵 복습 완료
}

extension ReviewStateX on ReviewState {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ReviewState.needsReview:
        return l10n.reviewNeedsReview;
      case ReviewState.completed:
        return l10n.reviewMastered;
    }
  }

  Color color(ColorScheme cs) {
    switch (this) {
      case ReviewState.needsReview:
        return const Color(0xFFFFD59E); // 🟡 Yellow
      case ReviewState.completed:
        return const Color(0xFFD1E9FF); // 🔵 Blue
    }
  }

  Color onColor(ColorScheme cs) {
    switch (this) {
      case ReviewState.needsReview:
        return const Color(0xFF92400E); // Dark Brown
      case ReviewState.completed:
        return const Color(0xFF1E40AF); // Dark Blue
    }
  }
}

class InterviewSession {
  InterviewSession({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.role,
    required this.round,
    required this.heldAt,
    required this.questions,
    required this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String companyName;
  final String role;
  final InterviewRound round;
  final DateTime heldAt;
  final List<QuestionNote> questions;
  final DateTime updatedAt;

  InterviewSession copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? role,
    InterviewRound? round,
    DateTime? heldAt,
    List<QuestionNote>? questions,
    DateTime? updatedAt,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      round: round ?? this.round,
      heldAt: heldAt ?? this.heldAt,
      questions: questions ?? this.questions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'role': role,
      'round': round.name,
      'heldAt': heldAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(growable: false),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static InterviewSession fromJson(Map<String, Object?> json) {
    final roundName = (json['round'] as String?) ?? InterviewRound.unknown.name;
    final round = InterviewRound.values.firstWhere(
      (r) => r.name == roundName,
      orElse: () => InterviewRound.unknown,
    );
    final rawQuestions = (json['questions'] as List?)?.whereType<Map>() ?? const <Map>[];

    return InterviewSession(
      id: (json['id'] as String?) ?? '',
      companyId: (json['companyId'] as String?),
      companyName: (json['companyName'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      round: round,
      heldAt: DateTime.tryParse((json['heldAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      questions: rawQuestions.map((m) => QuestionNote.fromJson(m.cast<String, Object?>())).toList(growable: false),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class QuestionNote {
  QuestionNote({    required this.id,
    required this.question,
    required this.intent,
    required this.answerAtTheTime,
    required this.improved60,
    required this.improved120,
    required this.pitfalls,
    required this.nextAction,
    required this.reviewState,
    required this.nextReviewAt,
    this.feeling = 3, // Default: Neutral
  });

  final String id;
  final String question;
  final String intent;
  final String answerAtTheTime;
  final String improved60;
  final String improved120;
  final List<String> pitfalls;
  final String nextAction;
  final ReviewState reviewState;
  final DateTime? nextReviewAt;
  final int feeling; // 자가 점수 (1-5)

  QuestionNote copyWith({
    String? id,
    String? question,
    String? intent,
    String? answerAtTheTime,
    String? improved60,
    String? improved120,
    List<String>? pitfalls,
    String? nextAction,
    ReviewState? reviewState,
    DateTime? nextReviewAt,
    int? feeling,
  }) {
    return QuestionNote(
      id: id ?? this.id,
      question: question ?? this.question,
      intent: intent ?? this.intent,
      answerAtTheTime: answerAtTheTime ?? this.answerAtTheTime,
      improved60: improved60 ?? this.improved60,
      improved120: improved120 ?? this.improved120,
      pitfalls: pitfalls ?? this.pitfalls,
      nextAction: nextAction ?? this.nextAction,
      reviewState: reviewState ?? this.reviewState,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      feeling: feeling ?? this.feeling,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'question': question,
      'intent': intent,
      'answerAtTheTime': answerAtTheTime,
      'improved60': improved60,
      'improved120': improved120,
      'pitfalls': pitfalls,
      'nextAction': nextAction,
      'reviewState': reviewState.name,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
      'feeling': feeling,
    };
  }

  static QuestionNote fromJson(Map<String, Object?> json) {
    final stateName = (json['reviewState'] as String?) ?? ReviewState.needsReview.name;
    ReviewState state;
    
    // Enum migration
    if (stateName == 'needsReview' || stateName == 'needsReorganize' || stateName == 'needsRefine' || stateName == 'reviewing' || stateName == 'none') {
      state = ReviewState.needsReview;
    } else if (stateName == 'completed' || stateName == 'mastered') {
      state = ReviewState.completed;
    } else {
      state = ReviewState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => ReviewState.needsReview,
      );
    }
    
    final pitfalls =
        (json['pitfalls'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ??
            const <String>[];
    final nextReviewAtRaw = (json['nextReviewAt'] as String?)?.trim();
    final feeling = (json['feeling'] as int?) ?? 3;

    return QuestionNote(
      id: (json['id'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      intent: (json['intent'] as String?) ?? '',
      answerAtTheTime: (json['answerAtTheTime'] as String?) ?? '',
      improved60: (json['improved60'] as String?) ?? '',
      improved120: (json['improved120'] as String?) ?? '',
      pitfalls: pitfalls,
      nextAction: (json['nextAction'] as String?) ?? '',
      reviewState: state,
      nextReviewAt: nextReviewAtRaw == null || nextReviewAtRaw.isEmpty ? null : DateTime.tryParse(nextReviewAtRaw),
      feeling: feeling,
    );
  }
}

