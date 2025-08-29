import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/material_provider.dart';
import 'material_edit_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MaterialProvider>(context, listen: false).fetchMaterials();
      Provider.of<MaterialProvider>(context, listen: false).search('');
    });
    _searchController.addListener(() {
      Provider.of<MaterialProvider>(context, listen: false)
          .search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search for materials...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<MaterialProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.materials.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.materials.isEmpty) {
                  return const Center(child: Text('No materials found.'));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchMaterials(),
                  child: ListView.builder(
                    itemCount: provider.materials.length,
                    itemBuilder: (context, index) {
                      final material = provider.materials[index];
                      return ListTile(
                        title: Text(material.name),
                        subtitle: Text(
                            '${material.quantity} ${material.unit} | Reorder at: ${material.lowStockThreshold} ${material.unit} | Style: ${material.style}'),
                        trailing: authProvider.isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MaterialEditScreen(
                                                  material: material),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Are you sure?'),
                                          content: Text(
                                              'Do you want to delete ${material.name}?'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('No'),
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Yes'),
                                              onPressed: () async {
                                                try {
                                                  await provider
                                                      .deleteMaterial(material.id);
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Material deleted successfully!'),
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
                                                              'Failed to delete material: $e')),
                                                    );
                                                  }
                                                }
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: authProvider.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MaterialEditScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Material',
            )
          : null,
    );
  }
}
