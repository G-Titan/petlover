#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching dependencies..."
flutter pub get

echo "🏗️ Building Flutter Web app for production..."
flutter build web --release --base-href "/petlover/"

echo "📂 Copying compiled website to docs/ folder for single-branch deployment..."
# Remove any old docs folder
rm -rf docs

# Copy everything from the compile output to docs
cp -r build/web docs

# Add .nojekyll file so GitHub Pages doesn't block Flutter framework files
touch docs/.nojekyll

echo "✅ Web build copied to 'docs/'!"
echo "👉 To deploy, just run these standard git commands in your terminal:"
echo "   git add docs/"
echo "   git commit -m \"Update live website files\""
echo "   git push origin main"
