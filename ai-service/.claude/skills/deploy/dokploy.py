#!/usr/bin/env python3
"""Dokploy helper for the /deploy skill (DEV-Johnstocker/chatwoot#1).

  dokploy.py [--target staging] status   compose status, deployed commit, recent deployments
  dokploy.py [--target staging] deploy   start a deploy (refuses while one is running) and wait
  dokploy.py [--target staging] verify   public checks plus container health over SSH

The target is production unless --target staging is given (DEV-Johnstocker/chatwoot#37).

Configuration comes from an env file, never from this public repository:
DOKPLOY_URL, DOKPLOY_API_KEY and DOKPLOY_COMPOSE_ID; for staging also
DOKPLOY_STAGING_COMPOSE_ID, which must differ from the production one. The file is
$DEPLOY_ENV_FILE, or the first `.env.supabase` found in the current directory
or its parents. Secrets are never printed.

Optional: CHATWOOT_PUBLIC_URL (default https://pronto.johnstockeraistudio.com),
STAGING_PUBLIC_URL (default https://pronto-staging.johnstockeraistudio.com)
and DEPLOY_SSH_HOST (default llmopshostinger). DEPLOY_SSH_FORCED=1 (CI) sends
keywords for the VPS staging-ci forced command instead of shell commands.
DEPLOY_NO_SSH=1 skips the container check in verify (the production promote
workflow has no SSH key).
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

PUBLIC_URL = os.environ.get("CHATWOOT_PUBLIC_URL", "https://pronto.johnstockeraistudio.com")
STAGING_URL = os.environ.get("STAGING_PUBLIC_URL", "https://pronto-staging.johnstockeraistudio.com")
STAGING_ADMIN_URL = os.environ.get("STAGING_ADMIN_URL", "https://ai-admin-staging.johnstockeraistudio.com")
# Staging shares the production VPS: refuse to build/pull with less disk free.
MIN_FREE_GB = 10
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


def select_target(values, target):
    """Return the config for one target: DOKPLOY_COMPOSE_ID is that target's compose."""
    config = dict(values)
    if target == "production":
        config["PUBLIC_URL"] = PUBLIC_URL
        return config
    if target != "staging":
        fail(f"unknown target {target!r}: use production or staging")
    staging_id = values.get("DOKPLOY_STAGING_COMPOSE_ID")
    if not staging_id:
        fail("missing in env file: DOKPLOY_STAGING_COMPOSE_ID")
    if staging_id == values.get("DOKPLOY_COMPOSE_ID"):
        fail("DOKPLOY_STAGING_COMPOSE_ID equals the production compose; refusing")
    config["DOKPLOY_COMPOSE_ID"] = staging_id
    config["PUBLIC_URL"] = STAGING_URL
    config["TARGET"] = "staging"
    return config


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


def remote_command(kind, app):
    """The command sent over SSH for one kind of check.

    With DEPLOY_SSH_FORCED=1 (CI) the key may only run the staging-ci script on the
    VPS (an authorized_keys forced command), which takes these keywords instead.
    """
    shell = {
        "free-gb": "df -BG --output=avail / | tail -1",
        "containers": f"docker ps -a --filter name={app}- --format '{{{{.Names}}}}\t{{{{.Status}}}}'",
    }
    if kind not in shell:
        fail(f"unknown remote check {kind!r}")
    return kind if os.environ.get("DEPLOY_SSH_FORCED") == "1" else shell[kind]


def free_gb():
    """Free disk on the VPS root filesystem in GB, or None if unknown."""
    command = ["ssh", "-o", "BatchMode=yes", SSH_HOST, remote_command("free-gb", None)]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    digits = re.sub(r"[^0-9]", "", result.stdout)
    return int(digits) if result.returncode == 0 and digits else None


def check_disk(target, available):
    """Fail a staging deploy when the shared VPS is short of disk."""
    if target != "staging":
        return
    if available is None:
        fail("could not read free disk on the VPS; refusing a staging deploy")
    if available < MIN_FREE_GB:
        fail(f"only {available} GB free on the VPS (need {MIN_FREE_GB}); refusing a staging deploy")


def deploy(config):
    check_disk(config.get("TARGET", "production"), free_gb() if config.get("TARGET") == "staging" else None)
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


# Cloudflare blocks the default "Python-urllib" agent on the staging host (403 before
# the request reaches Access or ai-service), so public checks name themselves.
USER_AGENT = "chatwoot-deploy-verify/1 (+DEV-Johnstocker/chatwoot#37)"


def public_request(url, method="GET"):
    return urllib.request.Request(url, method=method, data=b"{}" if method == "POST" else None,
                                  headers={"Content-Type": "application/json", "User-Agent": USER_AGENT})


def http_status(url, method="GET"):
    request = public_request(url, method)
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


def public_checks(config):
    """(name, url, method, wanted statuses) for the target's public address."""
    url = config["PUBLIC_URL"]
    webhook = ("POST /webhooks/chatwoot unsigned", f"{url}/webhooks/chatwoot", "POST", {401})
    if config.get("TARGET") == "staging":
        # Everything sits behind Cloudflare Access except the signed webhook.
        # Onboarding matters most: on a fresh install it creates the super admin.
        access = {302, 403}
        return [
            ("GET /api (behind Access)", f"{url}/api", "GET", access),
            ("GET /installation/onboarding (behind Access)", f"{url}/installation/onboarding", "GET", access),
            ("GET staging /admin (behind Access)", f"{STAGING_ADMIN_URL}/admin", "GET", access),
            webhook,
        ]
    return [
        ("GET /api", f"{url}/api", "GET", {200}),
        ("GET /app/login", f"{url}/app/login", "GET", {200}),
        ("GET /admin (public host)", f"{url}/admin", "GET", {404}),
        webhook,
    ]


def verify(config):
    checks = [(name, http_status(url, method), want) for name, url, method, want in public_checks(config)]
    ok = True
    for name, got, want in checks:
        passed = got in want
        ok &= passed
        print(f"{'PASS' if passed else 'FAIL'}  {name}: {got} (want {'/'.join(map(str, sorted(want)))})")

    app = api(config, "compose.one", {"composeId": config["DOKPLOY_COMPOSE_ID"]}).get("appName")
    containers_ok, lines = container_check(app)
    for line in lines:
        print(line)
    sys.exit(0 if ok and containers_ok else 1)


def container_check(app):
    """(ok, report lines) for the stack's containers, read over SSH.

    DEPLOY_NO_SSH=1 skips it: the production promote workflow has no SSH key
    and relies on the public checks (DEV-Johnstocker/chatwoot#39).
    """
    if os.environ.get("DEPLOY_NO_SSH") == "1":
        return True, ["SKIP  containers: no SSH here (DEPLOY_NO_SSH=1); public checks only"]
    command = ["ssh", "-o", "BatchMode=yes", SSH_HOST, remote_command("containers", app)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        return False, ["FAIL  containers: ssh failed"]
    ok, lines = True, []
    for line in result.stdout.splitlines():
        name, _, state = line.partition("\t")
        healthy = state.startswith("Up") and "unhealthy" not in state
        ok &= healthy
        lines.append(f"{'PASS' if healthy else 'FAIL'}  {name}: {state}")
    return ok, lines


def parse_args(argv):
    """Return (target, command) from argv[1:]."""
    target = "production"
    if len(argv) == 3 and argv[0] == "--target":
        target, argv = argv[1], argv[2:]
    if len(argv) != 1 or argv[0] not in ("status", "deploy", "verify"):
        fail("usage: dokploy.py [--target staging] status|deploy|verify")
    return target, argv[0]


def main():
    target, command = parse_args(sys.argv[1:])
    config = select_target(load_config(), target)
    print(f"target={target}")
    {"status": status, "deploy": deploy, "verify": verify}[command](config)


if __name__ == "__main__":
    main()
