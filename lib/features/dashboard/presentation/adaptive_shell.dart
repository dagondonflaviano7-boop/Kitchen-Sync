import 'package:flutter/material.dart';
import 'package:kitchen_sync/core/connectivity/connectivity_service.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    _ModulePlaceholder(
      title: 'Dashboard',
      icon: Icons.dashboard,
    ),
    _ModulePlaceholder(
      title: 'POS',
      icon: Icons.point_of_sale,
    ),
    _ModulePlaceholder(
      title: 'Inventory',
      icon: Icons.inventory_2,
    ),
    _ModulePlaceholder(
      title: 'Reports',
      icon: Icons.bar_chart,
    ),
    _ModulePlaceholder(
      title: 'More',
      icon: Icons.more_horiz,
    ),
  ];

  void selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onlineStream,
      initialData: false,
      builder: (context, snapshot) {
        final bool online = snapshot.data ?? false;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool tablet =
                constraints.maxWidth >= AppConstants.tabletBreakpoint;

            return Scaffold(
              appBar: AppBar(
                title: const Text('KITCHEN SYNC'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Chip(
                      avatar: Icon(
                        online ? Icons.cloud_done : Icons.cloud_off,
                        size: 18,
                      ),
                      label: Text(online ? 'Online' : 'Offline'),
                    ),
                  ),
                ],
              ),
              body: tablet
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: selectPage,
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.dashboard),
                              label: Text('Dashboard'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.point_of_sale),
                              label: Text('POS'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.inventory_2),
                              label: Text('Inventory'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.bar_chart),
                              label: Text('Reports'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.more_horiz),
                              label: Text('More'),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: pages[selectedIndex],
                        ),
                      ],
                    )
                  : pages[selectedIndex],
              bottomNavigationBar: tablet
                  ? null
                  : NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: selectPage,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.point_of_sale),
                          label: 'POS',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.inventory_2),
                          label: 'Inventory',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bar_chart),
                          label: 'Reports',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu),
                          label: 'More',
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ModulePlaceholder({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            '$title foundation ready',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
