#!/bin/bash
set -e

TYPE=$1

read -p "Releasing new $TYPE version. Does this sound right? [y/n] " confirmation

if [ $confirmation != "y" ]; then
  echo "Exiting..."
  exit
fi

echo "Bumping package.json version..."
npm version $TYPE

# Version key/value should be on it's own line
# https://gist.github.com/DarrenN/8c6a5b969481725a4413
PACKAGE_VERSION=$(node -pe "require('./package.json').version")

echo "Version bumped to $PACKAGE_VERSION"

echo "Building distribution file..."
yarn build

echo "Publishing to npm..."
yarn publish --new-version $PACKAGE_VERSION

echo "Committing changes..."
git add package.json dist/

git commit -m "chore(release): release $PACKAGE_VERSION"

echo "Pushing changes to master..."
git push origin master