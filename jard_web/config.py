# -*- coding: utf-8 -*-
"""
إعدادات أداة الجرد
==================
عدّل القيم أدناه فقط. اترك MYSQL_USER فارغًا لاستخدام قاعدة SQLite المحلية (ملف داخل مجلد data).

على PythonAnywhere (تبويب Databases):
  MYSQL_USER     = اسم مستخدمك في PythonAnywhere
  MYSQL_PASSWORD = كلمة مرور MySQL التي اخترتها في تبويب Databases
  MYSQL_HOST     = اسمك.mysql.pythonanywhere-services.com
  MYSQL_DB       = اسمك$jard      (أنشئ قاعدة بهذا الاسم من تبويب Databases)
"""
import os

# ↓↓↓ عدّل هذه الأسطر الأربعة لاستخدام MySQL (اتركها فارغة "" لاستخدام SQLite) ↓↓↓
MYSQL_USER = ""          # مثال: "myname"
MYSQL_PASSWORD = ""      # كلمة مرور MySQL من تبويب Databases
MYSQL_HOST = ""          # مثال: "myname.mysql.pythonanywhere-services.com"
MYSQL_DB = ""            # مثال: "myname$jard"

# اجعلها True بعد تفعيل «Force HTTPS» في تبويب Web على PythonAnywhere (مستحسن)
SECURE_COOKIES = False

# متغيرات البيئة (اختيارية) تتقدّم على القيم أعلاه
MYSQL_USER = os.environ.get("JARD_MYSQL_USER", MYSQL_USER)
MYSQL_PASSWORD = os.environ.get("JARD_MYSQL_PASSWORD", MYSQL_PASSWORD)
MYSQL_HOST = os.environ.get("JARD_MYSQL_HOST", MYSQL_HOST)
MYSQL_DB = os.environ.get("JARD_MYSQL_DB", MYSQL_DB)
SECURE_COOKIES = os.environ.get("JARD_SECURE_COOKIES", "1" if SECURE_COOKIES else "0") == "1"

# بيانات المدير الافتراضي (تُنشأ مرة واحدة عند أول تشغيل فقط إذا كانت قاعدة البيانات فارغة)
DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_PASSWORD = "admin123"

# ---------------------------------------------------------------- لا تعدّل ما بعد هذا السطر
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")


def database_uri():
    url = os.environ.get("JARD_DATABASE_URL", "")
    if url:
        return url
    if MYSQL_USER:
        from urllib.parse import quote_plus
        return "mysql+mysqldb://%s:%s@%s/%s?charset=utf8mb4" % (
            quote_plus(MYSQL_USER), quote_plus(MYSQL_PASSWORD), MYSQL_HOST, MYSQL_DB)
    os.makedirs(DATA_DIR, exist_ok=True)
    return "sqlite:///" + os.path.join(DATA_DIR, "jard.db")


def secret_key():
    """مفتاح سري ثابت يُولَّد مرة واحدة ويُحفظ في data/secret.key"""
    env = os.environ.get("JARD_SECRET_KEY")
    if env:
        return env
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, "secret.key")
    if not os.path.exists(path):
        import secrets
        with open(path, "w") as f:
            f.write(secrets.token_hex(32))
        try:
            os.chmod(path, 0o600)
        except OSError:
            pass
    with open(path) as f:
        return f.read().strip()
