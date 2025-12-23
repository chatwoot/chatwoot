---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(bundle install)
description: Bump version, update changelog and commit changes
---

You need to bump the version of the ruby gem and update the CHANGELOG. We need a #$ARGUMENTS version bump.

The types of version jumps are

- patch: Increment the third number in the version number.
- minor: Increment the second number in the version number.
- major: Increment the first number in the version number.

To bump up the version, follow these steps:

1. Update the version number in the `lib/agents/version.rb` file.
2. Run `bundle install` to ensure the lock file picks up the new version.

To update the changelog.

1. Find the changelog file in `CHANGELOG.md`.
2. Add a new section for the new version number.
3. List the changes made in the new version.

We follow the `keepachangelog.com` guide for writing these changelogs and follow semantic versioning.

Here's what makes a good changelog.

**Guiding Principles**
- Changelogs are for humans, not machines.
- There should be an entry for every single version.
- The same types of changes should be grouped.
- Versions and sections should be linkable.
- The latest version comes first.

**Types of changes**
`Added` for new features.
`Changed` for changes in existing functionality.
`Deprecated` for soon-to-be removed features.
`Removed` for now removed features.
`Fixed` for any bug fixes.
`Security` in case of vulnerabilities

Once done, commit the changes with a message like "chore: bump version to <new-version>".
