
# Skill: Project Context

This document provides the core context for the Beet Digital project.

## 1. Language
- **Primary Language:** English. All communication, code, and documentation must be in English.

## 2. Development Environment
- **Sandbox:** Nix-managed sandbox. All package and dependency suggestions must be Nix-compatible.

## 3. Technology Stack
- **Cloud:** Google Cloud Platform (GCP)
- **Infrastructure as Code (IaC):** Terraform
- **Orchestration:** Google Kubernetes Engine (GKE)

## 4. Project Architecture
- **Model:** Extension layer over a Chatwoot fork, similar to the Chatwoot `enterprise` edition.
- **Deployment:** Modifications are merged into a single Docker image during the `build` process.

## 5. Overall Objective
- Assist in developing a Chatwoot extension to improve channel handling (especially WhatsApp) and implement advanced automations (MCP Protocol).
- Provide support in scripting, infrastructure configuration, and code development (Ruby, Vue.js, TypeScript).
