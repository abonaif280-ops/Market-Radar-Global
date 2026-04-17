import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار أبو نايف الشامل", page_icon="🌍", layout="centered")

# --- 2. ستايل CSS للجوال ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');
    html, body, .stApp { direction: rtl; text-align: right; font-family: 'Cairo', sans-serif; }
    .main-title { color: #1E3A8A; text-align: center; font-size: 26px; font-weight: bold; }
    .stLinkButton a {
        background-color: #ffffff !important; color: #1E40AF !important;
        border: 2px solid #DBEafe !important; border-radius: 15px !important;
        padding: 15px !important; margin-bottom: 10px !important;
        display: block !important; text-align: center !important; font-weight: bold !important;
    }
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة بيانات الروابط المباشرة (تحديث 2026) ---
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "عام": [
            ("Alibaba Direct", "https://www.alibaba.com/trade/search?SearchText="),
            ("AliExpress Search", "https://www.aliexpress.com/wholesale?SearchText="),
            ("1688 Factory Search", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
            ("Made-in-China Direct", "https://www.made-in-china.com/search_product?word=")
        ]
    },
    "تركيا 🇹🇷": {
        "عام": [
            ("Trendyol Search", "https://www.trendyol.com/sr?q="),
            ("Hepsiburada Direct", "https://www.hepsiburada.com/ara?q="),
            ("TurkishExporter Search", "https://www.turkishexporter.net/en/search?q=")
        ]
    },
    "الخليج العربي 🇸🇦": {
        "عام": [
            ("أمازون السعودية", "https://www.amazon.sa/s?k="),
            ("نون", "https://www.noon.com/saudi-ar/search/?q="),
            ("حراج (بحث مباشر)", "https://haraj.com.sa/search/")
        ]
    },
    "الهند 🇮🇳": {
        "عام": [
            ("IndiaMART Direct", "https://dir.indiamart.com/search.mp?ss="),
            ("TradeIndia Search", "https://www.tradeindia.com/search.html?keyword=")
        ]
    },
    "المغرب 🇲🇦": {
        "عام": [
            ("Jumia MA Search", "https://www.jumia.ma/catalog/?q="),
            ("Avito Direct", "https://www.avito.ma/fr/maroc/")
        ]
    }
}

LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar", "الفرنسية 🇫🇷": "fr"}

# --- 4. واجهة المستخدم ---
st.markdown('<p class="main-title">🌍 رادار المشتريات العالمي</p>', unsafe_allow_html=True)
st.markdown('<center><p style="color:gray;">إعداد: أبو نايف المرواني</p></center>', unsafe_allow_html=True)

item_ar = st.text_input("📦 اكتب اسم البضاعة بالعربي:", placeholder="مثلاً: رخام، أثاث...")

col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 الدولة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث:", list(LANGUAGES.keys()))

st.markdown("---")

if item_ar:
    with st.spinner('⏳ جاري الترجمة والبحث الآلي...'):
        try:
            # الترجمة الآلية
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.success(f"🔍 تم تحويل البحث إلى: **{translated_text}**")
            
            top_sites = MARKET_LOGIC[target_country]["عام"]
            
            for name, url in top_sites:
                # دمج الرابط مع الكلمة المترجمة
                full_search_url = f"{url}{translated_text}"
                st.link_button(f"🚀 ابحث في {name}", full_search_url)
                
        except:
            st.error("عذراً، المترجم مشغول حالياً. حاول ثانية.")
else:
    st.info("💡 أدخل الكلمة بالعربي وسأقوم أنا بالبحث المترجم والآلي.")