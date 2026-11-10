import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/companion_model.dart';
import '../services/api_service.dart';

class CompanionFilter {
  final String? city;
  final String? gender;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String searchQuery;

  CompanionFilter({
    this.city,
    this.gender,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.searchQuery = '',
  });

  CompanionFilter copyWith({
    String? city,
    String? gender,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? searchQuery,
    bool clearCity = false,
    bool clearGender = false,
  }) {
    return CompanionFilter(
      city: clearCity ? null : (city ?? this.city),
      gender: clearGender ? null : (gender ?? this.gender),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CompanionListState {
  final bool isLoading;
  final List<CompanionCardModel> companions;
  final String? errorMessage;
  final CompanionFilter filter;

  CompanionListState({
    required this.isLoading,
    required this.companions,
    this.errorMessage,
    required this.filter,
  });

  factory CompanionListState.initial() => CompanionListState(
        isLoading: false,
        companions: [],
        filter: CompanionFilter(),
      );

  CompanionListState copyWith({
    bool? isLoading,
    List<CompanionCardModel>? companions,
    String? errorMessage,
    CompanionFilter? filter,
  }) {
    return CompanionListState(
      isLoading: isLoading ?? this.isLoading,
      companions: companions ?? this.companions,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }

  List<CompanionCardModel> get filteredCompanions {
    if (filter.searchQuery.isEmpty) return companions;
    final q = filter.searchQuery.toLowerCase();
    return companions.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.city != null && c.city!.toLowerCase().contains(q)) ||
          c.interests.any((i) => i.toLowerCase().contains(q));
    }).toList();
  }
}

class CompanionNotifier extends StateNotifier<CompanionListState> {
  final ApiService _api = ApiService();

  CompanionNotifier() : super(CompanionListState.initial()) {
    fetchCompanions();
  }

  Future<void> fetchCompanions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final response = await _api.listCompanions(
      city: state.filter.city,
      gender: state.filter.gender,
      minPrice: state.filter.minPrice,
      maxPrice: state.filter.maxPrice,
      minRating: state.filter.minRating,
    );

    if (response.success && response.data != null) {
      final List list = response.data['companions'] ?? response.data ?? [];
      final companions = list.map((item) => CompanionCardModel.fromJson(item)).toList();
      state = state.copyWith(isLoading: false, companions: companions);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message);
    }
  }

  void updateFilter(CompanionFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetchCompanions();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: query));
  }
}

final companionProvider = StateNotifierProvider<CompanionNotifier, CompanionListState>((ref) {
  return CompanionNotifier();
});
