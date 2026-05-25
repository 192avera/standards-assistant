# Company Engineering Standards

Source: Confluence — Engineering Standards and Development Guidelines for Consistency and Maintainability

---

## General Principles

- **Consistency over preference** — follow conventions, not personal style
- **Automation over manual enforcement** — Ruff and CI enforce rules, not reviews alone
- **Clarity over cleverness** — readable and simple beats optimized and obscure
- **Backward compatibility** — avoid breaking existing functionality
- **Incremental improvement** — small improvements while touching code, not big refactors

---

## Python Style

- Follow PEP8
- Maximum line length: **99 characters**
- Formatting and linting enforced by **Ruff** — never discuss formatting manually
- Variables and functions: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_CASE`

---

## Type Hints

- **Required** for all non-trivial functions
- If type hints become complex, simplify the design — do not create deeply nested generics
- Prefer **Pydantic models** over complicated `dict[str | int, list[...] | float]` types

BAD:
```python
def process(data: dict[str | int, list[str | int] | float]) -> None:
```

GOOD:
```python
from pydantic import BaseModel

class Item(BaseModel):
    name: str
    value: float

def process(data: list[Item]) -> None:
```

---

## Docstrings

- Use **Google Style** docstrings
- Required for all non-trivial functions, including private ones

```python
def calculate_total(values: list[float]) -> float:
    """Calculate total value.

    Args:
        values: List of numeric values.

    Returns:
        Sum of values.
    """
    return sum(values)
```

---

## Error Handling

- Handle errors **explicitly** — no generic `except Exception: pass`
- Bare `except` clauses are **not allowed**
- Log with context **before** re-raising
- Raise specific custom exception types

BAD:
```python
try:
    processed = process()
except Exception:
    pass
```

GOOD:
```python
class UserNotFoundError(Exception):
    pass

def get_user(user_id: int) -> User:
    user = database.find_user(user_id)
    if user is None:
        raise UserNotFoundError(f"User not found: {user_id}")
    try:
        processed = process(user)
    except ValueError as e:
        logger.exception("processing_failed", extra={"error": str(e)})
        raise
    return processed
```

---

## External Calls

- All external API calls must be **encapsulated in a client or wrapper class**
- Business logic must **not** call external services directly
- All external calls must include **explicit timeouts** — default/infinite timeouts are forbidden
- Implement retry with **limits and backoff**

BAD:
```python
requests.get("https://api.example.com")
```

GOOD:
```python
class APIClient:
    def get_data(self) -> dict:
        for attempt in range(3):
            try:
                return requests.get(url, timeout=(3, 10))
            except TimeoutError:
                time.sleep(2 ** attempt)
        raise ExternalServiceError("API failed after retries")
```

---

## Logging

- Use a **proper logger** — `print()` is never acceptable for logging
- Logs must include **meaningful context** (identifiers, relevant state)
- **Never log sensitive data** (passwords, tokens, secrets)

BAD:
```python
print("error occurred")
logger.info("login_attempt", extra={"password": password})
```

GOOD:
```python
logger.error("error_occurred", extra={"user_id": user_id})
logger.info("login_attempt", extra={"user_id": user.id})
```

---

## Commented-Out Code

Allowed **only with a full justification block** immediately above:
- Why it is commented
- What it used to do
- What replaced it
- When/under what condition it may be needed again
- Whether it should be removed later

```python
# Temporarily disabled because the legacy payment provider is being phased out.
# Replaced by StripePaymentClient in payment_gateway.py.
# Keep until all customers are migrated, then remove after 2026-09-30.
#
# legacy_client = LegacyPaymentClient()
# legacy_client.process_payment(order)
```

---

## Function Design

- Small, single responsibility, easy to test
- **Use verbs** in function names — they must describe what they do
- Prefer explicit arguments; use models instead of many parameters
- **Avoid:**
  - Deep nesting — prefer early returns
  - Long functions (> ~50 lines guideline)
  - Mixed return types
  - Repeated logic
  - Side effects
  - Hidden dependencies
  - Global state

BAD:
```python
def handle(data):
    if user:
        if user['bar'] > 10:
            if user['foo']:
                do_something()
    else:
        print('wrong')
    return
```

GOOD:
```python
def calculate_total_amount(items: list[Item]) -> float:
    ...

# Early returns over nesting:
if not user:
    print('wrong')
    return
if user['bar'] <= 10:
    return
if user['foo']:
    do_something()
```

---

## Security (OWASP Mindset)

- Input validation on all external inputs
- Secure authentication
- **Never hardcode API keys, secrets, or credentials**
- Use **AWS Secrets Manager** for sensitive information
- Secure AI usage — API keys must not appear in code or logs

---

## Dependencies

- Managed with **uv**
- **Lockfile must always be committed**
- CI validates that dependencies are consistent

---

## Configuration

- All config values from **environment variables**
- Use **`pydantic_settings.BaseSettings`** for typed config
- Secrets must never be in code or repositories

BAD:
```python
API_KEY = "123456"
```

GOOD:
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_key: str

settings = Settings()
```

---

## Testing

- Use **pytest**
- Dev and test environments mirror production
- Mirror path structure:
  - `src/app/services/payment.py` → `tests/services/test_payment.py`
- Test names use `test_should_*` convention:
  - `def test_should_fail_when_user_not_found():`
- Every new feature requires a test

---

## Project Structure

```
project/
├── src/
│   └── app/
│       ├── api/
│       ├── services/
│       ├── models/
│       └── utils/
├── tests/
├── pyproject.toml
└── README.md
```

No random scripts in root.

---

## Docker

- All services containerized with Docker
- Use **explicit base image version**, never `latest`
- Install only required system dependencies
- Use **uv** for Python dependency installation
- Copy only necessary files
- No secrets inside the image
- Clear documented entrypoint

BAD:
```dockerfile
FROM python:latest
COPY . .
RUN pip install -r requirements.txt
CMD python app.py
```

GOOD:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen
COPY src ./src
CMD ["uv", "run", "python", "-m", "app.main"]
```

---

## Git Workflow

- Commits must be **atomic** — one logical change per commit
- Commit messages must include the **Jira ticket ID** (example: PROJ):
  ```
  PROJ-123 feat: add timeout handling

  Why:
  Prevent hanging requests

  What:
  Added timeout and retries
  ```
- PR title format: `PROJ-123: Add payment timeout handling`
- PR description must include: what changed, why, Jira link, testing performed, risk/rollback notes
- **No direct commits to main**
- Require PR + passing pipeline + at least one approval + resolved comments
- **Squash merge** preferred for clean history
