enum UserRole {
  cashier,
  inventoryUser,
  manager,
  supervisor,
  admin,
}

enum Permission {
  dashboard,
  pos,
  ownSales,
  cashierSession,
  cashierEod,
  products,
  ingredients,
  recipes,
  receiving,
  approveReceiving,
  adjustments,
  approveAdjustments,
  inventoryReports,
  cashierReports,
  costing,
  manageUsers,
  settings,
}

final Map<UserRole, Set<Permission>> rolePermissions = {
  UserRole.cashier: {
    Permission.dashboard,
    Permission.pos,
    Permission.ownSales,
    Permission.cashierSession,
    Permission.cashierEod,
  },
  UserRole.inventoryUser: {
    Permission.dashboard,
    Permission.products,
    Permission.ingredients,
    Permission.receiving,
    Permission.adjustments,
    Permission.inventoryReports,
  },
  UserRole.manager: {
    Permission.dashboard,
    Permission.pos,
    Permission.products,
    Permission.ingredients,
    Permission.recipes,
    Permission.receiving,
    Permission.approveReceiving,
    Permission.adjustments,
    Permission.approveAdjustments,
    Permission.inventoryReports,
    Permission.cashierReports,
    Permission.costing,
  },
  UserRole.supervisor: {
    Permission.dashboard,
    Permission.pos,
    Permission.products,
    Permission.ingredients,
    Permission.recipes,
    Permission.receiving,
    Permission.approveReceiving,
    Permission.adjustments,
    Permission.approveAdjustments,
    Permission.inventoryReports,
    Permission.cashierReports,
    Permission.costing,
  },
  UserRole.admin: Permission.values.toSet(),
};

bool hasPermission(
  UserRole role,
  Permission permission,
) {
  return rolePermissions[role]?.contains(permission) ?? false;
}

String roleToStorage(UserRole role) {
  return switch (role) {
    UserRole.cashier => 'CASHIER',
    UserRole.inventoryUser => 'INVENTORY_USER',
    UserRole.manager => 'MANAGER',
    UserRole.supervisor => 'SUPERVISOR',
    UserRole.admin => 'ADMIN',
  };
}

UserRole roleFromStorage(String value) {
  return switch (value.trim().toUpperCase()) {
    'CASHIER' => UserRole.cashier,
    'INVENTORY_USER' => UserRole.inventoryUser,
    'MANAGER' => UserRole.manager,
    'SUPERVISOR' => UserRole.supervisor,
    'ADMIN' => UserRole.admin,
    _ => throw FormatException(
        'Unsupported Kitchen Sync role: $value',
      ),
  };
}
