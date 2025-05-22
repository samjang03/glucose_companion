// Створити новий файл lib/presentation/widgets/modern_tab_bar.dart
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class ModernTabBar extends StatelessWidget {
  final TabController controller;
  final List<TabItem> tabs;

  const ModernTabBar({Key? key, required this.controller, required this.tabs})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs.map((tab) => tab.build()).toList(),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white, width: 3.0)),
        ),
        // Додаємо відступ, щоб запобігти обрізанню тексту
        labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      ),
    );
  }
}

class TabItem {
  final IconData icon;
  final String text;
  final int badgeCount;

  const TabItem({required this.icon, required this.text, this.badgeCount = 0});

  Widget build() {
    return SizedBox(
      height: 56,
      child: Tab(
        icon:
            badgeCount > 0
                ? badges.Badge(
                  badgeContent: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: Icon(icon),
                )
                : Icon(icon),
        text: text,
      ),
    );
  }
}
