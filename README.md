# Buoy & Swimmer Detector (MATLAB)

Projekt z przedmiotu *Analiza Obrazów*:

System do automatycznego wykrywania **czerwonych boi nawigacyjnych** oraz **pływaków (swimmerów)** na obrazach morskich.  
Wykorzystuje:
- segmentację koloru (HSV),
- klasyczne cechy kształtu (morfologia),
- prostą sieć neuronową `feedforwardnet` do klasyfikacji obiektów: **boja vs człowiek**.

---

## Struktura katalogów

```text
buoy-detector/
├── src/                  
│   ├── read_yolo_annotations.m
│   ├── segment_orange_mask.m
│   └── compute_region_features.m
│
├── scripts/              
│   ├── prepare_dataset.m
│   ├── train_net.m
│   └── detect_buoys_and_swimmers.m
│
├── data/
│   ├── images/           # obrazy .jpg / .png
│   └── labels/           # adnotacje YOLO Darknet (.txt)
│
├── models/
│   └── net_buoy.mat      # wytrenowana sieć (tworzona przez train_net.m)
│
├── results/
│   ├── figures/          # confusion matrix, przykładowe detekcje (zapisywane automatycznie)
│   └── logs/             # logi z treningu i detekcji (zapisywane automatycznie)
│
└── README.md
