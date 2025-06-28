// lib/screens/cemetery_space_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../models/space_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'space_booking_details_page.dart';

class CemeterySpaceListPage extends StatefulWidget {
  final Cemetery cemetery;
  const CemeterySpaceListPage({super.key, required this.cemetery});

  @override
  State<CemeterySpaceListPage> createState() => _CemeterySpaceListPageState();
}

class _CemeterySpaceListPageState extends State<CemeterySpaceListPage> {
  // We still fetch all spaces to get a complete picture for the stream
  List<CemeterySpace> _allFetchedSpaces = [];
  // This list will ONLY contain available spaces
  List<CemeterySpace> _availableSpaces = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _spacesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndSubscribeToSpaces();
  }

  Future<void> _initializeAndSubscribeToSpaces() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // The initial fetch gets all spaces so the realtime listener works on the whole set
      final initialData = await Supabase.instance.client
          .from('cemetery_spaces')
          .select()
          .eq('cemetery_id', widget.cemetery.id)
          .order('space_identifier', ascending: true);

      if (mounted) {
        _updateSpacesList(
            initialData.map((data) => CemeterySpace.fromJson(data)).toList());
        _isLoading = false;
      }

      // The stream listens for ANY change in the cemetery's spaces
      _spacesSubscription = Supabase.instance.client
          .from('cemetery_spaces')
          .stream(primaryKey: ['id'])
          .eq('cemetery_id', widget.cemetery.id)
          .listen(
            (data) {
              if (mounted) {
                print("Realtime update received for spaces. Refiltering list.");
                _updateSpacesList(
                    data.map((item) => CemeterySpace.fromJson(item)).toList());
              }
            },
            onError: (error) {
              if (mounted)
                setState(() =>
                    _errorMessage = "Realtime error: ${error.toString()}");
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spaces: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================================
  // ===                 *** THIS IS THE CORRECTED METHOD ***              ===
  // =========================================================================
  void _updateSpacesList(List<CemeterySpace> newSpaces) {
    setState(() {
      _allFetchedSpaces = newSpaces;
      // Filter the list to only include spaces with the 'available' status.
      // This is the list we will show in the UI.
      _availableSpaces = _allFetchedSpaces
          .where((space) => space.status == SpaceStatus.available)
          .toList();
    });
  }
  // =========================================================================

  @override
  void dispose() {
    _spacesSubscription?.cancel();
    super.dispose();
  }

  void _onSpaceSelected(CemeterySpace space) async {
    // The list only shows available spaces, so this check is redundant but safe.
    if (space.status != SpaceStatus.available) {
      return;
    }

    final bool? bookingSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceBookingDetailsPage(
          cemetery: widget.cemetery,
          selectedSpace: space,
        ),
      ),
    );

    if (bookingSuccess == true && mounted) {
      // Pop this page and send the signal back to the main list page.
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Available Spaces in ${widget.cemetery.name}',
            style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.appBarTitle,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.appBar))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.errorColor)))
              : _availableSpaces.isEmpty // Check the filtered list now
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                            'There are no available spaces in ${widget.cemetery.name} at the moment. Please check back later.',
                            textAlign: TextAlign.center,
                            style: AppStyles.titleStyle.copyWith(
                                color: AppColors.secondaryText, fontSize: 16)),
                      ),
                    )
                  // Use the filtered list for the builder
                  : ListView.builder(
                      padding: AppStyles.pagePadding,
                      itemCount: _availableSpaces.length,
                      itemBuilder: (context, index) {
                        final space = _availableSpaces[index];

                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(
                                color: AppColors.statusApproved, width: 1.2),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.statusApproved,
                              child: Icon(Icons.event_seat_outlined,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text('Space: ${space.spaceIdentifier}',
                                style: AppStyles.cardTitleStyle
                                    .copyWith(fontSize: 16)),
                            subtitle: Text(
                              'Status: ${space.status.displayName}',
                              style: AppStyles.caption.copyWith(
                                fontSize: 13,
                                color: AppColors.statusApproved,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: AppColors.appBar),
                            onTap: () => _onSpaceSelected(space),
                          ),
                        );
                      },
                    ),
    );
  }
}
