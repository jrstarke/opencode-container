# TensorZero Functions Listing Design

## Goal
Provide a reliable way to retrieve the list of available TensorZero functions for integration purposes.

## Approach Options
1. **Public API Query** – Use TensorZero’s published OpenAPI documentation to locate a `GET /v1/functions` (or similar) endpoint and call it directly.
2. **Repository Clone & Search** – Clone the TensorZero source repository, locate the gateway route that returns function metadata, and extract the function names.

## Recommended Approach
Option 1 (Public API Query) because it avoids pulling the large repository and gives up‑to‑date information.

## Steps
1. Identify the base URL from the TensorZero docs (e.g., `https://tensorzero.example.com/openai/v1`).
2. Perform a request:
   ```bash
   curl -s https://tensorzero.example.com/openai/v1/functions | jq . > functions.json
   ```
3. Verify the response contains an array of function objects with `name` fields.
4. Store the JSON list at `docs/superpowers/specs/2026-07-19-tensorzero-functions.json` for downstream tooling.

## Fallback
If the endpoint is missing, clone the repo and search under `gateway/api` for a route returning function metadata, then extract the names.

## Output Files
- `docs/superpowers/specs/2026-07-19-tensorzero-functions-design.md` (this design doc)
- `docs/superpowers/specs/2026-07-19-tensorzero-functions.json` (generated at runtime)

---
*Please review this design. Once approved, I will invoke the `writing-plans` skill to create an implementation plan.*