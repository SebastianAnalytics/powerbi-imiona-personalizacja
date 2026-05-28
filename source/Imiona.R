library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)


# ── 1. Lista zasobów z API ────────────────────────────────────────────────────
# meta.count = 82 zasoby, per_page = 100 pobiera wszystkie w 1 żądaniu
res_list  <- GET(
  "https://api.dane.gov.pl/1.4/datasets/219,imiona-nadawane-dzieciom-w-polsce/resources",
  query = list(lang = "pl", per_page = 100))

resources <- fromJSON(content(res_list, "text", encoding = "UTF-8"))
df_links  <- resources$data

# Filtr: tylko zasoby wg województw (tytułu zawiera "województw")
filtr_woj <- grepl("województw", df_links$attributes$title, ignore.case = TRUE)

df_zasoby <- df_links %>%
  filter(filtr_woj) %>%                        # 32 zasoby (w tym 4 pary duplikatów z 2019)
  select(id, links, attributes) %>%
  unnest_wider(col = attributes) %>%
  select(id, links, title, csv_download_url) %>%
  mutate(
    Rok    = str_extract(title, "\\d{4}"),
    Czlon  = str_extract(title, "(?<=imię )\\w+"),      # "pierwsze" lub "drugie"
    Rodzaj = str_extract(title, "żeńskie|męskie"),
    url    = links$self                                  # URL zasobu: .../resources/ID,slug
  ) %>%
  # 2019 ma po 2 zasoby z identycznym tytułem i tymi samymi danymi.
  # Zostawiamy 1 z każdej pary: preferujemy ten z CSV, przy braku – niższe ID.
  group_by(title) %>%
  arrange(is.na(csv_download_url), as.integer(id)) %>%
  slice(1) %>%
  ungroup()

cat("Zasobów do pobrania:", nrow(df_zasoby), "\n")   # 28 (32 - 4 duplikaty 2019)
cat("Lata:", paste(sort(unique(df_zasoby$Rok)), collapse = ", "), "\n\n")

# ── 2. Helpery ────────────────────────────────────────────────────────────────

# Ujednolicamy nazwy kolumn do krótkich, ASCII nazw (niezależnie od roku i członu).
# Struktura danych jest zawsze: WOJ | WOJEWÓDZTWO | IMIĘ_* | PŁEĆ | LICZBA_WYSTĄPIEŃ
standaryzuj_kolumny <- function(df) {
  names(df)[1:5] <- c("WOJ", "WOJEWODZTWO", "IMIE", "PLEC", "LICZBA")
  # WOJ: API zwraca "02" (character), CSV readr parsuje jako 2.0 (double) -> ujednolicamy
  df$WOJ    <- formatC(as.integer(df$WOJ), width = 2, flag = "0")  # zawsze "02", "04", …
  df$LICZBA <- as.integer(df$LICZBA)
  df
}

# Parsuje jedną stronę odpowiedzi /data do flat data.frame
parsuj_strone <- function(obj) {
  attrs     <- obj$data$attributes
  hmap      <- obj$meta$headers_map              # np. list(col1="WOJ", col2="WOJEWÓDZTWO", ...)
  col_keys  <- names(hmap)
  flat      <- lapply(col_keys, function(k) attrs[[k]]$repr)
  names(flat) <- col_keys
  as.data.frame(flat, stringsAsFactors = FALSE)  # kolumny: col1, col2, …col5
}

# ── 3. Pobieranie danych ───────────────────────────────────────────────────────
df_list <- list()
n_res   <- nrow(df_zasoby)

for (j in seq_len(n_res)) {

  rok_j    <- df_zasoby$Rok[j]
  czlon_j  <- df_zasoby$Czlon[j]
  rodzaj_j <- df_zasoby$Rodzaj[j]
  title_j  <- df_zasoby$title[j]
  csv_url  <- df_zasoby$csv_download_url[j]

  cat(sprintf("[%d/%d] %s\n        ", j, n_res, title_j))

  tmp <- tryCatch({

    if (!is.na(csv_url)) {
      # ── Ścieżka szybka: plik CSV (1 żądanie na zasób) ────────────────────
      # Dostępna dla 2020–2025 i 1 zasobu z 2019.
      Sys.sleep(1)
      r   <- GET(csv_url)
      df  <- read_csv(content(r, "raw"), show_col_types = FALSE,
                      locale = locale(encoding = "UTF-8"))
      standaryzuj_kolumny(df)

    } else {
      # ── Ścieżka wolna: endpoint /data z paginacją ─────────────────────────
      # Używana dla 3 zasobów z 2019, które nie mają pliku CSV.
      url_data <- paste0(df_zasoby$url[j], "/data?per_page=100&page=")

      # Pierwsza strona: pobieramy dane + meta.count (dokładna liczba rekordów)
      Sys.sleep(1)
      r1   <- GET(paste0(url_data, 1))
      obj1 <- fromJSON(content(r1, "text", encoding = "UTF-8"))

      total   <- obj1$meta$count          # łączna liczba wierszy
      n_stron <- ceiling(total / 100)     # dokładna liczba stron – bez zbędnego ostatniego żądania

      cat(sprintf("(API /data: %d wierszy, %d stron) ", total, n_stron))

      pages <- list(parsuj_strone(obj1))

      for (p in seq(2, n_stron)) {
        Sys.sleep(1)
        r   <- GET(paste0(url_data, p))
        obj <- fromJSON(content(r, "text", encoding = "UTF-8"))
        pages <- c(pages, list(parsuj_strone(obj)))
      }

      standaryzuj_kolumny(bind_rows(pages))
    }

  }, error = function(e) {
    cat("BŁĄD:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(tmp) && nrow(tmp) > 0) {
    tmp$Rok    <- rok_j
    tmp$Czlon  <- czlon_j
    tmp$Rodzaj <- rodzaj_j
    df_list    <- c(df_list, list(tmp))
    cat(sprintf("OK – %d wierszy\n", nrow(tmp)))
  }
}

# ── 4. Łączenie w jedną tabelę ────────────────────────────────────────────────
df_all <- bind_rows(df_list)

# Konwersja typów (WOJ i LICZBA już ujednolicone w standaryzuj_kolumny)
df_all$Rok <- as.integer(df_all$Rok)

cat("\n=== GOTOWE ===\n")
cat("Łączna liczba wierszy :", nrow(df_all), "\n")
cat("Kolumny               :", paste(names(df_all), collapse = ", "), "\n")
cat("Lata                  :", paste(sort(unique(df_all$Rok)), collapse = ", "), "\n")
cat("Województw            :", length(unique(df_all$WOJEWODZTWO)), "\n")

# ── 5. Zapis do pliku ─────────────────────────────────────────────────────────
sciezka_csv <- "C:/Projekty/Imiona/imiona_woj_wszystkie_lata.csv"
write_csv(df_all, sciezka_csv)
cat("\nZapisano:", sciezka_csv, "\n")
