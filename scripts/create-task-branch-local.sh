#!/usr/bin/env bash
# Usage: ./scripts/create-task-branch-local.sh T017 "manual entry" [--commit]
set -euo pipefail

# Arguments
TASK_ID=""
DESC=""
DO_COMMIT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      DO_COMMIT=1
      shift
      ;;
    -*|--*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      if [ -z "$TASK_ID" ]; then
        TASK_ID="$1"
      elif [ -z "$DESC" ]; then
        DESC="$1"
      else
        echo "Unexpected extra argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$TASK_ID" ] || [ -z "$DESC" ]; then
  echo "Usage: $0 T### \"short description\" [--commit]"
  echo "By default this creates the local branch and DOES NOT commit any changes."
  exit 1
fi

# normalize desc to kebab-case
SLUG=$(printf "%s" "$DESC" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
BRANCH="feature/${TASK_ID}-${SLUG}"

echo "Creating local branch: $BRANCH"
git fetch origin --prune || true
git checkout -b "$BRANCH"

if [ "$DO_COMMIT" -eq 1 ]; then
  # If requested, create an initial commit. Prefer empty commit when there are no changes.
  if git diff --quiet && git diff --cached --quiet; then
    git commit --allow-empty -m "chore(${TASK_ID}): start ${DESC}"
  else
    git add -A
    git commit -m "chore(${TASK_ID}): start ${DESC}" || echo "No changes to commit"
  fi
  echo "Branch $BRANCH created locally and initial commit was made."
else
  echo "Branch $BRANCH created locally. No commits were made."
  echo "Review your changes, then run:"
  echo "  git add -A"
  echo "  git commit -m \"feat(${TASK_ID}): implement ${DESC}\""
fi

echo "When ready to push: git push --set-upstream origin $BRANCH"
