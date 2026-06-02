import 'package:flutter/material.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/app_background.dart';
import 'home_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _ordersResetNonce = 0;
  int _profileResetNonce = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    _syncHomeBackground();
  }

  @override
  void dispose() {
    RouteTracker.isHomeTabActive.value = false;
    super.dispose();
  }

  void _syncHomeBackground() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RouteTracker.isHomeTabActive.value = _currentIndex == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(key: _homeKey),
      OrdersPage(resetNonce: _ordersResetNonce),
      ProfilePage(resetNonce: _profileResetNonce),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 0 && _currentIndex == 0) {
                  _homeKey.currentState?.scrollToTop();
                  return;
                }
                setState(() {
                  _currentIndex = index;
                  if (index == 1) _ordersResetNonce++;
                  if (index == 2) _profileResetNonce++;
                });
                _syncHomeBackground();
                if (index == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _homeKey.currentState?.scrollToTop();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
