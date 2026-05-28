# Power BI Case Study: personalizowana oferta produktów dla niemowląt

Projekt portfolio pokazujący raport Power BI dla firmy produkującej na dużą skalę personalizowane produkty dla niemowląt: kocyki, body, śliniaki i pamiątkowe akcesoria z imieniem.

Dane publiczne o imionach nadawanych dzieciom w Polsce zostały użyte jako przybliżenie zainteresowania wariantami personalizacji. Raport wspiera decyzję, jak szeroki katalog imion utrzymywać, które imiona powinny być priorytetem i jak często oferta wymaga aktualizacji.

## Co pokazuje projekt

- Pobranie danych z API dane.gov.pl przy użyciu skryptu R.
- Ujednolicenie zasobów pochodzących z plików CSV oraz endpointów z paginacją.
- Model Power BI z tabelą faktów, klasyfikacją imion, parametrem Top N i wydzieloną tabelą miar.
- 45 miar DAX pogrupowanych według zastosowania: miary bazowe, zmiany rok do roku, ranking i Top N, udziały, kategorie oraz elementy techniczne raportu.
- Raport zaprojektowany pod zgodność z filtrami: tytuły zależne od wyboru użytkownika, spójne slicery i elastyczny wybór liczby imion w katalogu.

## Scenariusz biznesowy

Raport odpowiada na pytania typowe dla planowania oferty personalizowanej:

- Ile imion powinno znaleźć się w podstawowym katalogu personalizacji?
- Jaka część popytu jest pokrywana przez wybrany zakres Top N?
- Które imiona utrzymują popularność rok do roku?
- Co firma traci, jeśli nie aktualizuje katalogu?
- Czy ten sam katalog działa podobnie w różnych województwach?


## Jak uruchomić

Otwórz `index.html` w przeglądarce. Plik raportu znajduje się w `powerbi/Raport.pbix`.
Techniczne informacje znajdują się w pliku `technical-notes.md`.

## Źródło danych

Publiczne dane z dane.gov.pl: imiona nadawane dzieciom w Polsce według roku, płci i województwa.
