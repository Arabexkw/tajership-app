import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import 'login.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const _OrdersTab(), const _ShipmentsTab(), const _AccountTab()];
    return Scaffold(
      appBar: AppBar(
        title: Text(api.session?.name ?? 'لوحة التاجر'),
        actions: [
          if (api.session?.demo ?? false)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Center(
                child: Chip(
                  label: Text('تجريبي', style: TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'الشحنات'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'جديد':
      return const Color(AppConfig.amber);
    case 'مسلّم':
      return const Color(0xFF4CD97B);
    case 'خرج للتوصيل':
      return const Color(0xFF5AB0FF);
    default:
      return Colors.white60;
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderItem>>(
      future: api.merchantOrders(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('لا توجد طلبات بعد', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('${o.id} — ${o.customer}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(o.date, style: const TextStyle(color: Colors.white54)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(o.amount,
                        style: const TextStyle(
                            color: Color(AppConfig.amber), fontWeight: FontWeight.bold)),
                    Text(o.status, style: TextStyle(color: statusColor(o.status), fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShipmentsTab extends StatelessWidget {
  const _ShipmentsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShipmentItem>>(
      future: api.merchantShipments(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ships = snap.data!;
        if (ships.isEmpty) {
          return const Center(child: Text('لا توجد شحنات بعد', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ships.length,
          itemBuilder: (context, i) {
            final s = ships[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.qr_code_2, color: Color(AppConfig.amber)),
                title: Text('${s.awb} — ${s.receiver}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.area, style: const TextStyle(color: Colors.white54)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.status, style: TextStyle(color: statusColor(s.status), fontSize: 12)),
                    if (s.cod)
                      const Text('COD', style: TextStyle(color: Color(AppConfig.amber), fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined, color: Color(AppConfig.amber)),
            title: Text(api.session?.name ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('حساب تاجر — تاجرشِب', style: TextStyle(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await api.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text('النسخة 0.1.0 — تاجرشِب من ArabEx Express',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
