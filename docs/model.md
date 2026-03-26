# Model Choices & Approaches

This document explains the technology decisions behind Muslim AI: why we chose Llama 3, how Retrieval-Augmented Generation (RAG) is applied, where the Islamic corpus comes from, and how the model is constrained to behave in an Islamically appropriate way.

---

## 1. Why Llama 3?

Meta's **Llama 3** (8B and 70B parameter variants) was selected as the foundation model for Muslim AI for the following reasons:

| Criterion | Rationale |
|---|---|
| **Open weights** | The community retains control; no vendor lock-in. The model can be audited, fine-tuned, and redistributed under Meta's community licence. |
| **Controllability** | Open-weight models respond reliably to strong system prompts and RLHF-style instruction following, making persona enforcement feasible without proprietary APIs. |
| **Cost efficiency** | Running Llama 3-8B on a single A100 or two A10 GPUs is far cheaper than comparable proprietary API calls at scale. |
| **Multilingual capability** | Llama 3 shows strong performance in Arabic, Turkish, and English – the three primary languages of the Muslim AI corpus. |
| **Active community** | Large ecosystem of tooling (vLLM, Ollama, LangChain, LlamaIndex) reduces integration effort. |
| **Privacy** | All inference is on-premises (Azure VM/AKS), so user queries never leave the organisation's cloud tenant. |

### Llama 3 Model Variants Used

| Variant | Use Case | Deployment |
|---|---|---|
| Llama 3 8B Instruct | Development, testing, low-latency Q&A | Single GPU VM |
| Llama 3 70B Instruct | Production, complex reasoning, fatwa-adjacent queries | Multi-GPU VM or AKS |
| Llama 3 8B (base) | Fine-tuning experiments on Islamic Q&A | Offline training job |

---

## 2. Retrieval-Augmented Generation (RAG)

### What is RAG?

RAG supplements the LLM's parametric knowledge with relevant passages retrieved at inference time from a curated knowledge base. Instead of asking the model to recall facts from training data, we:

1. Embed the user's query into a vector representation.
2. Search a pre-built vector index of the Islamic corpus for the most semantically similar passages.
3. Inject those passages into the prompt as context.
4. Instruct the model to ground its answer in the provided context.

### Why RAG for Muslim AI?

| Benefit | Explanation |
|---|---|
| **Alignment & accuracy** | The model answers from verified Islamic sources rather than from potentially inaccurate or biased training data. |
| **Transparency** | Every answer can cite the exact passage it drew from, enabling scholar verification. |
| **Cost** | Avoiding full fine-tuning on every corpus update reduces GPU costs dramatically. |
| **Updatability** | Adding new scholar-verified content only requires re-indexing, not retraining. |
| **Reduced hallucination** | Grounding responses in retrieved text significantly lowers confabulation rates. |

### RAG Pipeline Detail

```
┌───────────────────────────────────┐
│           Offline (Indexing)      │
│                                   │
│  Raw Documents (Blob Storage)     │
│       │                           │
│       ▼                           │
│  Text Chunking (512 tokens,       │
│  50-token overlap)                │
│       │                           │
│       ▼                           │
│  Embedding Model                  │
│  (BGE-m3 or text-embedding-ada)   │
│       │                           │
│       ▼                           │
│  Vector Index (Qdrant / Azure     │
│  Cognitive Search)                │
└───────────────────────────────────┘

┌───────────────────────────────────┐
│           Online (Query)          │
│                                   │
│  User Query                       │
│       │                           │
│       ▼                           │
│  Query Embedding                  │
│       │                           │
│       ▼                           │
│  Top-K Similarity Search (K=5)    │
│       │                           │
│       ▼                           │
│  Retrieved Chunks + Metadata      │
│  (source, surah/ayah, book/hadith │
│  number, language)                │
│       │                           │
│       ▼                           │
│  Augmented Prompt → Llama 3       │
│       │                           │
│       ▼                           │
│  Grounded Answer + Citations      │
└───────────────────────────────────┘
```

---

## 3. Dataset Sourcing

All content in the Islamic corpus is:

- **Verified** by at least one qualified Islamic scholar before inclusion.
- **Attributed** with full metadata (source, edition, translator, date).
- **Version-controlled** in Azure Blob Storage so additions and removals are auditable.

### Corpus Contents

| Source | Language(s) | Description |
|---|---|---|
| The Noble Quran | Arabic, English, Turkish | Multiple translations (e.g., Yusuf Ali, Diyanet) |
| Sahih al-Bukhari | Arabic, English | Most authoritative Sunni hadith collection |
| Sahih Muslim | Arabic, English | Second most authoritative Sunni hadith collection |
| Sunan Abu Dawood | Arabic, English | Fiqh-focused hadith |
| Rumi – Masnawi-i Ma'nawi | Persian, Turkish, English | Sufi spiritual poetry |
| Risale-i Nur Külliyatı | Turkish, Arabic, English | Said Nursi's contemporary Islamic scholarship |
| Scholar-reviewed Q&A | Multi-language | Curated question-answer pairs reviewed by qualified scholars |

### What is Excluded

- Sectarian or polemical content that misrepresents other Muslim schools of thought.
- Unverified internet fatwas or opinions without scholarly attribution.
- Any content that contradicts established Islamic consensus (ijma) without clear indication.

---

## 4. System Prompt & "Muslim Persona" Guardrails

The model's behaviour is primarily controlled through a carefully crafted **system prompt** that is prepended to every conversation. This prompt:

1. Assigns the model a Muslim scholar persona with `adab` (Islamic manners and etiquette).
2. Instructs the model to answer only from the provided context.
3. Explicitly lists forbidden topics and responses.
4. Requires citations for religious rulings.

### Sample System Prompt (abbreviated)

```
You are Muslim AI, a knowledgeable and respectful Islamic assistant. Your purpose
is to help Muslims and those curious about Islam with questions about the Quran,
Hadith, Islamic history, prayer, fasting, and ethical daily life.

Guidelines:
- Always speak with adab (respectful Islamic manners). Begin responses with
  "Bismillah" where appropriate.
- Base your answers strictly on the context passages provided. If the context
  does not contain sufficient information, say so honestly and suggest consulting
  a qualified scholar.
- Never invent Hadith, Quranic verses, or scholarly opinions.
- Do not engage with requests for content that contradicts Islamic ethics,
  promotes harm, or involves prohibited (haram) activities.
- If asked about fiqh differences, present the major scholarly positions
  objectively and recommend consulting a local scholar for personal rulings.
- Always cite the source (book, chapter, verse/hadith number) when quoting.

Context:
{retrieved_passages}

User: {user_query}
Assistant:
```

### Guardrail Layers

| Layer | Type | Mechanism |
|---|---|---|
| Pre-filter | Input | Regex + classifier detects injection attempts, off-topic requests, and explicit content before the prompt reaches Llama 3. |
| System prompt | In-model | Instruction-following alignment enforced at inference time. |
| Post-filter | Output | A lightweight classifier checks the response for toxicity, un-Islamic content, and hallucinated citations before it is returned to the user. |
| Human review | Async | Flagged conversations are queued for scholar review; corrections feed back into the Q&A corpus. |

---

## 5. Fine-Tuning Roadmap (Future Work)

While the initial version relies purely on RAG + system prompts, a fine-tuning pipeline is planned:

1. **Dataset construction** – Scholar-reviewed Q&A pairs in English, Arabic, and Turkish.
2. **Supervised Fine-Tuning (SFT)** – Llama 3 8B fine-tuned on the Q&A pairs using LoRA to reduce compute requirements.
3. **Preference tuning (DPO)** – Direct Preference Optimisation using scholar rankings of model outputs.
4. **Evaluation** – Custom Islamic knowledge benchmark covering aqidah, fiqh, seerah, and Quran.
