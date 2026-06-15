"""Editable agent system prompts.

A real business needs to tune tone, policy, and escalation rules without a redeploy. Specialist
prompts are stored in the ``agent_prompt`` table and edited in the admin panel; agents read them
at runtime (Pydantic AI re-evaluates dynamic system prompts on every run), so edits take effect
live. Code-defined defaults apply until an operator overrides them.
"""
from __future__ import annotations

from pydantic_ai import Agent
from sqlalchemy import select

# Runtime cache of overridden prompts: agent name → system prompt.
_cache: dict[str, str] = {}
# Code defaults, registered by each agent at import so the panel can show/restore them.
DEFAULTS: dict[str, str] = {}


def get(agent: str) -> str:
    return _cache.get(agent) or DEFAULTS.get(agent, "")


async def refresh() -> None:
    """Reload overridden prompts from the database (no-op if the DB is unavailable)."""
    from .db import SessionLocal
    from .models_db import AgentPrompt

    try:
        async with SessionLocal() as session:
            rows = (await session.execute(select(AgentPrompt))).scalars().all()
    except Exception:
        return
    _cache.clear()
    _cache.update({r.agent: r.system_prompt for r in rows if r.system_prompt})


async def set_prompt(agent: str, system_prompt: str) -> None:
    """Persist an override and update the cache."""
    from .db import SessionLocal
    from .models_db import AgentPrompt

    async with SessionLocal() as session:
        row = await session.get(AgentPrompt, agent)
        if row is None:
            row = AgentPrompt(agent=agent, system_prompt=system_prompt)
            session.add(row)
        else:
            row.system_prompt = system_prompt
        await session.commit()
    _cache[agent] = system_prompt


def register(agent: Agent, name: str, default: str) -> None:
    """Record the default and attach a dynamic system prompt that honours panel overrides."""
    DEFAULTS[name] = default

    @agent.system_prompt
    def _system() -> str:
        return get(name)
