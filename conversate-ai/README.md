# Conversate AI

This is the monorepo for the Conversate AI platform, a state-of-the-art, AI-first business communications and revenue platform.

## Overview

This project is a full rewrite of the original Chatwoot platform, architected from the ground up to be a scalable, multi-tenant, microservices-based system with AI at its core.

## Architecture

The platform is built on a microservices architecture, orchestrated with Kubernetes. The core services include:

*   **Identity Service:** Manages users, accounts, and authentication.
*   **CSG Service (Conversational State Graph):** The core memory of the platform, built on a graph database.
*   **SOR Service (Self-Optimizing Retrieval):** The RAG engine for the platform.
*   **LOR Service (LLM Orchestrator & Runtime):** The "brain" that routes to different LLMs and executes conversational logic.

## Tech Stack

*   **Backend:** Python & FastAPI
*   **Frontend:** Vue.js 3 & Vite
*   **Database:** PostgreSQL with `pgvector` & Neo4j (for the graph DB)
*   **Infrastructure:** Kubernetes & Docker
*   **Event Streaming:** Kafka

## Getting Started

*TODO: Add setup instructions.*
