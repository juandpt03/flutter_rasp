/// Severity of a [Breadcrumb] entry.
enum BreadcrumbLevel {
  debug,
  info,
  warning,
  error,
  fatal;

  String get wireName => name;

  static BreadcrumbLevel fromName(String name) {
    return BreadcrumbLevel.values.firstWhere(
      (l) => l.name == name,
      orElse: () => BreadcrumbLevel.info,
    );
  }
}
