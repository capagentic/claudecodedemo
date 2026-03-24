# Document

Generate standardised documentation for code files following Department of Health (DoH) documentation standards.

## Instructions

When invoked, analyse the specified file(s) or the current working context and produce a documentation block following the DoH standard below.

If the user provides a filename or path, document that file. If no file is specified, ask the user which file(s) to document.

## DoH Documentation Standard

Produce the following documentation header block for each file:

```
# ============================================================
# FILE:         <filename with extension>
# ============================================================
# PURPOSE:
#   <Clear, concise description of what this file does and
#    its role within the overall system or module.>
#
# BUSINESS REQUIREMENT:
#   <Reference to the business requirement, user story, or
#    ticket this code satisfies. Include ticket/story IDs
#    where applicable, e.g. A2I-123, JIRA-456.>
#
# CHANGE HISTORY:
#   Date          Author              Description
#   ----------    ----------------    ----------------------------
#   YYYY-MM-DD    <Full Name>         Initial creation
#   YYYY-MM-DD    <Full Name>         <Description of change>
#
# CONSIDERATIONS:
#   - <Any known limitations, dependencies, or assumptions>
#   - <Security or compliance considerations (e.g. PII handling,
#      OFFICIAL: Sensitive data, Essential Eight controls)>
#   - <Infrastructure or environment-specific notes>
#   - <Performance or scalability considerations>
#   - <Any technical debt or future improvements flagged>
# ============================================================
```

## Rules

- Use the comment style appropriate for the file type (e.g. `#` for Python/YAML/Shell, `//` for JavaScript/TypeScript, `/* */` for CSS/Java)
- Always use Australian date format: DD-MM-YYYY in change history display, but store as YYYY-MM-DD for sorting
- The PURPOSE should be 2–4 sentences maximum — clear and non-technical enough for a business stakeholder to understand
- BUSINESS REQUIREMENT must reference a ticket, user story, or requirement ID if one exists — if unknown, write "To be confirmed"
- CONSIDERATIONS must always include a security/compliance note relevant to DoH context (e.g. data sovereignty, PII, OFFICIAL: Sensitive classification)
- If documenting multiple files, produce a separate block for each file
- After generating the documentation block, insert it at the top of the file (below any shebang line if present)

## Example Output (Python)

```python
# ============================================================
# FILE:         litellm_guardrails.py
# ============================================================
# PURPOSE:
#   Implements custom guardrail logic for the LiteLLM proxy
#   deployed on EC2 as part of the AccelerateAI (A2I) platform.
#   Enforces OWASP LLM Top 10 mitigations and DoH content
#   filtering policies before requests reach AWS Bedrock.
#
# BUSINESS REQUIREMENT:
#   A2I-087 — Implement prompt injection and PII detection
#   guardrails for all LLM inference requests processed by
#   the A2I platform in the DoH environment.
#
# CHANGE HISTORY:
#   Date          Author              Description
#   ----------    ----------------    ----------------------------
#   2025-06-01    Kevin Wu            Initial creation
#   2025-06-15    Kevin Wu            Added Bedrock Guardrails integration
#
# CONSIDERATIONS:
#   - All requests may contain OFFICIAL: Sensitive data — ensure
#     no prompt content is logged to CloudWatch in plain text
#   - PII detection uses AWS Comprehend; ensure data remains
#     within ap-southeast-2 for data sovereignty compliance
#   - Guardrail bypass attempts should trigger an SNS alert
#   - Python 3.11+ required for match/case syntax used here
#   - Technical debt: regex patterns should be moved to config
# ============================================================
```
