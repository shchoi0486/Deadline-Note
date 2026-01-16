enum JobSite {
  jobkorea,
  saramin,
  incruit,
  albamon,
  unknown,
}

extension JobSiteLabels on JobSite {
  String get label {
    switch (this) {
      case JobSite.jobkorea:
        return '잡코리아';
      case JobSite.saramin:
        return '사람인';
      case JobSite.incruit:
        return '인쿠르트';
      case JobSite.albamon:
        return '알바몬';
      case JobSite.unknown:
        return '기타';
    }
  }
}

