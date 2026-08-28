enum UserRole {
  cashier,
  inventoryUser,
  manager,
  supervisor,
  admin,
}

enum Permission {
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
    Permission.pos,
    Permission.ownSales,
    Permission.cashierSession,
    Permission.cashierEod,
  },
  UserRole.inventoryUser: {
    Permission.products,
    Permission.ingredients,
    Permission.receiving,
    Permission.adjustments,
    Permission.inventoryReports,
  },
  UserRole.manager: {
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
