import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import 'login.dart';
import 'merchant_home.dart' show statusColor;

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(api.session?.name ?? 'مهام السائق'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await api.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ShipmentItem>>(
        future: api.driverTasks(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data!;
          final codCount = tasks.where((t) => t.cod).length;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(child: _kpi('مهام اليوم', '${tasks.length}')),
                  const SizedBox(width: 10),
                  Expanded(child: _kpi('شحنات COD', '$codCount')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('الشحنات المسندة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...tasks.map((s) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: Color(AppConfig.amber)),
                      title: Text('${s.awb} — ${s.receiver}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s.area, style: const TextStyle(color: Colors.white54)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(s.status,
                              style: TextStyle(color: statusColor(s.status), fontSize: 12)),
                          if (s.cod)
                            const Text('تحصيل نقدي',
                                style: TextStyle(color: Color(AppConfig.amber), fontSize: 11)),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(AppConfig.amber))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
