# Skill: Audit & QA

This document outlines the procedures for testing, quality assurance, and interacting with GitHub Issues.

## 1. GitHub Issue Management

- **Primary Tool:** All issue management must be performed using the GitHub CLI (`gh`).
- **Repository Config:** Before running commands, ensure your local environment is configured to default to the correct repository:
  ```bash
  gh repo set-default Beedataco/beetdigital
  ```

### Finding and Viewing an Issue

To prevent API errors related to deprecated fields (like `projectCards`), always specify the exact fields you need using the `--json` flag. 

- **View a specific issue:**
  ```bash
  gh issue view <ISSUE_NUMBER> --json number,title,body,state,author,assignees,labels,url
  ```

- **List open issues:**
  ```bash
  gh issue list --json number,title,author,state
  ```

### Issue and Commit Workflow

- **Commits:** Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification (`type(scope): subject`).
- **Closing an Issue:** Reference the issue in the commit message that resolves it.
  ```
  fix(billing): correct invoice calculation

  Closes #456
  ```

## 2. Code Quality and Style

- **Linting:** Run linters before every commit.
    - **Ruby:** `bundle exec rubocop -a`
    - **JavaScript/Vue:** `pnpm eslint:fix`
- **Guiding Principles:** Prioritize clarity over cleverness, focus on the MVP, and remove dead code.

## 3. Testing Protocol

- **Pre-commit:** All tests and linters must pass.
- **Test Commands:**
    - **JS/Vue:** `pnpm test`
    - **Ruby (all):** `bundle exec rspec`
    - **Ruby (file):** `bundle exec rspec spec/path/to/file_spec.rb`
    - **Ruby (single):** `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **New Specs:** Do not write new tests unless explicitly requested.
