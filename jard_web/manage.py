# -*- coding: utf-8 -*-
"""
أوامر مساعدة — تُشغَّل من Bash console داخل مجلد jard_web:
  python3 manage.py reset-admin            إعادة كلمة مرور admin إلى admin123 وتفعيله (عند نسيانها)
  python3 manage.py backup                 حفظ نسخة احتياطية كاملة في مجلد data
  python3 manage.py users                  عرض المستخدمين
"""
import json
import os
import sys
from datetime import datetime

from werkzeug.security import generate_password_hash

import jard_config as config
from jard_server import app, build_state
from jard_models import ROLE_ADMIN, User, db


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    with app.app_context():
        if cmd == "reset-admin":
            u = User.query.filter_by(username=config.DEFAULT_ADMIN_USERNAME).first()
            if not u:
                u = User(username=config.DEFAULT_ADMIN_USERNAME, name="مدير النظام", role=ROLE_ADMIN, password_hash="")
                db.session.add(u)
            u.password_hash = generate_password_hash(config.DEFAULT_ADMIN_PASSWORD)
            u.pw_ver = (u.pw_ver or 1) + 1
            u.role, u.active, u.default_pw = ROLE_ADMIN, True, True
            db.session.commit()
            print("تمت إعادة حساب %s بكلمة المرور %s — غيّرها بعد الدخول." % (u.username, config.DEFAULT_ADMIN_PASSWORD))
        elif cmd == "backup":
            admin = User.query.filter_by(role=ROLE_ADMIN).first()
            st = build_state(admin)
            pkg = {"type": "jard-backup", "version": 2, "exportedAt": datetime.utcnow().isoformat() + "Z",
                   "settings": st["settings"], "committee": {"decision": st["decision"], "members": st["members"]},
                   "report": st["report"], "categories": st["categories"], "items": st["items"],
                   "warehouses": st["warehouses"], "entities": st["entities"], "notes": st["notes"]}
            path = os.path.join(config.DATA_DIR, "backup-%s.txt" % datetime.utcnow().strftime("%Y%m%d-%H%M"))
            with open(path, "w", encoding="utf-8") as f:
                json.dump(pkg, f, ensure_ascii=False)
            print("تم الحفظ:", path)
        elif cmd == "users":
            for u in User.query.order_by(User.id).all():
                print(u.id, u.username, u.role_label, "نشط" if u.active else "موقوف", u.name)
        else:
            print(__doc__)


if __name__ == "__main__":
    main()
