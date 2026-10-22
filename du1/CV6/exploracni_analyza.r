# Generováno z CV6/exploracni_analyza.ipynb. Upravujte zdrojový notebook.


# # Cvičení 6 — Příprava dat a explorační analýza
#
# Michal Béreš, Adéla Vrtková, Martina Litschmannová
#
# Na datech světelného toku žárovek procvičíme import, uspořádání tabulky, dplyr, popisné
# charakteristiky a jednoduché grafy. Rozlišíme popis dat od závěrů o populaci.

# ## Balíčky a pracovní adresář
#
# V připraveném kontejneru jsou balíčky již nainstalované. V novém kernelu je pouze načteme. Pro
# jednotlivou funkci z jiného balíčku použijeme zápis `balicek::funkce`.

# Bílé pozadí grafů zajišťuje čitelnost i v tmavém motivu editoru.
pdf.options(bg = "white")
par(bg = "white")

set.seed(123)
library(dplyr)

# `dplyr` může maskovat stejnojmenné funkce jiných balíčků. Například `dplyr::filter()` výslovně
# vybírá řádky datové tabulky.

# Notebook spouštíme s pracovním adresářem v jeho složce `CV6`. Data načítáme relativní cestou z
# `data/`; v průběhu analýzy pracovní adresář neměníme.

# ### Cesty k souborům
#
# Funkce `getwd()` vypíše pracovní adresář. `file.path()` skládá cestu a `file.exists()` ověří její
# existenci.

# Výpis pracovního adresáře
getwd()

cesta_dat <- file.path("data", "zarovky.csv")
file.exists(cesta_dat)

list.files("data")

# V případě chybné cesty nejprve zkontrolujeme pracovní adresář a názvy souborů. Nepoužíváme osobní
# absolutní cesty, aby notebook fungoval i v Codespaces.

stopifnot(file.exists(cesta_dat))

# ## Načítání dat
#
# Po importu zkontrolujeme názvy sloupců, typy a prvních několik řádků pomocí `names()`, `str()` a
# `head()`.

# ### a) Ze souboru CSV
# Základní funkce - `read.table`, `read.csv`, `read.csv2`, ...
#
# Záleží hlavně na formátu souboru (.txt, .csv), na tzv. oddělovači jednotlivých hodnot, desetinné
# čárce/tečce, ...

data <- read.csv2("data/zarovky.csv")
head(data)

str(data)
names(data)

# U textového souboru volíme oddělovač a desetinný znak podle skutečného formátu. `read.csv2()`
# standardně očekává středník a desetinnou čárku, `read.csv()` čárku a desetinnou tečku.

# ### Import z Excelu
#
# `readxl::read_excel()` čte soubor XLSX. Zadáme list a případný počet úvodních řádků k přeskočení.
# Balíček `readxl` soubory nezapisuje; export si ukážeme pomocí `openxlsx`.

# při načítání dat z Excelu si sice nemusíme dělat starosti s oddělovači a formátem čísel
# musíme však specifikovat který list chceme načíst a případně kolik řádků od začátku chceme
# přeskočit
data <- readxl::read_excel("./data/zarovky.xlsx", sheet = "Data", skip = 3)
head(data)

# ### c) Odstranění nepotřebných sloupců a jejich přejmenování pro snadnější adresování dat

# indexování se zápornými indexy vrátí vše kromě hodnoty indexů
# nelze míchat záporné a kladné indexy!
data <- data[, -1] # odstraníme první sloupec s indexy
head(data)

# Přejmenování sloupců (obecně diakritika a mezery v názvech sloupců komplikují práci)
colnames(data) <- c("A5", "B5", "C5", "D5", "A22", "B22", "C22", "D22")
head(data)

# `readxl` vrací tabulku typu `tibble` bez ohledu na editor. Je to rozšíření `data.frame`. Pokud
# některá základní funkce vyžaduje běžný datový rámec, použijeme `as.data.frame()`. Číselný sloupec
# získáme například jako `data$A5`.

# ## Uspořádání dat
#
# Každý sloupec představuje proměnnou a každý řádek zvolenou jednotku pozorování. Například jeden
# řádek může obsahovat jednu žárovku, jejího výrobce a tok při dvou teplotách. Dlouhý formát může
# mít také jeden řádek pro každé měření téže žárovky; pak obsahuje identifikátor žárovky a teplotu.
# Formát volíme podle analýzy a zachováme vazbu párových měření.
#
# ### Jediné měření v široké tabulce
#
# Funkce `stack()` spojí sloupce do dvojice hodnota–skupina. Pro složitější převody lze použít
# `tidyr::pivot_longer()`; zde nejprve použijeme jednoduchý základní R.

# ### a) Základní převod jednoduché datové matice do standardního datového formátu - `stack(...)`

data_tok5_siroka <- data[, 1:4] # z dat vybereme ty sloupce, které odpovídají měřením po 5 cyklech
colnames(data_tok5_siroka) <- c("Amber", "Bright", "Clear", "Dim") # přejmenujeme sloupce
head(data_tok5_siroka)

data_tok5 <- stack(data_tok5_siroka) # a převedeme do st. datového formátu
head(data_tok5)

# přejmenujeme sloupce
colnames(data_tok5) <- c("tok5", "vyrobce")

# a přidáme sloupec id
data_tok5$id <- seq_along(data_tok5$tok5)

head(data_tok5)

# ### Dvě párová měření: `reshape()`

data_siroka <- readxl::read_excel("./data/datova_matice.xlsx")
head(data_siroka)

# smažeme první sloupec
data_siroka <- data_siroka[, -1]
# přejmenujeme sloupce
colnames(data_siroka) <- c("A22", "A5", "B22", "B5", "C22", "C5", "D22", "D5")
head(data_siroka)

# `reshape()` zde převádí širokou tabulku na dlouhou. `varying` spojuje odpovídající sloupce,
# `v.names` pojmenovává měřené proměnné, `times` označuje výrobce a `timevar` jméno jeho sloupce.
# Pořadí výrobců musí odpovídat pořadí sloupců. Identifikátor původního řádku sám nemusí být
# jednoznačný pro všechny žárovky.

data_dlouha <- reshape(
  data = as.data.frame(data_siroka),
  direction = "long",
  varying = list(
    c("A5", "B5", "C5", "D5"),
    c("A22", "B22", "C22", "D22")
  ),
  v.names = c("tok5", "tok22"),
  times = c("Amber", "Bright", "Clear", "Dim"),
  timevar = "vyrobce"
)
head(data_dlouha)

# ### Data na více listech Excelu
#
# Pro názornost načteme každý list zvlášť, doplníme výrobce a spojíme tabulky pomocí `bind_rows()`.
# Stejné operace lze později zapsat cyklem; zde není potřeba.

# načteme všechny listy do separátních proměnných
data_a <- readxl::read_excel("./data/po_listech.xlsx", sheet = 1)
head(data_a)
data_b <- readxl::read_excel("./data/po_listech.xlsx", sheet = 2)
data_c <- readxl::read_excel("./data/po_listech.xlsx", sheet = 3)
data_d <- readxl::read_excel("./data/po_listech.xlsx", sheet = 4)

# přidáme sloupec s výrobcem
data_a$vyrobce <- "Amber"
data_b$vyrobce <- "Bright"
data_c$vyrobce <- "Clear"
data_d$vyrobce <- "Dim"
head(data_a)

data_po_listech <- bind_rows(data_a, data_b, data_c, data_d)
data_po_listech <- data_po_listech[, -1]
tail(data_po_listech)

# přejmenujeme sloupce
colnames(data_po_listech) <- c("tok5", "tok22", "vyrobce")
# přidáme sloupec s id
data_po_listech$id <- seq_along(data_po_listech$tok5)
head(data_po_listech)

# ## Základní operace dplyr

# | Operace | Význam |
# | --- | --- |
# | `select()` | Vybere sloupce. |
# | `filter()` | Vybere řádky podle podmínky. |
# | `mutate()` | Vytvoří nebo upraví sloupec. |
# | `summarise()` | Spočítá souhrnné charakteristiky. |
# | `group_by()` | Určí skupiny pro následující operace. |
# | `arrange()` | Seřadí řádky. |
#
# Operátor `%>%` předává výsledek vlevo jako první argument funkci vpravo. Příkazy čteme shora dolů.
# Například `data %>% select(A5)` vybere sloupec A5. Podmínky oddělené čárkou ve `filter()`
# znamenají „a zároveň“, znak `|` znamená „nebo“.

# ### b) Výběry sloupců

# budeme pracovat s daty, které jsme připravili
head(data)

# pomocí funkce select balíčku dplyr, která vybere zvolené sloupce
vysledek <- data %>% select(C5)
head(vysledek)

# Uložení prvního a pátého sloupce dat. rámce data do dat. rámce pokus
pokus <- data %>% select(1, 5)
head(pokus)

# nebo pomocí názvů sloupců
pokus <- data %>% select(A5, A22)
head(pokus)

# ### c) Vylučování dat ze souboru (pomocí záporných indexů)

# nebo pomocí dplyr
pokus <- data %>% select(-1, -5)
head(pokus)

# nebo pomocí názvů
pokus <- data %>% select(-A5, -A22)
head(pokus)

# ### d) Práce s daty ve standardním datovém formátu

# budeme používat dříve vyrobený datový rámec data_dlouha
head(data_dlouha)

# #### Definování nových sloupců (`mutate`)

# vytvoříme nový sloupec pokles, který bude obsahovat rozdíl mezi hodnotami tok22 a tok5
data_dlouha <- data_dlouha %>% mutate(pokles = tok22 - tok5)
head(data_dlouha)

# pozor! pokud výsledek s nový sloupcem nikam neuložíme, tak se pouze vypíše a zmizí

# #### Vybírání řádků a sloupců (`filter` a `select`)

# filter - vybere / vyfiltruje řádky na základě daných podmínek
# Výběr výrobků od výrobce Amber
vysledek <- data_dlouha %>% filter(vyrobce == "Amber")
tail(vysledek)

# Výběr výrobků od výrobce Amber nebo Bright
# | oddělující podmínky odpovídá logickému "nebo"
vysledek <- data_dlouha %>% filter(vyrobce == "Amber" | vyrobce == "Bright")
tail(vysledek)

# Výběr všech výrobků s poklesem o 5 Lumenů a větším od výrobce Clear
# čárka oddělující podmínky odpovídá logickému "a zároveň"
vysledek <- data_dlouha %>% filter(pokles >= 5, vyrobce == "Clear")
vysledek

# chceme-li světelný tok při 5°C výrobce Amber
# nejprve vyfiltrujeme řádky pro Amber a pak vybereme sloupec tok5
tok_amber <- data_dlouha %>%
  filter(vyrobce == "Amber") %>%
  select(tok5)
head(tok_amber)

# #### generování souhrnných charakteristik (`summarise`)
# Sílu tohoto nástroje oceníme zejména v kombinaci s group_by.

data_dlouha %>% summarise(prumer = mean(tok5, na.rm = TRUE), median = median(tok5, na.rm = TRUE))

# #### seskupení hodnot do skupin podle zvolené proměnné (`group_by`)
# - Výsledkem je tzv. `grouped_df` (tibble), který obsahuje informace o seskupení.
# - Jedná se zejména o mezioperace, které nám umožní provádět další operace nad seskupenými daty.

# tabulka je "virtuálně" rozdělená na skupiny pro pozdější zpracování např. summarise
vysledek <- data_dlouha %>% group_by(vyrobce)
head(vysledek)

data_dlouha %>%
  group_by(vyrobce) %>%
  summarise(
    prumer = mean(tok5, na.rm = TRUE),
    smerodatna_odchylka = sd(tok5, na.rm = TRUE)
  )

# #### setřízení dat (`arrange`)

# Vzestupné a sestupné seřazení řádků podle hodnoty poklesu
vysledek <- data_dlouha %>% arrange(pokles)

head(vysledek)
tail(vysledek)

# případně sestupně
vysledek <- data_dlouha %>% arrange(desc(pokles))
head(vysledek)
tail(vysledek)

# ## Explorační analýza a vizualizace kategoriální proměnné

# ### a) Absolutní a relativní četnosti kategoriální proměnné
# - **`table()`** – vytvoří tabulku absolutních četností kategoriální proměnné ze sloupce datového
# rámce podle unikátních hodnot.
# - lze i pomocí knihovny `dplyr`:
#     - ```r
#       data %>% count(vyrobce)
#       ```
#       nebo
#     - ```r
#       data %>% group_by(vyrobce) %>% summarise(n = n())
#       ```

# Tabulka absolutních četností kategoriální proměnné výrobce...
cetnosti <- table(data_dlouha$vyrobce)
cetnosti # výpis - objekt typu "table" - většinou vhodnější, ale těžší převedení do typu data.frame

# **Tabulka relativních četností pomocí `prop.table()`**

relativni_cetnosti <- prop.table(cetnosti)
relativni_cetnosti # výpis

# U tabulek relativních četností je potřeba pohlídat zaokrouhlení a s ním spojené riziko
# zaokrouhlovací chyby.

round(relativni_cetnosti, 3)
# Zaokrouhlujeme pouze výpis; jednotlivé četnosti uměle nedorovnáváme.

# ### b) Vizualizace pomocí sloupcového grafu

# Sloupcový graf
barplot(cetnosti)

# lze i pro relativní četnosti, také má funkce mnoho dalších parametrů
barplot(relativni_cetnosti,
  # alt. může být volen vektor konkrétních barev, např. c("blue","yellow,"red","green")
  col = heat.colors(4),
  # nebo jiné škály (heat.colors, topo.colors, terrain.colors a mnoho dalších)
  main = "Zastoupení výrobců ve výběru", # nadpis grafu
  space = 0.5, # parametr space vytvoří mezeru mezi sloupci
  xlab = "Výrobce", # popisek osy x
  ylab = "Relativní četnost" # popisek osy y
)

# ### Export výsledků
#
# Vytvoříme složku `vystupy/`, která obsahuje pouze regenerovatelné výstupy. Zdrojová data
# nepřepisujeme.

dir.create("vystupy", showWarnings = FALSE)
png("vystupy/sloupcovy_graf.png")
barplot(relativni_cetnosti, xlab = "Výrobce", ylab = "Relativní četnost")
dev.off()

# **A v podobě PDF:**

pdf("vystupy/sloupcovy_graf.pdf", encoding = "ISOLatin2")
barplot(relativni_cetnosti, xlab = "Výrobce", ylab = "Relativní četnost")
dev.off()

# ## Explorační analýza a vizualizace kvantitativní proměnné

# ### a) Základní deskriptivní statistiky kvantitativní proměnné
# - **průměr** pomocí `mean()` (pozor na chybějící hodnoty, dají se ignorovat pomocí `na.rm = TRUE`)
# - **medián** pomocí `median()`
# - **rozptyl** pomocí `var()`
# - **směrodatná odchylka** pomocí `sd()`
# - **kvantily** pomocí `quantile()` (např. `quantile(data$tok5, c(0.25, 0.75))`)
# - **velikost výběru** pomocí `length()`
# - **variační koeficient** pomocí `sd()/mean()*100`
# - **interkvartilové rozpětí** pomocí `IQR()`
# - **vnitřní hradby** pomocí `quantile() +/- 1.5*IQR()`
# - **šikmost** pomocí `moments::skewness()`
# - **špičatost** pomocí `moments::kurtosis() - 3` (Pozor na normalizaci!)
#
#
# **pozor na chybějící hodnoty, dají se ignorovat pomocí `na.rm = TRUE`**
#
# Variační koeficient dává smysl pro poměrovou veličinu s kladnou střední hodnotou; není
# univerzálním měřítkem variability. Špičatost zde uvádíme jako exces, tedy oproti hodnotě 3 u
# normálního rozdělení.

# výpočty popisné statistiky pro proměnnou tok5 (pro všechny výrobce)
mean(data_dlouha$tok5, na.rm = TRUE) # průměr
median(data_dlouha$tok5, na.rm = TRUE) # medián
var(data_dlouha$tok5, na.rm = TRUE) # rozptyl
sd(data_dlouha$tok5, na.rm = TRUE) # směrodatná odchylka
quantile(data_dlouha$tok5, probs = c(0.25, 0.75), na.rm = TRUE) # kvartily
length(data_dlouha$tok5) # počet hodnot (pozor jsou včetně NA)
length(data_dlouha$tok5[!is.na(data_dlouha$tok5)]) # počet hodnot bez NA
# variační koeficient
sd(data_dlouha$tok5, na.rm = TRUE) / mean(data_dlouha$tok5, na.rm = TRUE) * 100
IQR(data_dlouha$tok5, na.rm = TRUE) # interkvartilové rozpětí
# dolní mez vnitřních hradeb
quantile(data_dlouha$tok5, 0.25, na.rm = TRUE) - 1.5 * IQR(data_dlouha$tok5, na.rm = TRUE)
# horní mez vnitřních hradeb
quantile(data_dlouha$tok5, 0.75, na.rm = TRUE) + 1.5 * IQR(data_dlouha$tok5, na.rm = TRUE)
moments::skewness(data_dlouha$tok5, na.rm = TRUE) # šikmost
moments::kurtosis(data_dlouha$tok5, na.rm = TRUE) - 3 # špičatost

# **Totéž lze udělat pomocí knihovny `dplyr`**

tabulka_statistik <- data_dlouha %>% summarise(
  prumer = mean(tok5, na.rm = TRUE),
  median = median(tok5, na.rm = TRUE),
  rozptyl = var(tok5, na.rm = TRUE),
  smerodatna_odchylka = sd(tok5, na.rm = TRUE),
  dolni_kvartil = quantile(tok5, 0.25, na.rm = TRUE),
  horni_kvartil = quantile(tok5, 0.75, na.rm = TRUE),
  pocet_radku = n(),
  pocet_hodnot = sum(!is.na(tok5)),
  variacni_koeficient = sd(tok5, na.rm = TRUE) / mean(tok5, na.rm = TRUE) * 100,
  interkvartilove_rozpeti = IQR(tok5, na.rm = TRUE),
  dolni_hradba = quantile(tok5, 0.25, na.rm = TRUE) - 1.5 * IQR(tok5, na.rm = TRUE),
  horni_hradba = quantile(tok5, 0.75, na.rm = TRUE) + 1.5 * IQR(tok5, na.rm = TRUE),
  skewness = moments::skewness(tok5, na.rm = TRUE),
  kurtosis = moments::kurtosis(tok5, na.rm = TRUE) - 3
)
t(tabulka_statistik) # transpozice tabulky pro lepší čitelnost

# **A finálně pro každou skupinu zvlášť skrze `group_by`**

tabulka_statistik <- data_dlouha %>%
  group_by(vyrobce) %>%
  summarise(
    prumer = mean(tok5, na.rm = TRUE),
    median = median(tok5, na.rm = TRUE),
    rozptyl = var(tok5, na.rm = TRUE),
    smerodatna_odchylka = sd(tok5, na.rm = TRUE),
    dolni_kvartil = quantile(tok5, 0.25, na.rm = TRUE),
    horni_kvartil = quantile(tok5, 0.75, na.rm = TRUE),
    pocet_radku = n(),
    pocet_hodnot = sum(!is.na(tok5)),
    variacni_koeficient = sd(tok5, na.rm = TRUE) / mean(tok5, na.rm = TRUE) * 100,
    interkvartilove_rozpeti = IQR(tok5, na.rm = TRUE),
    dolni_hradba = quantile(tok5, 0.25, na.rm = TRUE) - 1.5 * IQR(tok5, na.rm = TRUE),
    horni_hradba = quantile(tok5, 0.75, na.rm = TRUE) + 1.5 * IQR(tok5, na.rm = TRUE),
    skewness = moments::skewness(tok5, na.rm = TRUE),
    kurtosis = moments::kurtosis(tok5, na.rm = TRUE) - 3
  )
t(tabulka_statistik) # transpozice tabulky pro lepší čitelnost

# ### Stručná tabulka pomocí rstatix
#
# Pro běžné souhrny nemusíme psát vlastní obecnou funkci. `get_summary_stats()` vypočítá několik
# charakteristik v každé skupině.

tabulka_statistik <- data_dlouha %>%
  group_by(vyrobce) %>%
  rstatix::get_summary_stats(tok5, type = "common")
tabulka_statistik

# **Může se hodit si takovou tabulku uložit do excelu pomocí `openxlsx::write.xlsx()`:**

openxlsx::write.xlsx(tabulka_statistik, "vystupy/tabulka_statistik.xlsx", rowNames = FALSE)

# ### Krabicový graf
#
# Čára uvnitř krabice označuje medián, okraje krabice dolní a horní kvartil (v základním `boxplot()`
# přesněji Tukeyho závěsy). Vousy sahají k nejvzdálenějším pozorováním do vzdálenosti 1,5 násobku
# interkvartilového rozpětí od krabice. Vzdálenější hodnoty se kreslí jednotlivě. U malých souborů
# se závěsy mohou lišit od výchozích kvantilů `quantile()`.
#
# Začneme grafem všech původních dat. Odlehlý bod je podnět ke kontrole, nikoli automaticky chyba.

# Jednoduché a rychlé vykreslení pomocí základní funkce pro jeden vektor
boxplot(data_dlouha$tok5)

# #### Vždy když budeme uvádět více boxplotů pro srovnatelná data (například různé skupiny), je
# ***nutné*** je vykreslit v jednom grafu
# - vícenásobný boxplot se jednoduše vykreslí pro data ve standardním datovém formátu
# - syntaxe je pomocí `~`: `boxplot(hodnoty ~ trizeni, data = data)`

# vykreslení vícenásobného krabicového grafu
boxplot(tok5 ~ vyrobce, data_dlouha)

# Při vytváření grafu pro publikace je nutné dodržet určité standardy úpravy

boxplot(tok5 ~ vyrobce, data_dlouha,
  xlab = "Výrobce", # popisek osy x
  ylab = "Světelný tok [lm]", # popisek osy y
  # nadpis grafu (vynechat pokud je součástí textu)
  main = "Světelný tok při 5°C v závislosti na výrobci"
)
grid() # přidání mřížky do grafu pro snadnější porovnání hodnot

# **Samozřejmě můžeme uložit stejným způsobem jako u předchozího sloupcového grafu.**

png("vystupy/boxplot.png", width = 800, height = 500) # název souboru a velikost grafu v pixelech
boxplot(tok5 ~ vyrobce, data_dlouha, xlab = "Výrobce", ylab = "Světelný tok [lm]")
grid()
dev.off() # ukončení zápisu a uložení na disk

# velikost (v palcích) a kódování
pdf("vystupy/boxplot.pdf", width = 8, height = 5, encoding = "ISOLatin2")
boxplot(tok5 ~ vyrobce, data_dlouha, xlab = "Výrobce", ylab = "Světelný tok [lm]")
grid()
dev.off() # ukončení zápisu a uložení na disk

# ### Odlehlá pozorování
#
# `rstatix::identify_outliers()` označí hodnoty mimo vnitřní hradby, tedy mimo interval od dolního
# kvartilu minus 1,5 IQR do horního kvartilu plus 1,5 IQR. U seskupených dat počítáme hradby uvnitř
# skupin.
#
# **Odlehlé hodnoty automaticky neodstraňujeme.** Mohou být platnou součástí populace. Nejprve
# ověříme záznam a kontext. Pro ilustraci citlivosti vytvoříme druhý sloupec, ve kterém označené
# hodnoty nahradíme `NA`, a porovnáme výsledky. Původní sloupec zachováme; vyřazení při skutečné
# analýze musí mít věcný důvod.

data_dlouha <- data_dlouha %>% mutate(id = row_number())

# pro srovnání vykreslíme oba grafy s i bez OP
boxplot(tok5 ~ vyrobce, data_dlouha)

# díky funkci identify_outliers z balíčku rstatix můžeme identifikovat odlehlé hodnoty
# dostaneme jejich seznam včetně náležitosti do skupin, id, ...
# toto se hodí pro jednoduchý reporting počtu OP a jejich identifikaci
odlehla_pozorovani <-
  data_dlouha %>%
  group_by(vyrobce) %>%
  rstatix::identify_outliers(tok5)
odlehla_pozorovani

data_dlouha <- data_dlouha %>%
  mutate(tok5_bez_odlehlych = ifelse(id %in% odlehla_pozorovani$id, NA, tok5))

boxplot(tok5_bez_odlehlych ~ vyrobce, data_dlouha)

data_dlouha %>%
  group_by(vyrobce) %>%
  rstatix::get_summary_stats(tok5, tok5_bez_odlehlych, type = "common")

# Porovnáme původní a upravená data a uvedeme počet označených hodnot. Opakované ořezávání nových
# odlehlých bodů po každém přepočtu hradeb by dále měnilo rozdělení; takový postup zde nepoužíváme.

# ### Histogram a odhad hustoty
#
# `hist()` zobrazuje rozložení číselných hodnot do intervalů. Argument `breaks` je požadavek na
# členění; při zadání jednoho čísla nemusí být výsledný počet intervalů přesně stejný. `freq =
# FALSE` škáluje plochu histogramu na jedničku.
#
# `density()` odhaduje hustotu přímo z dat, nikoli z histogramu. Před výpočtem vyřešíme chybějící
# hodnoty. Ukážeme původní data výrobce Amber; případné vyřazení nesmí sloužit k vynucení normality.

tok_amber <- data_dlouha %>%
  filter(vyrobce == "Amber") %>%
  pull(tok5)
tok_amber <- tok_amber[!is.na(tok_amber)]
hist(tok_amber)

# Lze si hrát s parametry, přidat do jednoho grafu i odhad hustoty pravděpodobnosti, a fit pomocí
# normálního rozdělení.

# Již tradičně lze nastavit popisky a další parametry
hist(tok_amber,
  main = "Histogram světelného toku při 5°C pro výrobce Amber",
  xlab = "Světelný tok [lm]",
  ylab = "Hustota pravděpodobnosti",
  freq = FALSE, # hustota: celková plocha je jedna
  breaks = 10 # počet intervalů
) # přidá absolutní četnosti daných kategorií ve formě popisků

lines(density(tok_amber), col = "red") # přidá odhad hustoty pravděpodobnosti

# generování hodnot pro osu x
osa_x <- seq(min(tok_amber), max(tok_amber), length = 100)
# generování hodnot pro osu y
normalni_hustota <- dnorm(osa_x, mean = mean(tok_amber), sd = sd(tok_amber))

# přidání křivky odhadu pomocí normálního rozdělení
lines(osa_x, normalni_hustota, col = "blue", lwd = 2)
# Takto kombinovaný graf může posloužit k vizuálnímu posouzení normality.

# A samozřejmě exportovat například do PDF.

pdf("vystupy/histogram.pdf", width = 8, height = 5, encoding = "ISOLatin2")
hist(tok_amber,
  freq = FALSE, breaks = 10,
  xlab = "Světelný tok [lm]", ylab = "Hustota pravděpodobnosti", main = ""
)
grid()
dev.off() # ukončení zápisu a uložení na disk

# ### Q–Q graf
#
# `qqnorm()` porovnává výběrové kvantily s teoretickými kvantily normálního rozdělení, `qqline()`
# doplní orientační přímku. Systematické odchylky mohou ukazovat na nesoulad s normálním modelem.
# Graf z konečného výběru normalitu neprokazuje.

# Nezapomenout na popisků os...
qqnorm(tok_amber,
  xlab = "Teoretické kvantily",
  ylab = "Výběrové kvantily",
  main = "QQ-graf, pro žárovky výrobce Amber při 5°C"
)
qqline(tok_amber)

# ## Posouzení normality
#
# Histogram a Q–Q graf společně poskytují orientační informaci o tvaru rozdělení. Výběrová šikmost a
# exces jsou další popisné charakteristiky. Jejich umístění v intervalu (−2, 2) **není testem ani
# zárukou normality**. Posuzujeme také velikost souboru, způsob sběru a případné směsi skupin.

# vyrobíme si data pro ukázku
data1 <- rnorm(100, mean = 1, sd = 1)
data2 <- runif(100, min = 0, max = 2)
data3 <- rexp(100, rate = 1)

# Stejný stručný postup použijeme na tři simulované soubory. Grafy i popisky zachováme jednoduché.

exploracni_overeni_normality <- function(data) {
  # výpočet popisných statistik
  sikmost <- moments::skewness(data)
  spicatost <- moments::kurtosis(data) - 3
  cat("Šikmost:", sikmost, "\n")
  cat("Špičatost:", spicatost, "\n")

  # QQ graf
  qqnorm(data)
  qqline(data)

  # histogram s odhadem hustoty pravděpodobnosti normálního rozdělení
  hist(data,
    freq = FALSE, breaks = 10,
    xlab = "Hodnota", ylab = "Hustota pravděpodobnosti", main = ""
  )
  osa_x <- seq(min(data), max(data), length = 100)
  normalni_hustota <- dnorm(osa_x, mean = mean(data), sd = sd(data))
  lines(osa_x, normalni_hustota, col = "blue", lwd = 2)
}

# jak to vypadá pro skutečná data z normálního rozdělení
exploracni_overeni_normality(data1)

# jak to vypadá pro skutečná data z uniformního rozdělení
exploracni_overeni_normality(data2)

# jak to vypadá pro skutečná data z exponenciálního rozdělení
exploracni_overeni_normality(data3)

# ### Pravidlo tří sigma a Čebyševova nerovnost
#
# Je-li $X\sim N(\mu,\sigma^2)$, pravděpodobnost uvnitř $\mu\pm k\sigma$ je pro $k=1,2,3$ přibližně
# 0,6827, 0,9545 a 0,9973.
#
# Pro libovolné rozdělení s konečnou střední hodnotou a konečným kladným rozptylem platí Čebyševova
# nerovnost
# $$P(|X-\mu|\geq k\sigma)\leq\frac{1}{k^2},\qquad k>0.$$
# Tedy $P(|X-\mu|<k\sigma)\geq1-1/k^2$. Pro $k=1,2,3$ dostáváme dolní meze 0, 0,75 a $8/9$. Nejde o
# rovnosti. Dosazení výběrového průměru a výběrové odchylky samo nezaručuje stejné pokrytí populace.

tok_amber <- data_dlouha %>%
  filter(vyrobce == "Amber") %>%
  pull(tok5)
tok_amber <- tok_amber[!is.na(tok_amber)]

# příslušné 1, 2 a 3 sigma intervaly
mu <- mean(tok_amber)
sigma <- sd(tok_amber)
cat("<", mu - sigma, ", ", mu + sigma, ">\n")
cat("<", mu - 2 * sigma, ", ", mu + 2 * sigma, ">\n")
cat("<", mu - 3 * sigma, ", ", mu + 3 * sigma, ">\n")

# ## Zaokrouhlování výsledků
#
# Výpočty provádíme s plnou přesností a zaokrouhlujeme až výstup. Uvedeme jednotky a rozumný počet
# platných číslic. Míry polohy obvykle zapisujeme na stejné desetinné místo jako směrodatnou
# odchylku, nikoli na stejný počet platných číslic.
#
# Pokud zadání vyžaduje původní kurzovou konvenci, zaokrouhlíme směrodatnou odchylku nahoru na jednu
# platnou číslici pro 2–10 hodnot, na dvě pro 11–30 a na tři pro 31–2 000 hodnot. To je formátovací
# konvence kurzu, nikoli obecná statistická věta. Následující data mají odchylku, u níž tři platné
# číslice odpovídají jednomu desetinnému místu.

# podíváme se na velikost souboru a směrodatnou odchylku
length(tok_amber)
smerodatna_odchylka <- sd(tok_amber)
smerodatna_odchylka

# na 3 platné cifry, tedy na jedno desetinné místo
ceiling(smerodatna_odchylka * 10) / 10

prumer <- mean(tok_amber)
prumer

round(prumer, digits = 1)

# ## Postup od importu k porovnání skupin
#
# Po každém importu ověříme rozměry tabulky, názvy a typy sloupců a několik řádků. Dvě reprezentace
# stejných dat porovnáváme až po sjednocení názvů, pořadí řádků, typů a jednotek; shodný počet řádků
# sám shodu dat nedokazuje. `all.equal()` slouží k numerické kontrole s tolerancí a jeho výsledek
# musíme skutečně vyhodnotit. Při spojování listů přidáme identifikátor zdroje před `bind_rows()`,
# abychom zachovali původ každého řádku.
#
# Novou číselnou veličinu odvozujeme až po sjednocení jednotek; například BMI počítáme jako hmotnost
# v kilogramech dělenou druhou mocninou výšky v metrech. Kategorie vytváříme z věcně zdůvodněných
# hranic pomocí podmínek v `if_else()` nebo `case_when()`. Vzájemně se překrývající podmínky se
# vyhodnocují v pořadí, proto nejprve zapisujeme specifičtější případy a nakonec úplnou výchozí
# větev. `factor()` používáme tehdy, když potřebujeme zachovat množinu nebo pořadí kategorií; pořadí
# úrovní ovlivňuje tabulky i osy grafů.
#
# Při porovnání skupin počítáme souhrny a pravidla pro odlehlost uvnitř stejné skupiny, kterou
# ukazuje graf. Boxploty srovnatelných skupin kreslíme na společné ose. Histogramy a Q–Q grafy
# můžeme rozdělit do facetů, ale zachováme srovnatelné měřítko a uvedeme velikosti skupin. Odlehlé
# hodnoty pouze označíme; pomocnou variantu bez nich porovnáváme s původními daty a věcný důvod
# případného vyloučení dokumentujeme. Export zapisujeme do nové cesty a před zápisem vytvoříme
# cílový adresář, nikdy nepřepisujeme zdrojový soubor.

# ### Pracovní složka a pomocné souhrny v původních podkladech
#
# Funkce `setwd()` mění pracovní složku R podle argumentu `dir`. Původní notebook přecházel do
# složky s daty a zpět. Zde zachováváme pracovní složku notebooku a používáme relativní cesty
# `data/...`, aby opakované spuštění buněk nezáviselo na předchozím přepnutí složky.
#
# Původní lokální funkce `statistika_sloupce()` sdružovala popisné charakteristiky a diagnostiku
# zvoleného sloupce po skupinách. Stejné typy souhrnů zde sestavujeme průhledně pomocí `group_by()`,
# `summarise()` nebo `rstatix::get_summary_stats()`. Označení odlehlých hodnot neznamená automatický
# pokyn k jejich odstranění.

# ## Nové funkce R v tomto cvičení
#
# Přehled uvádí funkce použité nebo definované v tomto notebooku, které se neobjevily v žádném
# předchozím cvičení. Více notebooků téhož týdne porovnáváme se stejnými předchozími týdny; lokální
# pomocné funkce uvádíme při jejich nové definici.
#
# U společného řádku jsou uvedeny argumenty používané alespoň u jedné z funkcí. Znak `…` označuje
# předávané hodnoty, sloupce či výrazy. Při zápisu s `%>%` se datová tabulka předává jako první
# argument automaticky. Nejde o úplný seznam všech možností funkcí.
#
# | Funkce | Používané parametry | K čemu ji použijeme |
# | --- | --- | --- |
# | `min()` | `…`, `na.rm` (vynechání NA) | Najdeme největší (`max`) nebo nejmenší (`min`) hodnotu.
# |
# | `seq_len()` | `length.out` | Vytvoříme bezpečnou posloupnost indexů podle objektu nebo zadaného
# počtu. |
# | `cat()` | `…` | Zobrazíme výsledek nebo vysvětlující zprávu; `cat` skládá textový výstup. |
# | `getwd()` | bez argumentů | Zjistíme pracovní složku, vůči níž se vyhodnocují relativní cesty k
# datům. |
# | `file.exists()` | `…` | Ověříme, zda existuje požadovaný vstupní soubor. |
# | `file.path()` | `…` | Sestavíme cestu ke vstupnímu či výstupnímu souboru. |
# | `list.files()` | `path` | Vypíšeme soubory ve složce a případně je omezíme vzorem názvu. |
# | `dir.create()` | `path`, `showWarnings` | Vytvoříme složku pro regenerovatelné výstupy. |
# | `library()` | `package` | Načteme balíček, aby bylo možné volat jeho funkce bez předpony. |
# | `read.csv()`, `read.csv2()` | `file` | Načteme CSV; varianty se liší výchozím oddělovačem polí a
# desetinným znakem. |
# | `openxlsx::read.xlsx()`, `readxl::read_excel()` | `xlsxFile`, `sheet`, `path`, `skip` | Načteme
# Excel, vybereme list a případně přeskočíme úvodní řádky. |
# | `write.csv()` | `x`, `file`, `row.names` | Uložíme tabulku do nového CSV souboru. |
# | `openxlsx::write.xlsx()`, `writexl::write_xlsx()` | `x`, `file`, `rowNames`, `path` | Uložíme
# tabulku nebo listy do nového souboru Excel. |
# | `colnames()`, `names()` | `x` | Zjistíme nebo změníme názvy složek objektu, sloupců či řádků. |
# | `dim()`, `nrow()` | `x` | Zjistíme rozměry tabulky nebo počet jejích řádků či sloupců. |
# | `head()`, `tail()` | `x` | Prohlédneme začátek nebo konec dat bez výpisu celého souboru. |
# | `str()` | `object` | Zkontrolujeme strukturu, datové typy a ukázku hodnot objektu. |
# | `summary()` | `object` | Získáme základní souhrn dat nebo výslednou tabulku statistického
# modelu. |
# | `as.data.frame()` | `x` | Převedeme tabulkový objekt na běžný datový rámec pro funkce základního
# R. |
# | `stack()` | `x` | Převedeme sloupce na dlouhou tabulku hodnot a označení skupiny. |
# | `reshape()` | `data`, `direction`, `varying`, `v.names`, `times`, `timevar` | Přeuspořádáme
# související měření mezi širokým a dlouhým formátem. |
# | `bind_rows()` | `…` | Spojíme více datových tabulek pod sebe podle názvů sloupců. |
# | `select()` | `.data`, `…` | Vybereme nebo vynecháme sloupce datové tabulky. |
# | `filter()` | `.data`, `…` | Vybereme řádky splňující podmínky, například konkrétní skupinu. |
# | `mutate()` | `.data`, `…` | Vytvoříme či upravíme sloupce, například BMI nebo rozdíl párových
# měření. |
# | `if_else()` | `condition`, `true`, `false` | Vytvoříme sloupec podle logické podmínky se
# zachováním jednotného datového typu. |
# | `case_when()` | `…` | Vytvoříme kategorie pomocí několika podmínek vyhodnocovaných postupně. |
# | `summarise()` | `.data`, `…` | Spočteme souhrny celkem nebo po skupinách; `summarize` je
# alternativní název `summarise`. |
# | `group_by()` | `.data`, `…` | Určíme skupiny, pro které se mají následující souhrny vypočítat
# zvlášť. |
# | `arrange()` | `.data`, `…` | Seřadíme řádky podle zadaných sloupců. |
# | `desc()` | `x` | Určíme sestupné řazení uvnitř `arrange()`. |
# | `count()` | `x`, `…`, `name` | Sestavíme tabulku absolutních četností kategorií. |
# | `n()` | bez argumentů | Vrátíme počet řádků právě zpracovávané skupiny v dplyr. |
# | `row_number()` | bez argumentů | Přidáme pořadové číslo řádku jako identifikátor pozorování. |
# | `pull()` | `.data`, `var` | Z tabulky získáme jeden sloupec jako vektor pro další výpočty. |
# | `reorder()` | `x`, `X`, `FUN`, `na.rm` (vynechání NA) | Seřadíme úrovně faktoru podle souhrnné
# hodnoty, například mediánu. |
# | `table()` | `…` | Sestavíme četnosti kategorií nebo kontingenční tabulku. |
# | `prop.table()` | `x` | Převedeme četnosti na podíly celkem, po řádcích nebo po sloupcích. |
# | `t()` | `x` | Transponujeme matici, například pro vhodnou orientaci grafu. |
# | `median()` | `x`, `na.rm` (vynechání NA) | Spočteme medián jako odolnější charakteristiku
# polohy. |
# | `quantile()` | `x`, `probs`, `na.rm` (vynechání NA) | Určíme vybrané výběrové kvantily, zejména
# kvartily. |
# | `IQR()` | `x`, `na.rm` (vynechání NA) | Spočteme mezikvartilové rozpětí jako míru variability. |
# | `sd()`, `var()` | `x`, `na.rm` (vynechání NA) | Spočteme výběrový rozptyl (`var`) a výběrovou
# směrodatnou odchylku (`sd`). |
# | `moments::skewness()` | `x`, `na.rm` (vynechání NA) | Popíšeme asymetrii rozdělení pomocí
# výběrové šikmosti. |
# | `moments::kurtosis()` | `x`, `na.rm` (vynechání NA) | Spočteme špičatost; pro exces v našich
# výpočtech odečteme 3. |
# | `rstatix::get_summary_stats()` | `data`, `…`, `type` | Získáme souhrnnou tabulku popisných
# charakteristik, případně po skupinách. |
# | `rstatix::identify_outliers()` | `data`, `…` | Označíme odlehlé hodnoty pomocí IQR; jejich
# odstranění vyžaduje samostatné zdůvodnění. |
# | `is.na()` | `x` | Zjistíme, které hodnoty chybějí, a zohledníme je při výpočtu. |
# | `na.omit()` | `object` | Vytvoříme pomocný objekt bez chybějících hodnot. |
# | `abs()` | `x` | Spočteme absolutní rozdíl, například při porovnání přesnosti souborů. |
# | `all.equal()` | `target`, `current` | Porovnáme objekty se zohledněním numerické tolerance. |
# | `stopifnot()` | `…` | Zastavíme výpočet, pokud neplatí požadovaná kontrolní podmínka. |
# | `ceiling()` | `x` | Zaokrouhlíme číslo nahoru při přípravě požadovaného zobrazení. |
# | `barplot()` | `height`, `col`, `main`, `space`, `xlab`, `ylab`, `names.arg` | Nakreslíme
# sloupcový graf četností nebo podílů kategorií. |
# | `boxplot()` | `x`, `formula` (vztah hodnoty ~ skupina), `data`, `xlab`, `ylab`, `main`, `…`,
# `names` | Porovnáme polohu, variabilitu a odlehlé hodnoty jedné či více skupin. |
# | `hist()` | `x`, `main`, `xlab`, `ylab`, `freq`, `breaks`, `probability` | Nakreslíme histogram
# četností nebo hustoty číselných hodnot. |
# | `density()` | `x` | Odhadneme hustotu z dat a doplníme ji do histogramu. |
# | `qqline()`, `qqnorm()` | `y`, `xlab`, `ylab`, `main` | Porovnáme data s normálními kvantily a
# přidáme orientační přímku. |
# | `heat.colors()` | `n` | Vytvoříme jednoduchou barevnou nebo šedou paletu pro graf. |
# | `pdf()`, `png()` | `file`, `encoding`, `width`, `height`, `filename` | Otevřeme výstupní
# grafické zařízení a uložíme následující grafy do souboru. |
# | `dev.off()` | bez argumentů | Uzavřeme grafické zařízení a dokončíme zápis obrázku do souboru. |
# | `ggplot2::ggplot()` | `data`, `mapping` | Založíme graf ze zadané tabulky dat. |
# | `ggplot2::aes()` | `x`, `sample` | Propojíme proměnné s osami grafu nebo s výběrovými kvantily.
# |
# | `ggplot2::geom_histogram()` | `bins`, `na.rm` (vynechání NA) | Přidáme histogram; `bins` určuje
# požadovaný počet intervalů. |
# | `ggplot2::facet_wrap()` | `facets` | Rozdělíme graf do panelů podle skupin. |
# | `ggplot2::labs()` | `x`, `y` | Nastavíme srozumitelné názvy os a další popisky grafu. |
# | `ggplot2::stat_qq()`, `ggplot2::stat_qq_line()` | `na.rm` (vynechání NA) | Vytvoříme Q–Q graf v
# ggplot2 a přidáme referenční přímku. |
# | `rexp()`, `runif()` | `n`, `rate` (intenzita), `min`, `max` | Vygenerujeme ukázkový náhodný
# výběr z rovnoměrného nebo exponenciálního modelu. |
# | `exploracni_overeni_normality()` | `data` | Naše pomocná funkce spojí jednoduché grafy a popis
# tvaru; normalitu neprokazuje. |

# ## Doplňující úlohy
#
# Úlohy vycházejí z materiálů Martiny Litschmannové ke cvičením. Přehled podkladů dostupných v kurzu
# najdete v [mapě zdrojů](../docs/source-map.md#cv6).
#
# ### 1. Studenti: příprava dat
#
# Načtěte `studenti.xlsx`, zkontrolujte rozměry a typy sloupců a přejmenujte proměnné bez
# diakritiky. Vytvořte BMI z hmotnosti v kg a výšky v metrech, věkovou kategorii do 22 let/více než
# 22 let, kategorii BMI pod 25/alespoň 25 a kategorii studijního průměru do 1,5, do 2 a nad 2.
# Procvičte výběr sloupců, filtrování, souhrny podle pohlaví a export.
#
# **Postup.** Výška je již v metrech; při výpočtu BMI ji nedělíme stem. Kategorie BMI zde slouží k
# procvičení práce s daty, nejsou kompletní zdravotní klasifikací.

# 1) Načtěte studenty a upravte názvy proměnných.
# Zkontrolujeme rozměry a typy; názvy bez diakritiky usnadní další výpočty.
studenti <- readxl::read_excel("data/studenti.xlsx")
dim(studenti)
str(studenti)
names(studenti) <- c(
  "id", "pohlavi", "vek", "vyska", "hmotnost",
  "studijni_prumer", "obor", "forma_studia"
)

# 2) Vytvořte BMI a požadované kategorie.
# Výška je v metrech; hranice věku, BMI a průměru zapisujeme přímo do podmínek.
studenti <- studenti %>%
  mutate(
    bmi = hmotnost / vyska^2,
    vek_kategorie = factor(if_else(vek <= 22, "do 22 let", "nad 22 let"),
      levels = c("do 22 let", "nad 22 let")
    ),
    bmi_kategorie = factor(if_else(bmi < 25, "pod 25", "alespoň 25"),
      levels = c("pod 25", "alespoň 25")
    ),
    prumer_kategorie = case_when(
      is.na(studijni_prumer) ~ NA_character_,
      studijni_prumer <= 1.5 ~ "výborný",
      studijni_prumer <= 2 ~ "velmi dobrý",
      TRUE ~ "dobrý"
    ),
    prumer_kategorie = factor(prumer_kategorie,
      levels = c("výborný", "velmi dobrý", "dobrý")
    )
  )
head(studenti)
summary(studenti$bmi)

# 3) Procvičte výběr sloupců a filtrování studentů.
# select vybírá proměnné, filter vybírá řádky splňující zadané podmínky.
studenti %>% select(id, pohlavi, vek)
studenti %>% select(-bmi)
studenti %>% filter(vek > 22)
studenti %>% filter(pohlavi == "žena", vek > 22)
studenti %>% filter(studijni_prumer <= 1.5)

# 4) Spočtěte souhrny celkem a podle pohlaví.
# summarise vytváří souhrny; group_by je vyhodnotí zvlášť pro každé pohlaví.
studenti %>% summarise(
  prumer_vek = mean(vek, na.rm = TRUE),
  min_vek = min(vek, na.rm = TRUE),
  max_vek = max(vek, na.rm = TRUE)
)
studenti %>%
  group_by(pohlavi) %>%
  summarise(
    pocet = n(), prumer_vek = mean(vek, na.rm = TRUE),
    prumer_bmi = mean(bmi, na.rm = TRUE)
  )

# 5) Připravte výběr studentek s výškou v centimetrech.
# Po filtrování převedeme jednotky a ponecháme požadované sloupce.
studentky <- studenti %>%
  filter(pohlavi == "žena") %>%
  mutate(vyska_cm = vyska * 100) %>%
  select(id, vek, vyska_cm, bmi_kategorie)
studentky

# 6) Exportujte upravená data studentů.
# Zapíšeme nový soubor do vystupy; zdrojová data nepřepisujeme.
openxlsx::write.xlsx(studenti, "vystupy/studenti_upraveni.xlsx")

# ### 2. Kyberbezpečnost: kategoriální proměnné
#
# V `cybersecurity.xlsx` popište používané protokoly a obdobně analyzujte
#
# - **a)** šifrování,
#
# - **b)** prohlížeče,
#
# - **c)** netypickou dobu přihlášení,
#
# - **d)** zaznamenání útoku. Uveďte absolutní a relativní četnosti a jednoduché sloupcové grafy.
# Připravte tabulku pro export.
#
# **Postup.** Každý řádek je záznam relace. Nejprve ověříme typy, protokol převedeme na faktor a
# stanovíme pořadí kategorií. Četnosti počítáme i pro chybějící hodnoty; procenta zaokrouhlujeme jen
# pro zobrazení.

# Ukázka: popište protokoly a připravte export četností.
# Načteme relace, stanovíme pořadí kategorií a počty převedeme na podíly.
kyber <- readxl::read_excel("data/cybersecurity.xlsx")
str(kyber)
kyber <- kyber %>% mutate(
  id = row_number(),
  protokol = factor(protokol, levels = c("TCP", "UDP", "ICMP"))
)
tabulka_protokolu <- kyber %>%
  count(protokol, name = "pocet") %>%
  mutate(relativni_cetnost = pocet / sum(pocet), procenta = round(100 * relativni_cetnost, 1))
tabulka_protokolu
barplot(tabulka_protokolu$pocet,
  names.arg = tabulka_protokolu$protokol,
  xlab = "Protokol", ylab = "Počet relací"
)
openxlsx::write.xlsx(tabulka_protokolu, "vystupy/protokoly.xlsx")

# a) Popište četnosti šifrování.
# Spočteme absolutní a relativní četnosti včetně chybějících hodnot a zobrazíme sloupce.
cetnosti <- kyber %>%
  count(sifrovani, name = "pocet") %>%
  mutate(relativni_cetnost = pocet / sum(pocet))
cetnosti
barplot(cetnosti$pocet, names.arg = cetnosti$sifrovani, xlab = "Šifrování", ylab = "Počet relací")

# b) Popište četnosti prohlížečů.
# Počty kategorií vydělíme počtem relací a zobrazíme sloupcový graf.
cetnosti <- kyber %>%
  count(prohlizec, name = "pocet") %>%
  mutate(relativni_cetnost = pocet / sum(pocet))
cetnosti
barplot(cetnosti$pocet, names.arg = cetnosti$prohlizec, xlab = "Prohlížeč", ylab = "Počet relací")

# c) Popište netypickou dobu přihlášení.
# Porovnáme počty a podíly kategorií a doplníme sloupcový graf.
cetnosti <- kyber %>%
  count(doba_netypicka, name = "pocet") %>%
  mutate(relativni_cetnost = pocet / sum(pocet))
cetnosti
barplot(cetnosti$pocet,
  names.arg = cetnosti$doba_netypicka,
  xlab = "Netypická doba přihlášení",
  ylab = "Počet relací"
)

# d) Popište zaznamenání útoku.
# Pro obě kategorie určíme počty, relativní četnosti a sloupcový graf.
cetnosti <- kyber %>%
  count(utok, name = "pocet") %>%
  mutate(relativni_cetnost = pocet / sum(pocet))
cetnosti
barplot(cetnosti$pocet, names.arg = cetnosti$utok, xlab = "Zaznamenaný útok", ylab = "Počet relací")

# ### 3. Oxid dusičitý v ovzduší
#
# Načtěte `airquality.xlsx`, připravte názvy a identifikátor. Pro koncentraci NO₂ určete počet,
# minimum, kvartily, průměr, medián, maximum, rozptyl, směrodatnou odchylku, variační koeficient,
# šikmost a exces. Identifikujte odlehlé hodnoty pomocí rstatix a pro porovnání vytvořte pomocný
# sloupec s označenými hodnotami nahrazenými `NA`. Porovnejte charakteristiky a nakreslete krabicový
# graf, histogram s odhadem hustoty a Q–Q graf.
#
# Celý postup zopakujte pro dny s kvalitou ovzduší „dobrá“ (`Good`). Původní data vždy zachovejte.
# Odlehlé hodnoty zde vynecháváme jen pro srovnání citlivosti výsledků.

# Příprava: načtěte údaje o ovzduší a vyberte kvalitní dny.
# Sjednotíme názvy, přidáme identifikátor a vytvoříme samostatný výběr Good.
ovzdusi <- readxl::read_excel("data/airquality.xlsx")
names(ovzdusi) <- c(
  "teplota", "vlhkost", "pm25", "pm10", "no2", "so2", "co",
  "vzdalenost", "hustota", "kvalita"
)
ovzdusi <- ovzdusi %>% mutate(id = row_number())
str(ovzdusi)
ovzdusi_dobra <- ovzdusi %>% filter(kvalita == "Good")

# #### Všechna měření

# 1) Popište NO2 u všech měření a porovnejte vliv odlehlých hodnot.
# Označíme odlehlé řádky a vytvoříme pomocný sloupec; porovnáme souhrny bez změny originálu.
odlehla_no2 <- ovzdusi %>% rstatix::identify_outliers(no2)
odlehla_no2
ovzdusi <- ovzdusi %>%
  mutate(no2_bez_odlehlych = ifelse(id %in% odlehla_no2$id, NA, no2))
ovzdusi %>% rstatix::get_summary_stats(no2, no2_bez_odlehlych, type = "full")
ovzdusi %>% summarise(
  rozptyl = var(no2, na.rm = TRUE),
  variacni_koeficient = 100 * sd(no2, na.rm = TRUE) / mean(no2, na.rm = TRUE),
  sikmost = moments::skewness(no2, na.rm = TRUE),
  exces = moments::kurtosis(no2, na.rm = TRUE) - 3,
  rozptyl_bez = var(no2_bez_odlehlych, na.rm = TRUE),
  variacni_koeficient_bez = 100 * sd(no2_bez_odlehlych, na.rm = TRUE) /
    mean(no2_bez_odlehlych, na.rm = TRUE),
  sikmost_bez = moments::skewness(no2_bez_odlehlych, na.rm = TRUE),
  exces_bez = moments::kurtosis(no2_bez_odlehlych, na.rm = TRUE) - 3
)

# 2) Nakreslete boxplot NO2 u všech měření.
# Ve společném grafu porovnáme původní a pomocný soubor.
boxplot(ovzdusi$no2, ovzdusi$no2_bez_odlehlych,
  names = c("Původní", "Bez označených"), ylab = "NO2 [µg/m³]"
)

# 3) Nakreslete histogram s hustotou NO2 u všech měření.
# Pomocný sloupec zbavíme NA a histogram škálujeme jako hustotu.
hodnoty_no2 <- na.omit(ovzdusi$no2_bez_odlehlych)
hist(hodnoty_no2, freq = FALSE, main = "Všechna měření", xlab = "NO2 [µg/m³]")
lines(density(hodnoty_no2))

# 4) Nakreslete Q–Q graf NO2 u všech měření.
# Výběrové kvantily porovnáme s normálními; přímka je pouze orientační.
qqnorm(hodnoty_no2)
qqline(hodnoty_no2)

# #### Dobrá kvalita ovzduší

# 1) Popište NO2 u dobrých dnů a porovnejte vliv odlehlých hodnot.
# Označíme odlehlé řádky a vytvoříme pomocný sloupec; porovnáme souhrny bez změny originálu.
odlehla_no2 <- ovzdusi_dobra %>% rstatix::identify_outliers(no2)
odlehla_no2
ovzdusi_dobra <- ovzdusi_dobra %>%
  mutate(no2_bez_odlehlych = ifelse(id %in% odlehla_no2$id, NA, no2))
ovzdusi_dobra %>% rstatix::get_summary_stats(no2, no2_bez_odlehlych, type = "full")
ovzdusi_dobra %>% summarise(
  rozptyl = var(no2, na.rm = TRUE),
  variacni_koeficient = 100 * sd(no2, na.rm = TRUE) / mean(no2, na.rm = TRUE),
  sikmost = moments::skewness(no2, na.rm = TRUE),
  exces = moments::kurtosis(no2, na.rm = TRUE) - 3,
  rozptyl_bez = var(no2_bez_odlehlych, na.rm = TRUE),
  variacni_koeficient_bez = 100 * sd(no2_bez_odlehlych, na.rm = TRUE) /
    mean(no2_bez_odlehlych, na.rm = TRUE),
  sikmost_bez = moments::skewness(no2_bez_odlehlych, na.rm = TRUE),
  exces_bez = moments::kurtosis(no2_bez_odlehlych, na.rm = TRUE) - 3
)

# 2) Nakreslete boxplot NO2 u dobrých dnů.
# Ve společném grafu porovnáme původní a pomocný soubor.
boxplot(ovzdusi_dobra$no2, ovzdusi_dobra$no2_bez_odlehlych,
  names = c("Původní", "Bez označených"), ylab = "NO2 [µg/m³]"
)

# 3) Nakreslete histogram s hustotou NO2 u dobrých dnů.
# Pomocný sloupec zbavíme NA a histogram škálujeme jako hustotu.
hodnoty_no2 <- na.omit(ovzdusi_dobra$no2_bez_odlehlych)
hist(hodnoty_no2, freq = FALSE, main = "Dobrá kvalita ovzduší", xlab = "NO2 [µg/m³]")
lines(density(hodnoty_no2))

# 4) Nakreslete Q–Q graf NO2 u dobrých dnů.
# Výběrové kvantily porovnáme s normálními; přímka je pouze orientační.
qqnorm(hodnoty_no2)
qqline(hodnoty_no2)

# ### 4. Doba relace podle protokolu
#
# Na datech kyberbezpečnosti porovnejte délku relace v sekundách podle protokolu. Seřaďte skupiny
# podle mediánu, zkontrolujte odlehlé hodnoty uvnitř skupin a porovnejte původní i pomocné očištěné
# hodnoty. Uveďte souhrnné charakteristiky a společný krabicový graf, histogramy a Q–Q grafy po
# skupinách.
#
# **Postup.** Hodnoty označíme funkcí `identify_outliers()` uvnitř protokolu. Identifikátor zůstává
# jedinečný v celém souboru. Grafy netvoří důkaz normality a případné odstranění musí mít ve
# skutečné analýze samostatné odůvodnění.

# 1) Seřaďte protokoly a označte odlehlé doby relace.
# Řadíme podle mediánu a odlehlost posuzujeme uvnitř protokolu; původní sloupec zachováme.
kyber <- kyber %>% mutate(protokol = reorder(protokol, relace_doba, median, na.rm = TRUE))
odlehle_relace <- kyber %>%
  group_by(protokol) %>%
  rstatix::identify_outliers(relace_doba)
odlehle_relace
kyber <- kyber %>% mutate(
  relace_bez_odlehlych =
    ifelse(id %in% odlehle_relace$id, NA, relace_doba)
)

# 2) Spočtěte souhrny délek relací podle protokolu.
# Porovnáme původní a pomocné hodnoty a doplníme charakteristiky variability a tvaru.
kyber %>%
  group_by(protokol) %>%
  rstatix::get_summary_stats(relace_doba, relace_bez_odlehlych, type = "full")
kyber %>%
  group_by(protokol) %>%
  summarise(
    pocet_chybejicich = sum(is.na(relace_bez_odlehlych)),
    rozptyl = var(relace_bez_odlehlych, na.rm = TRUE),
    variacni_koeficient = 100 * sd(relace_bez_odlehlych, na.rm = TRUE) /
      mean(relace_bez_odlehlych, na.rm = TRUE),
    sikmost = moments::skewness(relace_bez_odlehlych, na.rm = TRUE),
    exces = moments::kurtosis(relace_bez_odlehlych, na.rm = TRUE) - 3
  )

# 3) Nakreslete společné boxploty délek relací.
# Skupiny porovnáme na společné ose zvlášť pro původní a pomocný soubor.
boxplot(relace_doba ~ protokol, data = kyber, ylab = "Doba relace [s]")
boxplot(relace_bez_odlehlych ~ protokol, data = kyber, ylab = "Doba relace [s]")

# 4) Nakreslete histogramy délek relací po protokolech.
# Facety udrží stejnou vodorovnou osu; chybějící pomocné hodnoty vynecháme.
# Jednoduché facety udrží stejnou vodorovnou osu mezi skupinami.
ggplot2::ggplot(kyber, ggplot2::aes(x = relace_bez_odlehlych)) +
  ggplot2::geom_histogram(bins = 10, na.rm = TRUE) +
  ggplot2::facet_wrap(~protokol) +
  ggplot2::labs(x = "Doba relace [s]", y = "Četnost")

# 5) Nakreslete Q–Q grafy délek relací po protokolech.
# Každou skupinu porovnáme s normálními kvantily a přidáme referenční přímku.
ggplot2::ggplot(kyber, ggplot2::aes(sample = relace_bez_odlehlych)) +
  ggplot2::stat_qq(na.rm = TRUE) +
  ggplot2::stat_qq_line(na.rm = TRUE) +
  ggplot2::facet_wrap(~protokol) +
  ggplot2::labs(x = "Teoretické normální kvantily", y = "Výběrové kvantily [s]")

# ### 5. Akumulátory: od importu k porovnání výrobců
#
# Úloha vychází z materiálů Martiny Litschmannové k explorační analýze (viz [mapa
# zdrojů](../docs/source-map.md#cv6)); používá data `aku2.xlsx` a `aku_st2.csv`.
#
# Soubor obsahuje kapacitu 317 akumulátorů po 5 a po 100 cyklech.
#
# - **a)** Načtěte CSV a list `standard`; porovnejte strukturu a přesnost čísel.
#
# - **b)** Spojte listy A–D, doplňte výrobce, identifikátor a absolutní pokles kapacity.
#
# - **c)** Vyberte výrobce A a B, seřaďte data podle poklesu a určete skupinové průměry.
#
# - **d)** Sestavte tabulku četností výrobců, graf a export.
#
# - **e)** Popište kapacitu po 5 cyklech celkem i podle výrobce, včetně variability, šikmosti a
# špičatosti.
#
# - **f)** Nakreslete boxploty, histogramy s hustotou a Q–Q grafy.
#
# - **g)** Označte odlehlé hodnoty uvnitř skupin a porovnejte souhrny s pomocnou variantou bez nich.
#
# **Postup.** Názvy sloupců sjednotíme až po importu. CSV má čárkový oddělovač a tečku v číslech,
# proto použijeme `read.csv`; `read.csv2` očekává jiné oddělovače. XLSX zachovává více desetinných
# míst. Odlehlé hodnoty automaticky nepovažujeme za chyby a původní měření zachováme.

# a) Porovnejte CSV a list standard v Excelu.
# Načteme obě verze, sjednotíme názvy a porovnáme strukturu, rozsah a číselnou přesnost.
aku_csv <- read.csv("data/aku_st2.csv")
aku_standard <- readxl::read_excel("data/aku2.xlsx", sheet = "standard")
names(aku_csv) <- names(aku_standard) <- c("id", "kap5", "kap100", "vyrobce")
str(aku_csv)
str(aku_standard)
aku_data_frame <- as.data.frame(aku_standard)
aku_openxlsx <- openxlsx::read.xlsx("data/aku2.xlsx", sheet = "standard")
c(rozsah_csv = nrow(aku_csv), rozsah_xlsx = nrow(aku_standard))
max(abs(aku_csv$kap5 - aku_standard$kap5))

# b) Spojte listy A–D a vytvořte výrobce, identifikátor a pokles.
# Listy připojíme pod sebe; absolutní pokles je kapacita po 5 minus po 100 cyklech.
aku <- data.frame()
for (vyrobce in c("A", "B", "C", "D")) {
  cast <- readxl::read_excel("data/aku2.xlsx", sheet = vyrobce)
  cast$vyrobce <- vyrobce
  aku <- bind_rows(aku, cast)
}
aku <- aku %>% mutate(
  id = row_number(), pokles = kap5 - kap100,
  vyrobce = factor(vyrobce, levels = c("A", "B", "C", "D"))
)
all.equal(aku$kap5, aku_standard$kap5)

# c) Vyberte výrobce A a B, seřaďte poklesy a spočtěte průměry.
# Pro výpis omezíme výrobce a seřadíme poklesy sestupně; souhrn vytvoříme po výrobcích.
aku %>%
  filter(vyrobce %in% c("A", "B")) %>%
  select(id, vyrobce, pokles) %>%
  arrange(desc(pokles)) %>%
  head()
aku %>%
  group_by(vyrobce) %>%
  summarise(prumer_poklesu = mean(pokles))

# d) Sestavte četnosti výrobců, graf a export.
# Počty převedeme na podíly a procenta; výsledky uložíme do složky vystupy.
cetnosti_aku <- aku %>%
  count(vyrobce) %>%
  mutate(podil = n / sum(n), procenta = 100 * podil)
cetnosti_aku
sum(cetnosti_aku$procenta)
barplot(cetnosti_aku$n,
  names.arg = cetnosti_aku$vyrobce,
  xlab = "Výrobce", ylab = "Počet akumulátorů"
)
dir.create("vystupy", showWarnings = FALSE)
write.csv(cetnosti_aku, "vystupy/aku_cetnosti.csv", row.names = FALSE)
writexl::write_xlsx(cetnosti_aku, "vystupy/aku_cetnosti.xlsx")

# e) Popište kapacitu po 5 cyklech celkem a podle výrobce.
# Vedle základních souhrnů doplníme rozptyl, variační koeficient, šikmost a exces.
aku %>% rstatix::get_summary_stats(kap5, type = "full")
aku %>%
  group_by(vyrobce) %>%
  rstatix::get_summary_stats(kap5, type = "full")
aku %>%
  group_by(vyrobce) %>%
  summarise(
    chybejici = sum(is.na(kap5)), rozptyl = var(kap5, na.rm = TRUE),
    variacni_koeficient = sd(kap5, na.rm = TRUE) / mean(kap5, na.rm = TRUE),
    sikmost = moments::skewness(kap5, na.rm = TRUE),
    exces = moments::kurtosis(kap5, na.rm = TRUE) - 3
  )

# f) Nakreslete boxploty, histogramy s hustotou a Q–Q grafy.
# Skupiny porovnáme společně a jejich tvary samostatně; grafy samy normalitu nedokazují.
boxplot(aku$kap5, ylab = "Kapacita po 5 cyklech")
boxplot(kap5 ~ vyrobce, data = aku, xlab = "Výrobce", ylab = "Kapacita po 5 cyklech")
prumery_aku <- aku %>%
  group_by(vyrobce) %>%
  summarise(prumer = mean(kap5))
points(seq_len(nrow(prumery_aku)), prumery_aku$prumer, pch = 18)
for (vyrobce in levels(aku$vyrobce)) {
  kapacita <- aku$kap5[aku$vyrobce == vyrobce]
  hist(kapacita,
    probability = TRUE, main = paste("Výrobce", vyrobce),
    xlab = "Kapacita po 5 cyklech", ylab = "Hustota"
  )
  lines(density(kapacita))
  qqnorm(kapacita, main = paste("Q–Q graf: výrobce", vyrobce))
  qqline(kapacita)
}

# g) Označte odlehlé hodnoty a porovnejte pomocnou variantu.
# Odlehlost určujeme uvnitř výrobců; původní kapacitu zachováme v nezměněném sloupci.
odlehle_aku <- aku %>%
  group_by(vyrobce) %>%
  rstatix::identify_outliers(kap5)
odlehle_aku
aku <- aku %>% mutate(kap5_bez_op = ifelse(id %in% odlehle_aku$id, NA, kap5))
aku %>%
  group_by(vyrobce) %>%
  rstatix::get_summary_stats(kap5, kap5_bez_op, type = "full")
boxplot(kap5_bez_op ~ vyrobce,
  data = aku, xlab = "Výrobce",
  ylab = "Kapacita po 5 cyklech (pomocná varianta)"
)

# ## Původní ze sbírky
#
# Původní notebook obsahoval průběžně řešený výklad na datech žárovek, nikoli samostatnou sbírku
# úloh. Tyto postupy zůstaly ve výkladu výše. Starší zdroj `skript_6_EDA_2024.R` je metodicky
# souběžná analýza akumulátorů; jeho import, převody formátu, četnosti, charakteristiky a práci s
# odlehlými hodnotami zde již pokrýváme.
