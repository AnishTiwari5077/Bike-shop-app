// lib/core/enums.dart
// ---------------------------------------------------------------------------
// ViewState enum — used by BaseViewModel and all ViewModels to represent
// the current async operation state of a screen or feature.
// ---------------------------------------------------------------------------

/// Represents the lifecycle state of any async operation in a ViewModel.
///
/// - [idle]    — No operation in progress. Default initial state.
/// - [loading] — An async operation is in progress (show spinner / shimmer).
/// - [success] — Operation completed successfully.
/// - [error]   — Operation failed; check [BaseViewModel.errorMessage].
enum ViewState { idle, loading, success, error }
