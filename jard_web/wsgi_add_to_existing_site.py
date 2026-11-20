# ============================================================================
# الحل 2: إضافة أداة الجرد داخل موقع موجود على مسار فرعي (مثل /fp)
# انسخ الأسطر التالية والصقها في **آخر** ملف WSGI للموقع الموجود (لا تحذف شيئًا منه)
# ثم غيّر USERNAME إلى اسم مستخدمك في PythonAnywhere، واضغط Reload
# فتصبح الأداة على: https://رابط-الموقع/fp/
# ============================================================================

import sys as _sys
_jard_path = "/home/USERNAME/jard_web"
if _jard_path not in _sys.path:
    _sys.path.append(_jard_path)
from werkzeug.middleware.dispatcher import DispatcherMiddleware as _Dispatcher
from jard_server import app as _jard_app
application = _Dispatcher(application, {"/fp": _jard_app})
