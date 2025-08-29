import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/remote/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/material_provider.dart';
import 'providers/mapping_provider.dart';
import 'providers/production_order_provider.dart';
import 'providers/report_provider.dart';
import 'providers/inward_entry_provider.dart';
import 'providers/user_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/calculator_provider.dart';
import 'screens/auth/auth_wrapper.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => ProductProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => MaterialProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => MappingProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => ProductionOrderProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => ReportProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => InwardEntryProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => UserProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => CalculatorProvider(apiService: apiService)),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Inventory Management',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}
