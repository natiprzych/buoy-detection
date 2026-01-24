# Buoy & Swimmer Detector (MATLAB)

Projekt z przedmiotu *Analiza Obrazów*:

---

System łączy klasyczne przetwarzanie obrazu z siecią neuronową, co pozwala na skuteczne rozróżnianie obiektów o zbliżonej kolorystyce, ale odmiennej strukturze i teksturze.

Wykorzystuje:
* segmentację koloru (HSV),
* klasyczne cechy kształtu (morfologia),
* **Hybrydowa ekstrakcja cech (13 parametrów):** Każdy obiekt opisany jest wektorem cech obejmującym geometrię (5), statystyki koloru HSV (4) oraz teksturę GLCM (4).
* **Architektura Sieci:** Wykorzystanie sieci `patternnet` zoptymalizowanej pod kątem klasyfikacji binarnej (boja vs pływak).
* **Algorytm Bayesian Regularization (`trainbr`):** Wybrany ze względu na wysoką skuteczność przy ograniczonej liczbie danych treningowych; algorytm ten nie wymaga wydzielania zbioru walidacyjnego, co pozwala na efektywniejsze wykorzystanie próbek.
* **Optymalizacja Hiperparametrów:** Liczba **26 neuronów** w warstwie ukrytej została dobrana poprzez dwuetapowe testy (zakres 5-40, a następnie szczegółowy 25-35), osiągając stabilną dokładność testową na poziomie ok. 98.7%.

---

## Efektywność rozwiązania

Dzięki ewolucji algorytmu od prostych masek kolorów do zaawansowanej analizy teksturalnej, system osiąga wysoką skuteczność w trudnych warunkach morskich:

* **Odporność na warunki morskie:** Wykorzystanie macierzy współwystępowania poziomów szarości (**GLCM**) pozwala systemowi odróżnić chaotyczną teksturę odblasków i piany morskiej od zwartej struktury boi i ludzi.
* **Detekcja pływaków:** Wprowadzenie rozszerzonej maski `dark_objects` w procesie segmentacji umożliwia wykrywanie osób w ciemnych piankach, które nie posiadają jaskrawych kamizelek i zlewają się z kolorem głębokiej wody.
* **Precyzja boi:** Zaimplementowana w logice detekcji funkcja **marginesów bezpieczeństwa (padding)** skutecznie eliminuje problem "pływaków widm" wykrywanych na czubkach i antenach boi, wchłaniając je do ramki głównego obiektu.

---

## Jak uruchomić aplikację

### Wymagania

* MATLAB (z Image Processing Toolbox i Neural Network Toolbox)
* Plik `models/net_buoy.mat` (wytrenowana sieć neuronowa)
* Wszystkie pliki z katalogu `src/` muszą być dostępne

### Szybki start

1. Otwórz MATLAB
2. Przejdź do katalogu projektu (`buoy-detection`)
3. Wpisz w Command Window: `run_app`
4. Przycisk `Wczytaj` służy do wczytania obrazu
5. Przycisk `Wykryj` służy do wykrycia boji i pływaków na wczytanym obrazie
6. Przycisk `Zapisz` służy do zapisania wyników do `results/`

### Testowanie

Folder `test_data/` zawiera przykładowe obrazy, na których system działa poprawnie. Można je użyć do szybkiego przetestowania aplikacji. 
Obrazy "zewnętrzne" mogą zawierać błędy związane z niedoskonałością systemu.

---

## Struktura katalogów

```text
buoy-detector/
├── src/                  
│   ├── read_yolo_annotations.m
│   ├── segment_mask.m
│   ├── detect_objects_logic.m
│   ├── visualize_results.m
│   └── compute_region_features.m
│
├── scripts/              
│   ├── prepare_dataset.m
│   ├── train_net.m
│   └── detect_buoys_and_swimmers.m
│
├── data/
│   ├── images/           # obrazy .jpg / .png
│   ├── labels/           # adnotacje YOLO Darknet (.txt)
│   └── buoy_dataset.mat
│
├── models/
│   └── net_buoy.mat      # wytrenowana sieć (tworzona przez train_net.m)
│
├── test_data/            # przykładowe obrazy do testowania
│
├── results/
│   ├── figures/          # confusion matrix, przykładowe detekcje (zapisywane automatycznie)
│   └── logs/             # logi z treningu i detekcji (zapisywane automatycznie)
│
├── main.mlapp            # Interfejs aplikacji
├── run_app.m             # Skrypt uruchamiający aplikację
│
└── README.md
```
---

**Autorzy:** Natalia Przychodzień, Dobrawa Rumszewicz, Filip Opacki, Marcin Oracz.
