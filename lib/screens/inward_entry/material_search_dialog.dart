import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/material.dart' as model;
import '../../providers/material_provider.dart';

class MaterialSearchDialog extends StatefulWidget {
  const MaterialSearchDialog({super.key});

  @override
  _MaterialSearchDialogState createState() => _MaterialSearchDialogState();
}

class _MaterialSearchDialogState extends State<MaterialSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
    final allMaterials = materialProvider.materials;

    final filteredMaterials = allMaterials.where((material) {
      return material.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Search Material'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Enter material name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredMaterials.length,
                itemBuilder: (context, index) {
                  final material = filteredMaterials[index];
                  return ListTile(
                    title: Text(material.name),
                    onTap: () {
                      Navigator.of(context).pop(material);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
