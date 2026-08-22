#!/usr/bin/env python3
"""Static server with SPA fallback: serves files from public/, but any
path without a file extension returns dash-check.html so Vue's client-side
router (e.g. /app/login) renders inside the mounted app."""
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.join(os.path.dirname(__file__), "..", "public")
INDEX = "dash-check.html"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=os.path.abspath(ROOT), **kw)

    def do_GET(self):
        path = self.path.split("?", 1)[0].split("#", 1)[0]
        fs_path = os.path.join(os.path.abspath(ROOT), path.lstrip("/"))
        # Serve real file if it exists; otherwise fall back to the harness
        # so client-side routes (/app/login etc.) render the mounted app.
        if path != "/" and (os.path.isfile(fs_path) or "." not in os.path.basename(path)):
            if not os.path.isfile(fs_path):
                self.path = "/" + INDEX
        elif path != "/" and "." not in os.path.basename(path):
            self.path = "/" + INDEX
        return super().do_GET()


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8089"))
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
