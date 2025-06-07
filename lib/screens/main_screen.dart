// lib/screens/main_screen.dart
import 'package:cmc/screens/cemetery_list_page.dart';
import 'package:flutter/material.dart';
import 'reservation_page.dart';
import 'services_page.dart';
import 'reporting_page.dart';
import 'settings_page.dart';
import 'notifications_page.dart'; // For navigation
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
// No need to import ../models/cemetery_model.dart directly in MainScreen anymore

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<String> _pageTitles = <String>[
    "EternalSpace", // Title for Home tab
    'My Reservations',
    'Services',
    'Report Issue',
    'Settings',
  ];

  // Corrected list of pages for the BottomNavigationBar
  static final List<Widget> _widgetOptions = <Widget>[
    const CemeteriesListPage(), // <<--- Index 0: Home is the list of cemeteries
    const ReservationPage(),
    const ServicesPage(),
    const ReportingPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    if (index < _widgetOptions.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double homeAppBarHeight = kToolbarHeight;
    const double otherTabsAppBarHeight =
        48.0; // Or kToolbarHeight if you prefer same height

    final bool isHomePage = _selectedIndex == 0;
    final double currentAppBarHeight =
        isHomePage ? homeAppBarHeight : otherTabsAppBarHeight;

    Widget? appBarTitleWidget;
    Widget? appBarLeadingWidget;
    List<Widget>? appBarActionsWidget;

    if (isHomePage) {
      appBarLeadingWidget = Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
        ),
      );
      appBarTitleWidget = const Text(
        'EternalSpace',
        style: AppStyles.appBarTitleStyle,
      );
      appBarActionsWidget = [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.notificationIcon,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
      ];
    } else {
      appBarLeadingWidget = null;
      if (_selectedIndex < _pageTitles.length) {
        // Check bounds
        appBarTitleWidget = Text(
          _pageTitles[_selectedIndex],
          style: AppStyles.appBarTitleStyle,
        );
      } else {
        appBarTitleWidget = const Text(''); // Fallback
      }
      appBarActionsWidget = [];
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(currentAppBarHeight),
        child: AppBar(
          leading: appBarLeadingWidget,
          title: appBarTitleWidget,
          centerTitle: !isHomePage,
          backgroundColor: AppColors.appBar,
          elevation: AppStyles.elevationLow,
          actions: appBarActionsWidget,
          automaticallyImplyLeading: false,
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services_outlined),
            activeIcon: Icon(Icons.miscellaneous_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            activeIcon: Icon(Icons.report),
            label: 'Reporting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ), // "More" or "Settings"
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.activeTab,
        unselectedItemColor: AppColors.inactiveTab,
        onTap: _onItemTapped,
        selectedLabelStyle: AppStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppStyles.caption,
        elevation: AppStyles.elevationMedium,
      ),
    );
  }
}
