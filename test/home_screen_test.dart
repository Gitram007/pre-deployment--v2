import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/material_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/models/dashboard_data.dart';
import 'package:frontend/models/material.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/production_order.dart';
import 'package:frontend/models/inward_entry.dart';


// Manual Mocks
class MockAuthProvider extends Mock implements AuthProvider {}
class MockDashboardProvider extends Mock implements DashboardProvider {}
class MockMaterialProvider extends Mock implements MaterialProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockDashboardProvider mockDashboardProvider;
  late MockMaterialProvider mockMaterialProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockDashboardProvider = MockDashboardProvider();
    mockMaterialProvider = MockMaterialProvider();
  });

  // Helper function to create the widget tree with all necessary providers
  Widget createHomeScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<DashboardProvider>.value(value: mockDashboardProvider),
        ChangeNotifierProvider<MaterialProvider>.value(value: mockMaterialProvider),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  // Mock data
  final tUserProfile = UserProfile(id: 1, username: 'test', email: 'test@test.com', companyId: 1, role: 'admin');
  final tDashboardData = DashboardData(
    productCount: 5,
    materialCount: 12,
    lowStockMaterials: [
      AppMaterial(id: 1, name: 'Low Stock Item', unit: 'kg', quantity: 5, lowStockThreshold: 10)
    ],
    recentProductionOrders: <ProductionOrder>[],
    recentInwardEntries: <InwardEntry>[],
  );

  testWidgets('HomeScreen shows loading indicator when data is null', (WidgetTester tester) async {
    // Arrange
    when(mockDashboardProvider.dashboardData).thenReturn(null);
    when(mockAuthProvider.userProfile).thenReturn(tUserProfile);
    when(mockAuthProvider.isAdmin).thenReturn(true);
    when(mockMaterialProvider.lowStockMaterials).thenReturn([]);

    // Act
    await tester.pumpWidget(createHomeScreen());

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen displays dashboard data when loaded', (WidgetTester tester) async {
    // Arrange
    when(mockDashboardProvider.dashboardData).thenReturn(tDashboardData);
    when(mockAuthProvider.userProfile).thenReturn(tUserProfile);
    when(mockAuthProvider.isAdmin).thenReturn(true);
    when(mockMaterialProvider.lowStockMaterials).thenReturn(tDashboardData.lowStockMaterials);

    // Act
    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle(); // Allow UI to settle

    // Assert
    expect(find.text('5'), findsOneWidget); // Product Count
    expect(find.text('12'), findsOneWidget); // Material Count
    expect(find.text('Low Stock Item'), findsOneWidget); // Low stock item name
    expect(find.byIcon(Icons.notifications), findsOneWidget);
    // Check for the badge content
    expect(find.text('1'), findsOneWidget);
  });
}
