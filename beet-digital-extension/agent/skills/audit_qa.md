# Skill: Development & QA

This document outlines the procedures for development, testing, and quality assurance.

## 1. Issue and Task Management

*   **Issue Tracker:** [GitHub Issues](https://github.com/Beedataco/beetdigital/issues)
*   **Bug Reports:** Must include a clear title, detailed reproduction steps, expected behavior, and actual behavior.
*   **Feature Requests:** Must include a clear title, a description of the feature, the problem it solves, and relevant context.
*   **Commits:** Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) (`type(scope): subject`).

## 2. Code Quality and Style

*   **Linting:** Run linters before committing.
    *   **Ruby:** `bundle exec rubocop -a`
    *   **JavaScript/Vue:** `pnpm eslint:fix`
*   **Guiding Principles:** Prioritize clarity over cleverness, focus on the MVP, and remove dead code.

## 3. Testing Protocol

*   **Pre-commit:** All tests and linters must pass before any commit.
*   **Test Commands:**
    *   **JS/Vue:** `pnpm test`
    *   **Ruby (all):** `bundle exec rspec`
    *   **Ruby (file):** `bundle exec rspec spec/path/to/file_spec.rb`
    *   **Ruby (single):** `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
*   **New Specs:** Do not write new tests unless explicitly requested.

## 4. Closing an Issue

*   **Verification:** Confirm the solution correctly addresses the issue by testing the happy path and any relevant edge cases.
*   **Final Tests:** Run the full test suite one last time to catch regressions.
*   **Link Commit:** Reference the issue in the final commit message (e.g., `Closes #123`).
