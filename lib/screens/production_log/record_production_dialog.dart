import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/production_order_provider.dart';
import '../../models/product.dart';

class RecordProductionDialog extends StatefulWidget {
  const RecordProductionDialog({super.key});

  @override
  _RecordProductionDialogState createState() => _RecordProductionDialogState();
}

class _RecordProductionDialogState extends State<RecordProductionDialog> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int? _quantity;

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || _selectedProduct == null) {
      return;
    }
    _formKey.currentState!.save();

    try {
      await Provider.of<ProductionOrderProvider>(context, listen: false)
          .addProductionOrder(
        _selectedProduct!.id,
        _quantity!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production order recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record production: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final products = productProvider.products;

    return AlertDialog(
      title: const Text('Record Production'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Product>(
              hint: const Text('Select Product'),
              value: _selectedProduct,
              items: products.map((Product product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (Product? newValue) {
                setState(() {
                  _selectedProduct = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a product' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Quantity Produced'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity.';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid positive number.';
                }
                return null;
              },
              onSaved: (value) {
                _quantity = int.parse(value!);
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
