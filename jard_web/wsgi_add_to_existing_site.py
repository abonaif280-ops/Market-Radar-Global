# ============================================================================
# إضافة أداة الجرد داخل موقع موجود على المسار /fp
# الصق هذه الأسطر في **آخر** ملف WSGI للموقع (لا تحذف شيئًا منه)، غيّر USERNAME، ثم Reload
# محمي: إذا فشلت الأداة يبقى الموقع الأصلي يعمل، وتظهر سبب المشكلة على /fp/
# ============================================================================
import sys as _sys
_jard_path = "/home/USERNAME/jard_web"
if _jard_path not in _sys.path:
    _sys.path.append(_jard_path)
try:
    from jard_server import app as _jard_app
except Exception as _e:
    import traceback as _tb
    _tb.print_exc()  # التفاصيل الكاملة في error log
    _jard_msg = ("أداة الجرد لم تعمل بعد. السبب:\n\n%s: %s\n\nالمسار المستخدم: %s"
                 % (type(_e).__name__, _e, _jard_path)).encode("utf-8")
    def _jard_app(environ, start_response):
        start_response("500 Internal Server Error", [("Content-Type", "text/plain; charset=utf-8")])
        return [_jard_msg]
from werkzeug.middleware.dispatcher import DispatcherMiddleware as _Dispatcher
application = _Dispatcher(application, {"/fp": _jard_app})
