"""اختبار شامل بحزمة برنامج وهمية مشفرة بنفس صيغة bundle.enc ونسخة احتياطية بصيغة .srbk."""

import hashlib
import io
import os
import struct
import sys
from pathlib import Path

import pytest
from Crypto.Cipher import AES
from werkzeug.test import Client

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_reports as R  # noqa: E402

PW = "كلمة-سر-تجريبية"
FAKE_APP = b'''
import os, sqlite3, hashlib
from flask import Flask, request
app = Flask(__name__)
DB = os.path.join("instance", "security_reports.db")
EXPORT_DIR = "exports"; os.makedirs(EXPORT_DIR, exist_ok=True)
_UPLOAD_MISSING = set()
def init_db():
    c = sqlite3.connect(DB); c.execute("create table if not exists r(t text)"); c.commit(); c.close()
@app.get("/")
def home():
    c = sqlite3.connect(DB); n = c.execute("select count(*) from r").fetchone()[0]; c.close()
    hashlib.scrypt(b"x", salt=b"y", n=16, r=8, p=1)
    up = sorted(os.listdir(os.path.join("static", "uploads")))
    return f"rows={n} uploads={up} tpl={open('templates/t.html').read()}"
@app.post("/add")
def add():
    c = sqlite3.connect(DB); c.execute("insert into r values (?)", (request.form["t"],)); c.commit(); c.close()
    return "ok"
'''


def pack(entries):
    out = b""
    for name, data in entries:
        n = name.encode()
        out += struct.pack("<I", len(n)) + n + struct.pack("<I", len(data)) + data
    return out


def enc(key, iv, data):
    c = AES.new(key, AES.MODE_GCM, nonce=iv)
    ct, tag = c.encrypt_and_digest(data)
    return ct + tag


def make_bundle(app_src=FAKE_APP):
    salt, iv = os.urandom(16), os.urandom(12)
    plain = pack([("app.py", app_src), ("templates/t.html", "قالب".encode())])
    return b"SRB1" + salt + iv + enc(R.derive(PW, salt), iv, plain)


def make_backup(db_bytes):
    salt = os.urandom(16)
    key = R.derive(PW, salt)
    out = b"SRBK" + salt
    for name, data in [("db", db_bytes), ("file:p1.jpg", b"\xff\xd8img")]:
        n, iv = name.encode(), os.urandom(12)
        ct = enc(key, iv, data)
        out += struct.pack("<I", len(n)) + n + iv + struct.pack("<I", len(ct)) + ct
    return out


@pytest.fixture
def env(tmp_path, monkeypatch):
    monkeypatch.setattr(R, "BUNDLE", tmp_path / "bundle.enc")
    monkeypatch.setattr(R, "PROGRAM", tmp_path / "program")
    monkeypatch.setattr(R, "STAMP", tmp_path / "program" / ".bundle_sha256")
    cwd = os.getcwd()
    yield tmp_path
    os.chdir(cwd)
    sys.modules.pop("app", None)
    sys.path[:] = [p for p in sys.path if not p.startswith(str(tmp_path))]


def token(client):
    body = client.get("/", environ_base={"REMOTE_ADDR": "127.0.0.1"}).get_data(as_text=True)
    return body.split('name="t" value="')[1].split('"')[0]


def test_wrong_password_then_unlock_with_backup(env):
    import sqlite3
    R.BUNDLE.write_bytes(make_bundle())
    dbf = env / "phone.db"
    c = sqlite3.connect(dbf); c.execute("create table r(t text)"); c.execute("insert into r values ('من الجوال')"); c.commit(); c.close()

    gate = R.Gate()
    cl = Client(gate)
    local = {"REMOTE_ADDR": "127.0.0.1"}
    # جهاز آخر لا يرى صفحة كلمة السر
    r = cl.get("/", environ_base={"REMOTE_ADDR": "192.168.1.20"})
    assert r.status_code == 503 and "password" not in r.get_data(as_text=True)
    # بدون رمز الصفحة يُرفض
    r = cl.post("/__unlock", data={"password": PW}, environ_base=local)
    assert gate.app is None
    t = token(cl)
    r = cl.post("/__unlock", data={"t": t, "password": "خطأ"}, environ_base=local)
    assert "كلمة السر غير صحيحة" in r.get_data(as_text=True) and gate.app is None
    r = cl.post("/__unlock", environ_base=local, data={
        "t": t, "password": PW, "backup": (io.BytesIO(make_backup(dbf.read_bytes())), "b.srbk")})
    assert r.status_code == 302 and gate.app is not None
    # بعد الفتح: أي جهاز في الشبكة يدخل البرنامج نفسه
    r = cl.get("/", environ_base={"REMOTE_ADDR": "192.168.1.20"})
    assert r.get_data(as_text=True) == "rows=1 uploads=['p1.jpg'] tpl=قالب"
    assert cl.post("/add", data={"t": "x"}, environ_base={"REMOTE_ADDR": "192.168.1.21"}).status_code == 200
    assert "rows=2" in cl.get("/").get_data(as_text=True)
    assert not R.needs_unlock()
    # كلمة السر لم تُكتب في أي ملف
    for f in R.PROGRAM.rglob("*"):
        if f.is_file():
            assert PW.encode() not in f.read_bytes()


def test_new_bundle_keeps_data(env):
    R.BUNDLE.write_bytes(make_bundle())
    files = R.decrypt_bundle(PW, R.BUNDLE.read_bytes())
    R.extract_program(files, hashlib.sha256(R.BUNDLE.read_bytes()).hexdigest())
    (R.PROGRAM / R.DB_REL).write_bytes(b"data")
    assert not R.needs_unlock()
    R.BUNDLE.write_bytes(make_bundle(FAKE_APP + b"\n# v2\n"))
    assert R.needs_unlock()
    R.extract_program(R.decrypt_bundle(PW, R.BUNDLE.read_bytes()), hashlib.sha256(R.BUNDLE.read_bytes()).hexdigest())
    assert (R.PROGRAM / R.DB_REL).read_bytes() == b"data"
    assert b"# v2" in (R.PROGRAM / "app.py").read_bytes()


def test_path_traversal_rejected(env):
    with pytest.raises(ValueError):
        R.safe_path(env / "program", "../evil.py")


def test_wrong_backup_password(env):
    R.PROGRAM.mkdir()
    bad = make_backup(b"db")
    with pytest.raises(R.WrongPassword):
        R.import_backup("غلط", io.BytesIO(bad))
    assert not (R.PROGRAM / R.DB_REL).exists()


def test_backup_data(env, monkeypatch):
    monkeypatch.setattr(R, "BASE", env)
    (R.PROGRAM / R.DB_REL).parent.mkdir(parents=True)
    (R.PROGRAM / R.DB_REL).write_bytes(b"db")
    (R.PROGRAM / R.UPL_REL).mkdir(parents=True)
    (R.PROGRAM / R.UPL_REL / "a.jpg").write_bytes(b"i")
    assert R.backup_data() == 0
    import zipfile
    z = next((env / "backups").glob("*.zip"))
    assert sorted(zipfile.ZipFile(z).namelist()) == ["instance/security_reports.db", "static/uploads/a.jpg"]


def test_import_any_time_replaces_data_after_auto_backup(env, monkeypatch):
    import sqlite3
    import zipfile
    monkeypatch.setattr(R, "BASE", env)
    R.BUNDLE.write_bytes(make_bundle())
    # السيرفر بدأ فارغًا وأُدخلت عليه بيانات
    gate = R.Gate(restart=lambda: restarts.append(1))
    restarts = []
    cl = Client(gate)
    local = {"REMOTE_ADDR": "127.0.0.1"}
    cl.post("/__unlock", data={"t": token(cl), "password": PW}, environ_base=local)
    assert gate.app is not None
    cl.post("/add", data={"t": "بيانات السيرفر القديمة"})
    old_db = (R.PROGRAM / R.DB_REL).read_bytes()

    phone = env / "phone.db"
    c = sqlite3.connect(phone); c.execute("create table r(t text)")
    c.executemany("insert into r values (?)", [("حالة 1",), ("حالة 2",), ("حالة 3",)]); c.commit(); c.close()
    srbk = make_backup(phone.read_bytes())

    # من جهاز آخر: ممنوع
    r = cl.post("/__import", environ_base={"REMOTE_ADDR": "192.168.1.20"})
    assert r.status_code == 403
    page = cl.get("/__import", environ_base=local).get_data(as_text=True)
    tok = page.split('name="t" value="')[1].split('"')[0]
    # كلمة سر خاطئة: لا يتغيّر شيء
    r = cl.post("/__import", environ_base=local, data={
        "t": tok, "password": "غلط", "ok": "1", "backup": (io.BytesIO(srbk), "b.srbk")})
    assert "لا تطابق" in r.get_data(as_text=True) and not restarts
    assert (R.PROGRAM / R.DB_REL).read_bytes() == old_db
    # بدون الموافقة على الاستبدال: يُرفض
    r = cl.post("/__import", environ_base=local, data={"t": tok, "password": PW, "backup": (io.BytesIO(srbk), "b.srbk")})
    assert not restarts
    # الاستيراد الصحيح
    r = cl.post("/__import", environ_base=local, data={
        "t": tok, "password": PW, "ok": "1", "backup": (io.BytesIO(srbk), "b.srbk")})
    assert "تم الاستيراد (2 عنصر)" in r.get_data(as_text=True) and restarts == [1]
    # نسخة تلقائية من البيانات القديمة قبل الاستبدال
    bk = next((env / "backups").glob("*.zip"))
    assert zipfile.ZipFile(bk).read("instance/security_reports.db") == old_db
    # أثناء إعادة التشغيل لا يصل أحد للبرنامج (حتى لا يكتب فوق البيانات الجديدة)
    assert cl.get("/", environ_base={"REMOTE_ADDR": "192.168.1.20"}).status_code == 503
    assert (R.PROGRAM / R.PENDING_REL).exists()
    assert (R.PROGRAM / R.UPL_REL / "p1.jpg").read_bytes() == b"\xff\xd8img"

    # إعادة التشغيل: تُطبَّق القاعدة المستوردة قبل فتح البرنامج
    sys.modules.pop("app", None)
    gate2 = R.Gate(R.load_program())
    body = Client(gate2).get("/", environ_base={"REMOTE_ADDR": "192.168.1.20"}).get_data(as_text=True)
    assert body.startswith("rows=3 uploads=['p1.jpg']")
    assert not (R.PROGRAM / R.PENDING_REL).exists()


def test_backup_without_db_rejected(env):
    salt = os.urandom(16); key = R.derive(PW, salt); iv = os.urandom(12)
    n = b"file:a.jpg"; ct = enc(key, iv, b"x")
    data = b"SRBK" + salt + struct.pack("<I", len(n)) + n + iv + struct.pack("<I", len(ct)) + ct
    with pytest.raises(ValueError, match="قاعدة بيانات"):
        R.import_backup(PW, io.BytesIO(data), later=True)
    assert not (R.PROGRAM / R.UPL_REL / "a.jpg").exists()


def test_import_page_needs_unlock_first(env):
    cl = Client(R.Gate())
    r = cl.get("/__import", environ_base={"REMOTE_ADDR": "127.0.0.1"})
    assert r.status_code == 302
