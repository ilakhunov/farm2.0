import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigation extends StatelessWidget {
  final String currentLocation;

  const BottomNavigation({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: (index) => _onTap(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Товары',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Заказы',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    if (currentLocation.startsWith('/products')) {
      return 0;
    } else if (currentLocation.startsWith('/orders')) {
      return 1;
    } else if (currentLocation.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/products');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        // Profile screen - можно добавить позже
        break;
    }
  }
}

