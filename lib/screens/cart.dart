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
  final _note = TextEditingController();

  List<ShipArea> _areas = [];
  ShipArea? _area;
  bool _loadingAreas = true;
  bool _submitting = false;
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

  double get _shipFee => _area?.fee ?? 0;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_area == null) {
      setState(() => _error = 'اختر منطقة التوصيل');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final addr =
          'قطعة ${_block.text.trim()} - شارع ${_street.text.trim()} - مبنى ${_building.text.trim()}';
      final result = await ShopApi.checkout(
        storeId: cart.storeId!,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        area: _area!,
        addressLine: addr,
        block: _block.text.trim(),
        street: _street.text.trim(),
        building: _building.text.trim(),
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
              decoration: const InputDecoration(
                  hintText: 'رقم الهاتف (8 أرقام)', prefixIcon: Icon(Icons.phone_outlined)),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _street,
                    decoration: const InputDecoration(hintText: 'الشارع'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _building,
                    decoration: const InputDecoration(hintText: 'المبنى'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
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
                    _row('الشحن', _area == null ? '—' : kd(_shipFee)),
                    const Divider(color: Colors.white12, height: 20),
                    _row('الإجمالي', kd(cart.subtotal + _shipFee), bold: true),
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
