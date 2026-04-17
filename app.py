import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار أبو نايف العالمي", page_icon="🌍", layout="centered")

# --- 2. ستايل احترافي مخصص للجوال ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');
    html, body, [data-testid="stSidebar"], .stApp {
        direction: rtl; text-align: right; font-family: 'Cairo', sans-serif;
    }
    [data-testid="stSidebar"] { display: none; }
    .main-title { color: #1E3A8A; text-align: center; font-size: 26px; font-weight: bold; margin-bottom: 5px; }
    .sub-title { color: #6B7280; text-align: center; font-size: 14px; margin-bottom: 20px; }
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

# --- 3. قاعدة البيانات الضخمة (10 مجالات و 7 مواقع لكل فئة) ---
MARKET_LOGIC = {
    "الصين 🇨🇳": {
        "بناء وإعمار": [
            ("1688 (سعر المصنع)", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
            ("Alibaba Construction", "https://www.alibaba.com/Construction-Real-Estate_p15?SearchText="),
            ("Made-in-China", "https://www.made-in-china.com/search_product?word="),
            ("Global Sources", "https://www.globalsources.com/searchProducts?keyword="),
            ("DHgate B2B", "https://www.dhgate.com/wholesale/search.do?searchkey="),
            ("HKTDC", "https://www.hktdc.com/search/product/en?query="),
            ("EC21 China", "https://www.ec21.com/ec21/search_product.jsp?searchTerm=")
        ],
        "إلكترونيات وأجهزة": [
            ("AliExpress Tech", "https://www.aliexpress.com/wholesale?SearchText="),
            ("Gearbest", "https://www.gearbest.com/search/?q="),
            ("Banggood", "https://www.banggood.com/search/"),
            ("Sourcing Map", "https://www.sourcingmap.com/search.php?keywords="),
            ("Sunsky Online", "https://www.sunsky-online.com/product/default!search.do?keyword="),
            ("Chinavasion", "https://www.chinavasion.com/search?q="),
            ("GeekBuying", "https://www.geekbuying.com/search?keyword=")
        ],
        "عام / أخرى": [
            ("Alibaba", "https://www.alibaba.com/trade/search?SearchText="),
            ("AliExpress", "https://www.aliexpress.com/wholesale?SearchText="),
            ("1688 Global", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
            ("Taobao", "https://world.taobao.com/search/search.htm?q="),
            ("JD Global", "https://search.jd.com/Search?keyword="),
            ("Tmall", "https://list.tmall.com/search_product.htm?q="),
            ("LightInTheBox", "https://www.lightinthebox.com/index.php?main_page=advanced_search_result&keyword=")
        ]
    },
    "تركيا 🇹🇷": {
        "أثاث وديكور": [
            ("Trendyol Home", "https://www.trendyol.com/sr?q="),
            ("Hepsiburada Home", "https://www.hepsiburada.com/ara?q="),
            ("IKEA Turkey", "https://www.ikea.com.tr/arama?q="),
            ("Vivense", "https://www.vivense.com/arama?q="),
            ("Dogtas", "https://www.dogtas.com/search?q="),
            ("Kelebek", "https://www.kelebek.com/search?q="),
            ("Sahibinden Decor", "https://www.sahibinden.com/arama?query=")
        ],
        "بناء وتصدير": [
            ("TurkishExporter", "https://www.turkishexporter.net/en/search?q="),
            ("TradeTurkey", "https://www.tradeturkey.com/search.php?q="),
            ("TurkeyIndustrial", "https://www.google.com/search?q=site:turkeyindustrial.com+"),
            ("Musiad B2B", "https://www.google.com/search?q=site:musiad.org.tr+"),
            ("Compass Turkey", "https://tr.kompass.com/search/companies/"),
            ("Export-TR", "https://www.google.com/search?q=site:tr.tradeford.com+"),
            ("YellowPages TR", "https://www.yellowpages.com.tr/ara?q=")
        ]
    },
    "الخليج العربي 🇸🇦": {
        "سيارات وقطع غيار": [
            ("حراج السيارات", "https://haraj.com.sa/tags/سيارات/"),
            ("سيارة (Syarah)", "https://syarah.com/search?q="),
            ("موتري", "https://saudi.motory.com/ar/search/"),
            ("أمانة قطع الغيار", "https://www.google.com/search?q=قطع+غيار+السعودية+"),
            ("دبي كارس", "https://www.dubicars.com/search?q="),
            ("YallaMotor", "https://www.yallamotor.com/arabic/used-cars/search?q="),
            ("سوق مستعمل", "https://www.mstaml.com/sections/cars/")
        ],
        "عام / أخرى": [
            ("أمازون السعودية", "https://www.amazon.sa/s?k="),
            ("نون", "https://www.noon.com/saudi-ar/search/?q="),
            ("حراج", "https://haraj.com.sa/search/"),
            ("جرير", "https://www.jarir.com/catalogsearch/result/?q="),
            ("إكسترا", "https://www.extra.com/ar-sa/search/?text="),
            ("السوق المفتوح", "https://sa.opensooq.com/ar/search?keyword="),
            ("سلة (متاجر محلية)", "https://www.google.com/search?q=site:salla.sa+")
        ]
    }
}

FIELDS = [
    "عام / أخرى", "بناء وإعمار", "أثاث وديكور", "إلكترونيات وأجهزة", 
    "سيارات وقطع غيار", "ملابس وأزياء", "مواد غذائية وجملة", 
    "معدات صناعية وآلات", "عقارات", "أدوات صحية وسباكة"
]

LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar", "الأوردو 🇵🇰": "ur"}

# --- 4. واجهة المستخدم ---
st.markdown('<p class="main-title">🌍 رادار المشتريات العالمي الذكي</p>', unsafe_allow_html=True)
st.markdown('<p class="sub-title">إعداد المحلل: أبو نايف المرواني</p>', unsafe_allow_html=True)

item_ar = st.text_input("📦 ما هي البضاعة التي ترغب البحث عنها؟", placeholder="مثلاً: رخام، رافعات، قطع غيار...")

col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث:", list(LANGUAGES.keys()))

target_field = st.selectbox("🏗️ المجال المخصص:", FIELDS)

st.markdown("---")

if item_ar:
    with st.spinner('⏳ جاري الترجمة والبحث في المصادر...'):
        try:
            # الترجمة باستخدام المترجم المستقر
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.info(f"🔍 يتم البحث الآن عن: **{translated_text}**")
            
            country_data = MARKET_LOGIC.get(target_country, {})
            top_sites = country_data.get(target_field, country_data.get("عام / أخرى", []))
            
            if top_sites:
                st.subheader(f"🚀 أفضل 7 ترشيحات في {target_country}:")
                for name, url in top_sites:
                    st.link_button(f"🌐 {name}", f"{url}{translated_text}")
            else:
                st.warning("لم يتم العثور على مواقع مخصصة لهذا المجال حالياً، جرب خيار 'عام'.")
                
        except Exception as e:
            st.error("فشل الاتصال بالمترجم، يرجى المحاولة لاحقاً.")
else:
    st.info("💡 أدخل اسم البضاعة بالأعلى لظهور أقوى 7 مصادر عالمية.")

st.markdown("<br><br><center><p style='color:gray; font-size:12px;'>نظام دعم اتخاذ القرار - المشتريات | 2026</p></center>", unsafe_allow_html=True)