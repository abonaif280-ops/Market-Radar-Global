"""البيانات الأولية (الإصدار 1) — مطابقة لتطبيق الجوال (lib/core/db/seed_data.dart
و lib/features/templates/domain/default_templates.dart).

يستخدمها Migration 0002 فقط. لا تُعدَّل بعد الاعتماد: أي تغيير لاحق يكون
في Migration جديد حتى تبقى القواعد المثبتة سابقًا متسقة.
"""

from __future__ import annotations

CASE_TYPE = "case_type"
GOVERNORATE = "governorate"
CENTER = "center"
REPORT_SOURCE = "report_source"
PARTY = "party"


def lookup_id(list_key: str, code: str) -> str:
    return f"{list_key}:{code}"


# (القائمة، الرمز، الاسم، رمز الأب)
LOOKUPS: list[tuple[str, str, str, str | None]] = [
    (CASE_TYPE, "SOLID_OBJECT", "جسم صلب", None),
    (CASE_TYPE, "SHRAPNEL", "شظايا", None),
    (CASE_TYPE, "DRONE", "طائرة مسيرة", None),
    (CASE_TYPE, "FIRE", "حريق", None),
    (CASE_TYPE, "SECURITY_CASE", "حالة أمنية", None),
    (CASE_TYPE, "SECURITY_INCIDENT", "حادث أمني", None),
    (CASE_TYPE, "OTHER", "أخرى", None),
    (GOVERNORATE, "MED", "المدينة المنورة", None),
    (GOVERNORATE, "YNB", "ينبع", None),
    (GOVERNORATE, "ULA", "العلا", None),
    (GOVERNORATE, "MAHD", "المهد", None),
    (GOVERNORATE, "HNK", "الحناكية", None),
    (GOVERNORATE, "BADR", "بدر", None),
    (GOVERNORATE, "KHAYBAR", "خيبر", None),
    (GOVERNORATE, "AIS", "العيص", None),
    (GOVERNORATE, "WFR", "وادي الفرع", None),
    (CENTER, "RAYES", "مركز الرايس", "BADR"),
    (REPORT_SOURCE, "911", "العمليات الموحدة (911)", None),
    (REPORT_SOURCE, "PATROL", "دورية ميدانية", None),
    (REPORT_SOURCE, "DIRECT", "بلاغ مباشر", None),
    (REPORT_SOURCE, "CITIZEN", "مواطن / مقيم", None),
    (REPORT_SOURCE, "GOV", "جهة حكومية", None),
    (PARTY, "CIVIL_DEF", "الدفاع المدني", None),
    (PARTY, "EOD", "إدارة الأسلحة والمتفجرات", None),
    (PARTY, "RED_CRESCENT", "الهلال الأحمر", None),
    (PARTY, "FORENSICS", "الأدلة الجنائية", None),
    (PARTY, "CID", "البحث والتحري", None),
    (PARTY, "PATROLS", "الدوريات الأمنية", None),
    (PARTY, "TRAFFIC", "المرور", None),
]

# (رمز النوع، المفتاح، العنوان، نوع الإدخال، الخيارات)
FIELDS: list[tuple[str, str, str, str, list[str] | None]] = [
    ("SOLID_OBJECT", "object_state", "حالة الجسم", "select",
     ["جسم صلب سليم", "أجزاء من جسم صلب", "بقايا متناثرة"]),
    ("SOLID_OBJECT", "has_fire", "وجود حريق", "boolean", None),
    ("SHRAPNEL", "pieces_count", "عدد الشظايا التقريبي", "number", None),
    ("SHRAPNEL", "spread_area", "نطاق الانتشار", "text", None),
    ("DRONE", "drone_state", "حالة الطائرة", "select",
     ["سليمة", "محطمة", "على شكل أجزاء متناثرة"]),
    ("DRONE", "has_fire", "وجود حريق", "boolean", None),
    ("FIRE", "fire_size", "حجم الحريق", "select", ["محدود", "متوسط", "كبير"]),
    ("FIRE", "fire_controlled", "تمت السيطرة", "boolean", None),
    ("SECURITY_INCIDENT", "incident_kind", "نوع الحادث", "text", None),
]

_OPENING = "عند الساعة {{الوقت}} ورد بلاغ{{#مصدر_البلاغ}} من {{مصدر_البلاغ}}{{/مصدر_البلاغ}}"
_TAIL = (
    "، {{عبارة_الإصابات_والوفيات}}"
    "{{#وجود_أضرار}}، مع وجود أضرار{{#وصف_الأضرار}} ({{وصف_الأضرار}}){{/وصف_الأضرار}}{{/وجود_أضرار}}"
    "{{#الإجراء_المتخذ}}، {{الإجراء_المتخذ}}{{/الإجراء_المتخذ}}"
    "{{#الجهات}}، وجرى إبلاغ {{الجهات}} لإكمال اللازم كل فيما يخصه{{/الجهات}}."
)

GENERIC_TEMPLATE_ID = "template:GENERIC"

# رمز النوع (أو None للعام) ← (الاسم، النص)
TEMPLATES: dict[str | None, tuple[str, str]] = {
    "SOLID_OBJECT": (
        "جسم صلب",
        _OPENING + " عن العثور على جسم صلب {{عبارة_الموقع}}"
        "{{#حالة_الجسم}}، وبالانتقال للموقع اتضح وجود {{حالة_الجسم}}"
        "{{#وجود_حريق}} تنبعث منها نيران{{/وجود_حريق}}{{/حالة_الجسم}}"
        "{{^حالة_الجسم}}{{#وجود_حريق}}، وتنبعث منه نيران{{/وجود_حريق}}{{/حالة_الجسم}}"
        "{{#معلومات_الحالة}}، {{معلومات_الحالة}}{{/معلومات_الحالة}}" + _TAIL,
    ),
    "SHRAPNEL": (
        "شظايا",
        _OPENING + " عن سقوط شظايا {{عبارة_الموقع}}"
        "{{#عدد_الشظايا_التقريبي}}، وبالانتقال للموقع اتضح وجود ({{عدد_الشظايا_التقريبي}}) شظايا تقريبًا{{/عدد_الشظايا_التقريبي}}"
        "{{#نطاق_الانتشار}} منتشرة في نطاق {{نطاق_الانتشار}}{{/نطاق_الانتشار}}"
        "{{#معلومات_الحالة}}، {{معلومات_الحالة}}{{/معلومات_الحالة}}" + _TAIL,
    ),
    "DRONE": (
        "طائرة مسيرة",
        _OPENING + " عن سقوط طائرة مسيرة {{عبارة_الموقع}}"
        "{{#حالة_الطائرة}}، وبالانتقال للموقع اتضح أنها {{حالة_الطائرة}}{{/حالة_الطائرة}}"
        "{{#وجود_حريق}} وتنبعث منها نيران{{/وجود_حريق}}"
        "{{#معلومات_الحالة}}، {{معلومات_الحالة}}{{/معلومات_الحالة}}" + _TAIL,
    ),
    "FIRE": (
        "حريق",
        _OPENING + " عن نشوب حريق{{#حجم_الحريق}} {{حجم_الحريق}}{{/حجم_الحريق}} {{عبارة_الموقع}}"
        "{{#تمت_السيطرة}}، وتمت السيطرة عليه{{/تمت_السيطرة}}"
        "{{#معلومات_الحالة}}، {{معلومات_الحالة}}{{/معلومات_الحالة}}" + _TAIL,
    ),
    None: (
        "قالب عام",
        _OPENING + " عن {{نوع_الحالة}} {{عبارة_الموقع}}"
        "{{#معلومات_الحالة}}، {{معلومات_الحالة}}{{/معلومات_الحالة}}" + _TAIL,
    ),
}
