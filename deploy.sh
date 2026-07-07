#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching dependencies..."
flutter pub get

echo "🏗️ Building Flutter Web app for production..."
flutter build web --release --base-href "/petlover/"

# Save the parent repository remote URL
REMOTE_URL=$(git remote get-url origin)

echo "📂 Navigating to build output..."
cd build/web

echo "🚀 Initializing temporary Git repo for deployment..."
git init
git checkout -b main
git add .
git commit -m "Deploy production assets to gh-pages"

echo "📤 Force pushing compiled assets to origin/gh-pages..."
git push --force "$REMOTE_URL" main:gh-pages

echo "✅ Deployment push completed successfully!"
