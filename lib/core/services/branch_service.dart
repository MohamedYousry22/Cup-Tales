import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../local_storage/hive_service.dart';
import '../di/injection_container.dart' as di;
import 'package:flutter/foundation.dart';

class BranchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final HiveService _hive = di.sl<HiveService>();

  Future<void> fetchBranches() async {
    try {
      final response = await _supabase
          .from('branches')
          .select()
          .eq('active', true);
      
      final List<Branch> branches = (response as List)
          .map((e) => Branch.fromMap(e as Map<String, dynamic>))
          .toList();

      if (branches.isNotEmpty) {
        appBranches = branches;
        _cacheBranches(branches);
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching branches: $e');
      _loadFromCache();
    }
  }

  void _cacheBranches(List<Branch> branches) {
    final List<Map<String, dynamic>> maps = branches.map((e) => e.toMap()).toList();
    _hive.branchesBox.put('list', maps);
  }

  void _loadFromCache() {
    final cached = _hive.branchesBox.get('list') as List?;
    if (cached != null) {
      appBranches = cached
          .map((e) => Branch.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      debugPrint('DEBUG: Loaded ${appBranches.length} branches from cache');
    }
  }
  
  // Initialize and return current list
  Future<List<Branch>> getBranches() async {
    if (appBranches.isEmpty) {
      await fetchBranches();
    }
    return appBranches;
  }
}
