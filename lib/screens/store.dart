import 'package:flutter/material.dart';

import '../config.dart';
import '../shop_api.dart';
import 'market.dart' show CartButton;

/// صفحة المتجر — الكتالوج بالتصنيفات وإضافة للسلة
class StoreScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const StoreScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Future<StoreCatalog> _future;
  int? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _future = ShopApi.catalog(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [const CartButton()],
      ),
      body: FutureBuilder<StoreCatalog>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text(snap.error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: Colors.white70)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data!;
          final products = c.products
              .where((p) => _categoryFilter == null || p.categoryId == _categoryFilter)
              .toList();
          return Column(
            children: [
              if (c.categories.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      _chip('الكل', _categoryFilter == null, () => setState(() => _categoryFilter = null)),
                      ...c.categories.map((cat) => _chip(cat.name, _categoryFilter == cat.id,
                          () => setState(() => _categoryFilter = cat.id))),
                    ],
                  ),
                ),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child:
                            Text('لا توجد منتجات', style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, i) => _productCard(products[i], c),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(AppConfig.amber),
        labelStyle: TextStyle(
            color: selected ? const Color(AppConfig.inkBlack) : Colors.white70,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _productCard(ShopProduct p, StoreCatalog c) {
    final out = !p.available || p.stock <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProduct(p, c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (p.image != null && p.image!.isNotEmpty)
                      ? Image.network(fullImageUrl(p.image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
                  if (p.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(AppConfig.amber),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('تخفيض',
                            style: TextStyle(
                                color: Color(AppConfig.inkBlack),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (out)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text('نفدت الكمية',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(kd(p.effectivePrice),
                          style: const TextStyle(
                              color: Color(AppConfig.amber), fontWeight: FontWeight.bold)),
                      if (p.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(kd(p.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: const Color(0xFF232A33),
        child: const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 42),
      );

  void _showProduct(ShopProduct p, StoreCatalog c) {
    int qty = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D232B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p.image != null && p.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(fullImageUrl(p.image),
                      height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              const SizedBox(height: 14),
              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (p.details != null && p.details!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.details!, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(kd(p.effectivePrice),
                      style: const TextStyle(
                          color: Color(AppConfig.amber),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  if (p.hasDiscount) ...[
                    const SizedBox(width: 8),
                    Text(kd(p.price),
                        style: const TextStyle(
                            color: Colors.white38, decoration: TextDecoration.lineThrough)),
                  ],
                  const Spacer(),
                  Text('المتوفر: ${p.stock}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IconButton.filledTonal(
                      onPressed: () => setSheet(() {
                            if (qty > 1) qty--;
                          }),
                      icon: const Icon(Icons.remove)),
                  Expanded(
                    child: Text('$qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                      onPressed: () => setSheet(() {
                            if (qty < p.stock) qty++;
                          }),
                      icon: const Icon(Icons.add)),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: (!p.available || p.stock <= 0)
                    ? null
                    : () {
                        cart.add(p, qty: qty);
                        cart.storeName = widget.storeName;
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('أُضيف للسلة ($qty × ${p.name})'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('أضف للسلة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
