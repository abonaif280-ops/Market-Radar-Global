# يدمج مكتبات PDF داخل الصفحة لتعمل بدون إنترنت
import pathlib,re
d=pathlib.Path(__file__).parent
s=(d/'form.src.html').read_text(encoding='utf-8')
for url,f in [('html2canvas/1.4.1/html2canvas.min.js','html2canvas.min.js'),('jspdf/2.5.1/jspdf.umd.min.js','jspdf.umd.min.js')]:
    tag=f'<script src="https://cdnjs.cloudflare.com/ajax/libs/{url}"></script>'
    assert tag in s, tag
    s=s.replace(tag,'<script>'+(d/'vendor'/f).read_text(encoding='utf-8').replace('</script','<\\/script')+'</script>')
(d/'index.html').write_text(s,encoding='utf-8')
print('ok',len(s))
