# Active Development Plan

## Phase 1: Foundation & Stability (Current)
*Focus: Ensuring the database and core project structure are solid.*
- [x] **Project Analysis**: Scan structure, dependencies, and static analysis.
- [x] **Database Fixes**: Optimize `create_employees_table.sql` (Index/FK).
- [x] **Schema Consistency**: Enforce `company_id` on `assets` and `profiles`.
- [x] **Migration Robustness**: Update `performance_fixes.sql` with self-checks.

## Phase 2: Context & Workflow Optimization (In Progress)
*Focus: Improving the development workflow and AI memory efficiency.*
- [x] **Context Analysis**: Identify what's bloating the chat.
- [x] **Filesystem Setup**: Create `context/` for finding storage.
- [x] **Log Offloading**: Move heavy analysis logs to `context/logs/`.
- [x] **Session Practices**: Adopt file-referencing workflow.

## Phase 3: Application Performance (Completed)
*Focus: Making the Flutter application faster and smoother.*
- [x] **Database Indexing**: Created `phase7_performance_indexing.sql` (mapped to `supabase/migrations/phase7_performance_indexing.sql`).
- [x] **Query Optimization**: Verified `SupabaseService` and `AssetService` (mapped to `lib/services/`).
- [x] **Asset Caching**: Implemented `CachedNetworkImage` in `MyCustodyScreen` and `AssetCard` (mapped to `lib/screens/my_custody_screen.dart`, `lib/widgets/asset_card.dart`).
- [x] **Code Cleanup**: Resolved 27+ lint issues across `lib/`.

## Phase 4: Security & Scalability Refactor (Completed)
*Focus: Secure data access with RLS and optimize backend queries.*
- [x] **RLS Enforcement**: Created `supabase/migrations/phase8_security_hardening.sql`. Enforced tenant isolation on `assets`, `employees`, `maintenance_*`.
- [x] **Service Refactor**: Updated `AssetService` to filter by `company_id` and added `getAssetsStreamForUser`.
- [x] **Client Optimization**: Refactored `MyCustodyScreen` to use server-side filtering via `StreamBuilder`.

## Scratchpad
- Use `context/scratch/` for large tool outputs.
- Checks `performance_fixes.sql` before running migration.
