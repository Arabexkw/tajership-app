/// إعدادات تطبيق تاجرشِب
///
/// قاعدة ثابتة من قواعد المشروع: الأسعار والبيانات الحساسة تُحسب في السيرفر
/// حصراً — التطبيق واجهة عرض فقط ولا يُوثق بأي قيمة محلية.
class AppConfig {
  /// عنوان الـ API الأساسي (الراوتر api/index.php عبر .htaccess)
  static const String apiBase = 'https://tajership.com/api';

  /// مفتاح X-Api-Key — يُحقن وقت البناء:
  /// flutter build apk --dart-define=TS_API_KEY=xxxx
  static const String apiKey = String.fromEnvironment('TS_API_KEY', defaultValue: '');

  /// وضع تجريبي: يعرض بيانات نموذجية بدون اتصال بالسيرفر
  /// (مفيد لمعاينة التطبيق قبل ربط الـ API نهائياً)
  static const bool demoAvailable = true;

  // هوية تاجرشِب البصرية
  static const int inkBlack = 0xFF14181D; // أسود حبري
  static const int amber = 0xFFFFB200; // كهرماني
}
