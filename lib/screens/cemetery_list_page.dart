// lib/screens/cemeteries_list_page.dart
import 'package:flutter/material.dart';
import '../widgets/cemetery_card.dart'; // Displays each cemetery
import '../models/cemetery_model.dart'; // Contains sampleCemeteries and Cemetery model
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class CemeteriesListPage extends StatefulWidget {
  const CemeteriesListPage({super.key});

  @override
  State<CemeteriesListPage> createState() => _CemeteriesListPageState();
}

class _CemeteriesListPageState extends State<CemeteriesListPage> {
  final List<Cemetery> _allCemeteries =
      sampleCemeteries; // From your cemetery_model.dart
  List<Cemetery> _filteredCemeteries = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredCemeteries = _allCemeteries;
    _searchController.addListener(_onSearchChanged);
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
    if (mounted) {
      setState(() {});
    }
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
    // This is the body content for the "Home" tab in MainScreen.
    // NO Scaffold or AppBar here.
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppStyles.pagePadding.copyWith(top: 16.0, bottom: 12.0),
            child: Material(
              elevation: AppStyles.elevationLow / 2,
              borderRadius: AppStyles.cardBorderRadius,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppStyles.bodyText1.copyWith(
                  color: AppColors.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search cemeteries by name or location...',
                  hintStyle: AppStyles.bodyText2.copyWith(
                    color: AppColors.secondaryText.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                    size: 22,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.secondaryText,
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                            splashRadius: 20,
                            tooltip: 'Clear search',
                          )
                          : null,
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(
                      color: AppColors.appBar,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          // List of Cemeteries
          Expanded(
            child:
                _filteredCemeteries.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No cemeteries found matching "${_searchController.text}".',
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : _allCemeteries.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No cemeteries are currently listed.',
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : ListView.builder(
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
        ],
      ),
    );
  }
}
