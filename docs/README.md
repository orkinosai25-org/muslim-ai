# Muslim AI – Documentation

Welcome to the official documentation for **Muslim AI**, an ethically-aligned, faith-based AI assistant powered by Llama 3 and Retrieval-Augmented Generation (RAG), hosted on Microsoft Azure.

---

## Table of Contents

| Document | Description |
|---|---|
| [Architecture](./architecture.md) | High-level system design, Azure services, and data flow |
| [Model Choices & Approaches](./model.md) | Why Llama 3, RAG rationale, dataset sourcing, guardrails |
| [Deployment & Scaling](./deployment.md) | Azure infrastructure, cost tips, SaaS options |
| [Contribution Guide](./contributing.md) | How to contribute code, translations, or Islamic content |
| [API Reference](./api-reference.md) | Endpoints, request/response examples |
| [Licensing & Transparency](./licensing.md) | Data provenance, ethics statement, open license notes |

---

## Project Overview

### Vision

Muslim AI aims to provide families, schools, mosques, and individuals with an AI companion that is:

- **Ethically aligned** with Islamic values (adab, honesty, care for the community)
- **Transparent** about its sources (Quran, Hadith, classical scholarship)
- **Controllable** and auditable by scholars, parents, and administrators
- **Affordable and open** – built on open-weight models so the community retains ownership

### Objectives

1. Deliver accurate, faith-conscious answers to questions about Islamic practice, history, and daily life.
2. Prevent harmful, un-Islamic, or misleading content through multi-layer guardrails.
3. Support multiple languages – English, Arabic, Turkish, and more – drawing on verified corpora.
4. Provide a SaaS platform suitable for institutions (schools, mosques) and individual subscribers.

### Target Audience

| Audience | Primary Use Case |
|---|---|
| Families | Age-appropriate Islamic learning at home |
| Schools & Madrasas | Curriculum support, Q&A assistant |
| Individuals | Personal Islamic guidance, prayer times, Quran reflection |
| Scholars & Reviewers | Content audit, fatwa verification workflow |
| Developers | Integration via REST API |

---

## Quick Start (for developers)

```bash
# Clone the repository
git clone https://github.com/orkinosai25-org/muslim-ai.git
cd muslim-ai

# Follow the deployment guide to stand up the API
# See docs/deployment.md
```

For full setup instructions see [Deployment & Scaling](./deployment.md).  
For API usage see [API Reference](./api-reference.md).
