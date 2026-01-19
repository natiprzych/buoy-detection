function [bboxes, labels, numBuoys, numSwimmers] = detect_objects_logic(I, net)
% DETECT_OBJECTS_LOGIC Główna logika detekcji (niezależna od GUI)
%
% WEJŚCIA:
%   I   - obraz wejściowy (macierz HxWx3)
%   net - wytrenowana sieć neuronowa (obiekt network)
%
% WYJŚCIA:
%   bboxes      - macierz Nx4 z ramkami (Bounding Boxes)
%   labels      - wektor Nx1 (1 = boja, 0 = pływak)
%   numBuoys    - liczba wykrytych boi
%   numSwimmers - liczba wykrytych pływaków

    % 1. Segmentacja pomarańczowej maski
    % (Zakładam, że masz funkcję segment_orange_mask w folderze src)
    orangeMask = segment_orange_mask(I);

    % 2. Znajdź spójne regiony
    [L, num] = bwlabel(orangeMask);

    % --- Obsługa przypadku, gdy nic nie znaleziono ---
    if num == 0
        bboxes = [];
        labels = [];
        numBuoys = 0;
        numSwimmers = 0;
        return;
    end

    % 3. Oblicz cechy dla każdego regionu
    stats = regionprops(L, 'BoundingBox');
    features = zeros(num, 5);
    validIdx = false(num, 1);

    for k = 1:num
        regionMask = (L == k);
        % (Zakładam, że masz funkcję compute_region_features w folderze src)
        feat = compute_region_features(regionMask);
        if ~isempty(feat)
            features(k, :) = feat;
            validIdx(k) = true;
        end
    end

    % --- Jeśli znaleziono plamy, ale żadna nie ma poprawnych cech ---
    if ~any(validIdx)
        bboxes = [];
        labels = [];
        numBuoys = 0;
        numSwimmers = 0;
        return;
    end

    % 4. Klasyfikacja przez sieć neuronową
    featuresValid = features(validIdx, :);
    Xnew = featuresValid.';
    
    % !!! WAŻNE: Tutaj używamy przekazanego 'net', a nie 'app.Net' !!!
    Ynew = net(Xnew);
    
    YnewBin = Ynew > 0.5;

    % 5. Przygotuj wstępne bounding boxy
    idxValid = find(validIdx);
    numValid = numel(idxValid);
    bboxes = zeros(numValid, 4);
    for i = 1:numValid
        k = idxValid(i);
        bb = stats(k).BoundingBox;
        bboxes(i, :) = bb;
    end

    isBuoy = YnewBin == 1;
    isSwimmer = YnewBin == 0;

    % 6. LOGIKA FILTROWANIA (Twoja autorska logika)
    
    % A. Usuń pływaków wewnątrz boi
    keep = true(numValid, 1);

    for i = 1:numValid
        if ~isSwimmer(i)
            continue;
        end

        bbS = bboxes(i, :);
        cx = bbS(1) + bbS(3)/2;
        cy = bbS(2) + bbS(4)/2;

        for j = 1:numValid
            if ~isBuoy(j)
                continue;
            end

            bbB = bboxes(j, :);
            if cx >= bbB(1) && cx <= bbB(1)+bbB(3) && ...
               cy >= bbB(2) && cy <= bbB(2)+bbB(4)
                keep(i) = false;
                break;
            end
        end
    end

    % B. Usuń małe boje wewnątrz większych
    for i = 1:numValid
        if ~isBuoy(i) || ~keep(i)
            continue;
        end

        bbSmall = bboxes(i, :);
        areaSmall = bbSmall(3) * bbSmall(4);

        for j = 1:numValid
            if i == j || ~isBuoy(j) || ~keep(j)
                continue;
            end

            bbBig = bboxes(j, :);
            areaBig = bbBig(3) * bbBig(4);

            if areaSmall >= areaBig
                continue;
            end

            if bbSmall(1) >= bbBig(1) && ...
               bbSmall(2) >= bbBig(2) && ...
               bbSmall(1)+bbSmall(3) <= bbBig(1)+bbBig(3) && ...
               bbSmall(2)+bbSmall(4) <= bbBig(2)+bbBig(4)
                keep(i) = false;
                break;
            end
        end
    end

    % 7. Zastosuj filtrowanie i przygotuj wynik
    YnewBin = YnewBin(keep);
    bboxes = bboxes(keep, :);

    % 8. Policz ostateczne wyniki
    isBuoy = YnewBin == 1;
    isSwimmer = YnewBin == 0;
    numBuoys = sum(isBuoy);
    numSwimmers = sum(isSwimmer);

    % 9. Etykiety wyjściowe
    labels = YnewBin;
end