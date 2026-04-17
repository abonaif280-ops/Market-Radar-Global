import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار المشتريات - أبو نايف", page_icon="🌍", layout="centered")

# --- 2. ستايل CSS المطور (تركيز على الوضوح واللون الأسود العريض) ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');
    
    /* لون خلفية الصفحة */
    .stApp {
        background-color: #F8F9FA;
        direction: rtl;
        text-align: right;
        font-family: 'Cairo', sans-serif;
    }

    /* جعل الحقول بعرض محدد وغير طويلة جداً */
    .block-container {
        max-width: 650px !important;
        padding-top: 2rem !important;
    }

    /* تنسيق النصوص لتكون سوداء وعريضة جداً */
    h1, h2, h3, p, label, .stMarkdown {
        color: #000000 !important;
        font-weight: 800 !important;
    }

    /* تنسيق تسميات الحقول (Labels) */
    .stWidget label p {
        font-size: 18px !important;
        color: #000000 !important;
        font-weight: bold !important;
    }

    /* تنسيق أزرار الروابط لتكون بارزة جداً */
    .stLinkButton a {
        background-color: #000000 !important;
        color: #ffffff !important;
        border-radius: 10px !important;
        padding: 15px !important;
        margin-bottom: 12px !important;
        display: block !important;
        text-align: center !important;
        font-size: 18px !important;
        font-weight: bold !important;
        text-decoration: none !important;
        border: 2px solid #000000 !important;
    }
    .stLinkButton a:hover {
        background-color: #333333 !important;
        color: #FFD700 !important; /* لون ذهبي عند المرور بالفأرة */
    }

    /* إخفاء الشريط الجانبي */
    [data-testid="stSidebar"] { display: none; }
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة البيانات الشاملة (الدول والمواقع) ---
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "عام": [("Alibaba Direct", "https://www.alibaba.com/trade/search?SearchText="), ("AliExpress Direct", "https://www.aliexpress.com/wholesale?SearchText="), ("1688 Search", "https://s.1688.com/selloffer/rpc_search.htm?keywords="), ("Made-in-China", "https://www.made-in-china.com/search_product?word=")]
    },
    "الهند 🇮🇳": {
        "عام": [("IndiaMART", "https://dir.indiamart.com/search.mp?ss="), ("TradeIndia", "https://www.tradeindia.com/search.html?keyword="), ("Amazon India", "https://www.amazon.in/s?k=")]
    },
    "تركيا 🇹🇷": {
        "عام": [("Trendyol Direct", "https://www.trendyol.com/sr?q="), ("Hepsiburada", "https://www.hepsiburada.com/ara?q="), ("TurkishExporter", "https://www.turkishexporter.net/en/search?q=")]
    },
    "الخليج العربي 🇸🇦": {
        "عام": [("أمازون السعودية", "https://www.amazon.sa/s?k="), ("نون السعودية", "https://www.noon.com/saudi-ar/search/?q="), ("حراج (بحث مباشر)", "https://haraj.com.sa/search/")]
    },
    "المغرب 🇲🇦": {
        "عام": [("جوميا المغرب", "https://www.jumia.ma/catalog/?q="), ("Avito Direct", "https://www.avito.ma/fr/maroc/")]
    }
}

LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar", "الفرنسية 🇫🇷": "fr"}
FIELDS = ["عام / أخرى", "بناء وإعمار", "أثاث وديكور", "إلكترونيات وأجهزة", "سيارات وقطع غيار", "عقارات"]

# --- 4. الواجهة الأمامية ---
st.markdown('<h1 style="text-align:center;">🌍 رادار المشتريات العالمي</h1>', unsafe_allow_html=True)
st.markdown('<p style="text-align:center; font-size:20px;">إعداد: أبو نايف المرواني</p>', unsafe_allow_html=True)
st.markdown("<br>", unsafe_allow_html=True)

# حقل الإدخال
item_ar = st.text_input("📦 ما هي البضاعة المطلوبة؟", placeholder="اكتب هنا بالعربي...")

# الحقول في صفوف مرتبة
col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث المترجم:", list(LANGUAGES.keys()))

target_field = st.selectbox("🏗️ المجال المخصص:", FIELDS)

st.markdown("<hr style='border:1px solid #000;'>", unsafe_allow_html=True)

# منطق التشغيل
if item_ar:
    try:
        with st.spinner('⏳ جاري الترجمة والبحث الآلي...'):
            # الترجمة الفورية
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.markdown(f"<h3 style='color:green;'>✅ تم تجهيز البحث بكلمة: {translated_text}</h3>", unsafe_allow_html=True)
            
            country_data = MARKET_LOGIC.get(target_country, {})
            top_sites = country_data.get("عام", [])
            
            st.markdown("<h3>🚀 اضغط على الموقع لفتح النتائج فوراً:</h3>", unsafe_allow_html=True)
            
            for name, url in top_sites:
                # دمج الرابط بالكلمة المترجمة للبحث الآلي
                full_url = f"{url}{translated_text}"
                st.link_button(f"🔎 ابحث في {name}", full_url)
                
    except Exception as e:
        st.error("حدث خطأ في الاتصال، حاول مرة أخرى.")
else:
    st.markdown("<p style='text-align:center; color:#555;'>💡 أدخل اسم البضاعة وسأقوم بالبحث المترجم تلقائياً.</p>", unsafe_allow_html=True)

st.markdown("<br><br><p style='text-align:center; font-size:12px; font-weight:normal;'>نظام دعم القرار الميداني - 2026</p>", unsafe_allow_html=True)