class CompanyNote {
  CompanyNote({
    required this.id,
    required this.companyName,
    required this.role,
    required this.keywords,
    required this.pitch,
    required this.risks,
    required this.summary,
    required this.fit,
    required this.newsSummary,
    required this.businessDirection,
    required this.jobConnection,
    required this.riskPoints,
    required this.expectedQuestions,
    required this.stories,
    required this.questionBank,
    required this.updatedAt,
    this.sourceUrls = const [],
  });

  final String id;
  final String companyName;
  final String role;
  final List<String> keywords;
  final String pitch;
  final List<String> risks;
  final String summary;
  final String fit;
  final String newsSummary;
  final String businessDirection;
  final String jobConnection;
  final String riskPoints;
  final String expectedQuestions;
  final List<CompanyStory> stories;
  final List<String> questionBank;
  final DateTime updatedAt;
  final List<String> sourceUrls;

  CompanyNote copyWith({
    String? id,
    String? companyName,
    String? role,
    List<String>? keywords,
    String? pitch,
    List<String>? risks,
    String? summary,
    String? fit,
    String? newsSummary,
    String? businessDirection,
    String? jobConnection,
    String? riskPoints,
    String? expectedQuestions,
    List<CompanyStory>? stories,
    List<String>? questionBank,
    DateTime? updatedAt,
    List<String>? sourceUrls,
  }) {
    return CompanyNote(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      keywords: keywords ?? this.keywords,
      pitch: pitch ?? this.pitch,
      risks: risks ?? this.risks,
      summary: summary ?? this.summary,
      fit: fit ?? this.fit,
      newsSummary: newsSummary ?? this.newsSummary,
      businessDirection: businessDirection ?? this.businessDirection,
      jobConnection: jobConnection ?? this.jobConnection,
      riskPoints: riskPoints ?? this.riskPoints,
      expectedQuestions: expectedQuestions ?? this.expectedQuestions,
      stories: stories ?? this.stories,
      questionBank: questionBank ?? this.questionBank,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceUrls: sourceUrls ?? this.sourceUrls,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'companyName': companyName,
      'role': role,
      'keywords': keywords,
      'pitch': pitch,
      'risks': risks,
      'summary': summary,
      'fit': fit,
      'newsSummary': newsSummary,
      'businessDirection': businessDirection,
      'jobConnection': jobConnection,
      'riskPoints': riskPoints,
      'expectedQuestions': expectedQuestions,
      'stories': stories.map((s) => s.toJson()).toList(growable: false),
      'questionBank': questionBank,
      'updatedAt': updatedAt.toIso8601String(),
      'sourceUrls': sourceUrls,
    };
  }

  static CompanyNote fromJson(Map<String, Object?> json) {
    final keywords = (json['keywords'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ??
        const <String>[];
    final risks = (json['risks'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? const <String>[];
    final questionBank =
        (json['questionBank'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ??
            const <String>[];
    final sourceUrls = (json['sourceUrls'] as List?)?.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ??
        const <String>[];
    final rawStories = (json['stories'] as List?)?.whereType<Map>() ?? const <Map>[];

    return CompanyNote(
      id: (json['id'] as String?) ?? '',
      companyName: (json['companyName'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      keywords: keywords,
      pitch: (json['pitch'] as String?) ?? '',
      risks: risks,
      summary: (json['summary'] as String?) ?? '',
      fit: (json['fit'] as String?) ?? '',
      newsSummary: (json['newsSummary'] as String?) ?? '',
      businessDirection: (json['businessDirection'] as String?) ?? '',
      jobConnection: (json['jobConnection'] as String?) ?? '',
      riskPoints: (json['riskPoints'] as String?) ?? '',
      expectedQuestions: (json['expectedQuestions'] as String?) ?? '',
      stories: rawStories.map((m) => CompanyStory.fromJson(m.cast<String, Object?>())).toList(growable: false),
      questionBank: questionBank,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      sourceUrls: sourceUrls,
    );
  }
}

class CompanyStory {
  CompanyStory({
    required this.id,
    required this.title,
    required this.situation,
    required this.action,
    required this.result,
    required this.metrics,
    required this.evidenceUrl,
  });

  final String id;
  final String title;
  final String situation;
  final String action;
  final String result;
  final String metrics;
  final String evidenceUrl;

  CompanyStory copyWith({
    String? id,
    String? title,
    String? situation,
    String? action,
    String? result,
    String? metrics,
    String? evidenceUrl,
  }) {
    return CompanyStory(
      id: id ?? this.id,
      title: title ?? this.title,
      situation: situation ?? this.situation,
      action: action ?? this.action,
      result: result ?? this.result,
      metrics: metrics ?? this.metrics,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'situation': situation,
      'action': action,
      'result': result,
      'metrics': metrics,
      'evidenceUrl': evidenceUrl,
    };
  }

  static CompanyStory fromJson(Map<String, Object?> json) {
    return CompanyStory(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      situation: (json['situation'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      result: (json['result'] as String?) ?? '',
      metrics: (json['metrics'] as String?) ?? '',
      evidenceUrl: (json['evidenceUrl'] as String?) ?? '',
    );
  }
}

