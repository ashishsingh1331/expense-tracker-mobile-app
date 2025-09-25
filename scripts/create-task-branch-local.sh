#!/usr/bin/env bash
# Usage: ./scripts/create-task-branch-local.sh T017 "manual entry"
set -e

TASK_ID="$1"
DESC="$2"

if [ -z "$TASK_ID" ] || [ -z "$DESC" ]; then
  echo "Usage: $0 T### \"short description\""
  exit 1
fi

# normalize desc to kebab-case
SLUG=$(echo "$DESC" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
BRANCH="feature/${TASK_ID}-${SLUG}"

echo "Creating local branch: $BRANCH"
git fetch origin --prune || true
git checkout -b "$BRANCH"

# if no staged changes and no working tree changes, create an empty commit to mark start
if git diff --quiet && git diff --cached --quiet; then
  git commit --allow-empty -m "chore(${TASK_ID}): start ${DESC}"
else
  git add -A
  git commit -m "chore(${TASK_ID}): start ${DESC}" || echo "No changes to commit"
fi

echo "Branch $BRANCH created locally. Not pushed to remote."
echo "When ready to push: git push --set-upstream origin $BRANCH"
