// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // <<--- CHANGED: Start with WelcomeScreen
import 'constants/app_styles.dart';
import 'constants/app_colors.dart'; // <<--- ADDED: Import AppColors for ThemeData

void main() {
  runApp(const CMCApp());
}

class CMCApp extends StatelessWidget {
  const CMCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:
          'CMC App', // Consider a slightly more descriptive title for app stores etc.
      theme: ThemeData(
        // Core Theme Colors
        primarySwatch:
            Colors
                .green, // Base for some default colors (like ripple, some highlights)
        primaryColor:
            AppColors
                .appBar, // Your main brand color for AppBars, primary buttons if not overridden
        scaffoldBackgroundColor:
            AppColors.background, // Default background for Scaffolds
        fontFamily: AppStyles.fontFamily, // Default font for the app
        brightness: Brightness.light, // Explicitly set brightness
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBar,
          foregroundColor:
              AppColors
                  .appBarTitle, // Color for icons and text if not styled explicitly
          titleTextStyle: AppStyles.appBarTitleStyle,
          iconTheme: const IconThemeData(color: AppColors.appBarTitle),
          elevation:
              AppStyles.elevationLow, // Consistent low elevation for AppBars
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBackground,
            foregroundColor: AppColors.buttonText,
            textStyle:
                AppStyles.buttonTextStyle, // Your defined button text style
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.buttonBorderRadius,
            ), // Use button specific radius
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: AppStyles.elevationLow, // Slight elevation for buttons
          ),
        ),

        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                AppColors.appBar, // Make text buttons use your primary color
            textStyle: AppStyles.button.copyWith(
              fontWeight: FontWeight.w600,
            ), // Use button style, maybe bolder
          ),
        ),

        // InputDecoration Theme (for TextFormFields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground.withOpacity(
            0.7,
          ), // Slightly transparent fill for depth
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ), // Consistent padding
          border: OutlineInputBorder(
            borderRadius:
                AppStyles.cardBorderRadius, // Consistent border radius
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ), // Default subtle border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppStyles.cardBorderRadius,
            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ), // Border when not focused
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppStyles.cardBorderRadius,
            borderSide: const BorderSide(
              color: AppColors.appBar,
              width: 1.5,
            ), // Border when focused
          ),
          errorBorder: OutlineInputBorder(
            // Border for error state
            borderRadius: AppStyles.cardBorderRadius,
            borderSide: const BorderSide(
              color: AppColors.errorColor,
              width: 1.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            // Border for error state when focused
            borderRadius: AppStyles.cardBorderRadius,
            borderSide: const BorderSide(
              color: AppColors.errorColor,
              width: 1.5,
            ),
          ),
          labelStyle: AppStyles.caption.copyWith(
            color: AppColors.secondaryText,
          ), // Style for floating label
          hintStyle: AppStyles.caption.copyWith(
            color: Colors.grey.shade500,
          ), // Style for hint text
          prefixIconColor: AppColors.appBar.withOpacity(
            0.8,
          ), // Color for prefix icons
          suffixIconColor: AppColors.secondaryText, // Color for suffix icons
          errorStyle: AppStyles.caption.copyWith(
            color: AppColors.errorColor,
          ), // Style for error text
        ),

        // Card Theme
        cardTheme: CardTheme(
          elevation: AppStyles.elevationLow, // Default elevation for cards
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.cardBorderRadius,
          ), // Default shape for cards
          margin: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 4.0,
          ), // Default margin for cards
          color: AppColors.cardBackground, // Default card color
        ),

        // BottomNavigationBar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.activeTab,
          unselectedItemColor: AppColors.inactiveTab,
          selectedLabelStyle: AppStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppStyles.caption,
          elevation:
              AppStyles.elevationMedium, // Elevation for the bottom nav bar
          type: BottomNavigationBarType.fixed,
        ),

        // Icon Theme (Global fallback for icons if not specified elsewhere)
        iconTheme: IconThemeData(
          color: AppColors.primaryText, // A sensible default icon color
          size: 24.0,
        ),

        // Text Theme (Define if you want more granular control over default text styles)
        // textTheme: TextTheme(
        //   displayLarge: AppStyles.appBarTitleStyle.copyWith(fontSize: 32, color: AppColors.primaryText),
        //   titleLarge: AppStyles.cardTitleStyle,
        //   bodyLarge: AppStyles.bodyText1,
        //   bodyMedium: AppStyles.bodyText2,
        //   labelLarge: AppStyles.button,
        //   bodySmall: AppStyles.caption,
        // ),

        // Define other theme properties as needed
        // e.g., floatingActionButtonTheme, dialogTheme, etc.
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch:
              Colors.green, // Used to derive other colors in the scheme
        ).copyWith(
          secondary: AppColors.appBar,
          surface: AppColors.cardBackground,
          error: AppColors.errorColor,
          // You can define onPrimary, onSecondary, onBackground, onSurface, onError for text/icon colors on these surfaces
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(), // <<--- CHANGED: Start with WelcomeScreen
    );
  }
}
