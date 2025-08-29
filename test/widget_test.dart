import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/remote/api_service.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/product_provider.dart';
import 'package:frontend/providers/material_provider.dart';
import 'package:frontend/providers/mapping_provider.dart';
import 'package:frontend/providers/report_provider.dart';

void main() {
  testWidgets('HomeScreen displays list tiles', (WidgetTester tester) async {
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProductProvider(apiService: apiService)),
          ChangeNotifierProvider(create: (_) => MaterialProvider(apiService: apiService)),
          ChangeNotifierProvider(create: (_) => MappingProvider(apiService: apiService)),
          ChangeNotifierProvider(create: (_) => ReportProvider(apiService: apiService)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Manage Products'), findsOneWidget);
    expect(find.text('Manage Materials'), findsOneWidget);
    expect(find.text('Product-Material Mappings'), findsOneWidget);
    expect(find.text('View Reports'), findsOneWidget);
  });
}
