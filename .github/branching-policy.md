Branching Policy — Expense Tracker

Goal
- Each task (T###) must be implemented on its own branch so work can be rolled back per-task.

Branch naming
- feature/T{TASK_ID}-{short-kebab-desc}
  - Example: feature/T017-manual-entry

Local vs remote workflow
- By default, create branches locally for development and testing.
- Push branch to remote only when ready for review.
- Use `./scripts/create-task-branch-local.sh` to create a correctly named branch locally without pushing.
- When ready to share: `git push --set-upstream origin feature/T017-manual-entry`

Workflow (recommended)
1. Create a local branch for the task:
   ./scripts/create-task-branch-local.sh T017 "manual entry"
2. Implement & test the task on that branch.
3. Commit frequently with scoped messages:
   feat(T017): add manual entry form
4. Push only when ready for PR and review.

Rules
- Never commit unrelated tasks to the same branch.
- Keep commits focused and testable (TDD where applicable).
- Update `specs/001-sms-scanning-to/tasks.md` to mark task status and link branch name.

Automation
- Use `./scripts/create-task-branch-local.sh` to create correctly named local branches.
- By default the script will NOT make commits. Use the `--commit` flag to create an initial commit automatically.

Examples
- Create a branch locally without committing:
   ./scripts/create-task-branch-local.sh T017 "manual entry"
- Create a branch and make an initial empty commit:
   ./scripts/create-task-branch-local.sh T017 "manual entry" --commit

Notes
- This file documents the local-branch-first workflow enforced by the project. Remote push is an explicit, manual step.
