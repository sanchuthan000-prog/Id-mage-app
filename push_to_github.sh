#!/usr/bin/env bash
# Script to push this project to GitHub and trigger APK build

echo "======================================"
echo "  FF ID Manager - GitHub Push Script"
echo "======================================"

if [ -z "$1" ]; then
  echo ""
  echo "Usage: bash push_to_github.sh <your-github-username>"
  echo ""
  echo "Example: bash push_to_github.sh johndoe"
  echo ""
  echo "Prerequisites:"
  echo "  1. Create a GitHub account at https://github.com"
  echo "  2. Create a new EMPTY repository named 'ff_id_manager'"
  echo "     Go to: https://github.com/new"
  echo "  3. Have git installed: pkg install git"
  echo "  4. Configure git: git config --global user.email 'you@email.com'"
  echo "                    git config --global user.name 'Your Name'"
  echo ""
  exit 1
fi

USERNAME=$1
REPO="ff_id_manager"
REPO_URL="https://github.com/$USERNAME/$REPO.git"

echo ""
echo "GitHub Username: $USERNAME"
echo "Repository URL: $REPO_URL"
echo ""

# Initialize git if not already
if [ ! -d ".git" ]; then
  echo "Initializing git repository..."
  git init
  git branch -M main
fi

# Configure remote
git remote remove origin 2>/dev/null || true
git remote add origin $REPO_URL

echo "Adding all files..."
git add -A

echo "Creating commit..."
git commit -m "Initial commit: FF ID Manager Flutter app

Complete Free Fire ID Sale Management application:
- Dashboard with financial stats
- FF ID management with images
- Seller & Buyer management
- Sale system with profit calculation
- DEO management
- Money transactions
- Reports with PDF/Excel export
- WhatsApp integration
- SQLite local database
- Dark gaming theme"

echo ""
echo "Pushing to GitHub..."
echo "(You will be prompted for your GitHub username and Personal Access Token)"
echo ""
echo "To create a Personal Access Token:"
echo "  1. Go to https://github.com/settings/tokens"
echo "  2. Click 'Generate new token (classic)'"
echo "  3. Select 'repo' scope"
echo "  4. Copy the token and use it as your password below"
echo ""

git push -u origin main

if [ $? -eq 0 ]; then
  echo ""
  echo "======================================"
  echo "SUCCESS! Code pushed to GitHub!"
  echo "======================================"
  echo ""
  echo "Next steps:"
  echo "1. Go to: https://github.com/$USERNAME/$REPO/actions"
  echo "2. Watch the build (takes about 5-10 minutes)"
  echo "3. Download APK from: https://github.com/$USERNAME/$REPO/releases"
  echo ""
else
  echo ""
  echo "Push failed. Make sure:"
  echo "  1. Repository '$REPO' exists on GitHub"
  echo "  2. Username and token are correct"
  echo ""
fi
