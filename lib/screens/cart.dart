import 'package:flutter/material.dart';

import '../config.dart';
import '../shop_api.dart';

/// السلة وإتمام الطلب (دفع عند الاستلام في هذه النسخة)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السلة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 52, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('سلتك فاضية', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : Column(
              children: [
                if (cart.storeName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 16, color: Color(AppConfig.amber)),
                        const SizedBox(width: 6),
                        Text('طلب من: ${cart.storeName}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.lines.length,
                    itemBuilder: (context, i) {
                      final l = cart.lines[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: (l.product.image != null && l.product.image!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(fullImageUrl(l.product.image),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.inventory_2_outlined)),
                                )
                              : const Icon(Icons.inventory_2_outlined),
                          title: Text(l.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(kd(l.total),
                              style: const TextStyle(color: Color(AppConfig.amber))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => setState(() {
                                  if (l.qty > 1) {
                                    cart.setQty(l.product.id, l.qty - 1);
                                  } else {
                                    cart.remove(l.product.id);
                                  }
                                }),
                              ),
                              Text('${l.qty}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => setState(() {
                                  if (l.qty < l.product.stock) cart.setQty(l.product.id, l.qty + 1);
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D232B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('مجموع المنتجات',
                                style: TextStyle(color: Colors.white70)),
                            const Spacer(),
                            Text(kd(cart.subtotal),
                                style: const TextStyle(
                                    color: Color(AppConfig.amber),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('رسوم الشحن تُحدد حسب منطقتك في الخطوة التالية',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const CheckoutScreen()))
                              .then((_) => setState(() {})),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('إتمام الطلب'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// شاشة إتمام الطلب — بيانات العميل والعنوان
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _block = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _country = TextEditingController();
  final _region = TextEditingController();
  final _addrLine = TextEditingController();
  final _postal = TextEditingController();
  final _note = TextEditingController();

  List<ShipArea> _areas = [];
  ShipArea? _area;
  String _scope = 'kw'; // kw / gcc / arab / intl
  bool _loadingAreas = true;
  bool _submitting = false;
  bool _lookingUp = false;
  bool _lookupDone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final c = await ShopApi.catalog(cart.storeId!);
      setState(() {
        _areas = c.areas;
        _loadingAreas = false;
      });
    } catch (e) {
      setState(() {
        _loadingAreas = false;
        _error = 'تعذر تحميل مناطق الشحن';
      });
    }
  }

  Future<void> _lookup(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || _lookingUp || _lookupDone) return;
    setState(() => _lookingUp = true);
    try {
      final d = await ShopApi.customerLookup(digits);
      if (d != null && mounted) {
        setState(() {
          _lookupDone = true;
          if ((d['name'] ?? '').toString().isNotEmpty && _name.text.isEmpty) {
            _name.text = d['name'].toString();
          }
          if ((d['email'] ?? '').toString().isNotEmpty && _email.text.isEmpty) {
            _email.text = d['email'].toString();
          }
          final sc = (d['ship_scope'] ?? '').toString();
          if (sc.isNotEmpty) _scope = sc;
          final aid = d['area_id'];
          if (aid != null && _areas.isNotEmpty) {
            final found = _areas.where((a) => a.id == (aid as num).toInt()).toList();
            if (found.isNotEmpty) _area = found.first;
          }
          if ((d['block'] ?? '').toString().isNotEmpty) _block.text = d['block'].toString();
          if ((d['street'] ?? '').toString().isNotEmpty) _street.text = d['street'].toString();
          if ((d['building'] ?? '').toString().isNotEmpty) _building.text = d['building'].toString();
          if ((d['country'] ?? '').toString().isNotEmpty) _country.text = d['country'].toString();
          if ((d['region'] ?? '').toString().isNotEmpty) _region.text = d['region'].toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم جلب بياناتك المسجلة'),
              duration: Duration(seconds: 2)));
        }
      }
    } catch (_) {
      // اختياري
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  double get _shipFee => _scope == 'kw' ? (_area?.fee ?? 0) : 0;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_scope == 'kw' && _area == null) {
      setState(() => _error = 'اختر منطقة التوصيل');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ShopApi.checkout(
        storeId: cart.storeId!,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        scope: _scope,
        area: _area,
        block: _block.text.trim(),
        street: _street.text.trim(),
        building: _building.text.trim(),
        country: _country.text.trim(),
        region: _region.text.trim(),
        addrLine: _addrLine.text.trim(),
        postalCode: _postal.text.trim(),
        note: _note.text.trim(),
        items: cart.lines,
      );
      cart.clear();
      if (!mounted) return;
      final orderId = (result['order_id'] ?? result['id'] ?? '').toString();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        (route) => route.isFirst,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('بياناتك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  hintText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().length < 3) ? 'اكتب اسمك الكامل' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              onChanged: _lookup,
              decoration: InputDecoration(
                  hintText: 'رقم الهاتف (8 أرقام)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  suffixIcon: _lookingUp
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : null),
              validator: (v) =>
                  (v == null || v.trim().replaceAll(RegExp(r'\D'), '').length < 8)
                      ? 'رقم غير صحيح'
                      : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  hintText: 'البريد الإلكتروني (لتأكيد الطلب)',
                  prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) =>
                  (v == null || !v.contains('@') || !v.contains('.')) ? 'بريد غير صحيح' : null,
            ),
            const SizedBox(height: 20),
            const Text('عنوان التوصيل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kw', label: Text('الكويت')),
                ButtonSegment(value: 'gcc', label: Text('الخليج')),
                ButtonSegment(value: 'arab', label: Text('عربي')),
                ButtonSegment(value: 'intl', label: Text('دولي')),
              ],
              selected: {_scope},
              onSelectionChanged: (sel) => setState(() => _scope = sel.first),
            ),
            const SizedBox(height: 12),
            if (_scope == 'kw') ...[
            _loadingAreas
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                : DropdownButtonFormField<ShipArea>(
                    value: _area,
                    decoration: const InputDecoration(
                        hintText: 'المنطقة', prefixIcon: Icon(Icons.location_on_outlined)),
                    dropdownColor: const Color(0xFF1D232B),
                    items: _areas
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text('${a.name} — شحن ${kd(a.fee)}',
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (a) => setState(() => _area = a),
                  ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _block,
                    decoration: const InputDecoration(hintText: 'القطعة'),
                    validator: (v) => (_scope == 'kw' && (v == null || v.trim().isEmpty)) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _street,
                    decoration: const InputDecoration(hintText: 'الشارع'),
                    validator: (v) => (_scope == 'kw' && (v == null || v.trim().isEmpty)) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _building,
                    decoration: const InputDecoration(hintText: 'المبنى'),
                    validator: (v) => (_scope == 'kw' && (v == null || v.trim().isEmpty)) ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            ] else ...[
              TextFormField(
                controller: _country,
                decoration: const InputDecoration(
                    hintText: 'الدولة', prefixIcon: Icon(Icons.public)),
                validator: (v) => (_scope != 'kw' && (v == null || v.trim().isEmpty)) ? 'اكتب الدولة' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _region,
                decoration: const InputDecoration(
                    hintText: 'المدينة / المنطقة', prefixIcon: Icon(Icons.location_city)),
                validator: (v) => (_scope != 'kw' && (v == null || v.trim().isEmpty)) ? 'اكتب المدينة' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addrLine,
                decoration: const InputDecoration(
                    hintText: 'العنوان التفصيلي', prefixIcon: Icon(Icons.home_outlined)),
                validator: (v) => (_scope != 'kw' && (v == null || v.trim().isEmpty)) ? 'اكتب العنوان' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _postal,
                decoration: const InputDecoration(
                    hintText: 'الرمز البريدي (اختياري)',
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined)),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                  hintText: 'ملاحظات للسائق (اختياري)', prefixIcon: Icon(Icons.notes)),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row('المنتجات (${cart.count})', kd(cart.subtotal)),
                    const SizedBox(height: 6),
                    _row(
                        'الشحن',
                        _scope != 'kw'
                            ? 'يُحسب حسب الوجهة والوزن'
                            : (_area == null ? '—' : kd(_shipFee))),
                    const Divider(color: Colors.white12, height: 20),
                    _row(
                        _scope == 'kw' ? 'الإجمالي' : 'الإجمالي (بدون شحن)',
                        kd(cart.subtotal + _shipFee),
                        bold: true),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 16, color: Colors.white54),
                        SizedBox(width: 6),
                        Text('الدفع عند الاستلام',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ) ,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF6B6B))),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('تأكيد الطلب'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: bold ? Colors.white : Colors.white70)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: const Color(AppConfig.amber),
                fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
                fontSize: bold ? 17 : 14)),
      ],
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CD97B), size: 72),
              const SizedBox(height: 16),
              const Text('تم استلام طلبك!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (orderId.isNotEmpty)
                Text('رقم الطلب: $orderId',
                    style: const TextStyle(color: Color(AppConfig.amber), fontSize: 16)),
              const SizedBox(height: 8),
              const Text('بيوصلك تأكيد على بريدك، وأرابكس تتولى التوصيل 🚚',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('رجوع للسوق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
