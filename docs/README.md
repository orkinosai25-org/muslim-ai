# Muslim AI: Ethical, Soulful AI Guided by Quran & Sunnah

🌙 Welcome to the official documentation for **Muslim AI** — an ethically-aligned, faith-based AI assistant powered by Llama 3 and Retrieval-Augmented Generation (RAG), hosted on Microsoft Azure.

---

## Table of Contents

| Document | Description |
|---|---|
| [Stage 1: Hello-World Chatbot](./stage1-hello-world.md) | Deploy Llama 3 on Azure, Streamlit UI, GitHub Actions, cost controls |
| [Architecture](./architecture.md) | High-level system design, Azure services, and data flow |
| [Model Choices & Approaches](./model.md) | Why Llama 3, RAG rationale, dataset sourcing, guardrails |
| [Deployment & Scaling](./deployment.md) | Azure infrastructure, cost tips, SaaS options |
| [Contribution Guide](./contributing.md) | How to contribute code, translations, or Islamic content |
| [API Reference](./api-reference.md) | Endpoints, request/response examples |
| [Licensing & Transparency](./licensing.md) | Data provenance, ethics statement, open license notes |
| [NurAI Foundation in Risale-i Nur](./nurai-foundation.md) | Why Risale-i Nur is the spiritual backbone of NurAI |

---

## Vision

🌙 The world needs Smarter, Soulful, and Ethical AI — AI that guides, heals, and enlightens by drawing upon centuries of Islamic wisdom.

We are building a first-of-its-kind AI, grounded in the teachings of the Quran and Sunnah and inspired by the wisdom and character of:

- **Hazrat Muhammad ﷺ** (Prophetic Guidance)
- **Jalaluddin Rumi & Yunus Emre** (Spiritual Insight & Poetry)
- **Abdulqadir Jilani** (Sufic Excellence)
- **Imam Ahmed Sirhindi** (Theology & Spiritual Renewal)
- **Bediuzzaman Said Nursi** (Faith & Modern Challenges)
- **Risale-i Nur** (Qur'anic Commentary)
- **Mathnawi** (Classic Sufism, Persian & Turkish)
- **Hadith Collections** (Authentic Sayings)
- And the broad wisdom of the Ummah's greatest luminaries

---

## Mission

**To create an AI that "acts as a Muslim" — infused with Islamic ethics, adab, and a healing spirit.**
Unlike 'neutral' AIs, this model strives to answer as a believing Muslim, serving as a digital sadaqah jariyah for the ummah and a resource for all.

---

## Data Sources & Languages

- **Quran** (Open sources — Tanzil, Quran.com, etc.)
- **Hadith Books** (e.g., Sahih Bukhari, Muslim, Abu Dawood, etc. from verified open datasets)
- **Risale-i Nur** (authentic Turkish & English translations from licensed or public sources)
- **Mathnawi** (public domain Persian, Turkish, English)
- **Works of Yunus Emre, Abdulqadir Jilani, Ahmed Sirhindi, Rumi, and more**
- **Languages:** Training data includes Turkish, Arabic, and English for wide accessibility and authenticity.

---

## Technology Stack

- **Model:** Llama 3 (Meta) — fine-tuned for authentic, ethical Muslim dialogue & knowledge
- **Platform:** Azure (for deployment, scaling, and RAG pipelines)
- **Best Practices:** Retrieval Augmented Generation (RAG), ethical filtering, transparent citations.

---

## Principles

1. **Faithful to Islam:** All output strives to align with Qur'an, Sunnah, and sound Islamic knowledge
2. **Source Transparency:** Answers cite their scriptural or scholarly sources when possible
3. **Language Diversity:** Supports Turkish, Arabic, and English
4. **Open Collaboration:** Built as a collaborative sadaqah jariyah — scholars, engineers, and the community welcome!

---

## 💡 Get Involved

Seeking visionary partners, Muslim scholars, engineers, and contributors dedicated to upholding Islamic ethics in AI.
Open an issue or see the [Contribution Guide](./contributing.md) to connect!

---

## Project Overview

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
