// import 'package:flutter/material.dart';
// import '../services/theme_service.dart';

// class ColorThemeSelector extends StatelessWidget {
//   final ThemeService themeService;
//   final Function(int) onColorSelected;
//   final String? currentTheme;
//   final Function(String)? onThemeSelected;

//   const ColorThemeSelector({
//     super.key,
//     required this.themeService,
//     required this.onColorSelected,
//     this.currentTheme,
//     this.onThemeSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final isDarkMode = themeService.isDarkMode;
//     final currentColorIndex = themeService.colorSeed;
//     final availableColors = themeService.availableColorSeeds;

//     // If onThemeSelected is provided and currentTheme is not null, use theme-based selection
//     if (onThemeSelected != null && currentTheme != null) {
//       return _buildThemeSelector(context, currentTheme!, colorScheme);
//     }

//     // Otherwise use the color-based selection
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12.0),
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.shadow.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Color Theme',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Choose your favorite color palette ✨',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: colorScheme.onSurfaceVariant.withOpacity(0.8),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children: List.generate(
//               availableColors.length,
//               (index) => _buildColorOption(
//                 context,
//                 availableColors[index],
//                 index == currentColorIndex,
//                 () => onColorSelected(index),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildThemeSelector(
//     BuildContext context,
//     String currentTheme,
//     ColorScheme colorScheme,
//   ) {
//     // Map of theme names to display names
//     final themeNames = {
//       'pink': 'Pink',
//       'hotPink': 'Hot Pink',
//       'deepPink': 'Deep Pink',
//       'raspberry': 'Raspberry',
//       'lightPink': 'Light Pink',
//       'babyPink': 'Baby Pink',
//       'mediumPink': 'Medium Pink',
//       'vividPink': 'Vivid Pink',
//       'darkPink': 'Dark Pink',
//       'crimson': 'Crimson',
//     };

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12.0),
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.shadow.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Color Theme',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: colorScheme.onSurfaceVariant,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children: themeNames.entries.map((entry) {
//               return _buildThemeOption(
//                 context,
//                 entry.key,
//                 entry.value,
//                 entry.key == currentTheme,
//                 () => onThemeSelected!(entry.key),
//                 colorScheme,
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildThemeOption(
//     BuildContext context,
//     String themeKey,
//     String themeName,
//     bool isSelected,
//     VoidCallback onTap,
//     ColorScheme colorScheme,
//   ) {
//     // Get color for theme
//     int colorIndex = 0;
//     switch(themeKey) {
//       case 'pink': colorIndex = 0; break;
//       case 'hotPink': colorIndex = 1; break;
//       case 'deepPink': colorIndex = 2; break;
//       case 'raspberry': colorIndex = 3; break;
//       case 'lightPink': colorIndex = 4; break;
//       case 'babyPink': colorIndex = 5; break;
//       case 'mediumPink': colorIndex = 6; break;
//       case 'vividPink': colorIndex = 7; break;
//       case 'darkPink': colorIndex = 8; break;
//       case 'crimson': colorIndex = 9; break;
//     }
    
//     final color = themeService.availableColorSeeds[colorIndex];
    
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 8.0),
//         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? color : colorScheme.outline.withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 24,
//               height: 24,
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               themeName,
//               style: TextStyle(
//                 color: isSelected ? color : colorScheme.onSurface,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildColorOption(
//     BuildContext context,
//     Color color,
//     bool isSelected,
//     VoidCallback onTap,
//   ) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 48,
//         height: 48,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: isSelected
//                 ? Colors.white
//                 : Colors.transparent,
//             width: 3,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.4),
//               blurRadius: isSelected ? 8 : 4,
//               spreadRadius: isSelected ? 2 : 0,
//             ),
//           ],
//         ),
//         child: isSelected
//             ? const Icon(
//                 Icons.check,
//                 color: Colors.white,
//                 size: 24,
//               )
//             : null,
//       ),
//     );
//   }
// }