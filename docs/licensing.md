# Licensing & Transparency

This document details the licensing of the Muslim AI software, the provenance and rights status of the Islamic corpus, and the project's ethics statement.

---

## 1. Software Licence

The Muslim AI source code is released under the **MIT Licence**.

```
MIT License

Copyright (c) 2024 Orkinosai25 Organisation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 2. Model Licence

The foundation model used by Muslim AI is **Meta Llama 3**, which is released under the [Meta Llama 3 Community Licence Agreement](https://llama.meta.com/llama3/license/).

Key points:
- Free for commercial use with attribution for deployments under 700M monthly active users.
- Derivative models must carry the "Built with Llama" designation.
- The model may not be used to infringe applicable laws or to harm individuals or groups.

---

## 3. Islamic Corpus – Data Provenance

All texts included in the Islamic corpus are documented in `corpus/manifest.json`. The table below summarises the major sources and their rights status.

| Source | Author / Publisher | Language(s) | Rights Status | Notes |
|---|---|---|---|---|
| The Noble Quran (Abdullah Yusuf Ali translation) | Yusuf Ali (d. 1953) | Arabic, English | Public domain | Published 1934 |
| The Noble Quran (Diyanet İşleri Başkanlığı translation) | Diyanet | Turkish | Used with attribution | Turkish government religious authority |
| Sahih al-Bukhari (USC-MSA English translation) | USC-MSA | Arabic, English | Public domain / open use | Widely distributed |
| Sahih Muslim (Abdul Hamid Siddiqui translation) | Abdul Hamid Siddiqui | Arabic, English | Out of copyright in most jurisdictions | First published 1971–1975 |
| Sunan Abu Dawood | Various translators | Arabic, English | Public domain translations used | Verified editions only |
| Masnawi-i Ma'nawi (Rumi) | Jalal al-Din Rumi (d. 1273) | Persian, Turkish, English | Public domain | 13th century text; public domain translations only |
| Risale-i Nur Külliyatı | Said Nursi (d. 1960) | Turkish, Arabic, English | Open use for non-commercial purposes | Per Risale-i Nur Institute guidelines |
| Scholar-reviewed Q&A pairs | Muslim AI Scholar Panel | Multi-language | CC BY 4.0 | Created for this project |

> If you believe any content in the corpus infringes your copyright, please contact legal@muslimAI.org immediately. We will investigate and remove the content if needed.

---

## 4. Third-Party Dependencies

The project uses the following key open-source dependencies. Full dependency lists are in `requirements.txt` and `package.json`.

| Package | Licence | Use |
|---|---|---|
| FastAPI | MIT | Web API framework |
| vLLM | Apache 2.0 | LLM inference engine |
| LangChain | MIT | RAG orchestration |
| Qdrant | Apache 2.0 | Vector database (self-hosted option) |
| PyTorch | BSD 3-Clause | Tensor computation |
| Hugging Face Transformers | Apache 2.0 | Embedding models |
| PostgreSQL | PostgreSQL Licence | Relational database |

---

## 5. Ethics Statement

### Our Commitments

**1. Islamic Alignment**
Muslim AI is designed to be consistent with the mainstream Islamic scholarly tradition. We do not seek to adjudicate between legitimate scholarly differences, but we are committed to ensuring that responses do not contradict clear Islamic principles (qat'iyat).

**2. Transparency**
- Every answer cites the source passage it draws from.
- Users can request the raw retrieved passages at any time.
- System prompt templates are publicly documented (see [Model Choices](./model.md#4-system-prompt--muslim-persona-guardrails)).
- The full corpus manifest is open and versioned.

**3. Scholar Oversight**
No change to the system prompt, guardrail logic, or Islamic corpus is merged without review by a qualified Islamic scholar. This is enforced by the contribution workflow (see [Contribution Guide](./contributing.md#6-scholar--parent-reviewer-process)).

**4. Privacy**
- No personally identifiable information (PII) is required to use the free tier.
- Conversation data is optionally ephemeral (deleted after each session on request).
- All data is stored within the user's chosen Azure region to comply with local data residency regulations.
- Data is never sold to third parties.

**5. No Harmful Content**
The system is designed to refuse requests for content that:
- Promotes violence, extremism, or terrorism.
- Encourages illegal activity.
- Demeans individuals based on ethnicity, gender, or religion.
- Misrepresents Islamic rulings to justify harm.

**6. Accessibility & Inclusivity**
We aim to serve the entire Muslim community – Sunni, Shia, and all schools of thought – with respect and without bias. Differences in fiqh are presented objectively, and users are always encouraged to consult their own scholars for personal rulings.

**7. Continuous Improvement**
We actively seek feedback from scholars, users, and the wider community. Detected failures are treated as high-priority issues and publicly tracked in the GitHub issue tracker.

---

## 6. Disclaimer

Muslim AI is an assistive tool, not a replacement for qualified Islamic scholarship. No output from Muslim AI should be treated as a formal fatwa (Islamic legal ruling). For personal religious decisions, always consult a qualified scholar in your community.

The project maintainers make no warranty that every response will be free of errors. Users are encouraged to verify important religious information with authoritative sources.

---

## 7. Contact

| Matter | Contact |
|---|---|
| General enquiries | general@muslimAI.org |
| Copyright / legal | legal@muslimAI.org |
| Security vulnerabilities | security@muslimAI.org |
| Scholar review applications | scholars@muslimAI.org |
