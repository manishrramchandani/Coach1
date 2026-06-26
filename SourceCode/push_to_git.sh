#!/usr/bin/env bash
# CALLOUT: Run THIS yourself — it pushes SourceCode to your Coach1 repo using YOUR
# GitHub credentials. (Claude can't and shouldn't handle your GitHub auth.)
# Usage: ./push_to_git.sh https://github.com/<you>/Coach1.git
set -e
REPO="${1:?Pass your repo URL, e.g. https://github.com/you/Coach1.git}"
git init
git add .
git commit -m "feat: CoachOS Phase 1 MVP iOS client + QA validation (SourceCode)"
git branch -M main
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git push -u origin main
echo "Pushed to $REPO"
