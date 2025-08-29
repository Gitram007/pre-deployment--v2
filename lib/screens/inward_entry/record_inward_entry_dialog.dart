import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/material.dart' as model;
import '../../providers/inward_entry_provider.dart';
import 'material_search_dialog.dart';

class RecordInwardEntryDialog extends StatefulWidget {
  const RecordInwardEntryDialog({super.key});

  @override
  _RecordInwardEntryDialogState createState() =>
      _RecordInwardEntryDialogState();
}

class _RecordInwardEntryDialogState extends State<RecordInwardEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  model.AppMaterial? _selectedMaterial;
  double? _quantity;
  final _materialController = TextEditingController();

  @override
  void dispose() {
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _selectedMaterial == null) {
      // The validator handles showing a message
      return;
    }
    _formKey.currentState!.save();

    try {
      await Provider.of<InwardEntryProvider>(context, listen: false).addInwardEntry(
        _selectedMaterial!.id,
        _quantity!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inward entry recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record inward entry: $e')),
        );
      }
    }
  }

  void _openMaterialSearchDialog() async {
    final selectedMaterial = await showDialog<model.AppMaterial>(
      context: context,
      builder: (ctx) => const MaterialSearchDialog(),
    );

    if (selectedMaterial != null) {
      setState(() {
        _selectedMaterial = selectedMaterial;
        _materialController.text = selectedMaterial.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Inward Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _materialController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Material',
                  hintText: 'Select a material',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _openMaterialSearchDialog,
                  ),
                ),
                validator: (_) {
                  if (_selectedMaterial == null) {
                    return 'Please select a material.';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity.';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid positive number.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _quantity = double.parse(value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: _saveForm,
        ),
      ],
    );
  }
}
