# Expense Tracker — Mobile Constitution

## Core Principles

### Mobile-first UX
Every design and implementation choice must prioritize a fast, clear, and accessible mobile experience. Screens should be focused, input minimal, and flows forgiving.

### Offline-first & Reliable Sync
Local storage and conservative caching are required. App must work while offline and reconcile with the backend when connectivity returns. Conflicts must be handled deterministically and surfaced to the user when necessary.

### Performance & Battery Consciousness
Aim for fast cold-start and smooth UI. Limit background work and network usage. Prefer lazy-loading and batching to reduce CPU/network/battery impact.

### Observability
Ship minimal structured logging, error/crash reporting, and usage metrics that respect privacy. Use these signals to prioritize fixes and UX improvements.

## Constraints

- Platforms: iOS 13+ and Android API 21+ (document if broader support is required).
- Implementation: native or cross-platform approaches are allowed; the chosen approach must be documented in the README and justified.
- Dependencies: keep third-party libraries minimal, vetted for licenses and security, and pinned in dependency manifests.
- Data storage: use a single local data source (SQLite/Realm/room) as the source-of-truth; sync layer is explicit and versioned.

## Governance

This constitution is the default guide for mobile work in this repository. Changes must be proposed via a documented PR and approved by project maintainers. Emergency exceptions must be recorded in the PR that introduces them.

**Version**: 1.0 | **Ratified**: 2025-09-25 | **Last Amended**: 2025-09-25
