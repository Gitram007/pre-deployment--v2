import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/material.dart' as model;
import '../../providers/inward_entry_provider.dart';
import '../../providers/material_provider.dart';
import 'record_inward_entry_dialog.dart';

class InwardEntryScreen extends StatefulWidget {
  const InwardEntryScreen({super.key});

  @override
  _InwardEntryScreenState createState() => _InwardEntryScreenState();
}

class _InwardEntryScreenState extends State<InwardEntryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<InwardEntryProvider>(context, listen: false).fetchInwardEntries();
      Provider.of<MaterialProvider>(context, listen: false).fetchMaterials();
    });
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

  void _showRecordInwardEntryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const RecordInwardEntryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inwardEntryProvider = Provider.of<InwardEntryProvider>(context);
    final materialProvider = Provider.of<MaterialProvider>(context, listen: false);

    final allEntries = inwardEntryProvider.entries;
    final filteredEntries = allEntries.where((entry) {
      final material = materialProvider.materials.firstWhere(
            (m) => m.id == entry.materialId,
        orElse: () => model.AppMaterial(id: 0, name: '', unit: '', quantity: 0),
      );
      return material.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inward Entry Log'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Material',
                hintText: 'Enter material name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: inwardEntryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => inwardEntryProvider.fetchInwardEntries(),
              child: ListView.builder(
                itemCount: filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = filteredEntries[index];
                  final material = materialProvider.materials.firstWhere(
                        (m) => m.id == entry.materialId,
                    orElse: () => model.AppMaterial(id: entry.materialId, name: 'Unknown Material', unit: 'N/A', quantity: 0),
                  );
                  return ListTile(
                    title: Text('Received ${entry.quantity} x ${material.name}'),
                    subtitle: Text(DateFormat.yMd().add_jm().format(entry.createdAt)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRecordInwardEntryDialog,
        child: const Icon(Icons.add),
        tooltip: 'Record Inward Entry',
      ),
    );
  }
}
