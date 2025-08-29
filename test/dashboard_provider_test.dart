import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/data/remote/api_service.dart';
import 'package:frontend/models/dashboard_data.dart';
import 'package:frontend/models/material.dart';
import 'package:frontend/models/production_order.dart';
import 'package:frontend/models/inward_entry.dart';
import 'package:frontend/providers/dashboard_provider.dart';

// Manual mock for ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late DashboardProvider dashboardProvider;

  setUp(() {
    mockApiService = MockApiService();
    dashboardProvider = DashboardProvider(apiService: mockApiService);
  });

  group('DashboardProvider', () {
    // Mock DashboardData for testing
    final tDashboardData = DashboardData(
      productCount: 10,
      materialCount: 25,
      lowStockMaterials: <AppMaterial>[],
      recentProductionOrders: <ProductionOrder>[],
      recentInwardEntries: <InwardEntry>[],
    );

    test('initial values are correct', () {
      expect(dashboardProvider.dashboardData, null);
      expect(dashboardProvider.isLoading, false);
    });

    group('fetchDashboardData', () {
      test('should get data from the api service', () async {
        // Arrange
        when(mockApiService.getDashboardData())
            .thenAnswer((_) async => tDashboardData);
        // Act
        await dashboardProvider.fetchDashboardData();
        // Assert
        verify(mockApiService.getDashboardData());
        verifyNoMoreInteractions(mockApiService);
      });

      test(
        'should set isLoading to true then false and update dashboardData on success',
        () async {
          // Arrange
          when(mockApiService.getDashboardData())
              .thenAnswer((_) async => tDashboardData);

          final List<bool> loadingStates = [];
          dashboardProvider.addListener(() {
            loadingStates.add(dashboardProvider.isLoading);
          });

          // Act
          await dashboardProvider.fetchDashboardData();

          // Assert
          expect(dashboardProvider.dashboardData, tDashboardData);
          expect(loadingStates, [true, false]);
        },
      );

      test(
        'should not change dashboardData on failure',
        () async {
          // Arrange
          when(mockApiService.getDashboardData()).thenThrow(Exception('API Error'));

          // Act
          await dashboardProvider.fetchDashboardData();

          // Assert
          expect(dashboardProvider.dashboardData, null);
        },
      );
    });
  });
}
