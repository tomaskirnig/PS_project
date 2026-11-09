import os
import subprocess
import docx
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

src_path = "/home/tomas/school/PS/PS_project/PS_DU1S_3S_prilohy_sablona_2026_2027.docx"
dst_docx = "/home/tomas/school/PS/PS_project/du1/PS_DU1S_3S_prilohy_sablona_2026_2027.docx"
dst_pdf = "/home/tomas/school/PS/PS_project/du1/PS_DU1S_3S_prilohy_sablona_2026_2027.pdf"
img_dir = "/home/tomas/school/PS/PS_project/du1/img"

doc = docx.Document(src_path)

# --- 1. Titulní strana (Page 1) ---
table = doc.tables[0]

def set_cell_text(cell, text, font_size=13, bold=True):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(2)
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(font_size)
    run.bold = bold
    run.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)

set_cell_text(table.rows[0].cells[1], "Tomáš Kirnig", font_size=13, bold=True)
set_cell_text(table.rows[1].cells[1], "KIR0041", font_size=13, bold=True)
set_cell_text(table.rows[2].cells[1], "[Doplnit jméno cvičícího]", font_size=12, bold=False)

# Odstraníme přebytečné prázdné odstavce mezi tabulkou a Ostrava na Page 1
p_ostrava_idx = None
for i, p in enumerate(doc.paragraphs):
    if "Ostrava, AR" in p.text:
        p_ostrava_idx = i
        break

del_count = 0
for i in range(p_ostrava_idx - 1, 0, -1):
    p = doc.paragraphs[i]
    if p.text.strip() == "" and del_count < 7:
        p._element.getparent().remove(p._element)
        del_count += 1

# --- 2. Strana 2: Popis datového souboru a Obecné pokyny ---
p_pokyny_idx = None
for i, p in enumerate(doc.paragraphs):
    if "Obecné pokyny:" in p.text:
        p_pokyny_idx = i
        break

del_count2 = 0
for i in range(p_pokyny_idx - 1, 0, -1):
    p = doc.paragraphs[i]
    if p.text.strip() == "" and del_count2 < 11:
        p._element.getparent().remove(p._element)
        del_count2 += 1

# --- 3. Záhlaví pro sekce 1 a 2 ---
for s in doc.sections[1:]:
    hp = s.header.paragraphs[0]
    hp.text = ''
    r1 = hp.add_run('Jméno: Tomáš Kirnig (KIR0041)')
    r1.font.name = 'Calibri'
    r1.font.size = Pt(9)
    r1.font.color.rgb = RGBColor(0x55, 0x55, 0x55)
    r_tab = hp.add_run('\t')
    r2 = hp.add_run('Domácí úkoly 1S – 3S (Příloha)')
    r2.font.name = 'Calibri'
    r2.font.size = Pt(9)
    r2.font.color.rgb = RGBColor(0x55, 0x55, 0x55)
    
    pPr = hp._element.get_or_add_pPr()
    for t in pPr.xpath('./w:tabs'):
        pPr.remove(t)
    new_tabs = parse_xml(f'<w:tabs {nsdecls("w")}><w:tab w:val="right" w:pos="9071"/></w:tabs>')
    pPr.append(new_tabs)

# --- 4. Příprava pro vložení obsahu Úkolu 1S ---
idx_u1s = None
idx_u3s = None
for i, p in enumerate(doc.paragraphs):
    if "Úkol 1S" in p.text:
        idx_u1s = i
    elif "Úkol 3S" in p.text:
        idx_u3s = i
        break

start_del = idx_u1s + 2
end_del = idx_u3s
for i in range(end_del - 1, start_del - 1, -1):
    p = doc.paragraphs[i]
    p._element.getparent().remove(p._element)

target_p = doc.paragraphs[start_del]

def insert_heading(text, level=2, page_break_before=False):
    p = target_p.insert_paragraph_before()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    if page_break_before:
        p.paragraph_format.page_break_before = True
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(12.5 if level==2 else 11.5)
    r.bold = True
    r.font.color.rgb = RGBColor(0x02, 0x4B, 0x7A)
    return p

def insert_image(img_path, caption_text, width=Cm(13.0), page_break_before=False):
    p_img = target_p.insert_paragraph_before()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(6)
    p_img.paragraph_format.space_after = Pt(2)
    p_img.paragraph_format.keep_with_next = True
    if page_break_before:
        p_img.paragraph_format.page_break_before = True
    run_img = p_img.add_run()
    run_img.add_picture(img_path, width=width)
    
    p_cap = target_p.insert_paragraph_before()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(2)
    p_cap.paragraph_format.space_after = Pt(6)
    p_cap.paragraph_format.keep_with_next = True
    run_cap = p_cap.add_run(caption_text)
    run_cap.font.name = "Calibri"
    run_cap.font.size = Pt(9.5)
    run_cap.bold = True
    run_cap.font.color.rgb = RGBColor(0x33, 0x33, 0x33)

def insert_comment(text, space_after=8):
    p = target_p.insert_paragraph_before()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(10)

# Úvod
insert_heading("1. Cíl analýzy a párové uspořádání dat")
insert_comment(
    "Cílem explorační analýzy je vyhodnotit vliv aktualizace hry Cyberpunk 2077 (patch 1.5) na výkonnostní skóre "
    "dvou grafických karet: Nvidia RTX 3070 Ti a AMD Radeon RX 6800 XT. Pro každou unikátní PC sestavu (id 1 až 73) "
    "byly zaznamenány hodnoty FPS před patchem (release) a po aplikaci patche (patched). Zkoumanou veličinou je párový "
    "rozdíl ΔFPS = FPS_patched − FPS_release, který eliminuje vliv nestejného hardwaru sestav (procesor, RAM, chlazení) "
    "a izoluje čistý přínos aktualizace."
)

# 2. Boxploty
insert_heading("2. Vícenásobné krabicové grafy a analýza odlehlých pozorování")
insert_image(
    os.path.join(img_dir, "obr1_boxplot_puvodni.png"),
    "Obr. 1: Vícenásobný krabicový graf nárůstu FPS pro původní data (červené křížky znázorňují aritmetické průměry)",
    width=Cm(12.8)
)
insert_comment(
    "Komentář k Obr. 1: Červené křížky v krabicových grafech znázorňují polohu výběrových aritmetických průměrů. "
    "V původních datech se projevují výrazná odlehlá pozorování: u karty Nvidia RTX 3070 Ti záporný propad −5,50 FPS "
    "(systém id = 38; chyba konfigurace systému), u AMD Radeon RX 6800 XT extrémní zisk +13,10 FPS (id = 7) a mírně "
    "odlehlá hodnota +7,50 FPS (id = 15). Vlivem těchto bodů je svislá osa Y roztažena na [−6, 14] FPS a krabice (IQR) jsou silně stlačeny."
)

insert_image(
    os.path.join(img_dir, "obr2_boxplot_ocisteny.png"),
    "Obr. 2: Vícenásobný krabicový graf nárůstu FPS (po odstranění odlehlých pozorování)",
    width=Cm(12.8)
)
insert_comment(
    "Komentář k Obr. 2 a zdůvodnění zařazení: K identifikaci anomálií bylo použito pravidlo Tukeyho vnitřních hradeb "
    "[Q1 − 1,5·IQR, Q3 + 1,5·IQR]. Po jejich vyřazení se rozsah svislé osy Y zúžil na cca [3, 7] FPS (přibližně 5násobné "
    "zvětšení detailu). Odstranění odlehlých pozorování vedlo k významné změně vzhledu původního grafu, zařazení Obr. 2 "
    "je proto v souladu se zadáním plně opodstatněné. Medián nárůstu výkonu činí 5,20 FPS u Nvidia RTX 3070 Ti a 4,70 FPS "
    "u AMD Radeon RX 6800 XT. Variabilita měřená mezikvartilovým rozpětím je nízká (IQR = 0,80 FPS resp. 0,90 FPS)."
)

# 3. Normalita: Histogramy a QQ grafy
insert_heading("3. Vizuální posouzení normality (Histogramy a Q-Q grafy)", page_break_before=True)
insert_comment(
    "Posouzení normality očištěných dat je založeno na statistické triádě CV6: posouzení tvaru histogramu "
    "s jádrovým a normálním odhadem hustoty, průběhu kvantilů v Q-Q grafu a vyhodnocení výběrové šikmosti a špičatosti."
)

insert_image(
    os.path.join(img_dir, "obr3_hist_rtx.png"),
    "Obr. 3: Histogram nárůstu FPS pro Nvidia RTX 3070 Ti (po odstranění odlehlých pozorování)",
    width=Cm(12.5)
)
insert_image(
    os.path.join(img_dir, "obr4_hist_rx.png"),
    "Obr. 4: Histogram nárůstu FPS pro AMD Radeon RX 6800 XT (po odstranění odlehlých pozorování)",
    width=Cm(12.5)
)
insert_image(
    os.path.join(img_dir, "obr5_qq_rtx.png"),
    "Obr. 5: Q-Q graf nárůstu FPS pro Nvidia RTX 3070 Ti (po odstranění odlehlých pozorování)",
    width=Cm(12.5),
    page_break_before=True
)
insert_image(
    os.path.join(img_dir, "obr6_qq_rx.png"),
    "Obr. 6: Q-Q graf nárůstu FPS pro AMD Radeon RX 6800 XT (po odstranění odlehlých pozorování)",
    width=Cm(12.5)
)
insert_comment(
    "Komentář k histogramům a Q-Q grafům: Histogramy (Obr. 3 a 4) vykazují symetrický zvonovitý tvar s jedním vrcholem; "
    "jádrový odhad hustoty (červená plná čára) dobře odpovídá teoretickému normálnímu rozdělení N(x̄, s²) (modrá čárkovaná čára). "
    "V Q-Q grafech (Obr. 5 a 6) leží body výběrových kvantilů těsně podél červené referenční přímky normality bez systematického "
    "vybočení v koncových oblastech. Grafické výstupy neodporují předpokladu normálního rozdělení a v kombinaci s výběrovou šikmostí "
    "a špičatostí v mezích (−2, 2) lze rozdělení výběrových dat považovat za přibližně normální."
)

# 4. Tabulka statistik
insert_heading("4. Souhrnná tabulka popisných statistik", page_break_before=True)
insert_comment(
    "Poznámka ke konvenci zaokrouhlování: Směrodatná odchylka je zaokrouhlena nahoru (funkcí ceiling) na 3 platné číslice "
    "dle metodiky kurzu VŠB-TUO pro rozsah n ∈ [31, 2000]. Míry polohy jsou uvedeny na stejné desetinné místo jako směrodatná odchylka."
)

stats_data = [
    ["Grafická karta", "Soubor dat", "n", "Průměr", "Sm. odch.*", "Medián", "IQR", "Min", "Max", "Šikmost", "Špičatost"],
    ["Nvidia RTX 3070 Ti", "Původní data", "70", "5,130", "1,420", "5,200", "0,800", "−5,500", "6,600", "−6,094", "43,650"],
    ["Nvidia RTX 3070 Ti", "Bez odlehlých poz.", "69", "5,284", "0,594", "5,200", "0,800", "3,900", "6,600", "0,131", "−0,220"],
    ["AMD Radeon RX 6800 XT", "Původní data", "73", "4,901", "1,220", "4,700", "0,900", "3,200", "13,100", "4,335", "26,546"],
    ["AMD Radeon RX 6800 XT", "Bez odlehlých poz.", "71", "4,749", "0,666", "4,700", "0,900", "3,200", "6,400", "0,223", "−0,182"]
]

tbl_elm = OxmlElement('w:tbl')
tblPr = OxmlElement('w:tblPr')
tblPr.append(parse_xml(f'<w:jc {nsdecls("w")} w:val="center"/>'))
tblPr.append(parse_xml(f'''
    <w:tblBorders {nsdecls("w")}>
        <w:top w:val="single" w:sz="6" w:space="0" w:color="024B7A"/>
        <w:bottom w:val="single" w:sz="8" w:space="0" w:color="024B7A"/>
        <w:left w:val="none"/>
        <w:right w:val="none"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="D0D7DE"/>
        <w:insideV w:val="none"/>
    </w:tblBorders>
'''))
tbl_elm.append(tblPr)

col_widths = [1600, 1400, 450, 750, 800, 750, 650, 750, 750, 700, 700]
tblGrid = OxmlElement('w:tblGrid')
for w in col_widths:
    gridCol = OxmlElement('w:gridCol')
    gridCol.set(qn('w:w'), str(w))
    tblGrid.append(gridCol)
tbl_elm.append(tblGrid)

for r_idx, row_vals in enumerate(stats_data):
    tr = OxmlElement('w:tr')
    trPr = OxmlElement('w:trPr')
    if r_idx == 0:
        trPr.append(OxmlElement('w:tblHeader'))
    trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
    tr.append(trPr)
    
    for c_idx, val in enumerate(row_vals):
        tc = OxmlElement('w:tc')
        tcPr = OxmlElement('w:tcPr')
        tcW = OxmlElement('w:tcW')
        tcW.set(qn('w:w'), str(col_widths[c_idx]))
        tcW.set(qn('w:type'), 'dxa')
        tcPr.append(tcW)
        
        tcMar = parse_xml(f'''
            <w:tcMar {nsdecls("w")}>
                <w:top w:w="80" w:type="dxa"/>
                <w:bottom w:w="80" w:type="dxa"/>
                <w:left w:w="90" w:type="dxa"/>
                <w:right w:w="90" w:type="dxa"/>
            </w:tcMar>
        ''')
        tcPr.append(tcMar)
        
        if r_idx == 0:
            tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="024B7A"/>'))
        elif r_idx in [2, 4]:
            tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="F0F4F8"/>'))
            
        tc.append(tcPr)
        
        p = OxmlElement('w:p')
        pPr = OxmlElement('w:pPr')
        align = "left" if c_idx < 2 else "center"
        pPr.append(parse_xml(f'<w:jc {nsdecls("w")} w:val="{align}"/>'))
        pPr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="0" w:after="0" w:line="220" w:lineRule="auto"/>'))
        p.append(pPr)
        
        r = OxmlElement('w:r')
        rPr = OxmlElement('w:rPr')
        rPr.append(parse_xml(f'<w:rFonts {nsdecls("w")} w:ascii="Calibri" w:hAnsi="Calibri"/>'))
        sz = "17" if r_idx == 0 else "18"
        rPr.append(parse_xml(f'<w:sz {nsdecls("w")} w:val="{sz}"/>'))
        rPr.append(parse_xml(f'<w:szCs {nsdecls("w")} w:val="{sz}"/>'))
        
        if r_idx == 0:
            rPr.append(OxmlElement('w:b'))
            rPr.append(parse_xml(f'<w:color {nsdecls("w")} w:val="FFFFFF"/>'))
        elif r_idx in [2, 4] and c_idx >= 2:
            rPr.append(OxmlElement('w:b'))
            
        r.append(rPr)
        t = OxmlElement('w:t')
        t.text = val
        r.append(t)
        p.append(r)
        tc.append(p)
        tr.append(tc)
    tbl_elm.append(tr)

target_p._element.addprevious(tbl_elm)

# 5. Závěrečné vyhodnocení
insert_heading("5. Závěrečné vyhodnocení")

insert_comment(
    "A. Posouzení normality (Statistická triáda):\n"
    "• Původní data: Vlivem anomálií měření (propad −5,50 FPS u Nvidia a skok +13,10 FPS u AMD) byla data silně asymetrická "
    "a vykazovala těžké chvosty. Výběrová šikmost i špičatost ležely hluboko mimo toleranční pásmo (šikmost dosahovala −6,094 resp. +4,335; "
    "špičatost 43,650 resp. 26,546). Původní data tedy normalitu hrubě nesplňovala.\n"
    "• Očištěná data: Po odstranění odlehlých pozorování leží výběrová šikmost i špičatost u obou karet uvnitř tolerančního intervalu (−2, 2):\n"
    "   - Nvidia RTX 3070 Ti: šikmost = 0,131; špičatost = −0,220\n"
    "   - AMD Radeon RX 6800 XT: šikmost = 0,223; špičatost = −0,182\n"
    "Společně se symetrickými zvonovitými histogramy a těsným přimknutím bodů k přímce v Q-Q grafech lze konstatovat, "
    "že očištěná data neodporují předpokladu normálního rozdělení a splňují podmínky pro následné parametrické testování."
)

insert_comment(
    "B. Věcné zhodnocení nárůstu výkonu ve hře Cyberpunk 2077 (patch 1.5):\n"
    "1. Pozitivní nárůst ve výběrovém souboru: Aktualizace hry na patch 1.5 přinesla u všech platných měření v datech zvýšení FPS "
    "(všechny očištěné hodnoty leží v kladném rozmezí +3,2 až +6,6 FPS). Explorační analýza tedy naznačuje nárůst výkonu; pro rigorózní "
    "ověření statistické významnosti tohoto přínosu je nutné provést testování statistických hypotéz (párový t-test v rámci úkolu 2S).\n"
    "2. Srovnání nárůstu: Grafická karta Nvidia RTX 3070 Ti dosáhla průměrného nárůstu 5,284 FPS (medián 5,200 FPS, rozsah 3,9 až 6,6 FPS, "
    "směrodatná odchylka zaokrouhlená nahoru s = 0,594 FPS), zatímco AMD Radeon RX 6800 XT dosáhla průměrného nárůstu 4,749 FPS "
    "(medián 4,700 FPS, rozsah 3,2 až 6,4 FPS, s = 0,666 FPS). Nvidia RTX 3070 Ti zaznamenala ve výběru v průměru o +0,535 FPS vyšší nárůst "
    "než konkurenční AMD.\n"
    "3. Stabilita přínosu: Nízká výběrová směrodatná odchylka i mezikvartilové rozpětí (IQR = 0,800 FPS pro RTX 3070 Ti a 0,900 FPS pro RX 6800 XT) "
    "dokládají, že nárůst výkonu byl napříč testovanými konfiguracemi vysoce konzistentní a stabilní."
)

# Stránkový zlom před Úkolem 3S
target_p.paragraph_format.page_break_before = True

doc.save(dst_docx)
print("Docx uložen.")
