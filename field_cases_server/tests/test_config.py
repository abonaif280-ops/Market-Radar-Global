from __future__ import annotations

import pytest

from app.config import ConfigError, load_settings


def write(tmp_path, text, bom=False):
    path = tmp_path / "config.ini"
    path.write_bytes((b"\xef\xbb\xbf" if bom else b"") + text.encode("utf-8"))
    return path


def test_reads_port_and_database(tmp_path, monkeypatch):
    monkeypatch.delenv("FC_DATABASE_URL", raising=False)
    path = write(tmp_path, "; تعليق\n[server]\nport = 9090\n[database]\nurl = sqlite:///x.db\n", bom=True)
    s = load_settings(path)
    assert s.port == 9090 and s.host == "0.0.0.0" and not s.https


def test_missing_database_url_is_a_clear_error(tmp_path, monkeypatch):
    monkeypatch.delenv("FC_DATABASE_URL", raising=False)
    with pytest.raises(ConfigError, match="قاعدة البيانات"):
        load_settings(write(tmp_path, "[server]\nport = 8080\n"))


def test_invalid_port_rejected(tmp_path, monkeypatch):
    monkeypatch.delenv("FC_DATABASE_URL", raising=False)
    with pytest.raises(ConfigError):
        load_settings(write(tmp_path, "[server]\nport = 99999\n[database]\nurl = sqlite:///x.db\n"))


def test_https_needs_both_files(tmp_path, monkeypatch):
    monkeypatch.delenv("FC_DATABASE_URL", raising=False)
    with pytest.raises(ConfigError, match="HTTPS"):
        load_settings(
            write(tmp_path, "[server]\ntls_cert_file = a.pem\n[database]\nurl = sqlite:///x.db\n")
        )


def test_environment_overrides_file(tmp_path, monkeypatch):
    monkeypatch.setenv("FC_DATABASE_URL", "sqlite:///env.db")
    monkeypatch.setenv("FC_PORT", "8443")
    s = load_settings(write(tmp_path, "[database]\nurl = sqlite:///file.db\n"))
    assert s.database_url == "sqlite:///env.db" and s.port == 8443
