# Test Modification Scenarios

Three concrete scenarios demonstrating `.claude/rules/test-modification.md` in action.
Each scenario starts from a working FastAPI project with passing tests.

---

## Scenario A: Add GET /items endpoint

**Code change type**: API endpoint added
**Affected layers**: unit + integration + snapshot

### Code change

```python
# src/my_project/main.py — add after /health endpoint

class Item(BaseModel):
    id: int
    name: str
    price: float

ITEMS_DB: list[Item] = [
    Item(id=1, name="Widget", price=9.99),
    Item(id=2, name="Gadget", price=24.99),
]

@app.get("/items", response_model=list[Item])
async def list_items() -> list[Item]:
    """Return all items."""
    return ITEMS_DB

@app.get("/items/{item_id}", response_model=Item)
async def get_item(item_id: int) -> Item:
    """Return a single item by ID."""
    for item in ITEMS_DB:
        if item.id == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item not found")
```

### Required test changes

**1. Unit test** — `tests/unit/test_items.py` (new file)

```python
from my_project.main import ITEMS_DB, Item

def test_items_db_has_entries() -> None:
    assert len(ITEMS_DB) >= 1
    assert all(isinstance(item, Item) for item in ITEMS_DB)

def test_item_model_fields() -> None:
    item = Item(id=1, name="Test", price=1.0)
    assert item.id == 1
    assert item.name == "Test"
    assert item.price == 1.0
```

**2. Integration test** — `tests/integration/test_items_api.py` (new file)

```python
from httpx import AsyncClient
import pytest
from my_project.main import app

@pytest.mark.anyio
async def test_list_items_returns_list() -> None:
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/items")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) >= 1

@pytest.mark.anyio
async def test_get_item_not_found() -> None:
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/items/9999")
    assert resp.status_code == 404
```

**3. Snapshot test** — `tests/snapshot/test_items_snapshot.py` (new file)

```python
from httpx import AsyncClient
import pytest
from syrupy.assertion import SnapshotAssertion
from my_project.main import app

@pytest.mark.anyio
async def test_list_items_snapshot(snapshot: SnapshotAssertion) -> None:
    async with AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/items")
    assert resp.json() == snapshot
```

Then run: `uv run pytest --snapshot-update` (first time only — snapshot doesn't exist yet).

---

## Scenario B: Add uptime field to HealthResponse

**Code change type**: Function signature / response schema changed
**Affected layers**: unit (existing) + snapshot (existing breaks)

### Code change

```python
# src/my_project/main.py — modify HealthResponse
import time

START_TIME = time.monotonic()

class HealthResponse(BaseModel):
    status: str
    version: str
    uptime_seconds: float  # NEW FIELD

@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(
        status="ok",
        version="0.1.0",
        uptime_seconds=round(time.monotonic() - START_TIME, 2),  # NEW
    )
```

### What happens

1. `uv run pytest` → **snapshot test fails** (response now has `uptime_seconds`)
2. Read the snapshot diff:
   ```diff
   + "uptime_seconds": 0.01,
   ```
3. Ask: "Did I intentionally add this field?" → **YES**
4. `uv run pytest --snapshot-update`
5. `git diff tests/` → verify only the `uptime_seconds` addition appears

### Also update

- **Existing unit test**: if it checks `HealthResponse` fields, add `uptime_seconds` assertion
- **Integration test**: response assertions need the new field

### What NOT to do

- Do NOT run `--snapshot-update` without reading the diff first
- Do NOT delete the snapshot test because it failed
- Do NOT snapshot `uptime_seconds` directly — it changes every call. Snapshot only deterministic fields (`status`, `version`), or use a syrupy matcher to ignore dynamic keys

---

## Scenario C: Refactor main.py (extract router)

**Code change type**: Refactoring (behavior unchanged)
**Affected layers**: none

### Code change

```python
# src/my_project/routes/health.py (new file — extracted from main.py)
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class HealthResponse(BaseModel):
    status: str
    version: str

@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(status="ok", version="0.1.0")
```

```python
# src/my_project/main.py (modified — include router)
from fastapi import FastAPI
from my_project.routes.health import router

app = FastAPI(title="my_project", version="0.1.0")
app.include_router(router)
```

### Required test changes

**None.** All existing tests must pass without modification.

- `uv run pytest` → all green → refactoring is correct
- If any test fails → the refactoring changed behavior → **fix the code, not the tests**

### Common mistakes

- Updating import paths in tests "because the code moved" — only do this if the tests directly import from the moved module. Integration tests hitting `/health` via HTTP client should be unaffected.
- Adding new tests for the router module — unnecessary if behavior is identical. Tests validate behavior, not structure.
