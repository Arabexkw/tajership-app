/// إعدادات تطبيق تاجرشِب (المسار B: غلاف أصلي + ميزات أصلية)
///
/// قاعدة ثابتة: الأسعار والطلبات والدفع تُحسب وتُنفَّذ في السيرفر حصراً.
/// التطبيق يعرض tajership.com داخل WebView ويضيف فوقه الميزات الأصلية:
/// إشعارات Push، مشاركة أصلية، حفظ الجلسة، فتح الروابط الخارجية بشكل صحيح.
class AppConfig {
  /// الصفحة الرئيسية التي يفتحها التطبيق
  static const String homeUrl = 'https://tajership.com/';

  /// النطاقات التي تُفتح داخل التطبيق (كل ما عداها يُفتح خارجياً)
  static const List<String> internalHosts = [
    'tajership.com',
    'www.tajership.com',
  ];

  /// نطاقات بوابات الدفع — تُفتح داخل التطبيق (لإتمام الدفع ثم العودة)
  /// KNET/MyFatoorah/MPGS تُعيد التوجيه إلى tajership.com عند الانتهاء
  static const List<String> paymentHosts = [
    'myfatoorah.com',
    'kpay.com.kw',
    'knet.com.kw',
    'mastercard.com',
    'gateway.mastercard.com',
    'ap-gateway.mastercard.com',
    'test-gateway.mastercard.com',
  ];

  /// ملف حذف الحساب (مطلوب من آبل وجوجل)
  static const String deleteAccountUrl = 'https://tajership.com/delete-account.html';

  /// سياسة الخصوصية
  static const String privacyUrl = 'https://tajership.com/privacy.html';

  /// User-Agent مخصص: يخبر السيرفر أن الطلب من التطبيق الأصلي
  /// (يُستخدم لاحقاً لإخفاء بانر "أضف للشاشة الرئيسية" داخل التطبيق)
  static const String userAgentSuffix = 'TajerShipApp/1.0';

  // هوية تاجرشِب البصرية
  static const int inkBlack = 0xFF14181D; // أسود حبري
  static const int amber = 0xFFFFB200; // كهرماني
  static const int cream = 0xFFF6F4EF;
}
