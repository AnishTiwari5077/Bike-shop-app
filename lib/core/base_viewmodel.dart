// lib/core/base_viewmodel.dart
// ---------------------------------------------------------------------------
// BaseViewModel — the root class for all ViewModels in this project.
//
// Every ViewModel extends this class instead of using `with ChangeNotifier`
// directly. It provides a unified state machine (ViewState) so Views can
// react to loading / success / error uniformly without duplicating logic.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:bike_shop/core/enums.dart';

/// Base class for all ViewModels in the Bike Shop MVVM architecture.
///
/// Provides:
///   - [state]        — Current [ViewState] (idle / loading / success / error)
///   - [errorMessage] — Human-readable error string set on failure
///   - [isLoading]    — Convenience bool; true when state == loading
///   - [hasError]     — Convenience bool; true when state == error
///
/// State transition helpers call [notifyListeners] automatically:
///   - [setLoading()]
///   - [setSuccess()]
///   - [setError(message)]
///   - [setIdle()]
abstract class BaseViewModel extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────

  ViewState _state = ViewState.idle;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// Current [ViewState] of this ViewModel.
  ViewState get state => _state;

  /// Error message set when [state] is [ViewState.error]. Null otherwise.
  String? get errorMessage => _errorMessage;

  /// Convenience getter — true while an async operation is in progress.
  bool get isLoading => _state == ViewState.loading;

  /// Convenience getter — true when the last operation resulted in an error.
  bool get hasError => _state == ViewState.error;

  // ─── State transition helpers ──────────────────────────────────────────────

  /// Transition to [ViewState.loading] and clear any previous error.
  /// Automatically calls [notifyListeners].
  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Transition to [ViewState.success].
  /// Automatically calls [notifyListeners].
  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }

  /// Transition to [ViewState.error] with an optional [message].
  /// Automatically calls [notifyListeners].
  void setError([String? message]) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Transition back to [ViewState.idle], clearing any error.
  /// Automatically calls [notifyListeners].
  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message without changing state (useful for inline dismissal).
  void clearError() {
    if (_errorMessage != null || _state == ViewState.error) {
      _errorMessage = null;
      _state = ViewState.idle;
      notifyListeners();
    }
  }
}
