function [bboxes, labels, numBuoys, numSwimmers] = detect_objects_logic(I, net)
    orangeMask = segment_orange_mask(I);

    [L, num] = bwlabel(orangeMask);

    if num == 0
        bboxes = [];
        labels = [];
        numBuoys = 0;
        numSwimmers = 0;
        return;
    end

    stats = regionprops(L, 'BoundingBox');
    validIdx = false(num, 1);
    all_feats = cell(num, 1);

    for k = 1:num
        regionMask = (L == k);
        
        bb = stats(k).BoundingBox;
        x0 = max(1, floor(bb(1)));
        y0 = max(1, floor(bb(2)));
        x1 = min(size(I,2), ceil(bb(1)+bb(3)));
        y1 = min(size(I,1), ceil(bb(2)+bb(4)));
        
        I_crop = I(y0:y1, x0:x1, :);
        regionMaskCrop = regionMask(y0:y1, x0:x1);

        feat = compute_region_features(regionMaskCrop, I_crop);
        
    if ~isempty(feat)
            all_feats{k} = feat; 
            validIdx(k) = true;
        end
    end

    if ~any(validIdx)
        bboxes = [];
        labels = [];
        numBuoys = 0;
        numSwimmers = 0;
        return;
    end

    featuresValid = cell2mat(all_feats(validIdx)); 
    Xnew = featuresValid.';

    Ynew = net(Xnew);
    
    YnewBin = Ynew > 0.5;

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
            
            padW = bbB(3) * 0.15;
            padH = bbB(4) * 0.15;
            
            extendedBB = [bbB(1)-marginW, bbB(2)-marginH, ...
                          bbB(3)+2*marginW, bbB(4)+2*marginH];

            if cx >= extendedBB(1) && cx <= extendedBB(1)+extendedBB(3) && ...
               cy >= extendedBB(2) && cy <= extendedBB(2)+extendedBB(4)
                keep(i) = false;
                break;
            end
        end
    end

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

    YnewBin = YnewBin(keep);
    bboxes = bboxes(keep, :);

    isBuoy = YnewBin == 1;
    isSwimmer = YnewBin == 0;
    numBuoys = sum(isBuoy);
    numSwimmers = sum(isSwimmer);

    labels = YnewBin;
end