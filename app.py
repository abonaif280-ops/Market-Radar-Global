import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار المشتريات - أبو نايف", page_icon="🌍", layout="centered")

# --- 2. ستايل CSS المطور (تركيز على الوضوح واللون الأسود العريض والترتيب) ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;800&display=swap');
    
    /* لون خلفية الصفحة (رمادي فاتح جداً) */
    .stApp {
        background-color: #F8F9FA;
        direction: rtl;
        text-align: right;
        font-family: 'Cairo', sans-serif;
    }

    /* جعل الحقول بعرض محدد ومجمعة في المنتصف (ليست طويلة جداً) */
    .block-container {
        max-width: 600px !important;
        padding-top: 1.5rem !important;
        margin: auto;
    }

    /* تنسيق النصوص لتكون سوداء وعريضة جداً (Bold 800) */
    h1, h2, h3, p, label, .stMarkdown, .stSubheader, .stAlert, .stButton {
        color: #000000 !important;
        font-weight: 800 !important;
        font-family: 'Cairo', sans-serif !important;
    }

    /* تنسيق تسميات الحقول (Labels) - سوداء وغليظة */
    .stWidget label p {
        font-size: 18px !important;
        color: #000000 !important;
        font-weight: 800 !important;
    }

    /* تنسيق أزرار الروابط لتكون بارزة جداً وعسكرية */
    .stLinkButton a {
        background-color: #000000 !important; /* أسود كامل */
        color: #ffffff !important; /* خط أبيض */
        border: 2px solid #000000 !important;
        border-radius: 12px !important;
        padding: 18px !important;
        margin-bottom: 12px !important;
        display: block !important;
        text-align: center !important;
        font-size: 20px !important;
        font-weight: 800 !important;
        text-decoration: none !important;
        transition: all 0.2s ease;
    }
    .stLinkButton a:hover {
        background-color: #333333 !important;
        border-color: #333333 !important;
        transform: translateY(-2px); /* حركة بسيطة عند التمرير */
    }

    /* إخفاء الشريط الجانبي */
    [data-testid="stSidebar"] { display: none; }
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة البيانات الشاملة (الدول والروابط المباشرة للبحث الآلي) ---
# قمت بتحديث الروابط لتكون "روابط بحث مباشرة" تجبر الموقع على وضع الكلمة المترجمة في خانة البحث فوراً.
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "عام": [
            ("Alibaba Search", "https://www.alibaba.com/trade/search?SearchText="),
            ("AliExpress Direct", "https://www.aliexpress.com/wholesale?SearchText="),
            ("1688 Search", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
            ("Made-in-China Builder", "https://www.made-in-china.com/search_product?word=")
        ]
    },
    "الهند 🇮🇳": {
        "عام": [
            ("IndiaMART Search", "https://dir.indiamart.com/search.mp?ss="),
            ("TradeIndia Direct", "https://www.tradeindia.com/search.html?keyword="),
            ("Exporters India", "https://www.exportersindia.com/search.php?srch_val=")
        ]
    },
    "تركيا 🇹🇷": {
        "عام": [
            ("Trendyol Search", "https://www.trendyol.com/sr?q="),
            ("Hepsiburada Direct", "https://www.hepsiburada.com/ara?q="),
            ("TurkishExporter", "https://www.turkishexporter.net/en/search?q=")
        ]
    },
    "الخليج العربي 🇸🇦": {
        "عام": [
            ("أمازون السعودية", "https://www.amazon.sa/s?k="),
            ("نون (noon.com)", "https://www.noon.com/saudi-ar/search/?q="),
            ("حراج (بحث)", "https://haraj.com.sa/search/")
        ]
    },
    "المغرب 🇲🇦": {
        "عام": [
            ("جوميا المغرب", "https://www.jumia.ma/catalog/?q="),
            ("Avito.ma", "https://www.avito.ma/fr/maroc/")
        ]
    }
}

# لغات المصدر للترجمة
LANGUAGES = {
    "الإنجليزية 🇺🇸": "en",
    "الصينية 🇨🇳": "zh-CN",
    "التركية 🇹🇷": "tr",
    "العربية 🇸🇦": "ar",
    "الأوردو 🇵🇰": "ur"
}

# --- 4. الواجهة الأمامية ---
st.markdown('<h1 style="text-align:center;">🌍 رادار المشتريات الشامل</h1>', unsafe_allow_html=True)
st.markdown('<p style="text-align:center; font-size:22px;">إعداد المحلل: أبو نايف المرواني</p>', unsafe_allow_html=True)
st.markdown("<br>", unsafe_allow_html=True)

# حقل الإدخال - مجمّع وقصير بفضل الستايل CSS
item_ar = st.text_input("📦 ما هي البضاعة التي ترغب البحث عنها؟", placeholder="اكتب هنا بالعربي...")

# الحقول في صفوف مرتبة، قصيرة ومجمعة
col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة المستهدفة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 ترجم وابحث بلغة:", list(LANGUAGES.keys()))

st.markdown("<hr style='border:1px solid #000;'>", unsafe_allow_html=True)

# منطق التشغيل والبحث الآلي
if item_ar:
    try:
        with st.spinner('⏳ جاري ترجمة طلبك والبحث الآلي في المصادر...'):
            # الترجمة الفورية باستخدام المترجم المستقر
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.success(f"🔍 تم تجهيز البحث بكلمة: **{translated_text}**")
            
            country_data = MARKET_LOGIC.get(target_country, {})
            top_sites = country_data.get("عام", [])
            
            st.markdown("<h3>🚀 اضغط على الموقع لفتح النتائج فوراً:</h3>", unsafe_allow_html=True)
            
            for name, url in top_sites:
                # دمج الرابط بالكلمة المترجمة للبحث الآلي والعميق
                full_search_url = f"{url}{translated_text}"
                st.link_button(f"🔎 ابحث في {name}", full_search_url)
                
    except Exception as e:
        st.error(f"عذراً، حدث خطأ فني: {e}. حاول مرة أخرى.")
else:
    st.markdown("<p style='text-align:center; color:#4B5563; font-weight:800; font-size:18px;'>💡 أدخل الكلمة بالعربي وسأقوم بالبحث المترجم تلقائياً.</p>", unsafe_allow_html=True)

st.markdown("<br><br><p style='text-align:center; font-size:12px; font-weight:400;'>نظام دعم اتخاذ القرار | شرطة منطقة المدينة | 2026</p>", unsafe_allow_html=True)