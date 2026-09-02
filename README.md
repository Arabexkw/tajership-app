# تاجرشِب — تطبيق iOS/Android (المسار B)

غلاف أصلي حول **tajership.com** يضيف الميزات الأصلية التي تطلبها آبل (Guideline 4.2):

| الميزة الأصلية | الملف |
|---|---|
| إشعارات Push (تحديث الطلب/الشحنة، تفتح الرابط داخل التطبيق) | `lib/services/push_service.dart` |
| مشاركة أصلية (Share Sheet) لصفحة المنتج/المتجر | `lib/screens/home.dart` |
| حفظ الجلسة (كوكيز WKWebView) — بلا OTP كل فتح | تلقائي في WebView |
| فتح واتساب/الهاتف/الخرائط بالتطبيق الصحيح، وبوابات الدفع داخل التطبيق | `home.dart → _decideNavigation` |
| شاشة بداية أصلية + كشف الأوفلاين + زر رجوع ذكي | `main.dart` / `home.dart` |

## البناء (بدون ماك)
كل شيء عبر **Codemagic** (`codemagic.yaml`):
1. الريبو يحفظ كود Dart + الملفات المخصصة فقط (`ios/Runner/Info.plist`، `AppDelegate.swift`، `Podfile`، `AndroidManifest.xml`).
2. Codemagic يشغّل `flutter create` لتوليد الهياكل الرسمية ثم يطبّق ملفاتنا فوقها ثم يبني.

### المتطلبات في Codemagic
- **App Store Connect integration** باسم `tajership_asc` (مفتاح API من App Store Connect → Users and Access → Integrations).
- Bundle ID: `com.tajership.app` (يُنشأ في Apple Developer → Identifiers، مع تفعيل Push Notifications).
- `APP_STORE_APPLE_ID` بعد إنشاء التطبيق في App Store Connect.
- (اختياري للإشعارات) مجموعة `tajership_firebase` بمتغير `GOOGLE_SERVICE_INFO_PLIST` = محتوى `GoogleService-Info.plist` مشفّراً base64.
- (لأندرويد) مجموعة `tajership_keystore`: `CM_KEYSTORE` (base64) + `CM_KEYSTORE_PASSWORD` + `CM_KEY_ALIAS` + `CM_KEY_PASSWORD` — **نفس keystore الأصلي** `com.tajership.app`.

## الإشعارات من السيرفر
الرسالة تحمل `data.url` بالرابط المراد فتحه:
```json
{ "to": "<fcm_token>", "notification": {"title": "تحديث طلبك", "body": "شحنتك في الطريق"}, "data": {"url": "https://tajership.com/track?awb=..."} }
```
التوكن يُحفظ محلياً بمفتاح `fcm_token` (ربطه بحساب العميل على السيرفر: مهمة لاحقة).

## قواعد ثابتة
- الأسعار والطلبات والدفع تُنفَّذ في السيرفر حصراً — التطبيق واجهة.
- أي تحديث للموقع يصل التطبيق فوراً بلا إصدار جديد.
