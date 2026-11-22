# تثبيت "الحالات الميدانية" على Windows Server (بدون إنترنت)

## ما تحتاجه
- Windows Server 2016 أو أحدث (64-bit).
- قاعدة بيانات: **SQL Server** (2016 فأحدث) **أو PostgreSQL** (13 فأحدث)، على نفس السيرفر أو سيرفر آخر في الشبكة.
- لـ SQL Server فقط: **Microsoft ODBC Driver 18 for SQL Server** على سيرفر البرنامج. غالبًا موجود مع أدوات SQL Server، وإلا يطلبه قسم التقنية كملف تثبيت (msi).
- ملف الحزمة `field-cases-server-windows.zip`: من GitHub ← Actions ← field_cases_server ← Artifacts. يُنقل للسيرفر بفلاش أو بالشبكة الداخلية.

لا يُنزَّل أي شيء من الإنترنت أثناء التثبيت أو التشغيل: Python وكل المكتبات داخل الحزمة.

## 1. تجهيز قاعدة البيانات (مرة واحدة، يقوم بها مسؤول قواعد البيانات)

**SQL Server:**
```sql
CREATE DATABASE field_cases;
CREATE LOGIN field_cases WITH PASSWORD = 'كلمة-مرور-قوية';
USE field_cases;
CREATE USER field_cases FOR LOGIN field_cases;
ALTER ROLE db_owner ADD MEMBER field_cases;
```

**PostgreSQL:**
```sql
CREATE USER field_cases WITH PASSWORD 'كلمة-مرور-قوية';
CREATE DATABASE field_cases OWNER field_cases ENCODING 'UTF8';
```

## 2. التثبيت
1. فك ضغط الحزمة في مجلد مؤقت، مثل `C:\Temp\field-cases`.
2. افتح **PowerShell كمدير** (Run as Administrator)، وانتقل إلى المجلد ثم شغّل:
   ```powershell
   cd C:\Temp\field-cases
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Port 8080
   ```
   البرنامج يُنسخ إلى `C:\FieldCases`، ويُفتح المنفذ 8080 في جدار الحماية للشبكة الداخلية، ويُسجَّل تشغيل تلقائي مع بدء السيرفر.
3. افتح `C:\FieldCases\config.ini` بالمفكرة، واكتب رابط قاعدة البيانات في `[database] url`. الأمثلة داخل الملف:
   - SQL Server: `mssql+pyodbc://field_cases:كلمة-المرور@اسم-سيرفر-القاعدة:1433/field_cases?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes`
   - PostgreSQL: `postgresql+psycopg://field_cases:كلمة-المرور@اسم-سيرفر-القاعدة:5432/field_cases`
   - إذا احتوت كلمة المرور على رموز مثل `@` أو `:` أو `/`، استبدلها: `@` ← `%40`، `:` ← `%3A`، `/` ← `%2F`.
4. في PowerShell:
   ```powershell
   C:\FieldCases\manage.cmd check-db
   C:\FieldCases\manage.cmd init-db
   C:\FieldCases\manage.cmd create-admin --username admin --full-name "مدير النظام"
   Start-ScheduledTask -TaskName FieldCasesServer
   ```
   - `check-db`: يتأكد من الاتصال بقاعدة البيانات.
   - `init-db`: ينشئ الجداول.
   - `create-admin`: يطلب كلمة مرور مدير النظام.
   - `Start-ScheduledTask`: يشغّل البرنامج.

## 3. الدخول من الأجهزة الأخرى
من أي كمبيوتر في الشبكة الداخلية افتح المتصفح على:
```
http://اسم-السيرفر:8080
```
أو بعنوان السيرفر، مثل `http://10.10.5.20:8080`. ادخل بحساب مدير النظام، ثم أضف المستخدمين من صفحة **المستخدمون**.

**فحص التشغيل من السيرفر نفسه:** `http://localhost:8080/health` يجب أن يعرض `"status":"ok"`.

## 4. HTTPS (مستحسن)
1. اطلب من قسم التقنية شهادة للسيرفر من الجهة الداخلية (Internal CA)، بصيغة PEM: ملف الشهادة وملف المفتاح.
2. ضعهما في `C:\FieldCases\certs\` وعدّل `config.ini`:
   ```ini
   [server]
   port = 8443
   tls_cert_file = C:\FieldCases\certs\server.crt
   tls_key_file = C:\FieldCases\certs\server.key
   ```
3. أعد التثبيت بالمنفذ الجديد (`.\install.ps1 -Port 8443`) لفتحه في جدار الحماية، ثم أعد تشغيل المهمة.
4. الدخول يصبح: `https://اسم-السيرفر:8443`

## 5. التشغيل اليومي
| المهمة | الأمر |
|---|---|
| إيقاف | `Stop-ScheduledTask -TaskName FieldCasesServer` |
| تشغيل | `Start-ScheduledTask -TaskName FieldCasesServer` |
| نسي المدير كلمة مروره | `C:\FieldCases\manage.cmd reset-password --username admin` |
| تحديث لإصدار جديد | فك الحزمة الجديدة ثم `install.ps1` مرة أخرى (لا يمس `config.ini`)، ثم `manage.cmd init-db`، ثم إعادة التشغيل |
| النسخ الاحتياطي | نسخ احتياطي لقاعدة البيانات من SQL Server أو PostgreSQL حسب سياسة الجهة. صور الحالات (من المرحلة القادمة) في `C:\FieldCases\data` وتُنسخ معها |

## الحماية المطبقة
- كلمات المرور مخزنة بـ Argon2id، ولا تُحفظ كلمة المرور نفسها.
- قفل مؤقت للحساب بعد 5 محاولات خاطئة.
- الجلسة تنتهي بعد 30 دقيقة دون نشاط.
- كل نموذج محمي من الطلبات المزيفة (CSRF).
- الواجهة لا تحمّل أي شيء من خارج السيرفر.
- سجل عمليات لكل دخول وتغيير.
- `config.ini` مقصور على مدراء السيرفر لأنه يحتوي كلمة مرور قاعدة البيانات.
