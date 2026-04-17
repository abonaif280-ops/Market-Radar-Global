import streamlit as st
from deep_translator import GoogleTranslator

# --- 1. إعدادات الصفحة ---
st.set_page_config(page_title="رادار أبو نايف المرواني", page_icon="🌍", layout="centered")

# --- 2. ستايل "يفتح النفس" - تصميم احترافي ---
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap');
    
    /* خلفية الصفحة: أبيض ثلجي مريح للعين */
    .stApp {
        background-color: #F0F2F6;
        direction: rtl;
        text-align: right;
        font-family: 'Cairo', sans-serif;
    }

    /* حاوية المحتوى: مرتبة ومنمقة في المنتصف */
    .block-container {
        max-width: 650px !important;
        padding: 2rem !important;
        background-color: #ffffff;
        border-radius: 20px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        margin-top: 20px;
    }

    /* العناوين: أسود ملكي غليظ */
    h1 { color: #1E3A8A !important; font-weight: 900 !important; text-align: center; }
    h3 { color: #000000 !important; font-weight: 800 !important; }
    p, label { color: #000000 !important; font-weight: 700 !important; }

    /* الأزرار: تصميم واضح (كلام أبيض على خلفية زرقاء) */
    .stLinkButton a {
        background: linear-gradient(90deg, #1E3A8A 0%, #3B82F6 100%) !important; 
        color: #FFFFFF !important; /* أبيض ناصع */
        border: none !important;
        border-radius: 12px !important;
        padding: 20px 10px !important;
        margin-bottom: 15px !important;
        display: block !important;
        text-align: center !important;
        font-size: 22px !important; 
        font-weight: 900 !important; 
        text-decoration: none !important;
        box-shadow: 0 4px 15px rgba(30, 58, 138, 0.3) !important;
    }
    
    .stLinkButton a:hover {
        transform: scale(1.02);
        box-shadow: 0 6px 20px rgba(30, 58, 138, 0.4) !important;
        color: #FFD700 !important; 
    }

    /* إخفاء القوائم غير الضرورية */
    [data-testid="stSidebar"] { display: none; }
    footer {visibility: hidden;}
    </style>
    """, unsafe_allow_html=True)

# --- 3. قاعدة البيانات (البحث الآلي) ---
MARKET_LOGIC = {
    "الصين 🇨🇳": [
        ("علي بابا - البحث العالمي", "https://www.alibaba.com/trade/search?SearchText="),
        ("علي إكسبريس - بحث مباشر", "https://www.aliexpress.com/wholesale?SearchText="),
        ("موقع 1688 - سعر المصنع", "https://s.1688.com/selloffer/rpc_search.htm?keywords="),
        ("صنع في الصين - بناء", "https://www.made-in-china.com/search_product?word=")
    ],
    "تركيا 🇹🇷": [
        ("ترينديول - سوق تركيا الأول", "https://www.trendyol.com/sr?q="),
        ("هبسي بوردا - بحث شامل", "https://www.hepsiburada.com/ara?q="),
        ("المصدر التركي - تصدير", "https://www.turkishexporter.net/en/search?q=")
    ],
    "الخليج العربي 🇸🇦": [
        ("أمازون السعودية", "https://www.amazon.sa/s?k="),
        ("نون - السوق الخليجي", "https://www.noon.com/saudi-ar/search/?q="),
        ("حراج - بحث فوري", "https://haraj.com.sa/search/")
    ],
    "الهند 🇮🇳": [
        ("إنديا مارت - بالجملة", "https://dir.indiamart.com/search.mp?ss="),
        ("تريد إنديا - تجاري", "https://www.tradeindia.com/search.html?keyword=")
    ],
    "المغرب 🇲🇦": [
        ("جوميا المغرب", "https://www.jumia.ma/catalog/?q="),
        ("أفيتو - سوق المغرب", "https://www.avito.ma/fr/maroc/")
    ]
}

LANGUAGES = {"الإنجليزية 🇺🇸": "en", "الصينية 🇨🇳": "zh-CN", "التركية 🇹🇷": "tr", "العربية 🇸🇦": "ar", "الفرنسية 🇫🇷": "fr"}

# --- 4. الواجهة الأمامية ---
st.markdown('<h1>🌍 رادار المشتريات العالمي</h1>', unsafe_allow_html=True)
st.markdown('<p style="text-align:center; font-size:22px; color:#1E3A8A !important;">إعداد: أبو نايف المرواني</p>', unsafe_allow_html=True)
st.markdown("<br>", unsafe_allow_html=True)

# حقل البحث
item_ar = st.text_input("📦 ما هي البضاعة التي ترغب البحث عنها؟", placeholder="اكتب هنا بالعربي (مثلاً: رخام، أثاث...)")

col1, col2 = st.columns(2)
with col1:
    target_country = st.selectbox("📍 اختر الدولة المستهدفة:", list(MARKET_LOGIC.keys()))
with col2:
    target_lang = st.selectbox("🌐 لغة البحث المترجم:", list(LANGUAGES.keys()))

st.markdown("<hr>", unsafe_allow_html=True)

if item_ar:
    try:
        with st.spinner('⏳ جاري ترجمة طلبك وفتح الرادار...'):
            translated_text = GoogleTranslator(source='auto', target=LANGUAGES[target_lang]).translate(item_ar)
            
            st.markdown(f"<div style='background-color:#E0F2FE; padding:15px; border-radius:10px; border-right:5px solid #0369A1;'>"
                        f"<h3 style='margin:0;'>✅ تم تجهيز البحث بكلمة: <span style='color:#0369A1;'>{translated_text}</span></h3>"
                        f"</div>", unsafe_allow_html=True)
            
            st.markdown("<br><h3>🚀 اضغط على السوق المطلوب للبحث الآلي:</h3>", unsafe_allow_html=True)
            
            sites = MARKET_LOGIC.get(target_country, [])
            for name, url in sites:
                full_url = f"{url}{translated_text}"
                st.link_button(f"🔎 استكشاف {name}", full_url)
                
    except Exception as e:
        st.error("حدث خطأ في الاتصال، يرجى المحاولة مرة أخرى.")
else:
    st.markdown("<p style='text-align:center; background-color:#F3F4F6; padding:20px; border-radius:15px; border:1px dashed #999;'>"
                "💡 أدخل اسم البضاعة وسأقوم بالبحث المترجم تلقائياً في الأسواق العالمية.</p>", unsafe_allow_html=True)

st.markdown("<br><br><p style='text-align:center; font-size:14px; font-weight:bold; color:#999 !important;'>رادار المشتريات الشخصي | 2026</p>", unsafe_allow_html=True)