import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/calculator_provider.dart';
import '../../models/calculator_result.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch products if they are not already loaded.
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      // Also clear any previous calculator results when the screen is opened
      Provider.of<CalculatorProvider>(context, listen: false).clear();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _runCalculation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product.')),
        );
        return;
      }
      final quantity = int.tryParse(_quantityController.text);
      if (quantity != null && quantity > 0) {
        Provider.of<CalculatorProvider>(context, listen: false)
            .calculate(_selectedProduct!.id, quantity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final calculatorProvider = Provider.of<CalculatorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Dropdown
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                hint: const Text('Select a Product'),
                isExpanded: true,
                items: productProvider.products.map((Product product) {
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
              const SizedBox(height: 16),
              // Quantity Input
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Produce',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Calculate Button
              ElevatedButton(
                onPressed: _runCalculation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Calculate'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              // Results Area
              Expanded(
                child: _buildResults(calculatorProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(CalculatorProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Text(
          'An error occurred: ${provider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.results == null) {
      return const Center(
          child: Text('Enter a product and quantity to see the required materials.'));
    }

    if (provider.results!.isEmpty) {
      return const Center(
          child: Text('No material mappings found for the selected product.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Material', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Required'), numeric: true),
          DataColumn(label: Text('In Stock'), numeric: true),
          DataColumn(label: Text('Shortfall'), numeric: true),
        ],
        rows: provider.results!.map((result) {
          final shortfall = result.shortfall > 0;
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (shortfall) return Colors.red.withOpacity(0.1);
                return null; // Use default
              },
            ),
            cells: [
              DataCell(Text(result.materialName)),
              DataCell(Text('${result.requiredQuantity} ${result.materialUnit}')),
              DataCell(Text('${result.currentStock} ${result.materialUnit}')),
              DataCell(
                Text(
                  '${result.shortfall} ${result.materialUnit}',
                  style: TextStyle(
                    color: shortfall ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
