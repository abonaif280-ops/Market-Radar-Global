"""تشغيل برنامج «التقارير» (نفس برنامج abonaif280-ops.github.io) على سيرفر المكتب.

نفس برنامج Flask الأصلي الموجود داخل bundle.enc يعمل هنا بـ Python حقيقي بدل المتصفح،
فيدخل عليه أي جهاز في نفس الشبكة عبر http://<عنوان السيرفر>:8090

أول تشغيل: تفتح صفحة في متصفح السيرفر نفسه تطلب كلمة سر التطبيق (نفس كلمة السر في الجوال)
ويمكن معها استيراد النسخة الاحتياطية المشفرة (.srbk) لنقل بياناتك من الجوال.
- كلمة السر لا تُحفظ ولا تُرسل لأي مكان؛ تُستخدم مرة لفك البرنامج على هذا الجهاز.
- صفحة فك القفل لا تُفتح إلا من السيرفر نفسه (127.0.0.1).
- لا اتصال بالإنترنت إطلاقًا.
"""

from __future__ import annotations

import hashlib
import hmac
import html
import io
import os
import secrets
import socket
import struct
import sys
import threading
import webbrowser
from pathlib import Path

BASE = Path(__file__).resolve().parent
BUNDLE = BASE / "bundle.enc"
PROGRAM = BASE / "program"           # كود البرنامج بعد فكه + بياناته (instance و static/uploads)
STAMP = PROGRAM / ".bundle_sha256"
DB_REL = Path("instance") / "security_reports.db"
UPL_REL = Path("static") / "uploads"
ITER = 600_000
PORT = int(os.environ.get("REPORTS_PORT", "8090"))
HOST = os.environ.get("REPORTS_HOST", "0.0.0.0")


# ---------------------------------------------------------------- التشفير (مطابق لـ crypto.js)
def derive(password: str, salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, ITER, 32)


def gcm_decrypt(key: bytes, iv: bytes, data: bytes) -> bytes:
    from Crypto.Cipher import AES

    c = AES.new(key, AES.MODE_GCM, nonce=iv)
    return c.decrypt_and_verify(data[:-16], data[-16:])  # WebCrypto يُلحق الوسم (16 بايت) بالنهاية


class WrongPassword(Exception):
    pass


def unpack(buf: bytes) -> list[tuple[str, bytes]]:
    out, p = [], 0
    while p < len(buf):
        (nl,) = struct.unpack_from("<I", buf, p); p += 4
        name = buf[p:p + nl].decode("utf-8"); p += nl
        (dl,) = struct.unpack_from("<I", buf, p); p += 4
        out.append((name, buf[p:p + dl])); p += dl
    return out


def safe_path(root: Path, name: str) -> Path:
    target = (root / name).resolve()
    if root.resolve() not in target.parents:
        raise ValueError(f"unsafe path in package: {name!r}")
    return target


def decrypt_bundle(password: str, bundle: bytes) -> list[tuple[str, bytes]]:
    if bundle[:4] != b"SRB1":
        raise ValueError("bundle.enc is not a valid program file")
    key = derive(password, bundle[4:20])
    try:
        plain = gcm_decrypt(key, bundle[20:32], bundle[32:])
    except ValueError as e:
        raise WrongPassword() from e
    return unpack(plain)


def extract_program(files: list[tuple[str, bytes]], bundle_hash: str) -> None:
    """يكتب ملفات البرنامج فوق القديمة دون حذف instance أو uploads (البيانات تبقى عند التحديث)."""
    for name, data in files:
        t = safe_path(PROGRAM, name)
        t.parent.mkdir(parents=True, exist_ok=True)
        t.write_bytes(data)
    (PROGRAM / DB_REL).parent.mkdir(parents=True, exist_ok=True)
    (PROGRAM / UPL_REL).mkdir(parents=True, exist_ok=True)
    STAMP.write_text(bundle_hash, encoding="ascii")


def import_backup(password: str, stream) -> int:
    """يستورد ملف .srbk (من زر «حفظ نسخة احتياطية مشفرة» في الجوال)."""
    head = stream.read(20)
    if head[:4] != b"SRBK":
        raise ValueError("الملف ليس نسخة احتياطية لهذا التطبيق")
    key = derive(password, head[4:20])
    db, files, n = None, [], 0
    while True:
        h = stream.read(4)
        if not h:
            break
        (nl,) = struct.unpack("<I", h)
        name = stream.read(nl).decode("utf-8")
        iv = stream.read(12)
        (cl,) = struct.unpack("<I", stream.read(4))
        try:
            data = gcm_decrypt(key, iv, stream.read(cl))
        except ValueError as e:
            raise WrongPassword("كلمة السر لا تطابق هذه النسخة الاحتياطية") from e
        if name == "db":
            db = data
        elif name.startswith("file:"):
            files.append((name[5:], data))
        n += 1
    # الكتابة بعد التحقق من كل السجلات، حتى لا تُكتب نسخة ناقصة
    upl = PROGRAM / UPL_REL
    upl.mkdir(parents=True, exist_ok=True)
    for fname, data in files:
        safe_path(upl, fname).write_bytes(data)
    if db is not None:
        (PROGRAM / DB_REL).parent.mkdir(parents=True, exist_ok=True)
        (PROGRAM / DB_REL).write_bytes(db)
    return n


def load_program():
    os.chdir(PROGRAM)
    sys.path.insert(0, str(PROGRAM))
    import app as A  # noqa: PLC0415 — app.py داخل البرنامج المفكوك

    if hasattr(A, "init_db"):
        A.init_db()
    return A.app


# ---------------------------------------------------------------- صفحة فك القفل (أول مرة فقط)
PAGE = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>التقارير — تشغيل على السيرفر</title>
<style>body{{font-family:Tahoma,Arial,sans-serif;background:#f0f2f5;margin:0;padding:24px}}
.c{{max-width:520px;margin:40px auto;background:#fff;border-radius:14px;padding:24px;box-shadow:0 2px 10px #0001}}
h1{{color:#145c32;font-size:22px}}input,button{{font:inherit;width:100%;box-sizing:border-box;padding:12px;margin:8px 0;border-radius:8px;border:1px solid #ccc}}
button{{background:#145c32;color:#fff;border:0;cursor:pointer}}.e{{color:#b00020}}.m{{color:#666;font-size:14px}}</style></head>
<body><div class="c"><h1>التقارير — تشغيل على السيرفر</h1>{body}</div></body></html>"""

FORM = """<p>أدخل <b>كلمة سر التطبيق</b> (نفس كلمة السر التي تفتح بها التطبيق في الجوال).</p>
{err}<form method="post" action="/__unlock" enctype="multipart/form-data">
<input type="hidden" name="t" value="{tok}">
<input type="password" name="password" placeholder="كلمة سر التطبيق" required autofocus>
{imp}<button type="submit">فتح وتشغيل</button></form>
<p class="m">كلمة السر لا تُحفظ ولا تُرسل لأي مكان. تُستخدم مرة واحدة لفك البرنامج على هذا الجهاز.</p>"""

IMPORT = """<p class="m">اختياري — لنقل بياناتك من الجوال: ملف النسخة الاحتياطية المشفرة (.srbk).
بدونه يبدأ البرنامج بدون بيانات (المستخدم aaa وكلمة المرور 1234 ثم غيّرها فورًا).</p>
<input type="file" name="backup" accept=".srbk,.zip,application/octet-stream">"""

WAIT = """<p>البرنامج لم يُفتح بعد.</p><p class="m">افتح هذه الصفحة على جهاز السيرفر نفسه
وأدخل كلمة سر التطبيق، ثم أعد تحميل الصفحة هنا.</p>"""


def is_loopback(environ) -> bool:
    return environ.get("REMOTE_ADDR", "") in ("127.0.0.1", "::1")


class Gate:
    """قبل فك البرنامج: صفحة فك القفل. بعده: البرنامج نفسه لكل الطلبات."""

    def __init__(self, app=None):
        self.app = app
        self.token = secrets.token_urlsafe(24)
        self.lock = threading.Lock()

    def __call__(self, environ, start_response):
        if self.app is not None:
            return self.app(environ, start_response)
        from werkzeug.wrappers import Request, Response

        req = Request(environ)
        req.max_form_memory_size = 1024 * 1024
        if not is_loopback(environ):
            return self._page(WAIT, 503)(environ, start_response)
        if req.method == "POST" and req.path == "/__unlock":
            return self._unlock(req)(environ, start_response)
        return self._form()(environ, start_response)

    def _page(self, body, status=200):
        from werkzeug.wrappers import Response

        return Response(PAGE.format(body=body), status=status, content_type="text/html; charset=utf-8",
                        headers={"Cache-Control": "no-store", "X-Frame-Options": "DENY",
                                 "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'"})

    def _form(self, err: str = ""):
        has_db = (PROGRAM / DB_REL).exists()
        return self._page(FORM.format(err=f'<p class="e">{html.escape(err)}</p>' if err else "",
                                      tok=self.token, imp="" if has_db else IMPORT))

    def _unlock(self, req):
        from werkzeug.utils import redirect

        if not hmac.compare_digest(req.form.get("t", ""), self.token):
            return self._form("انتهت صلاحية الصفحة، أعد المحاولة.")
        pw = req.form.get("password", "")
        with self.lock:
            if self.app is not None:
                return redirect("/")
            try:
                raw = BUNDLE.read_bytes()
                files = decrypt_bundle(pw, raw)
                up = req.files.get("backup")
                if up and up.filename:
                    if (PROGRAM / DB_REL).exists():
                        return self._form("توجد بيانات على السيرفر مسبقًا؛ لم يُستورد الملف حتى لا تُستبدل.")
                    PROGRAM.mkdir(exist_ok=True)
                    import_backup(pw, up.stream)
                extract_program(files, hashlib.sha256(raw).hexdigest())
                self.app = load_program()
            except WrongPassword as e:
                return self._form(str(e) if str(e) else "كلمة السر غير صحيحة")
            except Exception as e:  # noqa: BLE001
                return self._form(f"تعذّر التشغيل: {e}")
            finally:
                pw = None
        print("Program unlocked and running.")
        return redirect("/")


def needs_unlock() -> bool:
    if not (PROGRAM / "app.py").exists():
        return True
    if BUNDLE.exists():  # نسخة جديدة من البرنامج (bundle.enc تغيّر) ← فكّه مرة أخرى بكلمة السر
        return STAMP.read_text(encoding="ascii").strip() != hashlib.sha256(BUNDLE.read_bytes()).hexdigest() \
            if STAMP.exists() else True
    return False


def lan_addresses() -> list[str]:
    found: list[str] = []
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127.") and ip not in found:
                found.append(ip)
    except OSError:
        pass
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.connect(("10.255.255.255", 1))  # لا يرسل أي بيانات
            ip = probe.getsockname()[0]
            if not ip.startswith("127.") and ip not in found:
                found.append(ip)
    except OSError:
        pass
    return found


def backup_data() -> int:
    """نسخة من البيانات (قاعدة البيانات + المرفقات) في مجلد backups بالتاريخ والوقت."""
    import datetime
    import zipfile

    if not (PROGRAM / "instance").exists():
        print("No data yet.")
        return 1
    out = BASE / "backups"
    out.mkdir(exist_ok=True)
    target = out / f"reports_{datetime.datetime.now():%Y-%m-%d_%H%M%S}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
        for sub in ("instance", UPL_REL.as_posix()):
            for f in (PROGRAM / sub).rglob("*"):
                if f.is_file():
                    z.write(f, f.relative_to(PROGRAM).as_posix())
    print(f"Saved: {target}")
    return 0


def main() -> int:
    for s in (sys.stdout, sys.stderr):
        try:
            s.reconfigure(encoding="utf-8", errors="replace")
        except Exception:  # noqa: BLE001
            pass
    if "--backup" in sys.argv:
        return backup_data()
    if not BUNDLE.exists() and not (PROGRAM / "app.py").exists():
        print("bundle.enc is missing next to run_reports.py")
        return 1
    gate = Gate(None if needs_unlock() else load_program())
    url = f"http://127.0.0.1:{PORT}"
    # نص إنجليزي: نافذة الأوامر في Windows لا تعرض العربية بشكل صحيح.
    print("=" * 60)
    print("  Reports (التقارير) is running.")
    print(f"  On this computer:   {url}")
    if HOST != "127.0.0.1":
        print("  From other computers on the office network:")
        for ip in lan_addresses() or ["<this computer's IP address>"]:
            print(f"                      http://{ip}:{PORT}")
    if gate.app is None:
        print()
        print("  First time: the browser opens a page asking for the app password.")
    print("  Keep this window open. To stop: close it or press Ctrl+C.")
    print("=" * 60)
    if os.environ.get("REPORTS_NO_BROWSER") != "1":
        threading.Timer(2.0, lambda: webbrowser.open(url)).start()
    from waitress import serve

    # threads=1: الطلبات تُنفَّذ بالتسلسل كما في نسخة المتصفح (قاعدة SQLite واحدة، بلا تداخل)
    serve(gate, host=HOST, port=PORT, threads=1, max_request_body_size=4 * 1024 ** 3, ident=None)
    return 0


if __name__ == "__main__":
    sys.exit(main())
