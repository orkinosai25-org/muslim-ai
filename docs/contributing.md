# Contribution Guide

Assalamu Alaikum! 🌙

Thank you for your interest in contributing to **Muslim AI**. This project is a community effort, and contributions of all kinds are welcome – whether you are a software developer, translator, Islamic scholar, or simply someone who cares about ethical AI for the Muslim community.

---

## Table of Contents

1. [Code of Conduct](#1-code-of-conduct)
2. [Ways to Contribute](#2-ways-to-contribute)
3. [Contributing Code](#3-contributing-code)
4. [Contributing Translations](#4-contributing-translations)
5. [Contributing Islamic Content](#5-contributing-islamic-content)
6. [Scholar / Parent Reviewer Process](#6-scholar--parent-reviewer-process)
7. [Reporting Issues](#7-reporting-issues)
8. [Getting Help](#8-getting-help)

---

## 1. Code of Conduct

All contributors are expected to:

- Communicate with **adab** (Islamic courtesy) and respect toward all participants regardless of background.
- Avoid sectarian disputes or divisive content in discussions and code contributions.
- Keep user privacy and data security a top priority.
- Not introduce content that contradicts clear Islamic principles (e.g., promoting haram activities).

Violations may result in removal from the project.

---

## 2. Ways to Contribute

| Contribution Type | Who It's For | Where to Start |
|---|---|---|
| Bug fixes & features | Software developers | [Contributing Code](#3-contributing-code) |
| UI/UX improvements | Designers & front-end developers | [Contributing Code](#3-contributing-code) |
| Arabic / Turkish / Urdu translations | Bilingual community members | [Contributing Translations](#4-contributing-translations) |
| Islamic text sources | Scholars, researchers | [Contributing Islamic Content](#5-contributing-islamic-content) |
| Q&A pair review | Scholars, parents | [Scholar / Parent Reviewer Process](#6-scholar--parent-reviewer-process) |
| Bug reports & suggestions | Anyone | [Reporting Issues](#7-reporting-issues) |

---

## 3. Contributing Code

### 3.1 Set Up Your Development Environment

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/<your-username>/muslim-ai.git
cd muslim-ai

# Create a virtual environment
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Copy environment config
cp .env.example .env
# Fill in your local settings

# Run the local dev server (uses Ollama for CPU inference)
docker compose up --build
```

### 3.2 Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, production-ready code |
| `develop` | Integration branch for upcoming release |
| `feature/<short-description>` | New features |
| `fix/<short-description>` | Bug fixes |
| `docs/<short-description>` | Documentation changes |
| `corpus/<short-description>` | Islamic content / corpus additions |

```bash
# Always branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/my-new-feature
```

### 3.3 Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

Examples:
feat(api): add Quran verse lookup endpoint
fix(guardrail): correct false-positive filter for Arabic diacritics
docs(architecture): update AKS deployment diagram
corpus(hadith): add Sahih Muslim volume 3 index
```

### 3.4 Pull Request Process

1. Ensure all tests pass locally:
   ```bash
   pytest tests/
   ```
2. Run the linter:
   ```bash
   ruff check . && ruff format --check .
   ```
3. Open a Pull Request against the `develop` branch.
4. Fill in the PR template completely.
5. At least **one code review approval** from a project maintainer is required to merge.
6. If your PR touches the Islamic corpus or system prompt, a **scholar review approval** is also required (see [§ 6](#6-scholar--parent-reviewer-process)).

### 3.5 Testing Guidelines

- Write unit tests for all new business logic in `tests/unit/`.
- Write integration tests for new API endpoints in `tests/integration/`.
- Aim for ≥ 80% code coverage on new code.
- Mock the Llama 3 inference endpoint in tests to keep them fast and deterministic.

---

## 4. Contributing Translations

Muslim AI aims to serve the global Muslim community in their native languages. We welcome translations of:

- The web application UI strings.
- Documentation (this `/docs` folder).
- System prompt templates in new languages.

### Process

1. Check the [open translation issues](https://github.com/orkinosai25-org/muslim-ai/issues?q=label%3Atranslation) to see what is needed.
2. If your language is not yet listed, open a new issue with the label `translation`.
3. Translation files live in `locales/<language-code>/` (e.g., `locales/ar/`, `locales/tr/`).
4. Copy the English base file and translate all strings.
5. Open a PR with the label `translation`.
6. A native speaker from the community will review the translation before merging.

### Translation Standards

- Use formal, respectful language appropriate for Islamic communication.
- Transliterate Arabic Islamic terms (e.g., *Bismillah*, *Alhamdulillah*) rather than translating them where the original term is standard.
- Do not change the meaning of system prompt guardrail instructions during translation.

---

## 5. Contributing Islamic Content

Expanding and maintaining the Islamic corpus is one of the most valuable contributions to this project.

### What We Accept

- **Primary texts**: Additional Quran translations (with proper attribution), hadith collections, tafsir works.
- **Secondary scholarship**: Books and papers from recognised scholars (with clear attribution and licence).
- **Scholar-reviewed Q&A pairs**: Question-answer pairs in any language that have been reviewed by a qualified Islamic scholar.

### What We Do Not Accept

- Anonymous internet fatwas.
- Content with dubious attribution.
- Sectarian polemical content.
- Any text that promotes harm.

### Submission Process

1. Open an issue with the label `corpus-proposal`.
2. Provide:
   - Full title, author, and edition.
   - Language(s) of the text.
   - Licence / copyright status.
   - Why this source is valuable for Muslim AI.
3. A project maintainer and a scholar reviewer will evaluate the proposal.
4. If approved, upload the source files via the PR and update `corpus/manifest.json` with the metadata.
5. Run the indexing script locally to verify the content chunks correctly.

---

## 6. Scholar / Parent Reviewer Process

All changes that affect how the model responds to users – including system prompt changes, corpus additions, and guardrail tuning – require a review by a member of our **Scholar Review Panel** before they can be merged to `main`.

### Becoming a Reviewer

We welcome qualified Islamic scholars (of any recognised school of thought), Arabic/Turkish/Urdu language experts, and parents who wish to help audit the system's outputs.

To apply:

1. Open an issue with the title `Reviewer Application: <Your Name>`.
2. Briefly describe your qualifications and areas of expertise.
3. A maintainer will reach out to verify credentials and onboard you.

### Review Scope

| Change Type | Required Reviewer |
|---|---|
| System prompt modification | Senior scholar reviewer |
| Corpus addition | Domain-appropriate scholar (e.g., fiqh for hadith, tafsir for Quran additions) |
| Guardrail tuning | Scholar + software maintainer |
| UI text / translations | Language reviewer (scholar if religious content is involved) |

### Review SLA

Reviewers commit to providing feedback within **7 business days**. If a time-sensitive fix is required, maintainers may request an expedited review.

### Anonymised Output Audit

Reviewers periodically receive a batch of randomly sampled (anonymised) conversation logs to audit model behaviour and flag any problematic outputs. Flagged outputs are used to improve the guardrail system.

---

## 7. Reporting Issues

- **Bugs**: Use the [Bug Report template](https://github.com/orkinosai25-org/muslim-ai/issues/new?template=bug_report.md).
- **Incorrect Islamic information**: Use the [Content Issue template](https://github.com/orkinosai25-org/muslim-ai/issues/new?template=content_issue.md) and label it `content-accuracy`. These are treated as high priority.
- **Security vulnerabilities**: Do **not** open a public issue. Email the maintainers directly at security@muslimAI.org.

---

## 8. Getting Help

- **GitHub Discussions**: [Start a discussion](https://github.com/orkinosai25-org/muslim-ai/discussions) for questions that are not bugs.
- **Discord**: Join our community server (link in the main README) for real-time help.
- **Email**: general@muslimAI.org for non-technical enquiries.

JazakAllahu Khayran for your contribution! 🤲
