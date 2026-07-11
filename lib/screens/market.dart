import 'package:flutter/material.dart';

import '../config.dart';
import '../shop_api.dart';
import 'cart.dart';
import 'store.dart';

/// السوق — كل متاجر تاجرشِب
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late Future<List<MarketStore>> _future;

  @override
  void initState() {
    super.initState();
    _future = ShopApi.stores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سوق تاجرشِب', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [const CartButton()],
      ),
      body: FutureBuilder<List<MarketStore>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return _error(snap.error.toString());
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stores = snap.data!;
          if (stores.isEmpty) {
            return const Center(
                child: Text('لا توجد متاجر حالياً', style: TextStyle(color: Colors.white54)));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = ShopApi.stores()),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: stores.length,
              itemBuilder: (context, i) => _storeCard(stores[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _error(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 40),
            const SizedBox(height: 12),
            Text(msg.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _future = ShopApi.stores()),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeCard(MarketStore s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StoreScreen(storeId: s.id, storeName: s.name)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.cover != null && s.cover!.isNotEmpty)
              SizedBox(
                height: 110,
                child: Image.network(
                  fullImageUrl(s.cover),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF232A33)),
                ),
              ),
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF232A33),
                backgroundImage: (s.logo != null && s.logo!.isNotEmpty)
                    ? NetworkImage(fullImageUrl(s.logo))
                    : null,
                child: (s.logo == null || s.logo!.isEmpty)
                    ? const Icon(Icons.storefront, color: Color(AppConfig.amber))
                    : null,
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(s.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${s.products}',
                      style: const TextStyle(
                          color: Color(AppConfig.amber),
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                  const Text('منتج', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر السلة الموحد في الشريط العلوي (مع عدّاد)
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'السلة',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CartScreen()))
          .then((_) => (context as Element).markNeedsBuild()),
      icon: Badge(
        isLabelVisible: cart.count > 0,
        label: Text('${cart.count}'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
