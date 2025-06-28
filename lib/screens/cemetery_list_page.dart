// lib/screens/cemeteries_list_page.dart
import 'package:cmc/screens/cemetery_space_list_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/cemetery_card.dart';
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

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
    _fetchCemeteriesWithStats();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCemeteriesWithStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> response =
          await Supabase.instance.client.rpc('get_cemeteries_with_stats');

      if (mounted) {
        setState(() {
          _allCemeteries =
              response.map((data) => Cemetery.fromJson(data)).toList();
          _filterCemeteries();
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
  }

  void _filterCemeteries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCemeteries = _allCemeteries;
      } else {
        _filteredCemeteries = _allCemeteries.where((cemetery) {
          return cemetery.name.toLowerCase().contains(query) ||
              (cemetery.locationDescription?.toLowerCase().contains(query) ??
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

  // This is the function that handles navigation and refreshing
  void _handleBookSpacesTap(Cemetery cemetery) async {
    final bool? refreshNeeded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CemeterySpaceListPage(cemetery: cemetery),
      ),
    );

    // If the page we navigated to returns 'true', it means we need to refresh our data.
    if (refreshNeeded == true && mounted) {
      print("CemeteriesListPage: Refreshing stats after booking/cancellation.");
      _fetchCemeteriesWithStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppStyles.pagePadding.copyWith(top: 16.0, bottom: 8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search by cemetery name or location...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.secondaryText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.secondaryText),
                        onPressed: _clearSearch)
                    : null,
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style:
                                const TextStyle(color: AppColors.errorColor)))
                    : RefreshIndicator(
                        onRefresh: _fetchCemeteriesWithStats,
                        color: AppColors.appBar,
                        child: ListView.builder(
                          padding: AppStyles.pagePadding
                              .copyWith(top: 0, left: 8.0, right: 8.0),
                          itemCount: _filteredCemeteries.length,
                          itemBuilder: (context, index) {
                            final cemetery = _filteredCemeteries[index];
                            // =======================================================
                            // ===         *** THIS IS THE CORRECTED PART ***      ===
                            // =======================================================
                            return CemeteryCard(
                              cemetery: cemetery,
                              // We are now providing the required 'onBookSpacesPressed' parameter.
                              // We pass our navigation and refresh logic into the card's button.
                              onBookSpacesPressed: () =>
                                  _handleBookSpacesTap(cemetery),
                            );
                            // =======================================================
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
