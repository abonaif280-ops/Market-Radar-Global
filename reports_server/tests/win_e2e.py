"""اختبار حقيقي على Windows: يشغّل start_reports.cmd ببرنامج وهمي يُبقي القاعدة مفتوحة دائمًا،
ثم يفك القفل ويستورد نسخة احتياطية من المتصفح ويتأكد من إعادة التشغيل والبيانات الجديدة.
الاستخدام: python win_e2e.py <مجلد النسخة>"""

import os
import re
import sqlite3
import struct
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

from Crypto.Cipher import AES

folder = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(folder))
import run_reports as R  # noqa: E402

PW = "test-pass"
APP = b'''
import os, sqlite3
from flask import Flask, request
app = Flask(__name__)
DB = os.path.join("instance", "security_reports.db")
_c = None
def init_db():
    global _c
    _c = sqlite3.connect(DB, check_same_thread=False)  # يبقى مفتوحًا طوال التشغيل
    _c.execute("create table if not exists r(t text)"); _c.commit()
@app.get("/")
def home():
    n = _c.execute("select count(*) from r").fetchone()[0]
    return f"rows={n} uploads={sorted(os.listdir(os.path.join('static','uploads')))}"
@app.post("/add")
def add():
    _c.execute("insert into r values ('x')"); _c.commit(); return "ok"
'''


def enc(key, iv, data):
    c = AES.new(key, AES.MODE_GCM, nonce=iv)
    ct, tag = c.encrypt_and_digest(data)
    return ct + tag


def pack(entries):
    return b"".join(struct.pack("<I", len(n.encode())) + n.encode() + struct.pack("<I", len(d)) + d for n, d in entries)


salt, iv = os.urandom(16), os.urandom(12)
(folder / "bundle.enc").write_bytes(b"SRB1" + salt + iv + enc(R.derive(PW, salt), iv, pack([("app.py", APP)])))

tmp = Path(tempfile.mkdtemp())
c = sqlite3.connect(tmp / "p.db"); c.execute("create table r(t text)")
c.executemany("insert into r values (?)", [("a",)] * 5); c.commit(); c.close()
bsalt = os.urandom(16); key = R.derive(PW, bsalt)
srbk = b"SRBK" + bsalt
for name, data in [("db", (tmp / "p.db").read_bytes()), ("file:sig1.png", b"PNG")]:
    v = os.urandom(12); ct = enc(key, v, data); nb = name.encode()
    srbk += struct.pack("<I", len(nb)) + nb + v + struct.pack("<I", len(ct)) + ct

BASE = "http://127.0.0.1:8090"


def get(path):
    try:
        with urllib.request.urlopen(BASE + path, timeout=10) as r:
            return r.read().decode()
    except urllib.error.HTTPError as e:
        return e.read().decode()


def post(path, fields, file=None):
    b = uuid.uuid4().hex
    body = b""
    for k, v in fields.items():
        body += f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode()
    if file:
        body += f'--{b}\r\nContent-Disposition: form-data; name="backup"; filename="b.srbk"\r\nContent-Type: application/octet-stream\r\n\r\n'.encode() + file + b"\r\n"
    body += f"--{b}--\r\n".encode()
    rq = urllib.request.Request(BASE + path, data=body, method="POST",
                                headers={"Content-Type": f"multipart/form-data; boundary={b}"})
    try:
        with urllib.request.urlopen(rq, timeout=60) as r:
            return r.read().decode()
    except urllib.error.HTTPError as e:
        return e.read().decode()


def wait_for(pred, what, secs=60):
    for _ in range(secs):
        try:
            if pred():
                return
        except OSError:
            pass
        time.sleep(1)
    raise SystemExit(f"timeout: {what}")


env = dict(os.environ, REPORTS_NO_BROWSER="1")
proc = subprocess.Popen(["cmd", "/c", str(folder / "start_reports.cmd")], env=env)
try:
    wait_for(lambda: 'name="password"' in get("/"), "unlock page")
    tok = re.search(r'name="t" value="([^"]+)"', get("/")).group(1)
    post("/__unlock", {"t": tok, "password": PW})
    wait_for(lambda: get("/").startswith("rows=0"), "program after unlock")
    post("/add", {})
    assert get("/").startswith("rows=1"), get("/")
    tok = re.search(r'name="t" value="([^"]+)"', get("/__import")).group(1)
    out = post("/__import", {"t": tok, "password": PW, "ok": "1"}, srbk)
    assert "تم الاستيراد" in out, out
    wait_for(lambda: get("/") == "rows=5 uploads=['sig1.png']", "restart on imported data")
    assert list((folder / "backups").glob("*.zip")), "no automatic backup"
    print("WINDOWS E2E OK:", get("/"))
finally:
    subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)], capture_output=True)
