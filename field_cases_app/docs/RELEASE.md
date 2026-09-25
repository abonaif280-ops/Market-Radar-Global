# البناء والتوقيع والتوزيع

التطبيق لا يحتاج أي خادم أو حساب سحابي أو مفاتيح API. ما يلزم فقط: أدوات البناء،
ومفتاح توقيع أندرويد، وحساب مطور Apple للجهة.

## التحقق الآلي (GitHub Actions)
`.github/workflows/field_cases_app.yml` يعمل عند كل تعديل على `field_cases_app/`:
1. تنسيق الكود، `flutter analyze`، وكل الاختبارات الآلية.
2. بناء APK للإصدار + **فحص أن إذن INTERNET غير موجود** + رفع ملف APK للتجربة (14 يومًا).
3. بناء iOS دون توقيع (للتحقق من كود Swift والإعدادات).

> ملف APK من CI موقَّع بمفتاح التطوير: للتجربة الداخلية فقط، وليس للتوزيع.

## متطلبات محلية
- Flutter 3.47.5 (`flutter --version`) — يُفضّل تعطيل إحصاءات الأداة: `flutter --disable-analytics`.
- أندرويد: Android Studio (SDK + NDK) و Java 17.
- iOS: جهاز Mac مع Xcode حديث، وحساب Apple Developer للجهة.

```bash
cd field_cases_app
flutter pub get
flutter analyze && flutter test
```

## قبل أول توزيع (قرارات لا تتغير بعدها)
| البند | القيمة الحالية | ملاحظة |
|---|---|---|
| معرّف أندرويد | `sa.fieldcases.field_cases` (`android/app/build.gradle.kts`) | تغييره بعد التوزيع = تطبيق جديد وتضيع البيانات |
| معرّف iOS | `sa.fieldcases.fieldCases` (Xcode ← Runner ← Signing) | يطابق حساب Apple للجهة |
| الاسم الظاهر | الحالات الميدانية | |
| أنواع الملفات | `sa.fieldcases.casepkg` و `sa.fieldcases.fcbackup` (`ios/Runner/Info.plist`) | تُغيَّر مع المعرّف إن تغيّر |
| الإصدار | `version: 1.0.0+1` في `pubspec.yaml` | يُرفع الرقم بعد `+` مع كل إصدار |

## أندرويد
1. إنشاء مفتاح التوقيع **مرة واحدة** (انظر `android/key.properties.example`) وحفظه مع كلمة المرور لدى الجهة. فقدانه = لا تحديثات فوق النسخة المثبتة.
2. نسخ `android/key.properties.example` إلى `android/key.properties` وملؤه (لا يُرفع إلى Git).
3. البناء:
   ```bash
   flutter build apk --release          # ملف واحد للتثبيت المباشر
   flutter build appbundle --release    # عند التوزيع عبر Google Play المُدار
   ```
4. التحقق: `aapt dump permissions build/app/outputs/flutter-apk/app-release.apk` — لا INTERNET.
5. التوزيع: تثبيت مباشر (MDM للجهة أو نقل الملف) أو Managed Google Play. الحد الأدنى Android 7.

## iOS
1. Xcode ← `ios/Runner.xcworkspace` ← Runner ← Signing & Capabilities: اختيار فريق الجهة و Bundle ID.
2. لا تُضاف أي Capability سحابية (لا iCloud، لا Push).
3. البناء:
   ```bash
   flutter build ipa --release
   ```
4. التوزيع الداخلي: TestFlight للتجربة، ثم **Custom App عبر Apple Business Manager** أو برنامج Enterprise حسب ما تملكه الجهة. الحد الأدنى iOS 15.
5. App Store Connect ← الخصوصية: "لا تُجمع أي بيانات" (Data Not Collected).

## ما يُتحقق منه في أول بناء على الأجهزة
الكود الأصلي التالي كُتب دون إمكانية تجميعه في بيئة التطوير (لا Android SDK ولا Xcode)،
ويتحقق CI من تجميعه، ويجب تجربة سلوكه على جهاز حقيقي (خطة `DEVICE_TEST_PLAN.md` البند 6 و 8):
- `android/app/src/main/kotlin/.../MainActivity.kt`: استقبال الملفات (VIEW/SEND) ونسخها.
- `ios/Runner/AppDelegate.swift`: استقبال الملفات عبر `FlutterSceneLifeCycleDelegate`، واستبعاد iCloud.
- `ios/Runner/Info.plist`: أنواع الملفات، أوصاف الأذونات.

## قائمة ما قبل الإصدار
- [ ] CI أخضر (الاختبارات + بناء أندرويد + بناء iOS).
- [ ] `DEVICE_TEST_PLAN.md` منفذة على iPhone و Android دون أخطاء حرجة.
- [ ] رقم الإصدار مرفوع في `pubspec.yaml`.
- [ ] مفتاح أندرويد والنسخة الاحتياطية منه محفوظان لدى الجهة.
- [ ] لا ملفات `key.properties` أو `.jks` في Git (`git status`).
