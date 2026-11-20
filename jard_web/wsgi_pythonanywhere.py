# انسخ محتوى هذا الملف كاملًا والصقه مكان محتوى ملف WSGI في تبويب Web على PythonAnywhere
# ثم غيّر USERNAME إلى اسم مستخدمك في PythonAnywhere
import sys

path = "/home/USERNAME/jard_web"
if path not in sys.path:
    sys.path.insert(0, path)

from flask_app import app as application  # noqa
