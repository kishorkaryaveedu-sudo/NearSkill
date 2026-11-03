import 'package:flutter/material.dart';

/// Maps skill/job names to appropriate Material Icons
class SkillIcons {
  SkillIcons._();

  static const Map<String, IconData> _map = {
    'plumber': Icons.plumbing,
    'plumbing': Icons.plumbing,
    'electrician': Icons.electrical_services,
    'electrical': Icons.electrical_services,
    'painter': Icons.format_paint,
    'painting': Icons.format_paint,
    'carpenter': Icons.carpenter,
    'carpentry': Icons.carpenter,
    'mechanic': Icons.build,
    'cleaning': Icons.cleaning_services,
    'cleaner': Icons.cleaning_services,
    'gardener': Icons.grass,
    'gardening': Icons.grass,
    'pest control': Icons.bug_report,
    'ac repair': Icons.ac_unit,
    'hvac': Icons.ac_unit,
    'welder': Icons.hardware,
    'welding': Icons.hardware,
    'mason': Icons.foundation,
    'masonry': Icons.foundation,
    'tiling': Icons.grid_view,
    'roofing': Icons.roofing,
    'locksmith': Icons.lock,
    'appliance repair': Icons.kitchen,
    'driver': Icons.directions_car,
    'delivery': Icons.local_shipping,
    'tutor': Icons.school,
    'tutoring': Icons.school,
    'photography': Icons.camera_alt,
    'photographer': Icons.camera_alt,
    'tailor': Icons.checkroom,
    'tailoring': Icons.checkroom,
    'beauty': Icons.face,
    'salon': Icons.content_cut,
    'barber': Icons.content_cut,
    'cooking': Icons.restaurant,
    'cook': Icons.restaurant,
    'catering': Icons.restaurant_menu,
    'security': Icons.security,
    'guard': Icons.security,
    'moving': Icons.local_shipping,
    'packers': Icons.inventory_2,
  };

  /// Get icon for a skill name (case-insensitive match)
  static IconData forSkill(String? skillName) {
    if (skillName == null) return Icons.handyman;
    final key = skillName.toLowerCase().trim();
    // Try exact match
    if (_map.containsKey(key)) return _map[key]!;
    // Try partial match
    for (final entry in _map.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return Icons.handyman;
  }

  /// Get a color associated with a skill for visual variety
  static Color colorForSkill(String? skillName) {
    if (skillName == null) return const Color(0xFF6366F1);
    final hash = skillName.hashCode.abs();
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF0EA5E9), // Sky
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF8B5CF6), // Violet
      Color(0xFF14B8A6), // Teal
      Color(0xFFEC4899), // Pink
      Color(0xFFF97316), // Orange
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[hash % colors.length];
  }
}
