import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/data/remote/api_service.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/user_provider.dart';

// Manual mock for ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late UserProvider userProvider;

  setUp(() {
    mockApiService = MockApiService();
    userProvider = UserProvider(apiService: mockApiService);
  });

  group('UserProvider', () {
    final tUser1 = UserProfile(id: 1, username: 'admin', email: 'admin@test.com', companyId: 1, role: 'admin');
    final tUser2 = UserProfile(id: 2, username: 'staff', email: 'staff@test.com', companyId: 1, role: 'staff');
    final tUserList = [tUser1, tUser2];

    test('initial values are correct', () {
      expect(userProvider.users, []);
      expect(userProvider.isLoading, false);
    });

    group('fetchUsers', () {
      test('should get users from the api service and update state', () async {
        // Arrange
        when(mockApiService.getUsers()).thenAnswer((_) async => tUserList);
        // Act
        await userProvider.fetchUsers();
        // Assert
        expect(userProvider.users, tUserList);
        verify(mockApiService.getUsers());
      });

      test('should handle exceptions gracefully', () async {
        // Arrange
        when(mockApiService.getUsers()).thenThrow(Exception('Failed to fetch'));
        // Act
        await userProvider.fetchUsers();
        // Assert
        expect(userProvider.users, []);
      });
    });

    group('addUser', () {
      test('should call addUser on the service and add user to state', () async {
        // Arrange
        when(mockApiService.createUser(any, any, any, any)).thenAnswer((_) async => tUser1);
        // Act
        await userProvider.addUser('admin', 'admin@test.com', 'password', 'admin');
        // Assert
        expect(userProvider.users.contains(tUser1), isTrue);
        verify(mockApiService.createUser('admin', 'admin@test.com', 'password', 'admin'));
      });
    });

    // Tests for updateUser and deleteUser would follow a similar pattern
  });
}
