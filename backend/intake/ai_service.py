import re
import logging
from concurrent.futures import ThreadPoolExecutor, TimeoutError
from django.conf import settings

logger = logging.getLogger(__name__)

_EMERGENCY_KEYWORDS = [
    "chest pain", "chest tightness", "difficulty breathing", "shortness of breath",
    "unconscious", "fainted", "passed out", "seizure", "convulsing",
    "severe bleeding", "uncontrollable bleeding", "head injury", "head trauma",
    "stroke", "face drooping", "slurred speech", "arm weakness",
    "allergic reaction", "anaphylaxis", "swollen throat", "can't breathe",
    "suicidal", "self-harm", "overdose", "poisoning",
    "severe burn", "third degree burn", "electrical shock",
    "drowning", "choking", "not breathing",
    "car accident", "traffic accident", "major trauma",
    "high fever", "temp over 104", "severe pain",
]


def _check_emergency(severity, symptoms_text):
    severity_emergency = severity.upper() == "CRITICAL"
    symptoms_lower = symptoms_text.lower()
    keyword_match = any(kw in symptoms_lower for kw in _EMERGENCY_KEYWORDS)
    return severity_emergency or keyword_match


def _get_genai_client():
    try:
        from google import genai
        return genai.Client(api_key=settings.GEMINI_API_KEY)
    except Exception as e:
        logger.warning(f"Gemini client init failed: {e}")
        return None


def generate_clinical_summary(sex, severity, duration, symptoms_text):
    is_emergency = _check_emergency(severity, symptoms_text)

    client = _get_genai_client()
    if client is None:
        return _fallback_summary(sex, severity, duration, symptoms_text, is_emergency)

    priority_flag = "**EMERGENCY — URGENT** This patient may require immediate attention.\n\n" if is_emergency else ""

    prompt = (
        f"You are a medical triage assistant. A patient has submitted an intake form.\n\n"
        f"{priority_flag}"
        f"Patient Information:\n"
        f"- Sex: {sex}\n"
        f"- Severity: {severity}\n"
        f"- Duration: {duration}\n"
        f"- Symptoms described: {symptoms_text}\n\n"
        f"Produce a structured clinical brief with:\n"
        f"1. **Emergency Status**: {'URGENT — flags detected' if is_emergency else 'Non-urgent'}\n"
        f"2. **Chief Complaint** (one sentence)\n"
        f"3. **History of Presenting Illness** (2-3 sentences)\n"
        f"4. **Key Observations** (bullet points)\n"
        f"5. **Triage Recommendation**\n"
        f"6. **Suggested Initial Actions**\n"
    )

    try:
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                client.models.generate_content,
                model="gemini-2.0-flash",
                contents=prompt,
            )
            response = future.result(timeout=15)
        summary = response.text or ""
        if is_emergency and "EMERGENCY" not in summary.upper():
            summary = "🚨 EMERGENCY — Immediate attention recommended\n\n" + summary
        return summary
    except TimeoutError:
        logger.warning("Gemini API timed out after 15s")
    except Exception as e:
        logger.warning(f"Gemini API error: {e}")

    return _fallback_summary(sex, severity, duration, symptoms_text, is_emergency)


def _fallback_summary(sex, severity, duration, symptoms_text, is_emergency=False):
    emergency_line = "🚨 EMERGENCY — Immediate attention required!\n" if is_emergency else ""
    return (
        f"{emergency_line}"
        f"PATIENT CLINICAL BRIEF\n"
        f"----------------------\n"
        f"Sex: {sex}\n"
        f"Severity Level: {severity}\n"
        f"Duration: {duration}\n"
        f"Symptoms: {symptoms_text}\n\n"
        f"[Offline — data captured for manual review]"
    )


def get_triage_priority(severity, symptoms_text):
    if _check_emergency(severity, symptoms_text):
        return "emergency"
    severity_map = {"CRITICAL": "emergency", "SEVERE": "high", "MODERATE": "medium", "MILD": "low"}
    return severity_map.get(severity.upper(), "medium")
