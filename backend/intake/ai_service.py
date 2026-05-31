from google import genai
from django.conf import settings


def generate_clinical_summary(sex, severity, duration, symptoms_text):
    if not settings.GEMINI_API_KEY:
        return _fallback_summary(sex, severity, duration, symptoms_text)

    client = genai.Client(api_key=settings.GEMINI_API_KEY)

    prompt = f"""You are a medical assistant. Format the following patient intake into a concise clinical summary for the doctor.

Patient Information:
- Sex: {sex}
- Severity: {severity}
- Duration: {duration}
- Symptoms described: {symptoms_text}

Please produce a structured clinical brief with:
1. Chief Complaint (one sentence)
2. History of Presenting Illness (2-3 sentences)
3. Key Observations
4. Recommended Next Steps (triage advice)

Keep it professional and concise. Use clinical terminology where appropriate."""

    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
        )
        return response.text
    except Exception:
        return _fallback_summary(sex, severity, duration, symptoms_text)


def _fallback_summary(sex, severity, duration, symptoms_text):
    return (
        f"PATIENT CLINICAL BRIEF\n"
        f"----------------------\n"
        f"Sex: {sex}\n"
        f"Severity Level: {severity}\n"
        f"Duration: {duration}\n"
        f"Symptoms: {symptoms_text}\n\n"
        f"[AI offline - structured data captured for manual review]"
    )
