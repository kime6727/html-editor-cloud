#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re

with open('LanguageManager.swift', 'r') as f:
    content = f.read()

translations_by_highlight = {
    "Syntax Highlighting": ("Highlight Off (Large File)", "Simplified Highlight"),
    "语法高亮": ("高亮已关闭(大文件)", "简化高亮"),
    "語法高亮": ("高亮已關閉(大文件)", "簡化高亮"),
    "構文ハイライト": ("ハイライトオフ(大ファイル)", "簡易ハイライト"),
    "구문 강조": ("강조 끄기(큰 파일)", "간단 강조"),
    "Coloration syntaxique": ("Surbrillance désactivée (fichier volumineux)", "Surbrillance simplifiée"),
    "Syntaxhervorhebung": ("Hervorhebung aus (große Datei)", "Vereinfachte Hervorhebung"),
    "Resaltado de sintaxis": ("Resaltado desactivado (archivo grande)", "Resaltado simplificado"),
    "Evidenziazione sintassi": ("Evidenziazione disattivata (file grande)", "Evidenziazione semplificata"),
    "Destaque de sintaxe": ("Destaque desativado (arquivo grande)", "Destaque simplificado"),
    "Подсветка синтаксиса": ("Подсветка выключена (большой файл)", "Упрощённая подсветка"),
    "تمييز بناء الجملة": ("تمييز معطل (ملف كبير)", "تمييز مبسط"),
    "सिंटैक्स हाइलाइट": ("हाइलाइट बंद (बड़ी फ़ाइल)", "सरल हाइलाइट"),
    "Sözdizimi vurgulama": ("Vurgulama kapalı (büyük dosya)", "Basitleştirilmiş vurgulama"),
    "Đánh dấu cú pháp": ("Đánh dấu tắt (tệp lớn)", "Đánh dấu đơn giản"),
    "ไฮไลท์ไวยากรณ์": ("ไฮไลท์ปิด (ไฟล์ใหญ่)", "ไฮไลท์แบบย่อ"),
    "Sorotan sintaks": ("Sorot mati (file besar)", "Sorot sederhana"),
    "Syntaxismarkering": ("Markering uit (groot bestand)", "Vereenvoudigde markering"),
    "Podświetlenie składni": ("Podświetlenie wyłączone (duży plik)", "Uproszczone podświetlenie"),
    "Penyorotan sintaks": ("Penyorotan mati (fail besar)", "Penyorotan ringkas"),
}

offset = 0
result = content
count = 0

for m in re.finditer(r'"syntax_highlighting":\s*"([^"]*)"', content):
    highlight_value = m.group(1)
    end_pos = m.end()

    nearby = content[end_pos:end_pos+200]
    if '"syntax_highlight_disabled"' in nearby:
        continue

    if highlight_value not in translations_by_highlight:
        print("WARNING: No translation for: " + highlight_value)
        continue

    disabled_text, limited_text = translations_by_highlight[highlight_value]

    insert = ', "syntax_highlight_disabled": "' + disabled_text + '", "syntax_highlight_limited": "' + limited_text + '"'

    result = result[:end_pos + offset] + insert + result[end_pos + offset:]
    offset += len(insert)
    count += 1

with open('LanguageManager.swift', 'w') as f:
    f.write(result)

print("Done. Added " + str(count) + " translations")
