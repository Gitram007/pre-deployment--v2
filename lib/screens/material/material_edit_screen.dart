import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/material.dart';
import '../../providers/material_provider.dart';

class MaterialEditScreen extends StatefulWidget {
  final AppMaterial? material;

  const MaterialEditScreen({super.key, this.material});

  @override
  _MaterialEditScreenState createState() => _MaterialEditScreenState();
}

class _MaterialEditScreenState extends State<MaterialEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _unit;
  late double _quantity;
  late String _style;
  late double _lowStockThreshold;

  @override
  void initState() {
    super.initState();
    _name = widget.material?.name ?? '';
    _unit = widget.material?.unit ?? '';
    _quantity = widget.material?.quantity ?? 0.0;
    _style = widget.material?.style ?? 'N/A';
    _lowStockThreshold = widget.material?.lowStockThreshold ?? 10.0;
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    final provider = Provider.of<MaterialProvider>(context, listen: false);
    final isUpdating = widget.material != null;

    try {
      final material = AppMaterial(
        id: widget.material?.id ?? 0,
        name: _name,
        unit: _unit,
        quantity: _quantity,
        style: _style,
        lowStockThreshold: _lowStockThreshold,
      );

      if (isUpdating) {
        await provider.updateMaterial(widget.material!.id, material);
      } else {
        await provider.addMaterial(material);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Material ${isUpdating ? 'updated' : 'created'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save material: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Material Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Unit (e.g., kg, liter)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _unit = value!;
                },
              ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
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
                  _quantity = double.parse(value!);
                },
              ),
              TextFormField(
                initialValue: _style,
                decoration: const InputDecoration(labelText: 'Style'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a style.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _style = value!;
                },
              ),
              TextFormField(
                initialValue: _lowStockThreshold.toString(),
                decoration: const InputDecoration(labelText: 'Reorder Level'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reorder level.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lowStockThreshold = double.parse(value!);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
