"""السيرفر معزول عن الإنترنت: لا موارد خارجية في الواجهة ولا اتصالات في الكود."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
URL = re.compile(r"(https?:)?//[a-z0-9.-]+\.[a-z]{2,}", re.IGNORECASE)


def test_templates_and_static_files_load_nothing_from_outside():
    for path in list((ROOT / "app" / "templates").rglob("*.html")) + list(
        (ROOT / "app" / "static").rglob("*.*")
    ):
        text = path.read_text(encoding="utf-8")
        assert not URL.search(text), f"external reference in {path}"
        assert "@import" not in text, path


def test_no_outbound_network_libraries_in_app_code():
    forbidden = ("requests", "urllib.request", "httpx", "aiohttp", "smtplib", "socket.create_connection")
    for path in (ROOT / "app").rglob("*.py"):
        text = path.read_text(encoding="utf-8")
        for name in forbidden:
            assert f"import {name}" not in text and f"from {name}" not in text, (path, name)
