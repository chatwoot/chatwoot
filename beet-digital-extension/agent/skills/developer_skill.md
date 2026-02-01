# Skill: Developer

This document outlines the architectural and development guidelines for creating and modifying code within the Beet Digital extension, following a methodology inspired by Chatwoot's own Enterprise development practices.

## 1. Core Principle: The Overlay System

Our project, `beet-digital-extension`, functions as an **overlay** on the core Chatwoot application. This is identical to how Chatwoot's `enterprise` module works.

- **NEVER EDIT THE CORE:** We **never** modify files outside the `beet-digital-extension` directory.
- **MIRROR FOR OVERRIDE:** To modify core functionality, you must create a corresponding file at the exact same path within the `beet-digital-extension` directory. For example, to change `app/services/message_creation_service.rb`, you will create `beet-digital-extension/app/services/message_creation_service.rb`.
- **EXTENSION-ONLY CODE:** New features that do not exist in the core app should be built directly within the `beet-digital-extension` directory, following standard Rails/Vue conventions.

## 2. The Development Workflow: A Practical Checklist

Follow these steps for any change to core logic to prevent duplicate work and ensure stability.

### Step 1: Search Before You Code

Before creating or modifying any file, search the *entire codebase* (both the core Chatwoot app and `beet-digital-extension`) for the relevant class, module, or component name.

```bash
# Example: Search for a service before overriding it
rg -n "MessageCreationService" .
```

This will tell you:
- If an override already exists in our extension.
- The location and content of the original file in the core app.

### Step 2: Choose Your Strategy: Create, Extend, or Edit

- **EDIT** an existing file **only if it is already inside `beet-digital-extension/`**. This is for iterating on features we have already built or modified.

- **CREATE** a file in `beet-digital-extension/` to **override** core Chatwoot logic for the first time. This is the most common approach for replacing or augmenting functionality.

- **EXTEND** core logic using Chatwoot's built-in mechanisms like `prepend_mod_with` or `include_mod_with`. This is the **preferred method** for adding new behavior without completely replacing a file, as it reduces code duplication and maintenance overhead. Use this for services, controllers, and policies whenever possible.

### Step 3: Implement and Test

- Write your code, following the project's code style and quality guidelines.
- If adding new logic, add corresponding tests inside `beet-digital-extension/spec/`, mirroring the core `spec/` directory structure.

## 3. Language Selection Guide

*   **Ruby on Rails:** All backend logic (Models, Controllers, Services, Workers).
*   **Vue.js (Composition API):** All frontend development. Use `<script setup>` and TypeScript.
*   **Terraform (HCL):** All GCP infrastructure management.
*   **Kubernetes (YAML):** All GKE resource manifests.
*   **Shell (Bash/Sh):** Automation scripts and build processes.
