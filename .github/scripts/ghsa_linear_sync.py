#!/usr/bin/env python3
"""Sync triage GitHub security advisories to Linear issues."""

from __future__ import annotations

import os
import sys
from typing import Any

import requests

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


def fetch_triage_advisories(repo: str, token: str) -> list[dict[str, Any]]:
    url: str | None = f"{GITHUB_API}/repos/{repo}/security-advisories"
    params: dict[str, Any] | None = {"state": "triage", "per_page": 100}
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    advisories: list[dict[str, Any]] = []
    while url:
        r = requests.get(url, headers=headers, params=params, timeout=30)
        r.raise_for_status()
        advisories.extend(r.json())
        next_link = r.links.get("next")
        url = next_link["url"] if next_link else None
        params = None
    return advisories


def linear_call(query: str, variables: dict[str, Any], api_key: str) -> dict[str, Any]:
    r = requests.post(
        LINEAR_API,
        headers={"Authorization": api_key},
        json={"query": query, "variables": variables},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()


def linear_issue_exists(ghsa_id: str, api_key: str) -> bool:
    query = (
        "query($q: String!) { issues(filter: {title: {contains: $q}}, first: 1) "
        "{ nodes { id } } }"
    )
    resp = linear_call(query, {"q": ghsa_id}, api_key)
    return len(resp.get("data", {}).get("issues", {}).get("nodes", [])) > 0


def linear_create_issue(input_data: dict[str, Any], api_key: str) -> dict[str, str] | None:
    query = (
        "mutation($input: IssueCreateInput!) { issueCreate(input: $input) "
        "{ success issue { identifier url } } }"
    )
    resp = linear_call(query, {"input": input_data}, api_key)
    create = resp.get("data", {}).get("issueCreate") or {}
    if not create.get("success"):
        return None
    return create.get("issue")


def reporter_login(advisory: dict[str, Any]) -> str:
    for credit in advisory.get("credits") or []:
        user = (credit or {}).get("user") or {}
        if user.get("login"):
            return user["login"]
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
        requests.post(webhook_url, json=payload, timeout=10)
    except requests.RequestException:
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
        except requests.RequestException:
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
