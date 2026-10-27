enum ViewStatus { initial, loading, data, empty, error }

class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? errorMessage;

  const ViewState._({
    required this.status,
    this.data,
    this.errorMessage,
  });

  factory ViewState.initial() => const ViewState._(status: ViewStatus.initial);

  factory ViewState.loading([T? currentData]) => ViewState._(
        status: ViewStatus.loading,
        data: currentData,
      );

  factory ViewState.data(T data) => ViewState._(
        status: ViewStatus.data,
        data: data,
      );

  factory ViewState.empty([String? message]) => ViewState._(
        status: ViewStatus.empty,
        errorMessage: message,
      );

  factory ViewState.error(String message, [T? fallbackData]) => ViewState._(
        status: ViewStatus.error,
        errorMessage: message,
        data: fallbackData,
      );

  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get hasData => status == ViewStatus.data;
  bool get isEmpty => status == ViewStatus.empty;
  bool get hasError => status == ViewStatus.error;
}
