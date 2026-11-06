#!/usr/bin/env python3
"""Dokploy helper for the /deploy skill (DEV-Johnstocker/chatwoot#1).

  dokploy.py status   compose status, deployed commit, recent deployments
  dokploy.py deploy   start a deploy (refuses while one is running) and wait
  dokploy.py verify   public checks plus container health over SSH

Configuration comes from an env file, never from this public repository:
DOKPLOY_URL, DOKPLOY_API_KEY and DOKPLOY_COMPOSE_ID. The file is
$DEPLOY_ENV_FILE, or the first `.env.supabase` found in the current directory
or its parents. Secrets are never printed.

Optional: CHATWOOT_PUBLIC_URL (default https://chat.johnstockeraistudio.com)
and DEPLOY_SSH_HOST (default llmopshostinger).
"""

import json
import os
import re
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request

PUBLIC_URL = os.environ.get("CHATWOOT_PUBLIC_URL", "https://chat.johnstockeraistudio.com")
SSH_HOST = os.environ.get("DEPLOY_SSH_HOST", "llmopshostinger")
DEPLOY_TIMEOUT_S = 30 * 60
POLL_S = 15
COMMIT = re.compile(r"Commit: ([0-9a-f]{40})")


def tls_context():
    """Verified TLS even when this Python ships without a CA bundle (python.org macOS builds)."""
    try:
        import certifi  # noqa: PLC0415 - optional
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        pass
    if os.path.isfile("/etc/ssl/cert.pem"):
        return ssl.create_default_context(cafile="/etc/ssl/cert.pem")
    return ssl.create_default_context()


TLS = tls_context()


def fail(message):
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


def find_env_file():
    explicit = os.environ.get("DEPLOY_ENV_FILE")
    if explicit:
        return explicit
    directory = os.getcwd()
    while True:
        candidate = os.path.join(directory, ".env.supabase")
        if os.path.isfile(candidate):
            return candidate
        parent = os.path.dirname(directory)
        if parent == directory:
            return None
        directory = parent


def load_config():
    path = find_env_file()
    if not path:
        fail("no env file: set DEPLOY_ENV_FILE or run inside the workspace")
    values = {}
    with open(path) as handle:
        for line in handle:
            match = re.match(r"\s*(?:export\s+)?([A-Z0-9_]+)=(.*)", line)
            if match:
                values[match.group(1)] = match.group(2).strip().strip("'\"")
    missing = [k for k in ("DOKPLOY_URL", "DOKPLOY_API_KEY", "DOKPLOY_COMPOSE_ID") if not values.get(k)]
    if missing:
        fail(f"missing in env file: {', '.join(missing)}")
    return values


def api(config, procedure, query=None, body=None):
    url = f"{config['DOKPLOY_URL'].rstrip('/')}/api/{procedure}"
    if query:
        url += "?" + "&".join(f"{k}={v}" for k, v in query.items())
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        url,
        data=data,
        headers={"x-api-key": config["DOKPLOY_API_KEY"], "Content-Type": "application/json"},
        method="POST" if data is not None else "GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=30, context=TLS) as response:
            text = response.read().decode()
    except urllib.error.HTTPError as error:
        fail(f"{procedure}: HTTP {error.code}")
    except urllib.error.URLError as error:
        fail(f"{procedure}: {error.reason}")
    return json.loads(text) if text else None


def deployments(config):
    return api(config, "deployment.allByCompose", {"composeId": config["DOKPLOY_COMPOSE_ID"]}) or []


def deployed_commit(items):
    for item in items:
        if item.get("status") == "done":
            match = COMMIT.search(item.get("description") or "")
            if match:
                return match.group(1)
    return None


def status(config):
    compose = api(config, "compose.one", {"composeId": config["DOKPLOY_COMPOSE_ID"]})
    items = deployments(config)
    print(f"branch={compose.get('customGitBranch')} status={compose.get('composeStatus')} "
          f"autoDeploy={compose.get('autoDeploy')} app={compose.get('appName')}")
    print(f"deployed_commit={deployed_commit(items) or 'unknown'}")
    running = [i for i in items if i.get("status") == "running"]
    print(f"running_deploys={len(running)}")
    for item in items[:5]:
        title = (item.get("title") or "").splitlines()[0][:70]
        print(f"  {item.get('status'):8} {item.get('createdAt')}  {title}")
    return compose, items


def deploy(config):
    items = deployments(config)
    if any(i.get("status") == "running" for i in items):
        fail("a deploy is already running; wait for it, do not start another")
    known = {i.get("deploymentId") for i in items}
    api(config, "compose.deploy", body={"composeId": config["DOKPLOY_COMPOSE_ID"]})
    print("deploy requested; waiting")
    deadline = time.time() + DEPLOY_TIMEOUT_S
    while time.time() < deadline:
        time.sleep(POLL_S)
        new = [i for i in deployments(config) if i.get("deploymentId") not in known]
        if not new:
            continue
        current = new[0]
        state = current.get("status")
        if state == "done":
            match = COMMIT.search(current.get("description") or "")
            print(f"deploy done: commit={match.group(1) if match else 'unknown'}")
            return
        if state == "error":
            fail(f"deploy failed: {(current.get('errorMessage') or '')[:300]}")
    fail("timed out waiting for the deploy; check Dokploy before retrying")


def http_status(url, method="GET"):
    request = urllib.request.Request(url, method=method, data=b"{}" if method == "POST" else None,
                                     headers={"Content-Type": "application/json"})
    opener = urllib.request.build_opener(NoRedirect, urllib.request.HTTPSHandler(context=TLS))
    try:
        with opener.open(request, timeout=20) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code
    except urllib.error.URLError:
        return None


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def verify(config):
    checks = [
        ("GET /api", http_status(f"{PUBLIC_URL}/api"), 200),
        ("GET /app/login", http_status(f"{PUBLIC_URL}/app/login"), 200),
        ("GET /admin (public host)", http_status(f"{PUBLIC_URL}/admin"), 404),
        ("POST /webhooks/chatwoot unsigned", http_status(f"{PUBLIC_URL}/webhooks/chatwoot", "POST"), 401),
    ]
    ok = True
    for name, got, want in checks:
        passed = got == want
        ok &= passed
        print(f"{'PASS' if passed else 'FAIL'}  {name}: {got} (want {want})")

    app = api(config, "compose.one", {"composeId": config["DOKPLOY_COMPOSE_ID"]}).get("appName")
    command = ["ssh", "-o", "BatchMode=yes", SSH_HOST,
               f"docker ps -a --filter name={app}- --format '{{{{.Names}}}}\t{{{{.Status}}}}'"]
    result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        print("FAIL  containers: ssh failed")
        ok = False
    for line in result.stdout.splitlines():
        name, _, state = line.partition("\t")
        healthy = state.startswith("Up") and "unhealthy" not in state
        ok &= healthy
        print(f"{'PASS' if healthy else 'FAIL'}  {name}: {state}")
    sys.exit(0 if ok else 1)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("status", "deploy", "verify"):
        fail("usage: dokploy.py status|deploy|verify")
    config = load_config()
    {"status": status, "deploy": deploy, "verify": verify}[sys.argv[1]](config)


if __name__ == "__main__":
    main()
