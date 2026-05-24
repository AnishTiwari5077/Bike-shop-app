// lib/providers/category_provider.dart
// ---------------------------------------------------------------------------
// CategoryViewModel — migrated from CategoryProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/category_provider.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - Uses setLoading()/setSuccess()/setError() from base class
//   - HTTP calls moved to CategoryService (Phase 1 MVVM migration)
// ---------------------------------------------------------------------------

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/category_model.dart';
import 'package:bike_shop/services/category_service.dart';

/// ViewModel for loading product categories from the backend API.
///
/// Consumed by HomeScreen, ExploreScreen for category filter chips.
class CategoryViewModel extends BaseViewModel {
  List<Category> _categories = [];

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Category> get categories => _categories;

  /// Backward-compatible alias for [errorMessage] from BaseViewModel.
  String? get error => errorMessage;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    setLoading();

    try {
      _categories = await CategoryService.instance.fetchCategories();
      setSuccess();
    } catch (e) {
      setError('Could not connect to server');
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef CategoryProvider = CategoryViewModel;
