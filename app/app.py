"""
NurAI — Stage 1 Hello-World Chatbot
A minimal Streamlit chat UI that connects to a Llama 3 model served via Ollama.

Usage (local):
    streamlit run app/app.py

Environment variables (see .env.example):
    OLLAMA_BASE_URL   – Base URL of the Ollama server (default: http://localhost:11434)
    OLLAMA_MODEL      – Model tag to use           (default: llama3:8b)
"""

import os
import json
import requests
import streamlit as st

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3:8b")

SYSTEM_PROMPT = (
    "You are NurAI, a helpful and knowledgeable Islamic assistant. "
    "You answer questions about the Quran, Hadith, Islamic history, fiqh, "
    "and daily Muslim life based on verified scholarly sources. "
    "Always be respectful, compassionate, and grounded in traditional Islamic knowledge. "
    "If you are unsure about something, acknowledge the uncertainty and recommend "
    "consulting a qualified scholar. Begin every response with 'Bismillah' only when "
    "the user's question concerns Islamic practice."
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def chat_stream(messages: list[dict]) -> str:
    """Send a list of messages to Ollama and return the full response text."""
    url = f"{OLLAMA_BASE_URL}/api/chat"
    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": True,
    }
    full_response = ""
    try:
        with requests.post(url, json=payload, stream=True, timeout=120) as resp:
            resp.raise_for_status()
            for line in resp.iter_lines():
                if line:
                    chunk = json.loads(line)
                    token = chunk.get("message", {}).get("content", "")
                    full_response += token
                    yield token
                    if chunk.get("done"):
                        break
    except requests.exceptions.ConnectionError:
        error_msg = (
            "⚠️ Cannot reach the Ollama server at "
            f"`{OLLAMA_BASE_URL}`. "
            "Please ensure Ollama is running and the `OLLAMA_BASE_URL` "
            "environment variable is set correctly."
        )
        yield error_msg
    except requests.exceptions.HTTPError as exc:
        yield f"⚠️ Ollama returned an error: {exc}"


def build_messages(history: list[dict]) -> list[dict]:
    """Prepend the system prompt and return the full message list."""
    return [{"role": "system", "content": SYSTEM_PROMPT}] + history


# ---------------------------------------------------------------------------
# Streamlit UI
# ---------------------------------------------------------------------------

st.set_page_config(
    page_title="NurAI — Islamic Assistant",
    page_icon="🌙",
    layout="centered",
)

st.title("🌙 NurAI — Islamic Assistant")
st.caption(
    "Powered by **Llama 3** · Stage 1 Hello-World · "
    f"Model: `{OLLAMA_MODEL}` · Endpoint: `{OLLAMA_BASE_URL}`"
)

st.markdown(
    """
    Ask any question about the Quran, Hadith, Islamic history, or daily Muslim life.

    > ⚠️ NurAI is an assistive tool — not a substitute for qualified Islamic scholarship.
    > For personal religious decisions, please consult a qualified scholar.
    ---
    """
)

# Initialise chat history in session state
if "messages" not in st.session_state:
    st.session_state.messages = []

# Render existing messages
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

# Accept user input
if prompt := st.chat_input("Ask a question about Islam…"):
    # Store and show the user's message
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Stream the assistant response
    with st.chat_message("assistant"):
        response_placeholder = st.empty()
        full_response = ""
        for token in chat_stream(build_messages(st.session_state.messages)):
            full_response += token
            response_placeholder.markdown(full_response + "▌")
        response_placeholder.markdown(full_response)

    st.session_state.messages.append(
        {"role": "assistant", "content": full_response}
    )
