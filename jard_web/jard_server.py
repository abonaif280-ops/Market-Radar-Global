# -*- coding: utf-8 -*-
"""
أداة الجرد — الخادم (Flask)
على PythonAnywhere يُستورد الكائن app من هذا الملف (jard_server.py) (انظر دليل_الرفع.md).
"""
import json
import os
import secrets
import time
from collections import defaultdict
from datetime import datetime, timedelta
from functools import wraps

from flask import (Flask, abort, flash, jsonify, redirect, render_template, request,
                   send_from_directory, session, url_for, Response)
from werkzeug.security import check_password_hash, generate_password_hash

import jard_config as config
from jard_models import (KV, ROLE_ADMIN, ROLE_CHAIR, ROLE_LABELS, ROLE_MEMBER, Entity, Item, Log,
                    Note, Row, User, db)

BASE = config.BASE_DIR
app = Flask(__name__, template_folder=os.path.join(BASE, "templates"),
            static_folder=os.path.join(BASE, "static"))
app.config.update(
    SECRET_KEY=config.secret_key(),
    SQLALCHEMY_DATABASE_URI=config.database_uri(),
    SQLALCHEMY_ENGINE_OPTIONS={"pool_recycle": 280, "pool_pre_ping": True},
    SESSION_COOKIE_NAME="jard_session",
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=config.SECURE_COOKIES,
    PERMANENT_SESSION_LIFETIME=timedelta(days=30),
    MAX_CONTENT_LENGTH=40 * 1024 * 1024,
)
db.init_app(app)


# ------------------------------------------------------------------ تهيئة قاعدة البيانات
def init_db():
    db.create_all()
    if not User.query.first():
        db.session.add(User(username=config.DEFAULT_ADMIN_USERNAME,
                            password_hash=generate_password_hash(config.DEFAULT_ADMIN_PASSWORD),
                            default_pw=True, name="مدير النظام", role=ROLE_ADMIN))
        db.session.commit()


def apply_seed():
    """إضافة القوائم الجاهزة (الجهات والأنواع والأصناف والمستودعات) من jard_seed.json مرة واحدة فقط.
    لا يحذف ولا يغيّر أي بيانات موجودة، ويضيف الناقص فقط."""
    path = os.path.join(BASE, "jard_seed.json")
    if not os.path.exists(path):
        return
    with open(path, encoding="utf-8") as f:
        seed = json.load(f)
    tag = "seed:" + str(seed.get("exportedAt", ""))
    if kv_get(tag):
        return
    cats = kv_get("categories") or []
    cats += [c for c in seed.get("categories", []) if c not in cats]
    if "أخرى" not in cats:
        cats.append("أخرى")
    kv_set("categories", cats)
    whs = kv_get("warehouses") or []
    whs += [w for w in seed.get("warehouses", []) if w not in whs]
    kv_set("warehouses", whs)
    for it in seed.get("items", []):
        if not Item.query.filter_by(cat=it["cat"], name=it["name"]).first():
            db.session.add(Item(cat=it["cat"], name=it["name"]))
            db.session.flush()
    names = {e.name.strip() for e in Entity.query.all()}
    for e in seed.get("entities", []):
        if e["name"].strip() in names:
            continue
        db.session.add(Entity(id=e["id"], name=e["name"], warehouses=json.dumps(e.get("warehouses", []), ensure_ascii=False),
                              delegates="[]", created=e.get("created", ""), date="", notes=""))
    kv_set(tag, True)
    kv_set("version", int(kv_get("version", 0) or 0) + 1)
    db.session.commit()


# ------------------------------------------------------------------ أدوات مساعدة
def S(v, n=None):
    v = "" if v is None else str(v)
    return v[:n] if n else v


def client_ip():
    return (request.headers.get("X-Real-IP") or request.headers.get("X-Forwarded-For", "").split(",")[0]
            or request.remote_addr or "")[:64]


def log(user, action, detail=""):
    db.session.add(Log(user_id=user.id if user else None, username=user.username if user else "",
                       action=action, detail=S(detail, 2000), ip=client_ip()))


def kv_get(key, default=None):
    row = db.session.get(KV, key)
    if row is None or row.value is None:
        return default
    try:
        return json.loads(row.value)
    except ValueError:
        return default


def kv_set(key, value):
    row = db.session.get(KV, key)
    if row is None:
        row = KV(key=key)
        db.session.add(row)
    row.value = json.dumps(value, ensure_ascii=False)


def csrf_token():
    if "csrf" not in session:
        session["csrf"] = secrets.token_hex(16)
    return session["csrf"]


app.jinja_env.globals["csrf_token"] = csrf_token
app.jinja_env.globals["ROLE_LABELS"] = ROLE_LABELS


def check_csrf():
    if request.form.get("csrf") != session.get("csrf"):
        abort(400)


def current_user():
    uid = session.get("uid")
    if not uid:
        return None
    u = db.session.get(User, uid)
    if not u or not u.active or u.pw_ver != session.get("pv"):
        session.clear()
        return None
    return u


def login_required(fn):
    @wraps(fn)
    def w(*a, **k):
        u = current_user()
        if not u:
            return redirect(url_for("login"))
        return fn(u, *a, **k)
    return w


def admin_required(fn):
    @wraps(fn)
    def w(*a, **k):
        u = current_user()
        if not u:
            return redirect(url_for("login"))
        if not u.is_admin:
            abort(403)
        return fn(u, *a, **k)
    return w


def api_login(fn):
    @wraps(fn)
    def w(*a, **k):
        u = current_user()
        if not u:
            return jsonify({"error": "auth"}), 401
        if request.method != "GET" and request.headers.get("X-Jard") != "1":
            abort(403)
        return fn(u, *a, **k)
    return w


@app.after_request
def security_headers(resp):
    resp.headers.setdefault("X-Content-Type-Options", "nosniff")
    resp.headers.setdefault("X-Frame-Options", "SAMEORIGIN")
    resp.headers.setdefault("Referrer-Policy", "same-origin")
    resp.headers.setdefault("X-Robots-Tag", "noindex, nofollow")
    if request.path.startswith("/api/"):
        resp.headers["Cache-Control"] = "no-store"
    return resp


# ------------------------------------------------------------------ تسجيل الدخول
_FAILS = defaultdict(list)


def too_many(ip):
    now = time.time()
    _FAILS[ip] = [t for t in _FAILS[ip] if now - t < 600]
    return len(_FAILS[ip]) >= 8


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        check_csrf()
        ip = client_ip()
        if too_many(ip):
            flash("محاولات كثيرة خاطئة — حاول بعد 10 دقائق", "err")
            return render_template("login.html"), 429
        u = User.query.filter_by(username=request.form.get("username", "").strip().lower()).first()
        if u and u.active and check_password_hash(u.password_hash, request.form.get("password", "")):
            session.clear()
            session.permanent = True
            session["uid"], session["pv"] = u.id, u.pw_ver
            u.last_login = datetime.utcnow()
            log(u, "login")
            db.session.commit()
            return redirect(url_for("index"))
        _FAILS[ip].append(time.time())
        log(u, "login_failed", request.form.get("username", "")[:64])
        db.session.commit()
        flash("اسم المستخدم أو كلمة المرور غير صحيحة", "err")
    elif current_user():
        return redirect(url_for("index"))
    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/password", methods=["GET", "POST"])
@login_required
def password(u):
    if request.method == "POST":
        check_csrf()
        old, new, new2 = (request.form.get(k, "") for k in ("old", "new", "new2"))
        if not check_password_hash(u.password_hash, old):
            flash("كلمة المرور الحالية غير صحيحة", "err")
        elif len(new) < 6:
            flash("كلمة المرور الجديدة يجب ألا تقل عن 6 أحرف", "err")
        elif new != new2:
            flash("كلمتا المرور غير متطابقتين", "err")
        else:
            u.password_hash = generate_password_hash(new)
            u.pw_ver += 1
            u.default_pw = False
            session["pv"] = u.pw_ver
            log(u, "password_changed")
            db.session.commit()
            flash("تم تغيير كلمة المرور", "ok")
            return redirect(url_for("index"))
    return render_template("password.html", u=u)


# ------------------------------------------------------------------ إدارة المستخدمين (المدير فقط)
@app.route("/users", methods=["GET", "POST"])
@admin_required
def users(u):
    if request.method == "POST":
        check_csrf()
        act = request.form.get("act")
        f = request.form
        if act == "add":
            un = f.get("username", "").strip().lower()
            pw = f.get("password", "")
            role = f.get("role") if f.get("role") in ROLE_LABELS else ROLE_MEMBER
            if not un or not un.replace("_", "").replace(".", "").isalnum() or len(un) > 64:
                flash("اسم المستخدم يجب أن يكون بالأحرف الإنجليزية أو الأرقام", "err")
            elif User.query.filter_by(username=un).first():
                flash("اسم المستخدم مستخدم مسبقًا", "err")
            elif len(pw) < 6:
                flash("كلمة المرور يجب ألا تقل عن 6 أحرف", "err")
            else:
                if role == ROLE_CHAIR:
                    User.query.filter_by(role=ROLE_CHAIR).update({"role": ROLE_MEMBER})
                db.session.add(User(username=un, password_hash=generate_password_hash(pw),
                                    name=S(f.get("name"), 200).strip(), rank=S(f.get("rank"), 100).strip(),
                                    role=role))
                log(u, "user_add", un)
                bump()
                db.session.commit()
                flash("تمت إضافة المستخدم: " + un, "ok")
        else:
            t = db.session.get(User, int(f.get("id", 0) or 0))
            if not t:
                abort(404)
            if act == "edit":
                role = f.get("role") if f.get("role") in ROLE_LABELS else t.role
                if t.id == u.id and role != ROLE_ADMIN:
                    flash("لا يمكنك إلغاء صلاحية المدير عن حسابك", "err")
                    return redirect(url_for("users"))
                if role == ROLE_CHAIR and t.role != ROLE_CHAIR:
                    User.query.filter_by(role=ROLE_CHAIR).update({"role": ROLE_MEMBER})
                t.name, t.rank, t.role = S(f.get("name"), 200).strip(), S(f.get("rank"), 100).strip(), role
                log(u, "user_edit", t.username)
                flash("تم حفظ بيانات " + t.username, "ok")
            elif act == "reset":
                pw = f.get("password", "")
                if len(pw) < 6:
                    flash("كلمة المرور يجب ألا تقل عن 6 أحرف", "err")
                    return redirect(url_for("users"))
                t.password_hash = generate_password_hash(pw)
                t.pw_ver += 1
                t.default_pw = False
                if t.id == u.id:
                    session["pv"] = t.pw_ver
                log(u, "user_reset_pw", t.username)
                flash("تم تغيير كلمة مرور " + t.username, "ok")
            elif act == "toggle":
                if t.id == u.id:
                    flash("لا يمكنك إيقاف حسابك", "err")
                    return redirect(url_for("users"))
                t.active = not t.active
                t.pw_ver += 1
                log(u, "user_toggle", "%s -> %s" % (t.username, t.active))
                flash(("تم تفعيل " if t.active else "تم إيقاف ") + t.username, "ok")
            elif act == "delete":
                if t.id == u.id:
                    flash("لا يمكنك حذف حسابك", "err")
                    return redirect(url_for("users"))
                log(u, "user_delete", t.username)
                db.session.delete(t)
                flash("تم حذف " + t.username, "ok")
            bump()
            db.session.commit()
        return redirect(url_for("users"))
    rows = User.query.order_by(User.role != ROLE_ADMIN, User.role != ROLE_CHAIR, User.id).all()
    logs = Log.query.order_by(Log.id.desc()).limit(60).all()
    return render_template("users.html", u=u, users=rows, logs=logs)


@app.route("/backup")
@admin_required
def backup(u):
    """نسخة احتياطية كاملة بصيغة حزمة الأداة (تُستورد من «استيراد وتصدير»)"""
    st = build_state(u)
    pkg = {"type": "jard-backup", "version": 2, "exportedAt": datetime.utcnow().isoformat() + "Z",
           "settings": st["settings"], "committee": {"decision": st["decision"], "members": st["members"]},
           "report": st["report"], "categories": st["categories"], "items": st["items"],
           "warehouses": st["warehouses"], "entities": st["entities"], "notes": st["notes"]}
    log(u, "backup")
    db.session.commit()
    fn = "jard-backup-%s.txt" % datetime.utcnow().strftime("%Y-%m-%d")
    return Response(json.dumps(pkg, ensure_ascii=False), mimetype="text/plain; charset=utf-8",
                    headers={"Content-Disposition": "attachment; filename=" + fn})


# ------------------------------------------------------------------ الواجهة
INJECT = ('<head><script>window.JARD_SERVER=1</script><link rel="manifest" href="manifest.json">'
          '<meta name="theme-color" content="#123a63"><link rel="apple-touch-icon" href="icon-192.png">'
          '<meta name="robots" content="noindex,nofollow">')


@app.before_request
def add_trailing_slash():
    # عند التشغيل على مسار فرعي (مثل /fp) يجب أن ينتهي الرابط بـ / لتعمل الروابط النسبية
    if request.script_root and request.environ.get("PATH_INFO", "") == "":
        return redirect(request.script_root + "/")


@app.route("/")
@login_required
def index(u):
    with open(os.path.join(BASE, "app", "jard.html"), encoding="utf-8") as f:
        html = f.read().replace("<head>", INJECT, 1)
    r = Response(html, mimetype="text/html")
    r.headers["Cache-Control"] = "no-cache"
    return r


@app.route("/sw.js")
def sw():
    r = send_from_directory(app.static_folder, "sw.js", mimetype="application/javascript")
    r.headers["Cache-Control"] = "no-cache"
    return r


@app.route("/manifest.json")
def manifest():
    return send_from_directory(app.static_folder, "manifest.json", mimetype="application/manifest+json")


@app.route("/icon-<int:size>.png")
def icon(size):
    return send_from_directory(app.static_folder, "icon-%d.png" % (512 if size >= 512 else 192))


# ------------------------------------------------------------------ واجهة البرمجة (API)
def bump():
    kv_set("version", int(kv_get("version", 0) or 0) + 1)


def jload(v, default):
    try:
        return json.loads(v) if v else default
    except ValueError:
        return default


def committee_members():
    q = User.query.filter(User.active.is_(True), User.role.in_([ROLE_CHAIR, ROLE_MEMBER]))
    out = []
    for m in q.order_by(User.role != ROLE_CHAIR, User.id).all():
        out.append({"id": str(m.id), "role": "chair" if m.role == ROLE_CHAIR else "member",
                    "name": m.name or "", "rank": m.rank or "", "sig": m.sig or "", "sigAt": m.sig_at or ""})
    return out


def build_state(u):
    rows_by = defaultdict(list)
    for r in Row.query.order_by(Row.entity_id, Row.pos, Row.id).all():
        rows_by[r.entity_id].append({
            "id": r.id, "cat": r.cat or "", "name": r.name or "", "serial": r.serial or "", "wh": r.wh or "",
            "book": r.book or "0", "actual": r.actual or "", "notes": r.notes or "", "updated": r.updated or "",
            "by": r.by_ref or "", "byName": r.by_name or "", "at": r.at or ""})
    ents = []
    for e in Entity.query.order_by(Entity.created, Entity.id).all():
        ents.append({"id": e.id, "name": e.name, "location": e.location or "", "rep": e.rep or "",
                     "phone": e.phone or "", "repSig": e.rep_sig or "", "repSigAt": e.rep_sig_at or "",
                     "date": e.date or "", "warehouses": jload(e.warehouses, []), "delegates": jload(e.delegates, []),
                     "notes": e.notes or "", "created": e.created or "", "rows": rows_by.get(e.id, [])})
    notes = [{"id": n.id, "entity": n.entity or "", "date": n.date or "", "cat": n.cat or "", "name": n.name or "",
              "book": n.book or "0", "actual": n.actual or "", "notes": n.notes or "", "byName": n.by_name or "",
              "merged": bool(n.merged), "created": n.created or "", "updated": n.updated or ""}
             for n in Note.query.order_by(Note.created.desc(), Note.id).all()]
    return {
        "me": {"id": str(u.id), "username": u.username, "name": u.name or u.username, "rank": u.rank or "",
               "role": u.role, "full": u.full, "admin": u.is_admin, "defaultPw": bool(u.default_pw)},
        "version": int(kv_get("version", 0) or 0),
        "settings": kv_get("settings"), "report": kv_get("report"), "decision": kv_get("decision", ""),
        "categories": kv_get("categories"), "warehouses": kv_get("warehouses"),
        "items": [{"cat": i.cat, "name": i.name} for i in Item.query.order_by(Item.id).all()],
        "members": committee_members(), "entities": ents, "notes": notes,
    }


@app.route("/api/me")
@api_login
def api_me(u):
    return jsonify({"id": str(u.id), "version": int(kv_get("version", 0) or 0)})


@app.route("/api/state")
@api_login
def api_state(u):
    return jsonify(build_state(u))


@app.route("/api/sync", methods=["POST"])
@api_login
def api_sync(u):
    d = request.get_json(silent=True) or {}
    full, denied, n = u.full, [], 0

    # إعدادات عامة
    for k, v in (d.get("kv") or {}).items():
        if k in ("settings", "report", "decision"):
            if not full:
                denied.append("kv:" + k)
                continue
            kv_set(k, v)
            n += 1
        elif k in ("categories", "warehouses") and isinstance(v, list):
            v = [S(x, 300) for x in v if str(x).strip()]
            if full:
                kv_set(k, v)
            else:
                old = kv_get(k) or []
                kv_set(k, old + [x for x in v if x not in old])
            n += 1

    # أعضاء اللجنة: الاسم والرتبة والتوقيع
    for m in d.get("members") or []:
        mid = str(m.get("id", ""))
        t = db.session.get(User, int(mid)) if mid.isdigit() else None
        if not t:
            continue
        if not (full or t.id == u.id):
            denied.append("member:" + mid)
            continue
        t.name, t.rank = S(m.get("name"), 200), S(m.get("rank"), 100)
        t.sig, t.sig_at = S(m.get("sig")), S(m.get("sigAt"), 40)
        n += 1

    # الجهات
    E = d.get("entities") or {}
    for e in E.get("up") or []:
        eid = S(e.get("id"), 40)
        if not eid:
            continue
        o = db.session.get(Entity, eid)
        if o is None:
            o = Entity(id=eid, created=S(e.get("created"), 40) or datetime.utcnow().isoformat())
            db.session.add(o)
        o.name, o.location, o.rep = S(e.get("name"), 300), S(e.get("location"), 300), S(e.get("rep"), 200)
        o.phone, o.date, o.notes = S(e.get("phone"), 50), S(e.get("date"), 20), S(e.get("notes"))
        o.rep_sig, o.rep_sig_at = S(e.get("repSig")), S(e.get("repSigAt"), 40)
        o.warehouses = json.dumps([S(x, 200) for x in (e.get("warehouses") or [])], ensure_ascii=False)
        o.delegates = json.dumps([S(x, 40) for x in (e.get("delegates") or [])])
        n += 1
    for eid in E.get("del") or []:
        if not full:
            denied.append("entity_del")
            continue
        o = db.session.get(Entity, S(eid, 40))
        if o:
            Row.query.filter_by(entity_id=o.id).delete()
            db.session.delete(o)
            n += 1

    # أصناف الجرد
    R = d.get("rows") or {}
    for r in R.get("up") or []:
        rid = S(r.get("id"), 40)
        if not rid or not r.get("entity_id"):
            continue
        o = db.session.get(Row, rid)
        if o is None:
            o = Row(id=rid, created_by=u.id)
            db.session.add(o)
        o.entity_id, o.pos = S(r.get("entity_id"), 40), int(r.get("pos") or 0)
        o.cat, o.name, o.serial, o.wh = S(r.get("cat"), 200), S(r.get("name"), 300), S(r.get("serial"), 200), S(r.get("wh"), 200)
        o.book, o.actual, o.notes = S(r.get("book"), 30) or "0", S(r.get("actual"), 30), S(r.get("notes"))
        o.by_ref, o.by_name, o.at, o.updated = S(r.get("by"), 40), S(r.get("byName"), 200), S(r.get("at"), 40), S(r.get("updated"), 40)
        n += 1
    for rid in R.get("del") or []:
        o = db.session.get(Row, S(rid, 40))
        if not o:
            continue
        if not (full or o.created_by == u.id):
            denied.append("row_del")
            continue
        db.session.delete(o)
        n += 1

    # الملاحظات
    N = d.get("notes") or {}
    for x in N.get("up") or []:
        nid = S(x.get("id"), 40)
        if not nid:
            continue
        o = db.session.get(Note, nid)
        if o is None:
            o = Note(id=nid, by_user=u.id, created=S(x.get("created"), 40) or datetime.utcnow().isoformat())
            db.session.add(o)
        elif not full and o.by_user not in (None, u.id):
            denied.append("note:" + nid)
            continue
        o.entity, o.date, o.cat, o.name = S(x.get("entity"), 300), S(x.get("date"), 20), S(x.get("cat"), 200), S(x.get("name"), 300)
        o.book, o.actual, o.notes = S(x.get("book"), 30) or "0", S(x.get("actual"), 30), S(x.get("notes"))
        o.by_name, o.merged, o.updated = S(x.get("byName"), 200), bool(x.get("merged")), S(x.get("updated"), 40)
        n += 1
    for nid in N.get("del") or []:
        o = db.session.get(Note, S(nid, 40))
        if not o:
            continue
        if not (full or o.by_user == u.id):
            denied.append("note_del")
            continue
        db.session.delete(o)
        n += 1

    # قائمة الأصناف
    I = d.get("items") or {}
    for it in I.get("up") or []:
        cat, name = S(it.get("cat"), 200), S(it.get("name"), 300)
        if name and not Item.query.filter_by(cat=cat, name=name).first():
            db.session.add(Item(cat=cat, name=name))
            db.session.flush()
            n += 1
    for it in I.get("del") or []:
        if not full:
            denied.append("item_del")
            continue
        Item.query.filter_by(cat=S(it.get("cat"), 200), name=S(it.get("name"), 300)).delete()
        n += 1

    if n:
        bump()
        log(u, "sync", "%d تعديل" % n + (" | مرفوض: %d" % len(denied) if denied else ""))
    db.session.commit()
    return jsonify({"ok": True, "version": int(kv_get("version", 0) or 0), "denied": denied})


@app.errorhandler(403)
def e403(e):
    if request.path.startswith("/api/"):
        return jsonify({"error": "forbidden"}), 403
    return render_template("msg.html", title="غير مسموح", msg="ليست لديك صلاحية لهذه الصفحة."), 403


# تهيئة قاعدة البيانات وإضافة القوائم الجاهزة عند بدء التشغيل
with app.app_context():
    init_db()
    try:
        apply_seed()
    except Exception:  # لا نوقف الموقع بسبب القوائم
        db.session.rollback()
        app.logger.exception("seed failed")


if __name__ == "__main__":
    app.run(debug=False, port=int(os.environ.get("PORT", 5000)))
