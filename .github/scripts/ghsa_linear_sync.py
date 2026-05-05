#!/usr/bin/env python3
"""Sync triage GitHub security advisories to Linear issues.

Behaviour mirrors the previous inline bash workflow: fetch all triage
advisories, dedupe against Linear by GHSA ID in the issue title, create
missing Linear issues with full advisory content in the description,
and post a Discord embed when DISCORD_WEBHOOK_URL is set.

The script prints an aggregate count line; it does not log GHSA IDs or
Linear ticket URLs, so logs are safe to leave in public Actions output.
Exit code is non-zero if any creation failed.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any

GITHUB_API = "https://api.github.com"
LINEAR_API = "https://api.linear.app/graphql"

SEVERITY_PRIORITY = {"critical": 1, "high": 2, "medium": 3, "low": 4}
SEVERITY_COLOR = {
    "critical": 15548997,
    "high": 15105570,
    "medium": 15844367,
    "low": 3066993,
}
DEFAULT_COLOR = 9807270


def required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        sys.exit(f"Missing required env var: {name}")
    return value


def http_json(url: str, headers: dict[str, str], payload: dict[str, Any] | None = None) -> tuple[dict[str, Any] | list[Any], dict[str, str]]:
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req_headers = dict(headers)
    if payload is not None:
        req_headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=req_headers)
    with urllib.request.urlopen(req) as resp:
        body = json.loads(resp.read())
        return body, dict(resp.headers)


def next_link(link_header: str | None) -> str | None:
    if not link_header:
        return None
    for chunk in link_header.split(","):
        parts = [p.strip() for p in chunk.split(";")]
        if len(parts) < 2:
            continue
        url = parts[0].strip("<>")
        if parts[1] == 'rel="next"':
            return url
    return None


def fetch_triage_advisories(repo: str, token: str) -> list[dict[str, Any]]:
    url: str | None = (
        f"{GITHUB_API}/repos/{repo}/security-advisories?state=triage&per_page=100"
    )
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    advisories: list[dict[str, Any]] = []
    while url:
        page, resp_headers = http_json(url, headers)
        assert isinstance(page, list)
        advisories.extend(page)
        url = next_link(resp_headers.get("Link"))
    return advisories


def linear_query(query: str, variables: dict[str, Any], api_key: str) -> dict[str, Any]:
    body, _ = http_json(
        LINEAR_API,
        {"Authorization": api_key},
        {"query": query, "variables": variables},
    )
    assert isinstance(body, dict)
    return body


def linear_issue_exists(ghsa_id: str, api_key: str) -> bool:
    query = (
        "query($q: String!) { issues(filter: {title: {contains: $q}}, first: 1) "
        "{ nodes { id } } }"
    )
    resp = linear_query(query, {"q": ghsa_id}, api_key)
    nodes = resp.get("data", {}).get("issues", {}).get("nodes", [])
    return len(nodes) > 0


def linear_create_issue(input_data: dict[str, Any], api_key: str) -> dict[str, str] | None:
    query = (
        "mutation($input: IssueCreateInput!) { issueCreate(input: $input) "
        "{ success issue { identifier url } } }"
    )
    resp = linear_query(query, {"input": input_data}, api_key)
    create = resp.get("data", {}).get("issueCreate") or {}
    if not create.get("success"):
        return None
    return create.get("issue")


def reporter_login(advisory: dict[str, Any]) -> str:
    for credit in advisory.get("credits") or []:
        user = (credit or {}).get("user") or {}
        login = user.get("login")
        if login:
            return login
    return "unknown"


def cvss_score(advisory: dict[str, Any]) -> str:
    score = (advisory.get("cvss") or {}).get("score")
    return str(score) if score is not None else "n/a"


def build_description(adv: dict[str, Any]) -> str:
    return (
        f"**GHSA:** {adv['ghsa_id']}\n"
        f"**CVE:** {adv.get('cve_id') or 'n/a'}\n"
        f"**Severity:** {adv.get('severity') or 'unknown'} (CVSS {cvss_score(adv)})\n"
        f"**Reporter:** {reporter_login(adv)}\n"
        f"**Reported:** {(adv.get('created_at') or '').split('T')[0]}\n"
        f"**Advisory:** {adv['html_url']}\n\n"
        f"---\n\n"
        f"{adv.get('description') or 'No description provided.'}"
    )


def post_discord(adv: dict[str, Any], issue: dict[str, str], webhook_url: str) -> None:
    severity = adv.get("severity") or "unknown"
    title = f"[{adv['ghsa_id']}] {adv['summary']}"[:250]
    payload = {
        "username": "GHSA Sync",
        "embeds": [
            {
                "title": title,
                "url": issue["url"],
                "color": SEVERITY_COLOR.get(severity, DEFAULT_COLOR),
                "fields": [
                    {"name": "Linear", "value": issue["identifier"], "inline": True},
                    {
                        "name": "Severity",
                        "value": f"{severity} (CVSS {cvss_score(adv)})",
                        "inline": True,
                    },
                    {
                        "name": "Advisory",
                        "value": f"[GitHub]({adv['html_url']})",
                        "inline": True,
                    },
                ],
            }
        ],
    }
    try:
        http_json(webhook_url, {}, payload)
    except (urllib.error.URLError, json.JSONDecodeError):
        pass


def main() -> int:
    repo = required_env("GITHUB_REPOSITORY")
    gh_token = required_env("GHSA_READ_TOKEN")
    linear_api_key = required_env("LINEAR_API_KEY")
    team_id = required_env("LINEAR_TEAM_ID")
    project_id = required_env("LINEAR_PROJECT_ID")
    label_id = required_env("LINEAR_LABEL_ID")
    discord_webhook = os.environ.get("DISCORD_WEBHOOK_URL") or None

    advisories = fetch_triage_advisories(repo, gh_token)
    print(f"Fetched {len(advisories)} triage advisories")

    created = skipped = failed = 0

    for adv in advisories:
        ghsa_id = adv.get("ghsa_id")
        if not ghsa_id:
            failed += 1
            continue

        try:
            if linear_issue_exists(ghsa_id, linear_api_key):
                skipped += 1
                continue

            severity = adv.get("severity") or "unknown"
            issue = linear_create_issue(
                {
                    "title": f"[{ghsa_id}] {adv.get('summary', '')}",
                    "description": build_description(adv),
                    "teamId": team_id,
                    "projectId": project_id,
                    "labelIds": [label_id],
                    "priority": SEVERITY_PRIORITY.get(severity, 3),
                },
                linear_api_key,
            )
        except (urllib.error.URLError, KeyError, json.JSONDecodeError):
            failed += 1
            continue

        if not issue:
            failed += 1
            continue

        created += 1
        if discord_webhook:
            post_discord(adv, issue, discord_webhook)

    print(f"Created {created}, skipped {skipped}, failed {failed}")
    return 1 if failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
