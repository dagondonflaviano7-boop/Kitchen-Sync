import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitchen_sync/core/connectivity/connectivity_service.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/core/permissions/role.dart';
import 'package:kitchen_sync/data/repositories/local_session_repository.dart';

class AdaptiveShell extends StatefulWidget {
  final LocalSessionContext sessionContext;

  const AdaptiveShell({
    super.key,
    required this.sessionContext,
  });

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int selectedIndex = 0;
  bool signingOut = false;

  UserRole get role => widget.sessionContext.profile.role;

  List<_ShellDestination> get destinations {
    final List<_ShellDestination> all = <_ShellDestination>[
      const _ShellDestination(
        label: 'Home',
        railLabel: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        permission: Permission.dashboard,
        page: _ModulePlaceholder(
          title: 'Dashboard',
          icon: Icons.dashboard,
        ),
      ),
      const _ShellDestination(
        label: 'POS',
        railLabel: 'POS',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        permission: Permission.pos,
        page: _ModulePlaceholder(
          title: 'POS',
          icon: Icons.point_of_sale,
        ),
      ),
      const _ShellDestination(
        label: 'Inventory',
        railLabel: 'Inventory',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        permission: Permission.products,
        page: _ModulePlaceholder(
          title: 'Inventory',
          icon: Icons.inventory_2,
        ),
      ),
      const _ShellDestination(
        label: 'Reports',
        railLabel: 'Reports',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        permission: Permission.inventoryReports,
        alternatePermission: Permission.cashierReports,
        page: _ModulePlaceholder(
          title: 'Reports',
          icon: Icons.bar_chart,
        ),
      ),
      const _ShellDestination(
        label: 'More',
        railLabel: 'More',
        icon: Icons.more_horiz,
        selectedIcon: Icons.more_horiz,
        permission: Permission.settings,
        alternatePermission: Permission.manageUsers,
        page: _ModulePlaceholder(
          title: 'More',
          icon: Icons.more_horiz,
        ),
      ),
    ];

    return all.where((destination) {
      final bool primaryAllowed = hasPermission(
        role,
        destination.permission,
      );

      final Permission? alternate = destination.alternatePermission;

      final bool alternateAllowed =
          alternate != null && hasPermission(role, alternate);

      return primaryAllowed || alternateAllowed;
    }).toList(growable: false);
  }

  void selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> signOut() async {
    if (signingOut) {
      return;
    }

    setState(() {
      signingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to sign out: $error',
          ),
        ),
      );

      setState(() {
        signingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_ShellDestination> available = destinations;

    final int safeIndex = selectedIndex >= available.length ? 0 : selectedIndex;

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
                title: const Text(
                  'KITCHEN SYNC',
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    child: Chip(
                      avatar: Icon(
                        online ? Icons.cloud_done : Icons.cloud_off,
                        size: 18,
                        color: online
                            ? const Color(0xFF2E6B4F)
                            : Theme.of(context).colorScheme.error,
                      ),
                      label: Text(
                        online ? 'Online' : 'Offline',
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Account and store',
                    onSelected: (value) {
                      if (value == 'logout') {
                        signOut();
                      }
                    },
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          enabled: false,
                          child: _AccountSummary(
                            sessionContext: widget.sessionContext,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'logout',
                          enabled: !signingOut,
                          child: Row(
                            children: [
                              if (signingOut)
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.logout,
                                  size: 20,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                signingOut ? 'Signing out...' : 'Logout',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                    icon: const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFFE8F1EC),
                      child: Icon(
                        Icons.person_outline,
                        size: 21,
                        color: Color(0xFF2E6B4F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: tablet
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: safeIndex,
                          onDestinationSelected: selectPage,
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: _StoreIdentityCard(
                              sessionContext: widget.sessionContext,
                              compact: true,
                            ),
                          ),
                          destinations: available
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: Icon(
                                    destination.icon,
                                  ),
                                  selectedIcon: Icon(
                                    destination.selectedIcon,
                                  ),
                                  label: Text(
                                    destination.railLabel,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Column(
                            children: [
                              _StoreIdentityCard(
                                sessionContext: widget.sessionContext,
                              ),
                              Expanded(
                                child: available[safeIndex].page,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _StoreIdentityCard(
                          sessionContext: widget.sessionContext,
                        ),
                        Expanded(
                          child: available[safeIndex].page,
                        ),
                      ],
                    ),
              bottomNavigationBar: tablet
                  ? null
                  : NavigationBar(
                      selectedIndex: safeIndex,
                      onDestinationSelected: selectPage,
                      destinations: available
                          .map(
                            (destination) => NavigationDestination(
                              icon: Icon(
                                destination.icon,
                              ),
                              selectedIcon: Icon(
                                destination.selectedIcon,
                              ),
                              label: destination.label,
                            ),
                          )
                          .toList(growable: false),
                    ),
            );
          },
        );
      },
    );
  }
}

class _ShellDestination {
  final String label;
  final String railLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Permission permission;
  final Permission? alternatePermission;
  final Widget page;

  const _ShellDestination({
    required this.label,
    required this.railLabel,
    required this.icon,
    required this.selectedIcon,
    required this.permission,
    required this.page,
    this.alternatePermission,
  });
}

class _StoreIdentityCard extends StatelessWidget {
  final LocalSessionContext sessionContext;
  final bool compact;

  const _StoreIdentityCard({
    required this.sessionContext,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final profile = sessionContext.profile;
    final store = sessionContext.store;

    if (compact) {
      return Tooltip(
        message: '${profile.name}\n${store.storeCode}\n${store.storeName}',
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE8F1EC),
          child: Text(
            profile.name.isEmpty
                ? '?'
                : profile.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF2E6B4F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F1),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFDBE5DD),
          ),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE8F1EC),
            child: Icon(
              Icons.storefront_outlined,
              color: Color(0xFF2E6B4F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF183027),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.storeCode} • '
                  '${profile.name} • '
                  '${roleToStorage(profile.role)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64756B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  final LocalSessionContext sessionContext;

  const _AccountSummary({
    required this.sessionContext,
  });

  @override
  Widget build(BuildContext context) {
    final profile = sessionContext.profile;
    final store = sessionContext.store;

    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.name,
            style: const TextStyle(
              color: Color(0xFF183027),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roleToStorage(profile.role),
            style: const TextStyle(
              color: Color(0xFF2E6B4F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            store.storeCode,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            store.storeName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64756B),
              fontSize: 12,
            ),
          ),
        ],
      ),
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
            color: const Color(0xFF2E6B4F),
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
