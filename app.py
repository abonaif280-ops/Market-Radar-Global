import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار أبو نايف العالمي", page_icon="🌍", layout="centered")

# --- 2. تنسيق احترافي للجوال ودعم اللغة العربية ---
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
        text-decoration: none !important;
    }
    .stLinkButton a:hover { background-color: #1E40AF !important; color: white !important; }
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة البيانات الشاملة (5 دول، 10 مجالات، 7 مواقع لكل مجال) ---
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "عام": [("1688", "https://s.1688.com/selloffer/rpc_search.htm?keywords="), ("Alibaba", "https://www.alibaba.com/trade/search?SearchText="), ("AliExpress", "https://www.aliexpress.com/wholesale?SearchText="), ("Made-in-China", "https://www.made-in-china.com/search_product?word="), ("Global Sources", "https://www.globalsources.com/searchProducts?keyword="), ("DHgate", "https://www.dhgate.com/wholesale/search.do?searchkey="), ("Taobao", "https://world.taobao.com/search/search.htm?q=")],
        "بناء وإعمار": [("Alibaba Construction", "https://www.alibaba.com/Construction-Real-Estate_p15?SearchText="), ("1688 Construction", "https://s.1688.com/selloffer/rpc_search.htm?keywords="), ("Made-in-China Builder", "https://www.made-in-china.com/search_product?word="), ("HKTDC Construction", "https://www.hktdc.com/search/product/en?query="), ("EC21 Construction", "https://www.ec21.com/ec21/search_product.jsp?searchTerm="), ("TradeKey China", "https://www.tradekey.com/index.html?action=search&search_type=products&query="), ("OKOrder", "http://www.okorder.com/search/product?keyword=")]
    },
    "الهند 🇮🇳": {
        "عام": [("IndiaMART", "https://dir.indiamart.com/search.mp?ss="), ("TradeIndia", "https://www.tradeindia.com/search.html?keyword="), ("Exporters India", "https://www.exportersindia.com/search.php?srch_val="), ("Amazon India", "https://www.amazon.in/s?k="), ("Flipkart", "https://www.flipkart.com/search?q="), ("JioMart", "https://www.jiomart.com/search/"), ("Moglix B2B", "https://www.moglix.com/search?controller=search&s=")]
    },
    "تركيا 🇹🇷": {
        "عام": [("Trendyol", "https://www.trendyol.com/sr?q="), ("Hepsiburada", "https://www.hepsiburada.com/ara?q="), ("N11", "https://www.n11.com/arama?q="), ("TurkishExporter", "https://www.turkishexporter.net/en/search?q="), ("Sahibinden", "https://www.sahibinden.com/arama?query="), ("Morhipo", "https://www.morhipo.com/arama?q="), ("CicekSepeti", "https://www.ciceksepeti.com/arama?query=")]
    },
    "الخليج العربي 🇸🇦": {
        "عام": [("أمازون السعودية", "https://www.amazon.sa/s?k="), ("نون", "https://www.noon.com/saudi-ar/search/?q="), ("حراج", "https://haraj.com.sa/search/"), ("جرير", "https://www.jarir.com/catalogsearch/result/?q="), ("إكسترا", "https://www.extra.com/ar-sa/search/?text="), ("السوق المفتوح", "https://sa.opensooq.com/ar/search?keyword="), ("سيارة Syarah", "https://syarah.com/search?q=")]
    },
    "المغرب 🇲🇦": {
        "عام": [("جوميا المغرب", "https://www.jumia.ma/catalog/?q="), ("Avito", "https://www.avito.ma/fr/maroc/"), ("Mubawab", "https://www.mubawab.ma/fr/search?q="), ("Marjane", "https://www.marjane.ma/search?query="), ("Electroplanet", "https://www.electroplanet.ma/catalogsearch/result/?q="), ("Decathlon MA", "https://www.decathlon.ma/search?query="), ("Bricoma", "https://www.bricoma.ma/?s=")]
    }
}

FIELDS = ["عام / أخرى", "بناء وإعمار", "أثاث وديكور", "إلكترونيات وأجهزة", "سيارات وقطع غيار", "ملابس وأزياء", "مواد غذائية وجملة", "معدات صناعية وآلات", "عقارات", "أدوات صحية وسباكة"]
LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar", "الأوردو 🇵🇰": "ur", "الفرنسية 🇫🇷": "fr"}

# --- 4. واجهة المستخدم ---
st.markdown('<p class="main-title">🌍 رادار المشتريات العالمي الشامل</p>', unsafe_allow_html=True)
st.markdown('<center><p style="color:gray;">إعداد: أبو نايف المرواني</p></center>', unsafe_allow_html=True)

item_ar = st.text_input("📦 ما هي البضاعة التي تبحث عنها؟", placeholder="مثلاً: رخام، أثاث، قطع غيار...")

col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث:", list(LANGUAGES.keys()))

target_field = st.selectbox("🏗️ المجال المخصص:", FIELDS)

st.markdown("---")

if item_ar:
    with st.spinner('⏳ جاري ترجمة طلبك والبحث في المصادر...'):
        try:
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            st.info(f"🔍 البحث عن: **{translated_text}**")
            
            country_data = MARKET_LOGIC.get(target_country, {})
            # جلب المواقع حسب التخصص، أو الرجوع للعام
            top_sites = country_data.get(target_field, country_data.get("عام", []))
            
            st.subheader(f"🚀 أهم 7 منصات في {target_country}:")
            for name, url in top_sites:
                st.link_button(f"🌐 {name}", f"{url}{translated_text}")
        except:
            st.error("فشل الاتصال بالمترجم، جرب مرة أخرى.")
else:
    st.info("💡 أدخل اسم البضاعة لبدء الاستكشاف العالمي.")

st.markdown("<br><hr><center><p style='color:gray; font-size:12px;'>نظام دعم المشتريات | أبو نايف المرواني | 2026</p></center>", unsafe_allow_html=True)