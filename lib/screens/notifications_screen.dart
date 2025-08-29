import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/material_provider.dart';
import 'material/material_edit_screen.dart'; // To navigate to edit screen

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Notifications'),
      ),
      body: Consumer<MaterialProvider>(
        builder: (context, provider, child) {
          if (provider.lowStockMaterials.isEmpty) {
            return const Center(
              child: Text('No low stock materials. Everything looks good!'),
            );
          }

          return ListView.builder(
            itemCount: provider.lowStockMaterials.length,
            itemBuilder: (context, index) {
              final material = provider.lowStockMaterials[index];
              return ListTile(
                title: Text(material.name),
                subtitle: Text(
                  'Current: ${material.quantity} ${material.unit}, Reorder at: ${material.lowStockThreshold} ${material.unit}',
                ),
                trailing: const Icon(Icons.warning, color: Colors.orange),
                onTap: () {
                  // Optional: navigate to the material edit screen to reorder
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MaterialEditScreen(material: material),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
