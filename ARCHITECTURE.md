# Kitchen Sync Phase 1 Architecture

## Source of truth
UI reads SQLite. Every business write is committed locally first. The same SQLite transaction writes the business row, movement/audit rows, and an idempotent sync queue item. Firebase is a synchronized cloud projection, not the operational dependency.

## Migration strategy
Versioned, append-only migrations. Migration 1 creates the foundation. Each future release adds `migration_vN.dart`; `onUpgrade` applies versions sequentially inside a transaction. Never edit an already released migration. Back up before destructive migrations and use create-copy-verify-rename for table rebuilds.

## Firebase RTDB schema
Top-level nodes: users, stores, products, ingredients, recipes, inventory, inventoryMovements, ingredientInventory, ingredientMovements, receiving, adjustments, sales, saleItems, payments, cashierSessions, cashierReports, costing, auditLogs, settings, devices. Records use UUID keys. Store-scoped records contain storeId. Movements and finalized sales are append-only.

## Authentication and store access
Firebase Auth proves identity. `/users/{uid}` supplies active, role, and storeId. The app denies access if profile is absent/inactive. UI permission checks improve UX; repository checks and RTDB rules enforce authorization. Store ID is injected from the signed-in profile, never trusted from editable UI.

## Roles
Cashier: POS, own sales/session/EOD only. Inventory user: products, ingredients, receiving, adjustments, stock and inventory reports. Manager/Supervisor: monitoring, approvals, recipes, costing and operational reports. Admin: all modules, users and settings. Cost visibility remains an explicit permission.

## Cloudinary
The app uses a restricted unsigned preset for development only, constrained to images, size and `kitchen-sync/products`. Production should request server-signed uploads from a trusted backend. Store only secure_url and public_id in SQLite/Firebase. Never ship API secret.

## Sync and conflict handling
Queue keys are unique per entity, entity ID and operation. Push checks the UUID at the destination before creating. Append-only inventory movements prevent last-writer stock replacement. A cloud aggregate may be rebuilt from movements. Master-data conflicts use version/updatedAt plus an explicit conflict record; approvals and finalized records are immutable. Never deduct stock during cloud replay because local completion already created the movement.

## Responsive Android
Below 720 logical pixels: bottom navigation and one-pane task flows. At/above 720: NavigationRail and adaptive two-pane content. Controls target at least 48 logical pixels. Orientation changes preserve selected module and local draft state.

## Roadmap
1 Foundation. 2 Master data. 3 Recipes. 4 Inventory. 5 POS. 6 Consumption. 7 Cashier. 8 Costing. 9 Dashboards. 10 Sync hardening. 11 Security and release hardening.
