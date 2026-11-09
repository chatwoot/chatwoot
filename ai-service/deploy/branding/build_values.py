#!/usr/bin/env python3
"""Build values.json for pronto_branding.rb from the files in this folder.

Usage: python3 build_values.py <site-url> > values.json
Example: python3 build_values.py https://chat.example.com > values.json

Standard library only. Logos are embedded as SVG data URIs, so Chatwoot serves
them from its own settings and no Chatwoot file has to change. Refs #1.
"""
import base64
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def data_uri(name):
    encoded = base64.b64encode((HERE / name).read_bytes()).decode()
    return "data:image/svg+xml;base64," + encoded


def build(site_url):
    values = {
        "INSTALLATION_NAME": "Pronto",
        "BRAND_NAME": "Pronto",
        "LOGO": data_uri("logo.svg"),
        "LOGO_DARK": data_uri("logo_dark.svg"),
        "LOGO_THUMBNAIL": data_uri("logo_thumbnail.svg"),
        "BRAND_URL": site_url,
        "WIDGET_BRAND_URL": site_url,
        "DASHBOARD_SCRIPTS": (HERE / "hide-paid-features.html").read_text(),
        # Off, or Chatwoot's own favicon PNGs win the browser tab over LOGO_THUMBNAIL.
        "DISPLAY_MANIFEST": False,
    }
    return {name: {"present": True, "value": value} for name, value in values.items()}


def main(argv):
    if len(argv) != 2 or not argv[1].startswith("https://"):
        sys.exit("usage: build_values.py https://<chatwoot-host> > values.json")
    json.dump(build(argv[1].rstrip("/")), sys.stdout)


if __name__ == "__main__":
    main(sys.argv)
