# System Architecture

This document describes the high-level architecture of the Muslim AI SaaS platform.

---

## High-Level Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  Web App / Mobile App / Third-party Integration (REST)           │
└───────────────────────────┬──────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Azure API Gateway                          │
│  Auth (Azure AD B2C) · Rate Limiting · Request Logging           │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Muslim AI Web API (FastAPI)                    │
│  Prompt Builder · Guardrail Pre-filter · Response Post-filter    │
└──────┬─────────────────────────────────────────┬─────────────────┘
       │                                         │
       ▼                                         ▼
┌─────────────────────┐               ┌──────────────────────────┐
│  Azure Cognitive    │               │  Llama 3 Inference       │
│  Search / Qdrant    │◄──── RAG ────►│  (Azure VM / AKS)        │
│  (Vector DB)        │               │  GPU-backed endpoint     │
└─────────────────────┘               └──────────────────────────┘
       ▲                                         │
       │                                         ▼
┌─────────────────────┐               ┌──────────────────────────┐
│  Azure Blob Storage │               │  Guardrail Post-filter   │
│  (Islamic Corpus)   │               │  (toxicity, off-topic)   │
│  Quran · Hadith ·   │               └──────────────────────────┘
│  Risale-i Nur · ... │                          │
└─────────────────────┘                          ▼
                                    ┌──────────────────────────┐
                                    │   Response returned to   │
                                    │   client (secure output) │
                                    └──────────────────────────┘

Admin / Reviewer Panel
  └─► Azure Application Insights (logging, audit trail)
  └─► Feedback loop: flagged answers queued for scholar review
```

---

## Component Descriptions

### 1. Client Layer

Any device or system that communicates with the platform over HTTPS:

- **Web Application** – React/Next.js front-end hosted on Azure Static Web Apps.
- **Mobile Application** – iOS / Android clients consuming the same REST API.
- **Third-party Integrations** – Mosque management systems, LMS platforms, chatbot widgets.

### 2. Azure API Gateway

Centralises cross-cutting concerns:

| Concern | Service / Approach |
|---|---|
| Authentication | Azure AD B2C (OAuth 2.0 / OIDC) |
| Rate Limiting | Azure API Management (APIM) policies |
| TLS Termination | Azure Application Gateway or APIM |
| Request Logging | Azure Monitor / Log Analytics |

### 3. Muslim AI Web API (FastAPI)

The core business-logic layer, responsible for:

- **Prompt Building** – Combining the user query with the retrieved context chunks and the Muslim persona system prompt.
- **Pre-filter (Guardrail)** – Detecting and rejecting requests that contain forbidden content before they reach the LLM.
- **Post-filter (Guardrail)** – Validating model output for Islamic alignment and safety before returning it.

Deployed as a containerised service on **Azure Kubernetes Service (AKS)** for horizontal scaling.

### 4. Retrieval-Augmented Generation (RAG) Pipeline

```
User Query
   │
   ▼
Embedding Model (text-embedding-ada or local BGE model)
   │
   ▼
Vector Similarity Search (Azure Cognitive Search / Qdrant)
   │
   ▼
Top-K Document Chunks retrieved from Islamic Corpus
   │
   ▼
Augmented Prompt  ──►  Llama 3
```

The vector index is built from the Islamic Corpus stored in Azure Blob Storage. Documents are chunked, embedded, and indexed offline; the index is updated periodically as the corpus grows.

### 5. Llama 3 Inference Service

- Deployed on an **Azure Virtual Machine** (GPU SKU: NC-series or ND-series) or an **AKS node pool** with GPU nodes.
- Served via **vLLM** or **Ollama** for efficient batched inference.
- Accepts a structured JSON prompt; returns a completion.
- The model is not fine-tuned by default – alignment is achieved through system prompts and RAG. Optional fine-tuning on curated Islamic Q&A is planned.

### 6. Azure Blob Storage – Islamic Corpus

Stores the raw and processed Islamic text documents:

| Dataset | Language | Notes |
|---|---|---|
| Quran (multiple translations) | Arabic, English, Turkish | Public domain translations |
| Sahih al-Bukhari, Sahih Muslim | Arabic, English | Established hadith collections |
| Rumi's Masnavi | Persian, Turkish, English | Classical spiritual poetry |
| Risale-i Nur | Turkish, Arabic, English | Contemporary Islamic scholarship |
| Verified Q&A Pairs | Multi-language | Scholar-reviewed FAQs |

### 7. Admin / Reviewer Panel

A secure internal web interface for:

- Viewing conversation logs (anonymised).
- Flagging and correcting model responses.
- Managing the content moderation queue.
- Triggering corpus re-indexing.

### 8. Azure Application Insights

Centralised observability: latency metrics, error rates, token usage, and user feedback signals feed back into the review pipeline.

---

## Security Considerations

| Threat | Mitigation |
|---|---|
| Prompt injection | Pre-filter strips malicious instruction patterns; system prompt is pinned |
| Data exfiltration | No PII stored; conversations optionally ephemeral |
| Model jailbreak | Post-filter classifies output; flagged responses are blocked |
| Unauthorised access | Azure AD B2C; API keys rotated via Azure Key Vault |
| Corpus poisoning | All corpus additions require scholar review and are version-controlled in Blob Storage |
