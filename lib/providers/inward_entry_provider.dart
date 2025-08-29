import 'package:flutter/material.dart';
import '../models/inward_entry.dart';
import '../data/remote/api_service.dart';

class InwardEntryProvider with ChangeNotifier {
  final ApiService apiService;
  List<InwardEntry> _entries = [];
  bool _isLoading = false;

  InwardEntryProvider({required this.apiService});

  List<InwardEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> fetchInwardEntries() async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await apiService.getInwardEntries();
      // Sort by most recent first
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInwardEntry(int materialId, double quantity) async {
    try {
      final newEntry = await apiService.addInwardEntry(
        InwardEntry(id: 0, materialId: materialId, quantity: quantity, createdAt: DateTime.now()),
      );
      _entries.insert(0, newEntry); // Insert at the beginning of the list
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
