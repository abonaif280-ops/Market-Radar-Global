"""يبني ملف Excel مكافئ لبرنامج رادار المشتريات العالمي (app.py)."""
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.comments import Comment

FONT = "Arial"
NAVY, BLUE, LIGHT, YELLOW = "1E3A8A", "3B82F6", "E0F2FE", "FFF59D"
thin = Side(style="thin", color="BFBFBF")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)
CENTER = Alignment(horizontal="center", vertical="center", wrap_text=True)

def f(size=12, bold=False, color="000000", underline=None):
    return Font(name=FONT, size=size, bold=bold, color=color, underline=underline)

def fill(c):
    return PatternFill("solid", start_color=c)

MARKETS = [
    ("الصين 🇨🇳", "علي بابا - البحث العالمي", "https://www.alibaba.com/trade/search?SearchText="),
    ("الصين 🇨🇳", "علي إكسبريس - بحث مباشر", "https://www.aliexpress.com/wholesale?SearchText="),
    ("الصين 🇨🇳", "موقع 1688 - سعر المصنع", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
    ("الصين 🇨🇳", "صنع في الصين - بناء", "https://www.made-in-china.com/search_product?word="),
    ("تركيا 🇹🇷", "ترينديول - سوق تركيا الأول", "https://www.trendyol.com/sr?q="),
    ("تركيا 🇹🇷", "هبسي بوردا - بحث شامل", "https://www.hepsiburada.com/ara?q="),
    ("تركيا 🇹🇷", "المصدر التركي - تصدير", "https://www.turkishexporter.net/en/search?q="),
    ("الخليج العربي 🇸🇦", "أمازون السعودية", "https://www.amazon.sa/s?k="),
    ("الخليج العربي 🇸🇦", "نون - السوق الخليجي", "https://www.noon.com/saudi-ar/search/?q="),
    ("الخليج العربي 🇸🇦", "حراج - بحث فوري", "https://haraj.com.sa/search/"),
    ("الهند 🇮🇳", "إنديا مارت - بالجملة", "https://dir.indiamart.com/search.mp?ss="),
    ("الهند 🇮🇳", "تريد إنديا - تجاري", "https://www.tradeindia.com/search.html?keyword="),
    ("المغرب 🇲🇦", "جوميا المغرب", "https://www.jumia.ma/catalog/?q="),
    ("المغرب 🇲🇦", "أفيتو - سوق المغرب", "https://www.avito.ma/fr/maroc/"),
]
COUNTRIES = list(dict.fromkeys(m[0] for m in MARKETS))
LANGS = [("الإنجليزية 🇺🇸", "en"), ("الصينية 🇨🇳", "zh-CN"), ("التركية 🇹🇷", "tr"),
         ("العربية 🇸🇦", "ar"), ("الفرنسية 🇫🇷", "fr")]
# القاموس: عربي | en | zh-CN | tr | ar | fr
DICT = [
    ("رخام", "marble", "大理石", "mermer", "رخام", "marbre"),
    ("أثاث", "furniture", "家具", "mobilya", "أثاث", "meubles"),
    ("ملابس", "clothes", "服装", "giyim", "ملابس", "vêtements"),
    ("أحذية", "shoes", "鞋子", "ayakkabı", "أحذية", "chaussures"),
    ("سجاد", "carpet", "地毯", "halı", "سجاد", "tapis"),
    ("عطور", "perfume", "香水", "parfüm", "عطور", "parfum"),
    ("جوالات", "mobile phones", "手机", "cep telefonu", "جوالات", "téléphones portables"),
    ("إلكترونيات", "electronics", "电子产品", "elektronik", "إلكترونيات", "électronique"),
    ("إضاءة", "lighting", "照明", "aydınlatma", "إضاءة", "éclairage"),
    ("بلاط", "tiles", "瓷砖", "fayans", "بلاط", "carrelage"),
    ("أواني مطبخ", "kitchenware", "厨具", "mutfak eşyası", "أواني مطبخ", "ustensiles de cuisine"),
    ("ألعاب أطفال", "toys", "玩具", "oyuncak", "ألعاب أطفال", "jouets"),
    ("قطع غيار سيارات", "auto parts", "汽车配件", "oto yedek parça", "قطع غيار سيارات", "pièces auto"),
    ("خيام", "tents", "帐篷", "çadır", "خيام", "tentes"),
    ("مستلزمات تخييم", "camping equipment", "露营装备", "kamp malzemeleri", "مستلزمات تخييم", "matériel de camping"),
    ("أقمشة", "fabric", "面料", "kumaş", "أقمشة", "tissu"),
    ("حقائب", "bags", "包", "çanta", "حقائب", "sacs"),
    ("ساعات", "watches", "手表", "saat", "ساعات", "montres"),
    ("مكيفات", "air conditioners", "空调", "klima", "مكيفات", "climatiseurs"),
    ("ألواح شمسية", "solar panels", "太阳能电池板", "güneş paneli", "ألواح شمسية", "panneaux solaires"),
    ("كاميرات مراقبة", "security cameras", "监控摄像头", "güvenlik kamerası", "كاميرات مراقبة", "caméras de surveillance"),
    ("أدوات كهربائية", "power tools", "电动工具", "elektrikli aletler", "أدوات كهربائية", "outils électriques"),
    ("مواد بناء", "building materials", "建筑材料", "inşaat malzemeleri", "مواد بناء", "matériaux de construction"),
    ("زيت زيتون", "olive oil", "橄榄油", "zeytinyağı", "زيت زيتون", "huile d'olive"),
    ("تمور", "dates fruit", "椰枣", "hurma", "تمور", "dattes"),
    ("قهوة", "coffee", "咖啡", "kahve", "قهوة", "café"),
    ("مستحضرات تجميل", "cosmetics", "化妆品", "kozmetik", "مستحضرات تجميل", "cosmétiques"),
    ("نظارات شمسية", "sunglasses", "太阳镜", "güneş gözlüğü", "نظارات شمسية", "lunettes de soleil"),
    ("ستائر", "curtains", "窗帘", "perde", "ستائر", "rideaux"),
    ("أجهزة منزلية", "home appliances", "家用电器", "ev aletleri", "أجهزة منزلية", "électroménager"),
]
MAX_SITES = 10
M_LAST = 1 + 50   # مساحة لإضافة أسواق حتى الصف 51
D_LAST = 1 + 300  # مساحة للقاموس حتى الصف 301

wb = Workbook()
ws = wb.active
ws.title = "الرادار"
wm = wb.create_sheet("الأسواق")
wl = wb.create_sheet("اللغات")
wd = wb.create_sheet("القاموس")
wh = wb.create_sheet("طريقة العمل")
for s in wb.worksheets:
    s.sheet_view.rightToLeft = True

def header(sheet, row, values):
    for i, v in enumerate(values, 1):
        c = sheet.cell(row=row, column=i, value=v)
        c.font = f(12, True, "FFFFFF"); c.fill = fill(NAVY); c.alignment = CENTER; c.border = BORDER

# ---------- ورقة الأسواق ----------
header(wm, 1, ["الدولة", "اسم السوق", "رابط البحث (يُلصق بعده المصطلح)", "ترتيب داخل الدولة", "مفتاح"])
for r in range(2, M_LAST + 1):
    if r - 2 < len(MARKETS):
        for col, v in enumerate(MARKETS[r - 2], 1):
            wm.cell(row=r, column=col, value=v).font = f(11, color="0000FF")
    wm.cell(row=r, column=4, value=f'=IF(A{r}="","",COUNTIF($A$2:A{r},A{r}))')
    wm.cell(row=r, column=5, value=f'=IF(A{r}="","",A{r}&"|"&D{r})')
    for col in range(1, 6):
        c = wm.cell(row=r, column=col); c.border = BORDER
        c.alignment = Alignment(vertical="center", wrap_text=col < 3)
        if col >= 4: c.font = f(10, color="808080")
wm.column_dimensions["A"].width = 20; wm.column_dimensions["B"].width = 30
wm.column_dimensions["C"].width = 58; wm.column_dimensions["D"].width = 14; wm.column_dimensions["E"].width = 22
wm["A1"].comment = Comment("أضف أسواقاً جديدة في الصفوف الفارغة (حتى الصف 51). العمودان D و E يُحسبان تلقائياً.", "Claude")
wm.freeze_panes = "A2"

# ---------- ورقة اللغات ----------
header(wl, 1, ["اللغة", "الرمز"])
for i, (n, code) in enumerate(LANGS, 2):
    wl.cell(row=i, column=1, value=n).font = f(11, color="0000FF")
    wl.cell(row=i, column=2, value=code).font = f(11, color="0000FF")
    for col in (1, 2): wl.cell(row=i, column=col).border = BORDER
wl.column_dimensions["A"].width = 22; wl.column_dimensions["B"].width = 10

header(wl, 10, ["الدول (قائمة منسدلة)"])
for i, cn in enumerate(COUNTRIES, 11):
    wl.cell(row=i, column=1, value=cn).font = f(11, color="0000FF")
wl["A9"] = "أضف دولة جديدة هنا تحت القائمة، ثم أضف أسواقها في ورقة «الأسواق»."
wl["A9"].font = f(10, color="808080")

# ---------- ورقة القاموس ----------
header(wd, 1, ["عربي", "en", "zh-CN", "tr", "ar", "fr"])
for i, row in enumerate(DICT, 2):
    for col, v in enumerate(row, 1):
        c = wd.cell(row=i, column=col, value=v); c.font = f(11, color="0000FF"); c.border = BORDER
for col, w in zip("ABCDEF", (22, 24, 16, 22, 22, 26)):
    wd.column_dimensions[col].width = w
wd.freeze_panes = "B2"
wd["A1"].comment = Comment("قاموس الترجمة المحلي (بديل Google Translate). أضف أي بضاعة جديدة بترجماتها في الصفوف الفارغة.", "Claude")

# ---------- الورقة الرئيسية ----------
ws.column_dimensions["A"].width = 6
ws.column_dimensions["B"].width = 34
ws.column_dimensions["C"].width = 48
ws.column_dimensions["D"].width = 4
ws.column_dimensions["E"].width = 30

ws.merge_cells("A1:C1"); ws["A1"] = "🌍 رادار المشتريات العالمي"
ws["A1"].font = f(24, True, NAVY); ws["A1"].alignment = CENTER; ws.row_dimensions[1].height = 42
ws.merge_cells("A2:C2"); ws["A2"] = "إعداد: أبو نايف المرواني"
ws["A2"].font = f(14, True, NAVY); ws["A2"].alignment = CENTER

labels = [
    (4, "📦 البضاعة (بالعربي)"),
    (5, "📍 الدولة المستهدفة"),
    (6, "🌐 لغة البحث المترجم"),
    (7, "✍️ ترجمة يدوية (اختياري)"),
]
for r, t in labels:
    ws.cell(row=r, column=2, value=t).font = f(12, True)
    ws.cell(row=r, column=2).alignment = Alignment(horizontal="right", vertical="center")
    c = ws.cell(row=r, column=3); c.fill = fill(YELLOW); c.border = BORDER
    c.font = f(13, True, "0000FF"); c.alignment = CENTER
    ws.row_dimensions[r].height = 26
ws["C4"] = "رخام"
ws["C5"] = COUNTRIES[0]
ws["C6"] = LANGS[0][0]

dv_c = DataValidation(type="list", formula1=f"='اللغات'!$A$11:$A$30", allow_blank=False)
dv_l = DataValidation(type="list", formula1=f"='اللغات'!$A$2:$A$7", allow_blank=False)
ws.add_data_validation(dv_c); ws.add_data_validation(dv_l)
dv_c.add("C5"); dv_l.add("C6")

# رمز اللغة (مخفي) + الترجمة
ws["E4"] = "رمز اللغة:"; ws["E5"] = f"=IFERROR(INDEX('اللغات'!$B$2:$B$7,MATCH(C6,'اللغات'!$A$2:$A$7,0)),\"en\")"
ws["E6"] = "مصدر الترجمة:"
ws["E7"] = (f'=IF(TRIM(C4)="","",IF(TRIM(C7)<>"","يدوي",'
            f"IF(ISNUMBER(MATCH(TRIM(C4),'القاموس'!$A$2:$A${D_LAST},0)),\"القاموس\",\"غير موجود بالقاموس — استخدم زر الترجمة\")))")
for a in ("E4", "E6"): ws[a].font = f(10, True, "808080")
for a in ("E5", "E7"): ws[a].font = f(10, color="808080"); ws[a].alignment = Alignment(wrap_text=True)

# الكلمة المترجمة (منطق: يدوي ← قاموس ← النص الأصلي)
ws["B9"] = "✅ تم تجهيز البحث بكلمة:"
ws["C9"] = (f'=IF(TRIM(C4)="","",IF(TRIM(C7)<>"",TRIM(C7),'
            f"IFERROR(INDEX('القاموس'!$A$2:$F${D_LAST},MATCH(TRIM(C4),'القاموس'!$A$2:$A${D_LAST},0),"
            f"MATCH($E$5,'القاموس'!$A$1:$F$1,0)),TRIM(C4))))")
for a in ("B9", "C9"):
    ws[a].fill = fill(LIGHT); ws[a].font = f(14, True, "0369A1"); ws[a].alignment = CENTER; ws[a].border = BORDER
ws.row_dimensions[9].height = 30

ws["B10"] = "🔤 لا توجد ترجمة؟"
ws["B10"].font = f(11, True)
ws["C10"] = ('=IF(TRIM(C4)="","",HYPERLINK("https://translate.google.com/?sl=ar&tl="&$E$5&"&text="'
             '&SUBSTITUTE(TRIM(C4)," ","+")&"&op=translate","افتح ترجمة Google ثم الصق الناتج في خانة الترجمة اليدوية"))')
ws["C10"].font = f(11, color="0563C1", underline="single"); ws["C10"].alignment = CENTER

# أزرار الأسواق
ws.merge_cells("A12:C12"); ws["A12"] = "🚀 اضغط على السوق المطلوب للبحث الآلي:"
ws["A12"].font = f(14, True); ws["A12"].alignment = Alignment(horizontal="right")
header_cells = ["م", "السوق", "رابط البحث"]
for i, v in enumerate(header_cells, 1):
    c = ws.cell(row=13, column=i, value=v); c.font = f(12, True, "FFFFFF"); c.fill = fill(NAVY); c.alignment = CENTER; c.border = BORDER

KEYS = f"'الأسواق'!$E$2:$E${M_LAST}"
for k in range(1, MAX_SITES + 1):
    r = 13 + k
    idx = f'MATCH($C$5&"|"&{k},{KEYS},0)'
    ws.cell(row=r, column=1, value=f'=IF(B{r}="","",{k})')
    ws.cell(row=r, column=2, value=f"=IFERROR(INDEX('الأسواق'!$B$2:$B${M_LAST},{idx}),\"\")")
    ws.cell(row=r, column=3, value=(
        f'=IF(OR(B{r}="",$C$9=""),"",HYPERLINK(INDEX(\'الأسواق\'!$C$2:$C${M_LAST},{idx})'
        f'&SUBSTITUTE($C$9," ","+"),"🔎 استكشاف "&B{r}))'))
    for col in (1, 2, 3):
        c = ws.cell(row=r, column=col); c.alignment = CENTER; c.border = BORDER
    ws.cell(row=r, column=1).font = f(11)
    ws.cell(row=r, column=2).font = f(12, True)
    ws.cell(row=r, column=3).font = f(13, True, BLUE, "single")
    ws.row_dimensions[r].height = 28

r_note = 14 + MAX_SITES + 1
ws.merge_cells(f"A{r_note}:C{r_note}")
ws[f"A{r_note}"] = "💡 الخانات الصفراء فقط للتعديل. أدخل اسم البضاعة واختر الدولة واللغة، وستتجهز روابط البحث تلقائياً."
ws[f"A{r_note}"].font = f(11, True, "666666"); ws[f"A{r_note}"].alignment = CENTER
ws.merge_cells(f"A{r_note+1}:C{r_note+1}")
ws[f"A{r_note+1}"] = "رادار المشتريات الشخصي | 2026"
ws[f"A{r_note+1}"].font = f(10, True, "999999"); ws[f"A{r_note+1}"].alignment = CENTER
ws.column_dimensions["E"].hidden = False
ws.freeze_panes = "A4"

# ---------- طريقة العمل ----------
steps = [
    "منطق البرنامج الأصلي (app.py) وكيف تحوّل إلى Excel",
    "",
    "1) المدخلات: اسم البضاعة بالعربي + الدولة + لغة البحث  ←  ورقة «الرادار» الخانات الصفراء C4:C6.",
    "2) الترجمة: البرنامج كان يترجم عبر Google Translate. Excel لا يترجم تلقائياً بدون إضافات، لذلك الترتيب هنا:",
    "     أ) إن كتبت ترجمة يدوية في C7 تُستخدم هي.",
    "     ب) وإلا يُبحث عن الكلمة في ورقة «القاموس» بعمود اللغة المختارة.",
    "     ج) وإلا تُستخدم الكلمة العربية كما هي (مواقع الخليج والمغرب تقبل العربي).",
    "     ونص C10 رابط يفتح Google Translate جاهزاً بالكلمة واللغة؛ انسخ الناتج إلى C7 أو أضفه للقاموس ليُحفظ دائماً.",
    "3) قاعدة الأسواق: ورقة «الأسواق» = القاموس MARKET_LOGIC في البرنامج (دولة، اسم السوق، رابط البحث).",
    "4) بناء الرابط: رابط البحث + الكلمة المترجمة (المسافات تُستبدل بـ +) — نفس full_url = url + translated_text.",
    "5) الأزرار: الجدول من الصف 14 يعرض كل أسواق الدولة المختارة (حتى 10) بروابط قابلة للنقر «🔎 استكشاف ...».",
    "",
    "الإضافة والتطوير:",
    "• سوق جديد: أضف صفاً في «الأسواق» (الدولة مكتوبة مطابقة لقائمة الدول).",
    "• دولة جديدة: أضفها تحت قائمة الدول في ورقة «اللغات» (من A11) ثم أضف أسواقها.",
    "• كلمة جديدة: أضفها في «القاموس» مع ترجماتها.",
    "• مستخدمو Excel 365 الحديث: يمكن كتابة =TRANSLATE(C4,\"ar\",E5) في C7 إن كانت الدالة متاحة لديك.",
    "",
    "ملاحظة: النص الأزرق = بيانات مُدخلة قابلة للتعديل، الأسود/الرمادي = معادلات لا تُعدّل.",
]
for i, t in enumerate(steps, 1):
    c = wh.cell(row=i, column=1, value=t)
    c.font = f(16 if i == 1 else 12, i == 1 or t.endswith(":"), NAVY if i == 1 else "000000")
    c.alignment = Alignment(horizontal="right", wrap_text=True, vertical="center")
wh.column_dimensions["A"].width = 120

out = __import__("sys").argv[1] if len(__import__("sys").argv) > 1 else "رادار_المشتريات.xlsx"
wb.save(out)
print("saved", out)
