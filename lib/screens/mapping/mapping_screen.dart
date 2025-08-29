import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/mapping_provider.dart';
import '../../models/product.dart';
import '../../models/material.dart';
import 'mapping_add_dialog.dart';
import 'product_search_dialog.dart';

class MappingScreen extends StatefulWidget {
  const MappingScreen({super.key});

  @override
  _MappingScreenState createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  Product? _selectedProduct;
  final _productController = TextEditingController();
  final _materialSearchController = TextEditingController();
  String _materialSearchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<MaterialProvider>(context, listen: false).fetchMaterials();
      Provider.of<MappingProvider>(context, listen: false).fetchAllMappings();
    });
    _materialSearchController.addListener(() {
      setState(() {
        _materialSearchQuery = _materialSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _productController.dispose();
    _materialSearchController.dispose();
    super.dispose();
  }

  void _showAddMappingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return MappingAddDialog(productId: _selectedProduct!.id);
      },
    );
  }

  void _openProductSearchDialog() async {
    final selectedProduct = await showDialog<Product>(
      context: context,
      builder: (ctx) => const ProductSearchDialog(),
    );

    if (selectedProduct != null) {
      setState(() {
        _selectedProduct = selectedProduct;
        _productController.text = selectedProduct.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mappingProvider = Provider.of<MappingProvider>(context);
    final materialProvider = Provider.of<MaterialProvider>(context);

    final allMappings = _selectedProduct == null
        ? []
        : mappingProvider.getMappingsForProduct(_selectedProduct!.id);

    final filteredMappings = allMappings.where((mapping) {
      final material = materialProvider.materials.firstWhere(
        (m) => m.id == mapping.materialId,
        orElse: () => AppMaterial(id: 0, name: '', unit: '', quantity: 0),
      );
      return material.name.toLowerCase().contains(_materialSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product-Material Mapping'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false).fetchProducts();
              Provider.of<MaterialProvider>(context, listen: false).fetchMaterials();
              Provider.of<MappingProvider>(context, listen: false).fetchAllMappings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _productController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Product',
                hintText: 'Select a product to see mappings',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _openProductSearchDialog,
                ),
              ),
            ),
          ),
          if (_selectedProduct != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _materialSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Mapped Materials',
                  hintText: 'Enter material name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          if (_selectedProduct != null)
            Expanded(
              child: mappingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredMappings.length,
                      itemBuilder: (context, index) {
                        final mapping = filteredMappings[index];
                        final material = materialProvider.materials.firstWhere(
                          (m) => m.id == mapping.materialId,
                          orElse: () => AppMaterial(
                              id: 0, name: 'Unknown', unit: '', quantity: 0),
                        );
                        return ListTile(
                          title: Text(material.name),
                          subtitle: Text(
                              'Quantity: ${mapping.fixedQuantity} ${material.unit}'),
                          trailing: authProvider.isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    try {
                                      await mappingProvider
                                          .deleteMapping(mapping.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Mapping deleted successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Failed to delete mapping: $e')),
                                        );
                                      }
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    ),
            ),
        ],
      ),
      floatingActionButton:
          authProvider.isAdmin && _selectedProduct != null
              ? FloatingActionButton(
                  onPressed: () => _showAddMappingDialog(context),
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
