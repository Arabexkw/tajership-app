import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// طبقة سوق العملاء — عقد shop.php الحقيقي (فُحص من الموقع الحي 11 يوليو 2026):
/// GET  ?action=stores                → قائمة متاجر السوق
/// GET  ?action=catalog&store=<id>    → كتالوج متجر (منتجات/تصنيفات/مناطق شحن)
/// POST ?action=checkout              → إنشاء طلب {customer:{name,phone}, email, area_id, items:[{product_id,qty}]}
/// قاعدة المشروع: الأسعار والرسوم تُحسب في السيرفر حصراً — التطبيق يعرض فقط.

class MarketStore {
  final int id;
  final String name;
  final String description;
  final String? logo;
  final String? cover;
  final int products;

  const MarketStore({
    required this.id,
    required this.name,
    required this.description,
    this.logo,
    this.cover,
    required this.products,
  });

  static MarketStore fromJson(Map<String, dynamic> j) => MarketStore(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        logo: j['logo'] as String?,
        cover: j['cover'] as String?,
        products: ((j['products'] ?? 0) as num).toInt(),
      );
}

class ShopProduct {
  final int id;
  final int storeId;
  final int? categoryId;
  final String name;
  final String? details;
  final String? image;
  final double price;
  final double? salePrice;
  final int stock;
  final bool available;

  const ShopProduct({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    this.details,
    this.image,
    required this.price,
    this.salePrice,
    required this.stock,
    required this.available,
  });

  /// السعر الفعلي المعروض (التخفيض إن وجد وكان أقل من الأصلي)
  double get effectivePrice =>
      (salePrice != null && salePrice! > 0 && salePrice! < price) ? salePrice! : price;

  bool get hasDiscount => salePrice != null && salePrice! > 0 && salePrice! < price;

  static double _d(dynamic v) => v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  static ShopProduct fromJson(Map<String, dynamic> j) => ShopProduct(
        id: (j['id'] as num).toInt(),
        storeId: ((j['store_id'] ?? 0) as num).toInt(),
        categoryId: j['category_id'] == null ? null : (j['category_id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        details: j['details'] as String?,
        image: j['image'] as String?,
        price: _d(j['price']),
        salePrice: j['sale_price'] == null ? null : _d(j['sale_price']),
        stock: ((j['stock'] ?? 0) as num).toInt(),
        available: (j['is_available'] ?? 0).toString() == '1',
      );
}

class ShopCategory {
  final int id;
  final String name;

  const ShopCategory({required this.id, required this.name});

  static ShopCategory fromJson(Map<String, dynamic> j) =>
      ShopCategory(id: (j['id'] as num).toInt(), name: (j['name'] ?? '') as String);
}

class ShipArea {
  final int id;
  final String governorate;
  final String name;
  final double fee;

  const ShipArea({required this.id, required this.governorate, required this.name, required this.fee});

  static ShipArea fromJson(Map<String, dynamic> j) => ShipArea(
        id: (j['id'] as num).toInt(),
        governorate: (j['governorate'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        fee: double.tryParse((j['shipping_fee'] ?? '0').toString()) ?? 0,
      );
}

class StoreCatalog {
  final MarketStore store;
  final List<ShopProduct> products;
  final List<ShopCategory> categories;
  final List<ShipArea> areas;

  const StoreCatalog({
    required this.store,
    required this.products,
    required this.categories,
    required this.areas,
  });
}

class CartLine {
  final ShopProduct product;
  int qty;

  CartLine(this.product, this.qty);

  double get total => product.effectivePrice * qty;
}

/// سلة بسيطة بالذاكرة — لكل متجر سلة مستقلة (الطلب يُنشأ على متجر واحد)
class Cart {
  int? storeId;
  String storeName = '';
  final List<CartLine> lines = [];

  /// مستمعون لتغيّر السلة (عدّاد الزر وغيره)
  final List<void Function()> listeners = [];

  void _notify() {
    for (final l in List.of(listeners)) {
      l();
    }
  }

  bool get isEmpty => lines.isEmpty;

  int get count => lines.fold(0, (s, l) => s + l.qty);

  double get subtotal => lines.fold(0.0, (s, l) => s + l.total);

  /// درس منصة تاجرشِب (خطأ زر السلة بالموقع): الكمية لا تكون أبداً null أو صفر
  void add(ShopProduct p, {int qty = 1}) {
    final q = qty < 1 ? 1 : qty;
    if (storeId != null && storeId != p.storeId) {
      // متجر مختلف — السلة تخص متجراً واحداً
      lines.clear();
    }
    storeId = p.storeId;
    final existing = lines.where((l) => l.product.id == p.id).toList();
    if (existing.isEmpty) {
      lines.add(CartLine(p, q));
    } else {
      existing.first.qty += q;
    }
    _notify();
  }

  void setQty(int productId, int qty) {
    for (final l in lines) {
      if (l.product.id == productId) l.qty = qty < 1 ? 1 : qty;
    }
    _notify();
  }

  void remove(int productId) {
    lines.removeWhere((l) => l.product.id == productId);
    if (lines.isEmpty) storeId = null;
    _notify();
  }

  void clear() {
    lines.clear();
    storeId = null;
    storeName = '';
    _notify();
  }
}

final cart = Cart();

String fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return 'https://tajership.com$path';
}

String kd(double v) => '${v.toStringAsFixed(3)} د.ك';

class ShopApi {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AppConfig.apiKey.isNotEmpty) 'X-Api-Key': AppConfig.apiKey,
      };

  static Future<List<MarketStore>> stores() async {
    final res = await http
        .get(Uri.parse('${AppConfig.apiBase}/shop.php?action=stores'))
        .timeout(const Duration(seconds: 20));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] != true) throw Exception((j['error'] ?? 'تعذر تحميل السوق') as String);
    return ((j['stores'] ?? []) as List)
        .map((e) => MarketStore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<StoreCatalog> catalog(int storeId) async {
    final res = await http
        .get(Uri.parse('${AppConfig.apiBase}/shop.php?action=catalog&store=$storeId'))
        .timeout(const Duration(seconds: 20));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] != true) throw Exception((j['error'] ?? 'تعذر تحميل المتجر') as String);
    final st = j['store'] as Map<String, dynamic>;
    return StoreCatalog(
      store: MarketStore(
        id: (st['id'] as num).toInt(),
        name: (st['name'] ?? '') as String,
        description: (st['description'] ?? '') as String,
        logo: st['logo'] as String?,
        cover: st['cover'] as String?,
        products: 0,
      ),
      products: ((j['products'] ?? []) as List)
          .map((e) => ShopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: ((j['categories'] ?? []) as List)
          .map((e) => ShopCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      areas: ((j['areas'] ?? []) as List)
          .map((e) => ShipArea.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// بيانات عميل مسجل (دفتر العناوين) — بحث بالهاتف
  static Future<Map<String, dynamic>?> customerLookup(String phone) async {
    final res = await http
        .get(Uri.parse('${AppConfig.apiBase}/shop.php?action=customer_lookup&phone=$phone'))
        .timeout(const Duration(seconds: 15));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] == true && j['found'] == true) {
      return j['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// تسعير شحن دولي مبدئي من السيرفر (يرجع 0 إن لم تُربط الوجهة بعد)
  static Future<double> intlQuote(String scope, String country) async {
    final res = await http
        .get(Uri.parse(
            '${AppConfig.apiBase}/shop.php?action=area_ship&scope=$scope&country=${Uri.encodeQueryComponent(country)}'))
        .timeout(const Duration(seconds: 15));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] == true) {
      return double.tryParse((j['total'] ?? '0').toString()) ?? 0;
    }
    return 0;
  }

  /// إنشاء الطلب — الدفع عند الاستلام (COD)
  /// العقد المؤكد من السيرفر الحي: customer:{name,phone,email} +
  /// address:{scope, area_id | country/region/addr_line} + items:[{product_id,qty}]
  static Future<Map<String, dynamic>> checkout({
    required int storeId,
    required String name,
    required String phone,
    required String email,
    required String scope, // kw / gcc / arab / intl
    ShipArea? area,
    String block = '',
    String street = '',
    String building = '',
    String country = '',
    String region = '',
    String addrLine = '',
    String postalCode = '',
    String nationalAddr = '',
    String note = '',
    required List<CartLine> items,
  }) async {
    final body = {
      'customer': {'name': name, 'phone': phone, 'email': email},
      'address': {
        'scope': scope,
        if (scope == 'kw') ...{
          'area_id': area?.id,
          'block': block,
          'street': street,
          'building': building,
        } else ...{
          'country': country,
          'region': region,
          'addr_line': addrLine,
          'postal_code': postalCode,
          'national_addr': nationalAddr,
        },
      },
      'customer_note': note,
      'payment_method': 'cod',
      'items': items.map((l) => {'product_id': l.product.id, 'qty': l.qty}).toList(),
    };
    final res = await http
        .post(
          Uri.parse('${AppConfig.apiBase}/shop.php?action=checkout&store=$storeId'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['ok'] != true) throw Exception((j['error'] ?? 'تعذر إتمام الطلب') as String);
    return j;
  }
}
