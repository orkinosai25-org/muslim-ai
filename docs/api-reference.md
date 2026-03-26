# API Reference

This document describes the Muslim AI REST API. All endpoints are served over HTTPS and require authentication via an API key or OAuth 2.0 bearer token (Azure AD B2C).

---

## Base URL

```
https://api.muslimAI.org/v1
```

For local development:

```
http://localhost:8000/v1
```

---

## Authentication

Include your API key in the `Authorization` header:

```
Authorization: Bearer <API_KEY>
```

API keys are issued via the admin panel or obtained during the OAuth 2.0 authorisation code flow.

---

## Rate Limits

| Plan | Requests / Minute | Requests / Month |
|---|---|---|
| Free | 5 | 50 |
| Individual | 30 | 1,000 |
| Family | 60 | 5,000 |
| Institution | 120 | Unlimited |

When a rate limit is exceeded the API returns `429 Too Many Requests`.

---

## Common Response Format

All responses are JSON with the following envelope:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

On error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_QUERY",
    "message": "The query field must not be empty."
  }
}
```

---

## Endpoints

### 1. Question & Answer

#### `POST /qa`

Submit a question and receive a faith-grounded answer with citations.

**Request**

```http
POST /v1/qa
Authorization: Bearer <API_KEY>
Content-Type: application/json
```

```json
{
  "query": "What does Islam say about caring for parents?",
  "language": "en",
  "context_mode": "rag",
  "conversation_id": "conv_abc123",
  "max_tokens": 512
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `query` | string | ✅ | The user's question (max 1,000 characters). |
| `language` | string | ✅ | Response language: `en`, `ar`, `tr`. |
| `context_mode` | string | ❌ | `rag` (default) uses retrieval; `direct` skips retrieval. |
| `conversation_id` | string | ❌ | Provide to maintain multi-turn conversation history. |
| `max_tokens` | integer | ❌ | Maximum tokens in the response (default: 512, max: 2048). |

**Response**

```json
{
  "success": true,
  "data": {
    "answer": "Islam places immense emphasis on honouring and caring for parents. Allah (SWT) commands in the Quran: 'And your Lord has decreed that you worship none but Him, and that you be dutiful to your parents.' (Surah Al-Isra, 17:23). The Prophet ﷺ also said: 'Ridha Allah fi ridha al-walidayn' – 'The pleasure of Allah lies in the pleasure of the parents.' (Tirmidhi, Hadith 1899).",
    "citations": [
      {
        "source": "Quran",
        "reference": "Surah Al-Isra (17:23)",
        "language": "en",
        "excerpt": "And your Lord has decreed that you worship none but Him, and that you be dutiful to your parents."
      },
      {
        "source": "Sunan al-Tirmidhi",
        "reference": "Hadith 1899",
        "language": "en",
        "excerpt": "The pleasure of Allah lies in the pleasure of the parents, and the displeasure of Allah lies in the displeasure of the parents."
      }
    ],
    "conversation_id": "conv_abc123",
    "model": "llama3-70b-instruct",
    "tokens_used": 287
  },
  "error": null
}
```

---

#### `GET /qa/history/{conversation_id}`

Retrieve the message history for a conversation.

**Request**

```http
GET /v1/qa/history/conv_abc123
Authorization: Bearer <API_KEY>
```

**Response**

```json
{
  "success": true,
  "data": {
    "conversation_id": "conv_abc123",
    "messages": [
      {
        "role": "user",
        "content": "What does Islam say about caring for parents?",
        "timestamp": "2024-06-01T10:00:00Z"
      },
      {
        "role": "assistant",
        "content": "Islam places immense emphasis...",
        "timestamp": "2024-06-01T10:00:02Z"
      }
    ]
  },
  "error": null
}
```

---

#### `DELETE /qa/history/{conversation_id}`

Delete all messages in a conversation (for user privacy).

**Request**

```http
DELETE /v1/qa/history/conv_abc123
Authorization: Bearer <API_KEY>
```

**Response**

```json
{
  "success": true,
  "data": { "deleted": true },
  "error": null
}
```

---

### 2. Feedback

#### `POST /feedback`

Submit feedback on a model response (thumbs up/down, free text, or flag for scholar review).

**Request**

```http
POST /v1/feedback
Authorization: Bearer <API_KEY>
Content-Type: application/json
```

```json
{
  "conversation_id": "conv_abc123",
  "message_index": 1,
  "rating": "down",
  "reason": "incorrect_citation",
  "comment": "The Hadith reference number seems wrong.",
  "request_scholar_review": true
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `conversation_id` | string | ✅ | Conversation being rated. |
| `message_index` | integer | ✅ | Index of the assistant message (0-based). |
| `rating` | string | ✅ | `up` or `down`. |
| `reason` | string | ❌ | One of: `incorrect_info`, `incorrect_citation`, `unhelpful`, `inappropriate`, `other`. |
| `comment` | string | ❌ | Free-text comment (max 500 characters). |
| `request_scholar_review` | boolean | ❌ | If `true`, the response is queued for scholar review (default: `false`). |

**Response**

```json
{
  "success": true,
  "data": { "feedback_id": "fb_xyz789" },
  "error": null
}
```

---

### 3. Admin Moderation

> ⚠️ These endpoints require an **admin** or **reviewer** role.

#### `GET /admin/moderation/queue`

List responses awaiting scholar review.

**Request**

```http
GET /v1/admin/moderation/queue?status=pending&page=1&per_page=20
Authorization: Bearer <ADMIN_API_KEY>
```

**Query Parameters**

| Parameter | Type | Description |
|---|---|---|
| `status` | string | `pending`, `approved`, `rejected` (default: `pending`) |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Results per page (default: 20, max: 100) |

**Response**

```json
{
  "success": true,
  "data": {
    "total": 5,
    "page": 1,
    "items": [
      {
        "review_id": "rev_001",
        "conversation_id": "conv_abc123",
        "message_index": 1,
        "query": "What does Islam say about caring for parents?",
        "response": "Islam places immense emphasis...",
        "flagged_reason": "incorrect_citation",
        "submitted_at": "2024-06-01T10:05:00Z",
        "status": "pending"
      }
    ]
  },
  "error": null
}
```

---

#### `POST /admin/moderation/{review_id}/decision`

Approve or reject a queued response and optionally provide a corrected answer.

**Request**

```http
POST /v1/admin/moderation/rev_001/decision
Authorization: Bearer <ADMIN_API_KEY>
Content-Type: application/json
```

```json
{
  "decision": "reject",
  "reviewer_note": "Hadith number is incorrect. Correct reference is Tirmidhi 1899.",
  "corrected_response": "Islam places immense emphasis on honouring parents..."
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `decision` | string | ✅ | `approve` or `reject`. |
| `reviewer_note` | string | ❌ | Internal note visible only to admins. |
| `corrected_response` | string | ❌ | If provided, replaces the original response in logs. |

**Response**

```json
{
  "success": true,
  "data": {
    "review_id": "rev_001",
    "decision": "reject",
    "processed_at": "2024-06-01T14:00:00Z"
  },
  "error": null
}
```

---

#### `GET /admin/logs`

Retrieve anonymised conversation logs for audit purposes.

**Request**

```http
GET /v1/admin/logs?from=2024-06-01&to=2024-06-07&page=1&per_page=50
Authorization: Bearer <ADMIN_API_KEY>
```

**Query Parameters**

| Parameter | Type | Description |
|---|---|---|
| `from` | date | Start date (ISO 8601, inclusive) |
| `to` | date | End date (ISO 8601, inclusive) |
| `page` | integer | Page number |
| `per_page` | integer | Results per page (max: 100) |

**Response**

```json
{
  "success": true,
  "data": {
    "total": 1024,
    "page": 1,
    "items": [
      {
        "log_id": "log_001",
        "conversation_id": "conv_abc123",
        "query_language": "en",
        "tokens_used": 287,
        "model": "llama3-70b-instruct",
        "had_feedback": true,
        "timestamp": "2024-06-01T10:00:02Z"
      }
    ]
  },
  "error": null
}
```

---

### 4. Health Check

#### `GET /health`

Returns the service health status. No authentication required.

**Request**

```http
GET /v1/health
```

**Response**

```json
{
  "status": "ok",
  "version": "1.0.0",
  "llm_backend": "reachable",
  "vector_db": "reachable",
  "timestamp": "2024-06-01T10:00:00Z"
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|---|---|---|
| `INVALID_QUERY` | 400 | The `query` field is missing or invalid. |
| `LANGUAGE_NOT_SUPPORTED` | 400 | The requested language is not supported. |
| `UNAUTHORIZED` | 401 | Missing or invalid API key. |
| `FORBIDDEN` | 403 | Insufficient permissions for this endpoint. |
| `NOT_FOUND` | 404 | The requested resource does not exist. |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests. |
| `CONTENT_FILTERED` | 422 | The query was blocked by the pre-filter guardrail. |
| `LLM_UNAVAILABLE` | 503 | The Llama 3 inference backend is not reachable. |
| `INTERNAL_ERROR` | 500 | Unexpected server error. |

---

## Versioning

The API is versioned via the URL path (`/v1`). Breaking changes will be introduced in a new version (`/v2`). Previous versions are supported for at least **12 months** after a new version is released.

---

## SDK & Code Examples

### Python

```python
import requests

API_KEY = "your_api_key"
BASE_URL = "https://api.muslimAI.org/v1"

response = requests.post(
    f"{BASE_URL}/qa",
    headers={"Authorization": f"Bearer {API_KEY}"},
    json={
        "query": "What are the five pillars of Islam?",
        "language": "en",
    },
)
data = response.json()
print(data["data"]["answer"])
```

### JavaScript (fetch)

```js
const response = await fetch("https://api.muslimAI.org/v1/qa", {
  method: "POST",
  headers: {
    Authorization: "Bearer your_api_key",
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    query: "What are the five pillars of Islam?",
    language: "en",
  }),
});
const { data } = await response.json();
console.log(data.answer);
```

### cURL

```bash
curl -X POST https://api.muslimAI.org/v1/qa \
  -H "Authorization: Bearer your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the five pillars of Islam?",
    "language": "en"
  }'
```
