import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exception.dart';
import '../../models/product.dart';
import '../../models/material.dart';
import '../../models/product_material_mapping.dart';
import '../../models/production_order.dart';
import '../../models/inward_entry.dart';
import '../../models/user_profile.dart';
import '../../models/dashboard_data.dart';
import '../../models/calculator_result.dart';

class ApiService {
  final String _baseUrl = "http://127.0.0.1:8000/api";
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false; // Avoid multiple refresh calls
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'access_token', value: data['access']);
        return true;
      } else {
        // If refresh fails, logout the user
        await logout();
        return false;
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getHeaders();
    var response = await request(headers);

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await request(headers);
      }
    }
    return response;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // Auth endpoints
  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'access_token', value: data['access']);
      await _storage.write(key: 'refresh_token', value: data['refresh']);
    } else {
      // Throw an exception with the error message from the server
      final errorData = json.decode(response.body);
      throw ApiException(errorData['detail'] ?? 'Failed to login');
    }
  }

  Future<void> register(String company, String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'company_name': company,
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<UserProfile> getCurrentUser() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/me/'), headers: headers),
    );
    return UserProfile.fromJson(_handleResponse(response));
  }

  Future<UserProfile> updateUser(int userId, String role) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$_baseUrl/users/$userId/'),
        headers: headers,
        body: json.encode({'role': role}),
      ),
    );
    return UserProfile.fromJson(_handleResponse(response));
  }

  Future<void> deleteUser(int userId) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.delete(Uri.parse('$_baseUrl/users/$userId/'), headers: headers),
    );
    _handleResponse(response);
  }

  Future<List<UserProfile>> getUsers() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/users/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => UserProfile.fromJson(item)).toList();
  }

  Future<UserProfile> createUser(String username, String email, String password, String role) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(
        Uri.parse('$_baseUrl/users/create/'),
        headers: headers,
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      ),
    );
    return UserProfile.fromJson(_handleResponse(response));
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      String errorMessage = 'An unknown error occurred.';
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else {
          errorMessage = errorData.values
              .expand((value) => value is List ? value : [value])
              .map((i) => i.toString())
              .join('\n');
        }
      } else if (errorData is List) {
        errorMessage = errorData.join('\n');
      } else if (errorData is String) {
        errorMessage = errorData;
      }
      throw ApiException(errorMessage);
    } else {
      throw ApiException('Failed API Call: ${response.statusCode}');
    }
  }

  // Product endpoints
  Future<List<Product>> getProducts() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/products/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => Product.fromJson(item)).toList();
  }

  Future<Product> addProduct(Product product) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(Uri.parse('$_baseUrl/products/'), headers: headers, body: json.encode(product.toJson())),
    );
    return Product.fromJson(_handleResponse(response));
  }

  Future<Product> updateProduct(int id, Product product) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.put(Uri.parse('$_baseUrl/products/$id/'), headers: headers, body: json.encode(product.toJson())),
    );
    return Product.fromJson(_handleResponse(response));
  }

  Future<void> deleteProduct(int id) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.delete(Uri.parse('$_baseUrl/products/$id/'), headers: headers),
    );
    _handleResponse(response);
  }

  // Material endpoints
  Future<List<AppMaterial>> getMaterials() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/materials/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => AppMaterial.fromJson(item)).toList();
  }

  Future<AppMaterial> addMaterial(AppMaterial material) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(Uri.parse('$_baseUrl/materials/'), headers: headers, body: json.encode(material.toJson())),
    );
    return AppMaterial.fromJson(_handleResponse(response));
  }

  Future<AppMaterial> updateMaterial(int id, AppMaterial material) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.put(Uri.parse('$_baseUrl/materials/$id/'), headers: headers, body: json.encode(material.toJson())),
    );
    return AppMaterial.fromJson(_handleResponse(response));
  }

  Future<void> deleteMaterial(int id) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.delete(Uri.parse('$_baseUrl/materials/$id/'), headers: headers),
    );
    _handleResponse(response);
  }

  Future<List<AppMaterial>> getLowStockMaterials() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/low-stock-materials/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => AppMaterial.fromJson(item)).toList();
  }

  // ProductMaterialMapping endpoints
  Future<List<ProductMaterialMapping>> getMappings() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/mappings/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => ProductMaterialMapping.fromJson(item)).toList();
  }

  Future<ProductMaterialMapping> addMapping(ProductMaterialMapping mapping) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(Uri.parse('$_baseUrl/mappings/'), headers: headers, body: json.encode(mapping.toJson())),
    );
    return ProductMaterialMapping.fromJson(_handleResponse(response));
  }

  Future<void> deleteMapping(int id) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.delete(Uri.parse('$_baseUrl/mappings/$id/'), headers: headers),
    );
    _handleResponse(response);
  }

  // Reporting endpoints
  Future<Map<String, dynamic>> getMaterialUsageByProduct(int productId, String frequency) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/reports/material-usage/$productId/?frequency=$frequency'), headers: headers),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOverallMaterialUsage(String frequency) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/reports/overall-material-usage/?frequency=$frequency'), headers: headers),
    );
    return _handleResponse(response);
  }

  // ProductionOrder endpoints
  Future<List<ProductionOrder>> getProductionOrders() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/production-orders/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => ProductionOrder.fromJson(item)).toList();
  }

  Future<ProductionOrder> addProductionOrder(ProductionOrder productionOrder) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(Uri.parse('$_baseUrl/production-orders/'), headers: headers, body: json.encode(productionOrder.toJson())),
    );
    return ProductionOrder.fromJson(_handleResponse(response));
  }

  // InwardEntry endpoints
  Future<List<InwardEntry>> getInwardEntries() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/inward-entries/'), headers: headers),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => InwardEntry.fromJson(item)).toList();
  }

  Future<InwardEntry> addInwardEntry(InwardEntry inwardEntry) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(Uri.parse('$_baseUrl/inward-entries/'), headers: headers, body: json.encode(inwardEntry.toJson())),
    );
    return InwardEntry.fromJson(_handleResponse(response));
  }

  Future<Map<String, dynamic>> getOverallReport(String frequency) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/reports/overall-report/?frequency=$frequency'), headers: headers),
    );
    return _handleResponse(response);
  }

  Future<List<CalculatorResult>> calculateMaterials(int productId, int quantity) async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.post(
        Uri.parse('$_baseUrl/calculator/'),
        headers: headers,
        body: json.encode({'product_id': productId, 'quantity': quantity}),
      ),
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => CalculatorResult.fromJson(item)).toList();
  }

  Future<DashboardData> getDashboardData() async {
    final response = await _makeAuthenticatedRequest(
      (headers) => http.get(Uri.parse('$_baseUrl/dashboard/'), headers: headers),
    );
    return DashboardData.fromJson(_handleResponse(response));
  }
}
