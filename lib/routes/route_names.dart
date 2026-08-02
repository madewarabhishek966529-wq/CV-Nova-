/// Route path constants. Keep every path here — screens should never
/// hardcode a route string.
class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const dashboard = '/dashboard';
  static const atsAnalyzer = '/ats';
  static const resumeList = '/resumes';
  static const resumeEditor = '/resumes/editor'; // append '/{id}'
  static const resumePreview = '/resumes/preview'; // append '/{id}'
}
