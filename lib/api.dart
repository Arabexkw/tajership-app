import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// أدوار الدخول الموحد في تاجرشِب (نفس أدوار /login/ بالمنصة)
enum UserRole { merchant, driver, admin, carrier }

class Session {
  final String name;
  final UserRole role;
  final String token;
  final bool demo;

  const Session({required this.name, required this.role, required this.token, this.demo = false});

  Map<String, dynamic> toJson() => {'name': name, 'role': role.name, 'token': token, 'demo': demo};

  static Session? fromJson(Map<String, dynamic> j) {
    final role = UserRole.values.where((r) => r.name == j['role']).toList();
    if (role.isEmpty) return null;
    return Session(
      name: (j['name'] ?? '') as String,
      role: role.first,
      token: (j['token'] ?? '') as String,
      demo: (j['demo'] ?? false) as bool,
    );
  }
}

class OrderItem {
  final String id;
  final String customer;
  final String status;
  final String amount;
  final String date;

  const OrderItem({
    required this.id,
    required this.customer,
    required this.status,
    required this.amount,
    required this.date,
  });
}

class ShipmentItem {
  final String awb;
  final String receiver;
  final String status;
  final String area;
  final bool cod;

  const ShipmentItem({
    required this.awb,
    required this.receiver,
    required this.status,
    required this.area,
    this.cod = false,
  });
}

/// عميل الـ API — كل الطلبات تمر من هنا حصراً (نفس مبدأ PaymentService بالسيرفر):
/// نقطة واحدة للهيدرات والمفاتيح والجلسة، وأي تغيير بالعقد يصير بمكان واحد.
class ApiClient {
  static const _sessionKey = 'ts_app_session';

  Session? _session;

  Session? get session => _session;

  Future<Session?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      _session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _session = null;
    }
    return _session;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_session == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, jsonEncode(_session!.toJson()));
    }
  }

  Future<void> logout() async {
    _session = null;
    await _persist();
  }

  /// دخول تجريبي بدون سيرفر — لمعاينة الواجهات
  Future<Session> loginDemo(UserRole role) async {
    _session = Session(
      name: role == UserRole.driver ? 'سائق تجريبي' : 'متجر تجريبي',
      role: role,
      token: 'demo',
      demo: true,
    );
    await _persist();
    return _session!;
  }

  /// الدخول الموحد — يستهدف user_auth.php (تجار) وامتداده للأدوار الأخرى.
  /// ملاحظة: عقد الـ API النهائي يُثبت بعد فحص user_auth.php على السيرفر؛
  /// عند تغيّره يُعدل هذا الميثود فقط.
  Future<Session> login(String user, String password) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.apiBase}/user_auth.php'),
          headers: {
            'Content-Type': 'application/json',
            if (AppConfig.apiKey.isNotEmpty) 'X-Api-Key': AppConfig.apiKey,
          },
          body: jsonEncode({'action': 'login', 'user': user, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('استجابة غير متوقعة من السيرفر (${res.statusCode})');
    }

    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception((data['error'] ?? 'فشل تسجيل الدخول — تأكد من البيانات') as String);
    }

    final roleName = (data['role'] ?? 'merchant') as String;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.merchant,
    );

    _session = Session(
      name: (data['name'] ?? user) as String,
      role: role,
      token: (data['token'] ?? data['sid'] ?? '') as String,
    );
    await _persist();
    return _session!;
  }

  // ---------------------------------------------------------------------
  // بيانات الشاشات — ترجع بيانات تجريبية في وضع الديمو، وتستهدف الـ API
  // الحي عند توفر جلسة حقيقية.
  // ---------------------------------------------------------------------

  Future<List<OrderItem>> merchantOrders() async {
    if (_session?.demo ?? true) {
      return const [
        OrderItem(id: 'TS-1041', customer: 'نورة العتيبي', status: 'جديد', amount: '18.500 د.ك', date: 'اليوم 10:24'),
        OrderItem(id: 'TS-1040', customer: 'محمد الشمري', status: 'قيد التجهيز', amount: '7.250 د.ك', date: 'اليوم 09:02'),
        OrderItem(id: 'TS-1039', customer: 'Sara K.', status: 'مشحون', amount: '32.000 د.ك', date: 'أمس'),
        OrderItem(id: 'TS-1038', customer: 'عبدالله الكندري', status: 'مسلّم', amount: '12.750 د.ك', date: 'أمس'),
        OrderItem(id: 'TS-1037', customer: 'ليلى حداد', status: 'مسلّم', amount: '9.900 د.ك', date: '8 يوليو'),
      ];
    }
    // TODO: ربط order_actions.php بعد تثبيت العقد
    return const [];
  }

  Future<List<ShipmentItem>> merchantShipments() async {
    if (_session?.demo ?? true) {
      return const [
        ShipmentItem(awb: 'ARX20441', receiver: 'نورة العتيبي', status: 'خرج للتوصيل', area: 'السالمية', cod: true),
        ShipmentItem(awb: 'ARX20438', receiver: 'Sara K.', status: 'في المستودع', area: 'حولي'),
        ShipmentItem(awb: 'ARX20431', receiver: 'عبدالله الكندري', status: 'مسلّم', area: 'الجهراء', cod: true),
      ];
    }
    // TODO: ربط تبويب الشحنات (sync_arabex) بعد تثبيت العقد
    return const [];
  }

  Future<List<ShipmentItem>> driverTasks() async {
    if (_session?.demo ?? true) {
      return const [
        ShipmentItem(awb: 'ARX20441', receiver: 'نورة العتيبي', status: 'خرج للتوصيل', area: 'السالمية ق4 ش2', cod: true),
        ShipmentItem(awb: 'ARX20444', receiver: 'فهد المطيري', status: 'بانتظار الاستلام', area: 'الفروانية ق1', cod: true),
        ShipmentItem(awb: 'ARX20445', receiver: 'حسين علي', status: 'بانتظار الاستلام', area: 'مبارك الكبير ق3'),
      ];
    }
    // TODO: ربط واجهة السائق (driver/) بعد تثبيت العقد
    return const [];
  }
}

/// نسخة وحيدة على مستوى التطبيق
final api = ApiClient();
