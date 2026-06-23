import 'package:flutter/material.dart';

class AppColors {
  // Primary: Deep Slate
  static const Color primary = Color(0xFF0F172A);
  
  // Surface: Glassmorphism Cards
  static const Color surface = Color(0xFF1E293B);
  
  // Accent: CloudPOS Indigo
  static const Color accent = Color(0xFF4F46E5);

  // Secondary Accent (for gradients or highlights)
  static const Color accentLight = Color(0xFF818CF8);

  // Readable foreground on top of [accent] fills (buttons, chips, badges).
  static const Color onAccent = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber/Yellow
  static const Color error = Color(0xFFEF4444);   // Red
  static const Color info = Color(0xFF3B82F6);    // Blue

  // Table Status Colors
  static const Color tableAvailable = Color(0xFF10B981);
  static const Color tableOccupied = Color(0xFFEF4444);
  static const Color tableBilling = Color(0xFFF59E0B);
  
  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Brand gradient (kept the name for compatibility; now CloudPOS indigo).
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C6FF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme Colors
  static const Color primaryLight = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
}
