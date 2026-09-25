# الحالات الميدانية — Field Cases

تطبيق جوال (iPhone / Android) يعمل دون إنترنت لإدخال الحالات الميدانية وحفظها محليًا،
وصياغة نصها آليًا، ومشاركتها، وتصديرها في حزم `.casepkg` يستوردها المشرف في نسخته من نفس التطبيق.

- المتطلبات المعتمدة: [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md)
- وثيقة التصميم والمعمارية وسجل المراحل: [`docs/DESIGN.md`](docs/DESIGN.md)

## التشغيل

```bash
cd field_cases_app
flutter pub get
dart run build_runner build   # فقط عند تعديل جداول قاعدة البيانات
flutter run                   # على جهاز أو محاكي
flutter test                  # الاختبارات الآلية
```

يتطلب Flutter 3.47 أو أحدث. الملف المولّد `lib/core/db/app_database.g.dart` محفوظ في المستودع.

## هيكل المجلدات

```
lib/
  app/        التطبيق، الثيم، التنقل، Providers
  core/       قاعدة البيانات، المعرفات، سجل العمليات
  features/   الميزات (home, cases, settings, ...) — لكل ميزة data/domain/presentation
  shared/     عناصر واجهة مشتركة
test/         اختبارات الوحدات والواجهة
```

## سياسة الخصوصية التقنية

لا يحتوي التطبيق على أي اتصال بسيرفر أو خدمة سحابية أو تحليلات. يوجد اختبار آلي
(`test/core/offline_policy_test.dart`) يفشل إذا أُضيفت حزمة شبكة أو سحابة أو إذا طُلب إذن INTERNET في نسخة الإصدار.
