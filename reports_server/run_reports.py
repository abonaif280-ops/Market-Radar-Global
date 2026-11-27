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


def pack(files: list[tuple[str, bytes]]) -> bytes:
    out = bytearray()
    for name, data in files:
        nb = name.encode("utf-8")
        out += struct.pack("<I", len(nb)) + nb + struct.pack("<I", len(data)) + data
    return bytes(out)


def encrypt_bundle(password: str, salt: bytes, files: list[tuple[str, bytes]]) -> bytes:
    """نفس صيغة bundle.enc ونفس الملح (salt) القديم، فتبقى كلمة السر نفسها، ولا يُطلب من الجوال
    إعادة إدخالها، وتبقى النسخ الاحتياطية القديمة متوافقة. المتجه iv جديد عشوائي في كل مرة."""
    from Crypto.Cipher import AES

    iv = secrets.token_bytes(12)
    c = AES.new(derive(password, salt), AES.MODE_GCM, nonce=iv)
    ct, tag = c.encrypt_and_digest(pack(files))
    return b"SRB1" + salt + iv + ct + tag


UPDATE_MAX = 50 * 1024 * 1024


def update_allowed(name: str) -> bool:
    """ملفات البرنامج فقط: app.py والقوالب والملفات الثابتة — وليس البيانات أو المرفقات."""
    if name == "app.py":
        return True
    if name.startswith("templates/"):
        return True
    return name.startswith("static/") and not name.startswith("static/uploads/")


def apply_update(password: str, zip_stream) -> tuple[int, int]:
    """يدمج ملفات التحديث في البرنامج المشفر: يُفك bundle.enc بكلمة السر، تُستبدل/تُضاف الملفات،
    ثم يُعاد التشفير بنفس كلمة السر. يرجع (عدد الملفات المحدَّثة، عدد الملفات الجديدة)."""
    import datetime
    import zipfile

    raw = BUNDLE.read_bytes()
    files = decrypt_bundle(password, raw)  # يرفع WrongPassword إن كانت كلمة السر خاطئة
    try:
        z = zipfile.ZipFile(io.BytesIO(zip_stream.read()))
    except zipfile.BadZipFile as e:
        raise ValueError("ملف التحديث ليس ملفًا مضغوطًا (zip) صالحًا") from e
    incoming: dict[str, bytes] = {}
    total = 0
    for info in z.infolist():
        if info.is_dir():
            continue
        name = info.filename.replace("\\", "/").lstrip("/")
        if ".." in name.split("/") or not update_allowed(name):
            raise ValueError(f"ملف غير مسموح في التحديث: {name}")
        total += info.file_size
        if total > UPDATE_MAX:
            raise ValueError("ملف التحديث أكبر من المسموح")
        incoming[name] = z.read(info)
    if "app.py" not in incoming and not any(n.startswith("templates/") for n in incoming):
        raise ValueError("ملف التحديث لا يحتوي على ملفات البرنامج")
    index = {name: i for i, (name, _) in enumerate(files)}
    changed = added = 0
    for name, data in incoming.items():
        if name in index:
            if files[index[name]][1] != data:
                files[index[name]] = (name, data)
                changed += 1
        else:
            files.append((name, data))
            added += 1
    new = encrypt_bundle(password, raw[4:20], files)
    if decrypt_bundle(password, new) != files:  # تحقق قبل الاستبدال
        raise ValueError("تعذّر التحقق من الملف المشفر الجديد")
    keep = BASE / "bundle_backups"
    keep.mkdir(exist_ok=True)
    (keep / f"bundle_{datetime.datetime.now():%Y-%m-%d_%H%M%S}.enc").write_bytes(raw)
    tmp = BUNDLE.with_suffix(".enc.new")
    tmp.write_bytes(new)
    os.replace(tmp, BUNDLE)
    extract_program(files, hashlib.sha256(new).hexdigest())
    return changed, added


def extract_program(files: list[tuple[str, bytes]], bundle_hash: str) -> None:
    """يكتب ملفات البرنامج فوق القديمة دون حذف instance أو uploads (البيانات تبقى عند التحديث)."""
    for name, data in files:
        t = safe_path(PROGRAM, name)
        t.parent.mkdir(parents=True, exist_ok=True)
        t.write_bytes(data)
    (PROGRAM / DB_REL).parent.mkdir(parents=True, exist_ok=True)
    (PROGRAM / UPL_REL).mkdir(parents=True, exist_ok=True)
    STAMP.write_text(bundle_hash, encoding="ascii")


PENDING_REL = Path("instance") / "security_reports.db.pending"


def apply_pending_db() -> bool:
    """قاعدة بيانات مستوردة تنتظر التطبيق: تُوضع مكان القديمة قبل أن يفتحها البرنامج."""
    pending = PROGRAM / PENDING_REL
    if not pending.exists():
        return False
    db = PROGRAM / DB_REL
    for extra in ("-wal", "-shm", "-journal"):  # بقايا القاعدة القديمة لا تُطبَّق على الجديدة
        Path(str(db) + extra).unlink(missing_ok=True)
    os.replace(pending, db)
    return True


def import_backup(password: str, stream, later: bool = False) -> int:
    """يستورد ملف .srbk (زر «حفظ نسخة احتياطية مشفرة» في التطبيق) كما يفعل التطبيق نفسه:
    تُستبدل قاعدة البيانات وتُضاف المرفقات (الصور والتوقيعات والمقاطع).
    يُفك كل شيء أولًا في مجلد مؤقت، ولا يُلمس شيء من البيانات الحالية إلا بعد نجاح الفك كاملًا."""
    import shutil

    head = stream.read(20)
    if head[:4] != b"SRBK":
        raise ValueError("الملف ليس نسخة احتياطية لهذا التطبيق")
    key = derive(password, head[4:20])
    stage = PROGRAM / ".import_tmp"
    shutil.rmtree(stage, ignore_errors=True)
    (stage / "files").mkdir(parents=True)
    try:
        db, names, n = None, [], 0
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
                db = stage / "db"
                db.write_bytes(data)
            elif name.startswith("file:"):
                safe_path(stage / "files", name[5:]).write_bytes(data)
                names.append(name[5:])
            n += 1
        if db is None:
            raise ValueError("الملف لا يحتوي على قاعدة بيانات")
        upl = PROGRAM / UPL_REL
        upl.mkdir(parents=True, exist_ok=True)
        for fname in names:
            os.replace(stage / "files" / fname, safe_path(upl, fname))
        (PROGRAM / DB_REL).parent.mkdir(parents=True, exist_ok=True)
        # later=True والبرنامج يعمل: Windows لا يسمح باستبدال ملف قاعدة مفتوح، فتُطبَّق عند إعادة التشغيل
        os.replace(db, PROGRAM / (PENDING_REL if later else DB_REL))
        if not later:
            apply_pending_db()  # لا شيء معلّق؛ للاحتياط فقط
        return n
    finally:
        shutil.rmtree(stage, ignore_errors=True)


def load_program():
    if apply_pending_db():
        print("Imported backup applied.")
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

IMPORT_PAGE = """<p><b>استيراد نسخة احتياطية</b> (ملف .srbk من زر ☰ ← «حفظ نسخة احتياطية مشفرة» في الجوال أو الجهاز الآخر).</p>
<p>تنقل الحالات كاملة: البيانات والصور والتوقيعات والتواريخ والتقارير.</p>
{err}<form method="post" action="/__import" enctype="multipart/form-data">
<input type="hidden" name="t" value="{tok}">
<input type="file" name="backup" accept=".srbk,.zip,application/octet-stream" required>
<input type="password" name="password" placeholder="كلمة سر النسخة (عادةً نفس كلمة سر التطبيق)" required>
<label><input type="checkbox" name="ok" value="1" required style="width:auto"> أفهم أن بيانات السيرفر الحالية ستُستبدل ببيانات هذه النسخة</label>
<button type="submit">استيراد</button></form>
<p class="m">قبل الاستبدال تُحفظ نسخة من بيانات السيرفر الحالية تلقائيًا في مجلد backups.</p>"""

IMPORT_DONE = """<meta http-equiv="refresh" content="8;url=/"><p><b>تم الاستيراد ({n} عنصر).</b></p>
<p>البرنامج يعيد التشغيل الآن، وستفتح الصفحة الرئيسية خلال ثوانٍ.</p>
<p class="m">نسخة البيانات السابقة: {bk}<br>إن لم يرجع البرنامج: شغّل start_reports.cmd مرة أخرى.</p>"""

UPDATE_PAGE = """<p><b>تحديث البرنامج</b> بملف التحديث (zip) الذي يصلك.</p>
{err}<form method="post" action="/__update" enctype="multipart/form-data">
<input type="hidden" name="t" value="{tok}">
<input type="file" name="update" accept=".zip,application/zip" required>
<input type="password" name="password" placeholder="كلمة سر التطبيق" required>
<button type="submit">تحديث</button></form>
<p class="m">يُحدَّث البرنامج على السيرفر ويُعاد تشفيره بنفس كلمة السر. بياناتك لا تتغير،
وتُحفظ منها نسخة تلقائيًا في مجلد backups قبل التحديث، ونسخة من البرنامج السابق في bundle_backups.</p>"""

UPDATE_DONE = """<p><b>تم التحديث</b> ({changed} ملف معدَّل، {added} ملف جديد).</p>
<p>البرنامج يعيد التشغيل الآن.</p>
<p><a href="/__bundle">⬇ تنزيل ملف البرنامج الجديد bundle.enc</a> — لتحديث نسخة الجوال على GitHub.</p>
<p><a href="/">فتح البرنامج</a></p>"""

RESTARTING = """<meta http-equiv="refresh" content="4"><p>البرنامج يعيد التشغيل… لحظات.</p>"""

WAIT = """<p>البرنامج لم يُفتح بعد.</p><p class="m">افتح هذه الصفحة على جهاز السيرفر نفسه
وأدخل كلمة سر التطبيق، ثم أعد تحميل الصفحة هنا.</p>"""


def is_loopback(environ) -> bool:
    return environ.get("REMOTE_ADDR", "") in ("127.0.0.1", "::1")


class Gate:
    """قبل فك البرنامج: صفحة فك القفل. بعده: البرنامج نفسه لكل الطلبات."""

    def __init__(self, app=None, restart=None):
        self.app = app
        self.token = secrets.token_urlsafe(24)
        self.lock = threading.Lock()
        self.restarting = False
        # بعد الاستيراد: الخروج بالرمز 3 فيعيد start_reports.cmd تشغيل البرنامج على البيانات الجديدة
        self.restart = restart or (lambda: threading.Timer(1.5, os._exit, (3,)).start())

    def __call__(self, environ, start_response):
        path = environ.get("PATH_INFO", "")
        if self.restarting:
            return self._page(RESTARTING, 503)(environ, start_response)
        if path in ("/__update", "/__bundle"):
            if not is_loopback(environ):
                return self._page("<p>هذه الصفحة متاحة من جهاز السيرفر نفسه فقط.</p>", 403)(environ, start_response)
            if path == "/__bundle":
                from werkzeug.wrappers import Response

                return Response(BUNDLE.read_bytes(), content_type="application/octet-stream",
                                headers={"Content-Disposition": "attachment; filename=bundle.enc",
                                         "Cache-Control": "no-store"})(environ, start_response)
            from werkzeug.wrappers import Request

            req = Request(environ)
            req.max_form_memory_size = 1024 * 1024
            if req.method == "POST":
                return self._update(req)(environ, start_response)
            return self._update_form()(environ, start_response)
        if path == "/__import":
            if not is_loopback(environ):
                return self._page("<p>الاستيراد متاح من جهاز السيرفر نفسه فقط.</p>", 403)(environ, start_response)
            if self.app is None:
                from werkzeug.utils import redirect
                return redirect("/")(environ, start_response)
            from werkzeug.wrappers import Request

            req = Request(environ)
            req.max_form_memory_size = 1024 * 1024
            if req.method == "POST":
                return self._import(req)(environ, start_response)
            return self._import_form()(environ, start_response)
        if self.app is not None:
            return self.app(environ, start_response)
        from werkzeug.wrappers import Request

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

    def _import_form(self, err: str = ""):
        return self._page(IMPORT_PAGE.format(err=f'<p class="e">{html.escape(err)}</p>' if err else "", tok=self.token))

    def _import(self, req):
        if not hmac.compare_digest(req.form.get("t", ""), self.token):
            return self._import_form("انتهت صلاحية الصفحة، أعد المحاولة.")
        up = req.files.get("backup")
        if not (up and up.filename) or req.form.get("ok") != "1":
            return self._import_form("اختر ملف النسخة الاحتياطية ووافق على الاستبدال.")
        with self.lock:
            try:
                bk = backup_data(quiet=True) if (PROGRAM / DB_REL).exists() else None
                n = import_backup(req.form.get("password", ""), up.stream, later=True)
            except (WrongPassword, ValueError) as e:
                return self._import_form(str(e) or "كلمة السر غير صحيحة")
            except Exception as e:  # noqa: BLE001
                return self._import_form(f"تعذّر الاستيراد: {e}")
            self.restarting = True
        print("Backup imported. Restarting...")
        self.restart()
        return self._page(IMPORT_DONE.format(n=n, bk=html.escape(bk.name if bk else "—")))

    def _update_form(self, err: str = ""):
        return self._page(UPDATE_PAGE.format(err=f'<p class="e">{html.escape(err)}</p>' if err else "", tok=self.token))

    def _update(self, req):
        if not hmac.compare_digest(req.form.get("t", ""), self.token):
            return self._update_form("انتهت صلاحية الصفحة، أعد المحاولة.")
        up = req.files.get("update")
        if not (up and up.filename):
            return self._update_form("اختر ملف التحديث.")
        with self.lock:
            try:
                if (PROGRAM / DB_REL).exists():
                    backup_data(quiet=True)
                changed, added = apply_update(req.form.get("password", ""), up.stream)
            except WrongPassword:
                return self._update_form("كلمة السر غير صحيحة")
            except ValueError as e:
                return self._update_form(str(e))
            except Exception as e:  # noqa: BLE001
                return self._update_form(f"تعذّر التحديث: {e}")
            # البرنامج المفكوك سابقًا قد لا يكون محمَّلًا (أول تشغيل)؛ إعادة التشغيل تحمّل الجديد
            self.restarting = self.app is not None
        print("Program updated.")
        if self.restarting:
            self.restart()
        return self._page(UPDATE_DONE.format(changed=changed, added=added))

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


def backup_data(quiet: bool = False):
    """نسخة من البيانات (قاعدة البيانات + المرفقات) في مجلد backups بالتاريخ والوقت."""
    import datetime
    import zipfile

    if not (PROGRAM / "instance").exists():
        if quiet:
            return None
        print("No data yet.")
        return 1
    out = BASE / "backups"
    out.mkdir(exist_ok=True)
    target = out / f"reports_{datetime.datetime.now():%Y-%m-%d_%H%M%S}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
        for sub in ("instance", UPL_REL.as_posix()):
            if not (PROGRAM / sub).exists():
                continue
            for f in (PROGRAM / sub).rglob("*"):
                if f.is_file():
                    z.write(f, f.relative_to(PROGRAM).as_posix())
    if quiet:
        return target
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
    else:
        print(f"  Import a backup (.srbk): run import_backup.cmd or open {url}/__import")
        print(f"  Update the program (.zip): run update_program.cmd or open {url}/__update")
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
