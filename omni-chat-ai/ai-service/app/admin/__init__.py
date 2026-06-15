"""Admin panel: server-rendered settings UI (login, first-run wizard, dashboard, settings).

Polished Tailwind (CDN) + Alpine.js templates served by FastAPI. All user-facing API keys are
entered here and stored encrypted via ``settings_service`` — no .env editing required.
"""
from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Form, Request
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from .. import auth, channels, provisioning, settings_service

_DIR = Path(__file__).parent
templates = Jinja2Templates(directory=str(_DIR / "templates"))

router = APIRouter(prefix="/admin", tags=["admin"])


def _grouped_specs() -> dict[str, list]:
    grouped: dict[str, list] = {g: [] for g in settings_service.GROUPS}
    for spec in settings_service.REGISTRY:
        grouped[spec.group].append(spec)
    return grouped


@router.get("/", response_class=HTMLResponse)
async def index(request: Request):
    if not await auth.admin_exists():
        return RedirectResponse("/admin/setup", status_code=303)
    if auth.read_session(request) is None:
        return RedirectResponse("/admin/login", status_code=303)
    return RedirectResponse("/admin/dashboard", status_code=303)


# ----------------------------------------------------------------- first-run setup wizard
@router.get("/setup", response_class=HTMLResponse)
async def setup_form(request: Request):
    if await auth.admin_exists():
        return RedirectResponse("/admin/login", status_code=303)
    return templates.TemplateResponse(request, "setup.html", {"error": None})


@router.post("/setup")
async def setup_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
):
    if await auth.admin_exists():
        return RedirectResponse("/admin/login", status_code=303)
    if len(password) < 8:
        return templates.TemplateResponse(
            request, "setup.html", {"error": "Password must be at least 8 characters."}
        )
    await auth.create_admin(email, password)
    resp = RedirectResponse("/admin/dashboard", status_code=303)
    resp.set_cookie(auth.COOKIE_NAME, auth.issue_session(email), httponly=True, samesite="lax")
    return resp


# ----------------------------------------------------------------- login / logout
@router.get("/login", response_class=HTMLResponse)
async def login_form(request: Request):
    if not await auth.admin_exists():
        return RedirectResponse("/admin/setup", status_code=303)
    return templates.TemplateResponse(request, "login.html", {"error": None})


@router.post("/login")
async def login_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
):
    if not await auth.authenticate(email, password):
        return templates.TemplateResponse(
            request, "login.html", {"error": "Invalid email or password."}
        )
    resp = RedirectResponse("/admin/dashboard", status_code=303)
    resp.set_cookie(auth.COOKIE_NAME, auth.issue_session(email), httponly=True, samesite="lax")
    return resp


@router.get("/logout")
async def logout():
    resp = RedirectResponse("/admin/login", status_code=303)
    resp.delete_cookie(auth.COOKIE_NAME)
    return resp


# ----------------------------------------------------------------- dashboard
@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    cards = [
        {"group": g, "configured": any(
            settings_service.is_configured(s.key) for s in specs if s.secret
        ) or all(settings_service.is_configured(s.key) for s in specs)}
        for g, specs in _grouped_specs().items()
    ]
    return templates.TemplateResponse(
        request, "dashboard.html", {"cards": cards, "groups": settings_service.GROUPS}
    )


# ----------------------------------------------------------------- settings
@router.get("/settings", response_class=HTMLResponse)
async def settings_page(request: Request):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    values = {s.key: settings_service.get(s.key) for s in settings_service.REGISTRY}
    return templates.TemplateResponse(
        request,
        "settings.html",
        {"grouped": _grouped_specs(), "values": values, "saved": request.query_params.get("saved")},
    )


@router.post("/settings")
async def settings_save(request: Request):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    form = await request.form()
    for spec in settings_service.REGISTRY:
        if spec.key not in form:
            continue
        value = str(form[spec.key]).strip()
        # Don't overwrite a stored secret with the empty placeholder when left blank.
        if spec.secret and not value:
            continue
        await settings_service.set_value(spec.key, value)
    # When the AI provider/model/key changes, (re)register the alias with LiteLLM at runtime so
    # it takes effect without a restart.
    if any(str(form.get(k, "")).strip() for k in ("ai.api_key", "ai.model", "ai.provider")):
        await provisioning.register_llm_model()
    return RedirectResponse("/admin/settings?saved=1", status_code=303)


# ----------------------------------------------------------------- channels (auto-provision)
@router.get("/channels", response_class=HTMLResponse)
async def channels_page(request: Request):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    ctx = {
        "has_token": settings_service.is_configured("chatwoot.api_access_token"),
        "widget_inbox": settings_service.get("chatwoot.web_widget_inbox_id"),
        "widget_script": settings_service.get("chatwoot.web_widget_script"),
        "telegram_inbox": settings_service.get("chatwoot.telegram_inbox_id"),
        "telegram_set": settings_service.is_configured("channels.telegram_bot_token"),
        "flash": request.query_params.get("flash"),
        "ok": request.query_params.get("ok"),
    }
    return templates.TemplateResponse(request, "channels.html", ctx)


@router.post("/channels/web-widget")
async def channels_web_widget(request: Request, website_url: str = Form(...)):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    ok, msg = await channels.ensure_web_widget(website_url.strip())
    return RedirectResponse(f"/admin/channels?ok={int(ok)}&flash={msg}", status_code=303)


@router.post("/channels/telegram")
async def channels_telegram(request: Request):
    if (redirect := auth.require_admin(request)) is not None:
        return redirect
    ok, msg = await channels.ensure_telegram()
    return RedirectResponse(f"/admin/channels?ok={int(ok)}&flash={msg}", status_code=303)


# ----------------------------------------------------------------- connection tests (AJAX)
@router.post("/test/{group}")
async def test_group(request: Request, group: str):
    if auth.read_session(request) is None:
        return JSONResponse({"ok": False, "message": "Unauthorized"}, status_code=401)
    ok, message = await provisioning.test_connection(group)
    return JSONResponse({"ok": ok, "message": message})
