import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار أبو نايف العالمي", page_icon="🌍", layout="centered")

# --- 2. ستايل احترافي للجوال ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');
    html, body, [data-testid="stSidebar"], .stApp {
        direction: rtl; text-align: right; font-family: 'Cairo', sans-serif;
    }
    [data-testid="stSidebar"] { display: none; }
    .main-title { color: #1E3A8A; text-align: center; font-size: 26px; font-weight: bold; }
    .stLinkButton a {
        background-color: #ffffff !important; color: #1E40AF !important;
        border: 2px solid #DBEafe !important; border-radius: 15px !important;
        padding: 12px !important; margin-bottom: 8px !important;
        display: block !important; text-align: center !important; font-weight: bold !important;
    }
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة البيانات ---
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "عام": [("Alibaba", "https://www.alibaba.com/trade/search?SearchText="), ("AliExpress", "https://www.aliexpress.com/wholesale?SearchText="), ("1688", "https://s.1688.com/selloffer/rpc_search.htm?keywords=")],
        "بناء وإعمار": [("Alibaba Construction", "https://www.alibaba.com/Construction-Real-Estate_p15?SearchText="), ("Made-in-China", "https://www.made-in-china.com/search_product?word=")]
    },
    "تركيا 🇹🇷": {
        "عام": [("Trendyol", "https://www.trendyol.com/sr?q="), ("Hepsiburada", "https://www.hepsiburada.com/ara?q=")],
        "بناء وتصدير": [("TurkishExporter", "https://www.turkishexporter.net/en/search?q="), ("Sahibinden", "https://www.sahibinden.com/arama?query=")]
    },
    "الخليج العربي 🇸🇦": {
        "عام": [("أمازون السعودية", "https://www.amazon.sa/s?k="), ("نون", "https://www.noon.com/saudi-ar/search/?q="), ("حراج", "https://haraj.com.sa/search/")]
    }
}

LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar"}

# --- 4. واجهة المستخدم ---
st.markdown('<p class="main-title">🌍 رادار المشتريات العالمي الذكي</p>', unsafe_allow_html=True)
st.markdown('<center><p style="color:gray;">إعداد: أبو نايف المرواني</p></center>', unsafe_allow_html=True)

item_ar = st.text_input("📦 ما هي البضاعة التي تبحث عنها؟")

col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث:", list(LANGUAGES.keys()))

st.markdown("---")

if item_ar:
    with st.spinner('⏳ جاري الترجمة والبحث...'):
        try:
            # استخدام المترجم الجديد المستقر
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.info(f"🔍 يتم البحث عن: **{translated_text}**")
            
            country_data = MARKET_LOGIC.get(target_country, {})
            top_sites = country_data.get("عام", [])
            
            for name, url in top_sites:
                st.link_button(f"🚀 فتح {name}", f"{url}{translated_text}")
        except Exception as e:
            st.error("حدث خطأ في الترجمة، يرجى المحاولة لاحقاً.")
else:
    st.info("💡 أدخل اسم البضاعة لبدء الاستكشاف.")