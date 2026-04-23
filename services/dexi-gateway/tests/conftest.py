from __future__ import annotations

import os

os.environ.setdefault("DEXI_MOCK_MODE", "true")
os.environ.setdefault("DATABASE_URL", "sqlite:///./test.db")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
