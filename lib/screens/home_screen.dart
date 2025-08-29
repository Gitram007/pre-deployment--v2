import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dashboard_data.dart';
import '../models/inward_entry.dart';
import '../models/production_order.dart';
import '../models/material.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/material_provider.dart';
import 'notifications_screen.dart';
import 'product/product_list_screen.dart';
import 'material/material_list_screen.dart';
import 'mapping/mapping_screen.dart';
import 'reports/report_screen.dart';
import 'inward_entry/inward_entry_screen.dart';
import 'production_log/production_log_screen.dart';
import 'reports/overall_report_screen.dart';
import 'user/user_list_screen.dart';
import 'calculator/calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ActivityItem {
  final DateTime createdAt;
  final dynamic data;
  final String type;

  _ActivityItem({required this.createdAt, required this.data, required this.type});
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
      Provider.of<MaterialProvider>(context, listen: false).fetchLowStockMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final dashboardData = dashboardProvider.dashboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<MaterialProvider>(
            builder: (context, materialProvider, child) {
              final lowStockCount = materialProvider.lowStockMaterials.length;
              return badges.Badge(
                showBadge: lowStockCount > 0,
                badgeContent: Text(
                  lowStockCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Manage Products'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const ProductListScreen()))
                    .then((_) => Provider.of<DashboardProvider>(context,
                        listen: false)
                    .fetchDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text('Manage Materials'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const MaterialListScreen()))
                    .then((_) => Provider.of<DashboardProvider>(context,
                        listen: false)
                    .fetchDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Product-Material Mappings'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const MappingScreen()))
                    .then((_) => Provider.of<DashboardProvider>(context,
                        listen: false)
                    .fetchDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Production Log'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const ProductionLogScreen()))
                    .then((_) => Provider.of<DashboardProvider>(context,
                        listen: false)
                    .fetchDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.input),
              title: const Text('Inward Entry'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const InwardEntryScreen()))
                    .then((_) => Provider.of<DashboardProvider>(context,
                        listen: false)
                    .fetchDashboardData());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Material Calculator'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const CalculatorScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Reports'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ReportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Overall Report'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const OverallReportScreen()));
              },
            ),
            if (authProvider.isAdmin) const Divider(),
            if (authProvider.isAdmin)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => const UserListScreen()))
                      .then((_) => Provider.of<DashboardProvider>(context,
                          listen: false)
                      .fetchDashboardData());
                },
              ),
          ],
        ),
      ),
      body: dashboardData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await dashboardProvider.fetchDashboardData();
          await context.read<MaterialProvider>().fetchLowStockMaterials();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Total Products',
                        dashboardData.productCount.toString(), Icons.business),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard('Total Materials',
                        dashboardData.materialCount.toString(), Icons.widgets),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Low Stock Materials', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildLowStockList(dashboardData.lowStockMaterials),
              const SizedBox(height: 24),
              Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildRecentActivity(context, dashboardData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList(List<AppMaterial> materials) {
    if (materials.isEmpty) {
      return const Text('No materials are low on stock. Well done!');
    }
    return Card(
      child: Column(
        children: materials.map((material) {
          return ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(material.name),
            trailing: Text('${material.quantity} ${material.unit}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, DashboardData data) {
    final activities = [
      ...data.recentProductionOrders.map((e) => _ActivityItem(createdAt: e.createdAt, data: e, type: 'Production')),
      ...data.recentInwardEntries.map((e) => _ActivityItem(createdAt: e.createdAt, data: e, type: 'Inward')),
    ];
    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (activities.isEmpty) {
      return const Text('No recent activity.');
    }

    return Card(
      child: Column(
        children: activities.take(5).map((activity) {
          if (activity.type == 'Production') {
            final order = activity.data as ProductionOrder;
            return ListTile(
              leading: const Icon(Icons.precision_manufacturing, color: Colors.red),
              title: Text('Production Order: ${order.quantity} units'),
              subtitle: Text('Product ID: ${order.productId}'),
            );
          } else {
            final entry = activity.data as InwardEntry;
            return ListTile(
              leading: const Icon(Icons.input, color: Colors.green),
              title: Text('Inward Entry: ${entry.quantity} units'),
              subtitle: Text('Material ID: ${entry.materialId}'),
            );
          }
        }).toList(),
      ),
    );
  }
}
