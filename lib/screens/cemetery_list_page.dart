// lib/screens/cemeteries_list_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../widgets/cemetery_card.dart';
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

final supabase = Supabase.instance.client; // Access global instance

class CemeteriesListPage extends StatefulWidget {
  const CemeteriesListPage({super.key});

  @override
  State<CemeteriesListPage> createState() => _CemeteriesListPageState();
}

class _CemeteriesListPageState extends State<CemeteriesListPage> {
  List<Cemetery> _allCemeteries = [];
  List<Cemetery> _filteredCemeteries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchCemeteriesFromSupabase(); // Fetch data on init
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCemeteriesFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> response = await supabase
          .from('cemeteries')
          .select() // Select all columns, or specify: 'id, name, available_spots, ...'
          .order('name', ascending: true); // Example ordering

      if (mounted) {
        setState(() {
          _allCemeteries =
              response.map((data) => Cemetery.fromJson(data)).toList();
          _filteredCemeteries = _allCemeteries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load cemeteries: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterCemeteries();
    if (mounted) setState(() {});
  }

  void _filterCemeteries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCemeteries = _allCemeteries;
      } else {
        _filteredCemeteries =
            _allCemeteries.where((cemetery) {
              return cemetery.name.toLowerCase().contains(query) ||
                  (cemetery.locationDescription?.toLowerCase().contains(
                        query,
                      ) ??
                      false);
            }).toList();
      }
    });
  }

  void _clearSearch() {
    if (!_searchFocusNode.hasFocus && mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Search Bar (keep your enhanced search bar UI)
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: AppColors.appBar),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : _filteredCemeteries.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? Center(/* ... No results for search ... */)
                    : _allCemeteries
                        .isEmpty // Check if original list from Supabase is empty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No cemeteries are currently available.',
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      // Add pull to refresh
                      onRefresh: _fetchCemeteriesFromSupabase,
                      color: AppColors.appBar,
                      child: ListView.builder(
                        padding: AppStyles.pagePadding.copyWith(
                          top: 0,
                          left: 8.0,
                          right: 8.0,
                        ),
                        itemCount: _filteredCemeteries.length,
                        itemBuilder: (context, index) {
                          return CemeteryCard(
                            cemetery: _filteredCemeteries[index],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
