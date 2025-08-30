import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/mapping_provider.dart';
import '../../models/material.dart';

class MappingAddDialog extends StatefulWidget {
  final int productId;

  const MappingAddDialog({super.key, required this.productId});

  @override
  _MappingAddDialogState createState() => _MappingAddDialogState();
}

class _MappingAddDialogState extends State<MappingAddDialog> {
  final _formKey = GlobalKey<FormState>();
  AppMaterial? _selectedMaterial;
  double? _fixedQuantity;

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _selectedMaterial == null) {
      return;
    }
    _formKey.currentState!.save();

    final errorMessage = await Provider.of<MappingProvider>(context, listen: false).addMapping(
      widget.productId,
      _selectedMaterial!.id,
      _fixedQuantity!,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mapping added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
    final materials = materialProvider.materials;

    return AlertDialog(
      title: const Text('Add Material to Product'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AppMaterial>(
              hint: const Text('Select Material'),
              value: _selectedMaterial,
              items: materials.map((AppMaterial material) {
                return DropdownMenuItem<AppMaterial>(
                  value: material,
                  child: Text(material.name),
                );
              }).toList(),
              onChanged: (AppMaterial? newValue) {
                setState(() {
                  _selectedMaterial = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a material' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Fixed Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity.';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                return null;
              },
              onSaved: (value) {
                _fixedQuantity = double.parse(value!);
              },
            ),
          ],
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
