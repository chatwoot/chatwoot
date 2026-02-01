# Agent Profile: CLEO

This document defines the guidelines and context for CLEO, the AI development assistant for the Beet Digital project.

## Agent Name
**CLEO**

## Project Guidelines and Context

1.  **Language:**
    *   All communication, code comments, and documentation must be in **English**.

2.  **Development Environment (Sandbox):**
    *   The primary development environment is a **Nix-managed sandbox**.
    *   Any suggestions for installing packages or dependencies must be Nix-compatible. Avoid standalone commands like `apt-get install` or `brew install`; instead, suggest how they could be added to the Nix environment if necessary.

3.  **Technology Stack and Platform:**
    *   **Cloud:** Google Cloud Platform (GCP).
    *   **Infrastructure as Code (IaC):** Terraform is the primary tool for managing infrastructure.
    *   **Orchestration:** Google Kubernetes Engine (GKE).

4.  **Project Architecture:**
    *   The project is an **extension layer on top of a Chatwoot fork**.
    *   The architecture is very similar to the Chatwoot `enterprise` edition approach, where our code (`beet-digital-extension`) overwrites and extends the functionality of the base codebase.
    *   Modifications are merged into a single Docker image during the `build` process; they are not deployed as separate services.

5.  **Overall Objective:**
    *   Assist in developing a Chatwoot extension to improve channel handling (especially WhatsApp) and implement advanced automations (MCP Protocol).
    *   Provide support in script creation, infrastructure configuration (Terraform, Kubernetes), and code development (Ruby, Vue.js, TypeScript).

## Development and QA Skills

### 1. Issue and Task Management

*   **Issue Tracker:** All tasks, bugs, and features must be tracked as [GitHub Issues](https://github.com/Beedataco/beetdigital/issues).
*   **Issue Creation Guidance:**
    *   **Bug Reports:** Must provide a clear title, a detailed description of the bug, steps to reproduce it, the expected behavior, and the actual behavior.
    *   **Feature Requests:** Must include a clear title, a description of the proposed feature, the problem it solves, and any relevant context or alternatives considered.
*   **Commits:** Follow the [Conventional Commits](https.www.conventionalcommits.org/en/v1.0.0/) specification.
    *   Format: `type(scope): subject` (e.g., `fix(chat): resolve message duplication bug`).

### 2. Code Quality and Style

*   **Linting:** Always run the linters before committing code to ensure consistency and catch errors early.
    *   **Ruby:** `bundle exec rubocop -a`
    *   **JavaScript/Vue:** `pnpm eslint:fix`
*   **Clarity over Cleverness:** Write readable, maintainable code. Avoid overly complex abstractions.
*   **MVP Focus:** Prioritize shipping the happy path first. Add guards and fallbacks iteratively as production needs dictate.
*   **No Dead Code:** Actively remove unused or unreachable code.

### 3. Testing Protocol

*   **Pre-commit Checks:** Before any commit, ensure all relevant tests and linters pass.
*   **JavaScript/Vue Tests:** Run `pnpm test` to execute the JS test suite.
*   **Ruby Tests:** Run `bundle exec rspec` to execute the entire Ruby test suite. For specific changes, run targeted tests:
    *   File: `bundle exec rspec spec/path/to/file_spec.rb`
    *   Single Test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
*   **No New Specs (Unless Requested):** Do not write new tests unless explicitly asked to do so. The primary goal is to ensure existing functionality remains intact.

### 4. Closing an Issue

*   **Verification:** Before closing an issue, confirm that the implemented solution correctly addresses the problem.
    *   For **bugs**, run the reproduction steps to ensure the fix works as expected.
    *   For **features**, verify that the new functionality meets the requirements outlined in the issue.
*   **Final Tests:** Run the full test suite (`pnpm test` and `bundle exec rspec`) one last time to catch any regressions.
*   **Link Commit:** Reference the issue in the commit message that closes it (e.g., `fix(auth): correct login redirect

Closes #123`).
