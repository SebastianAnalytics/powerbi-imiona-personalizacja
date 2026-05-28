# Notatki techniczne

## Pobranie danych

Dane są pobierane przez `source/Imiona.R` z API dane.gov.pl. Skrypt:

- pobiera listę zasobów dla zbioru danych,
- wybiera zasoby dotyczące województw,
- usuwa zduplikowane zasoby z 2019 roku na podstawie tytułu,
- pobiera pliki CSV, jeśli są dostępne,
- korzysta z paginowanego endpointu `/data`, jeśli CSV nie jest dostępny,
- ujednolica nazwy kolumn i typy danych,
- łączy wszystkie lata w jedną tabelę.

## Model

Model Power BI zawiera cztery główne tabele:

- `Imiona`: tabela faktów z rokiem, województwem, imieniem, płcią i liczbą nadań.
- `Kategorie`: tabela klasyfikacji imion połączona kluczem imię-płeć.
- `TopN`: rozłączona tabela parametru używana do wyboru zakresu katalogu imion.
- `Miary`: wydzielona tabela miar DAX.

Model to prosty schemat gwiazdy. Większość logiki analitycznej znajduje się w miarach DAX, używając jeśli jest taka potrzeba "wirtualnych tabel" - co daje prostotę i efektywność modelu.


## Obszary DAX

Eksport modelu zawiera 45 miar pogrupowanych w folderach:

- miary bazowe,
- zmiany rok do roku,
- ranking i Top N,
- udziały oraz pokrycie popytu,
- analiza kategorii,
- miary techniczne,
- tytuły zależne od filtrów.

Wszystkie miary znajdują się w pliku Dane.xlsx

## Wizualizacja mapy

Na potrzeby projektu, aby w przystępny sposób przedstawić województwa (bez pogranicznych państw itp.) ściągnąłem granicę województw z linku:
https://www.gis-support.pl/downloads/2022/wojewodztwa.zip
Na stronie https://mapshaper.org/ zmieniłem format pliku na json (obsługiwany przez Power BI) oraz zmniejszyłem szczegółowość granic.
