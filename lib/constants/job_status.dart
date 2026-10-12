abstract final class JobStatus {
  static const String open = 'open';
  static const String cancelled = 'cancelled';
  static const String deleted = 'deleted';

  static bool isOpen(String status) => status == open;
}
