# Hamburger Menu Implementation

## Overview

This directory contains a fully-featured hamburger menu implementation for the Amerike MBA 2026 project. The menu integrates seamlessly with the existing BottomNavBar and provides a comprehensive navigation solution with smooth animations.

## Files

### Core Components

1. **`hamburger_menu_provider.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/providers/hamburger_menu_provider.dart`)
   - State management using Riverpod
   - Controls menu visibility and enabled state
   - Admin control functionality
   - User access management

2. **`hamburger_menu_button.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_button.dart`)
   - Animated hamburger menu icon
   - Transforms between hamburger (☰) and close (✕) icons
   - Integrated with provider state

3. **`hamburger_menu_item.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_item.dart`)
   - Reusable menu item widget
   - Staggered animation support
   - Selected state highlighting
   - Danger state for actions like logout

4. **`hamburger_menu_header.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_header.dart`)
   - User information display
   - Avatar with initials
   - Role badge with color coding
   - Balance display card

5. **`hamburger_menu_footer.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_footer.dart`)
   - App name display
   - Version information
   - Consistent styling

6. **`hamburger_menu_drawer.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_drawer.dart`)
   - Main drawer container
   - Slide and fade animations
   - Overlay with tap-to-close
   - Swipe-to-close gesture
   - Menu items list
   - Logout confirmation dialog

### Supporting Files

7. **`menu_widgets.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/menu_widgets.dart`)
   - Export file for easy imports

8. **`hamburger_menu_example.dart`** (`/Users/raxgomez/Documents/MBA/Tania/lib/presentation/widgets/menu/hamburger_menu_example.dart`)
   - Complete integration example
   - Usage documentation
   - Admin control examples

## Features

### ✨ Animations
- Smooth slide-in from left (300ms)
- Fade-in overlay effect
- Staggered menu item animations (50ms delay per item)
- Icon transition animation (hamburger ↔ close)
- Haptic feedback on tap

### 📱 Responsive Design
- Adapts to different screen sizes
- 75% width on mobile, full width available on larger screens
- Touch-friendly tap targets (minimum 44px)
- Swipe gestures for closing

### 🎨 Design
- Dark mode support using existing `AppColors`
- Gradient accents (primaryAccent → secondaryAccent)
- Role-based color coding
- Consistent with app theme
- Glassmorphism effects on overlay

### 🔧 Functionality
- Admin control to enable/disable menu
- User authentication check
- Automatic route highlighting
- Logout confirmation dialog
- Integration with existing `BottomNavBar`
- Programmatic control (open/close/toggle)

### 🛡️ Error Handling
- Safe null handling for user data
- Graceful fallbacks when routes don't exist
- Confirmation dialogs for destructive actions

## Menu Items

The menu includes the following items:

1. **Inicio** (`/`) - Home screen
2. **Temas/Categorías** (`/themes`) - Browse by category
3. **Mis Inversiones** (`/investments`) - User's investments
4. **Ranking** (`/ranking`) - Leaderboard
5. **Perfil** (`/profile`) - User profile
6. **Historial de Inversiones** (`/investment-history`) - Investment history
7. **Ayuda** (`/help`) - Help and instructions
8. **Cerrar Sesión** - Logout (with confirmation)

## Integration Guide

### Step 1: Import Required Files

```dart
import 'package:your_app/presentation/widgets/menu/menu_widgets.dart';
import 'package:your_app/presentation/providers/hamburger_menu_provider.dart';
import 'package:your_app/presentation/providers/auth_provider.dart';
```

### Step 2: Wrap Screen Content

```dart
@override
Widget build(BuildContext context) {
  return HamburgerMenuDrawer(
    child: Scaffold(
      appBar: AppBar(
        leading: const HamburgerMenuButton(),
        title: const Text('Your Title'),
      ),
      body: YourContent(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    ),
  );
}
```

### Step 3: Initialize with User Data

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final user = ref.read(authProvider).value;
    ref.read(hamburger_menu_provider.notifier).updateUser(user);
  });
}
```

### Step 4: Admin Control (Optional)

```dart
// Disable menu
ref.read(hamburger_menu_provider.notifier).setMenuEnabled(false);

// Enable menu
ref.read(hamburger_menu_provider.notifier).setMenuEnabled(true);
```

## Testing

### Manual Testing Steps

1. **Open Menu**
   - Tap hamburger button in AppBar
   - Verify menu slides in from left
   - Check overlay appears
   - Confirm icon animates to close (✕)

2. **Close Menu**
   - Tap close button
   - Tap overlay
   - Swipe right to close
   - Verify smooth animation

3. **Navigate Items**
   - Tap each menu item
   - Verify navigation to correct route
   - Check selected state highlighting
   - Confirm menu closes after selection

4. **User Display**
   - Verify user name displays correctly
   - Check avatar shows initials
   - Confirm role badge appears
   - Validate balance display

5. **Logout**
   - Tap "Cerrar Sesión"
   - Verify confirmation dialog appears
   - Test cancel action
   - Test confirm action (should navigate to login)

6. **Admin Control**
   - Disable menu via provider
   - Verify hamburger button disappears
   - Re-enable menu
   - Verify button reappears

7. **Responsive Testing**
   - Test on mobile (≤ 600px width)
   - Test on tablet (600px - 1200px)
   - Test on desktop (> 1200px)
   - Verify animations remain smooth

8. **Edge Cases**
   - Open menu, then rotate device
   - Open menu with no user logged in
   - Navigate to non-existent route
   - Rapidly tap menu button

### Automated Testing

Create test file: `test/presentation/widgets/menu/hamburger_menu_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amerike_mba/presentation/widgets/menu/menu_widgets.dart';
import 'package:amerike_mba/presentation/providers/hamburger_menu_provider.dart';

void main() {
  testWidgets('HamburgerMenuButton toggles menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: const HamburgerMenuButton(),
            ),
          ),
        ),
      ),
    );

    final button = find.byType(HamburgerMenuButton);
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    // Verify menu opened
    // Add your assertions here
  });

  // Add more tests...
}
```

## Customization

### Change Menu Items

Edit `hamburger_menu_drawer.dart`:

```dart
List<MenuItemData> _getMenuItems(BuildContext context) {
  return [
    MenuItemData(
      icon: Icons.your_icon,
      label: 'Your Label',
      route: '/your-route',
    ),
    // Add more items...
  ];
}
```

### Modify Animations

Edit animation durations in `hamburger_menu_drawer.dart`:

```dart
_animationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 300), // Change this
);
```

### Change Colors

All colors use `AppColors` constants. Edit them in:
`/Users/raxgomez/Documents/MBA/Tania/lib/core/constants/app_colors.dart`

### Adjust Menu Width

In `hamburger_menu_drawer.dart`:

```dart
SizedBox(
  width: MediaQuery.of(context).size.width * 0.75, // Change 0.75 to desired ratio
  // ...
)
```

## Troubleshooting

### Menu doesn't appear
- Verify user is authenticated
- Check if menu is enabled: `ref.watch(hamburgerMenuProvider).isEnabled`
- Ensure `HamburgerMenuButton` is in AppBar leading position

### Animations are choppy
- Check device performance
- Reduce animation duration
- Test on physical device (not emulator)

### Navigation doesn't work
- Verify routes are defined in `routes.dart`
- Check route names match exactly
- Ensure route names start with `/`

### User info not showing
- Verify user data is loaded in `authProvider`
- Check `updateUser()` is called after login
- Ensure user data is not null

## Performance

### Optimizations Implemented
- Const constructors where possible
- Efficient animation controllers
- Lazy loading of menu items
- Proper widget disposal
- Minimal rebuilds using Riverpod

### Performance Tips
- Keep menu items under 15 for optimal performance
- Use lightweight icons
- Avoid complex widgets in menu items
- Test on target devices

## Accessibility

### Features
- Semantic labels on all interactive elements
- Sufficient color contrast (WCAG AA compliant)
- Touch targets ≥ 44px
- Keyboard navigation support
- Screen reader compatible

### Improvements
- Add more descriptive labels
- Implement focus management
- Add sound feedback options

## Future Enhancements

- [ ] Search functionality in menu
- [ ] Recently viewed items
- [ ] Customizable menu order
- [ ] Favorites section
- [ ] Notifications badge
- [ ] Dark/Light mode toggle
- [ ] Language selector
- [ ] Settings quick access
- [ ] Keyboard shortcuts
- [ ] Voice command integration

## Support

For issues or questions:
1. Check this README
2. Review `hamburger_menu_example.dart`
3. Examine existing implementations
4. Contact the development team

## Version History

- **v1.0.0** (2026-05-12)
  - Initial implementation
  - Core features complete
  - Full integration with BottomNavBar
  - Admin control functionality
  - Comprehensive animations
