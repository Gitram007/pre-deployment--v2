import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/production_order_provider.dart';
import '../../providers/product_provider.dart';
import 'record_production_dialog.dart';

class ProductionLogScreen extends StatefulWidget {
  const ProductionLogScreen({super.key});

  @override
  _ProductionLogScreenState createState() => _ProductionLogScreenState();
}

class _ProductionLogScreenState extends State<ProductionLogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProductionOrderProvider>(context, listen: false).fetchProductionOrders();
      // Also fetch products for the 'Add' dialog
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  void _showRecordProductionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const RecordProductionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<ProductionOrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Log'),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => orderProvider.fetchProductionOrders(),
              child: ListView.builder(
                itemCount: orderProvider.orders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  // Find the product name from the productId
                  final product = productProvider.products.firstWhere(
                    (p) => p.id == order.productId,
                    // Provide a dummy product if not found to avoid returning null.
                    orElse: () => Product(id: order.productId, name: 'Unknown Product'),
                  );
                  return ListTile(
                    title: Text('Produced ${order.quantity} x ${product.name}'),
                    subtitle: Text(DateFormat.yMd().add_jm().format(order.createdAt)),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRecordProductionDialog,
        child: const Icon(Icons.add),
        tooltip: 'Record Production',
      ),
    );
  }
}
