clear; clc;

data = load(fullfile('models','net_buoy.mat'),'net');
net = data.net;

[fn,fp] = uigetfile({'*.jpg;*.png','Obrazy (*.jpg, *.png)'},'Wybierz obraz');
if isequal(fn,0)
    disp('Anulowano.');
    return;
end

imgPath = fullfile(fp,fn);
I = imread(imgPath);
[H,W,~] = size(I);

orangeMask = segment_orange_mask(I);
[L,num] = bwlabel(orangeMask);

numBuoys = 0;
numSwimmers = 0;
idxValid = [];
YnewBin = [];
bboxes = [];

if num == 0
    figure; imshow(I);
    title('Brak kandydatow (maski kolorowej).');
    return;
end

if num > 0
    stats = regionprops(L,'BoundingBox');
    validIdx = false(num,1);
    all_feats = cell(num, 1); %
    
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
        figure; imshow(I);
        title('Brak obiektow z poprawnymi cechami.');
        return;
    end
    
    featuresValid = cell2mat(all_feats(validIdx));
    Xnew = featuresValid.';
    
    Ynew = net(Xnew);
    YnewBin = Ynew > 0.5;
    
    idxValid = find(validIdx);
    numValid = numel(idxValid);
    bboxes = zeros(numValid,4);
    for i = 1:numValid
        k = idxValid(i);
        bb = stats(k).BoundingBox;
        bboxes(i,:) = bb;
    end
    
    isBuoy    = YnewBin == 1;
    isSwimmer = YnewBin == 0;
    
    keep = true(numValid,1);
    
    for i = 1:numValid
        if ~isSwimmer(i)
            continue;
        end
        
        bbS = bboxes(i,:);
        cx = bbS(1) + bbS(3)/2;
        cy = bbS(2) + bbS(4)/2;
        
        for j = 1:numValid
            if ~isBuoy(j)
                continue;
            end
            
            bbB = bboxes(j,:);
            if cx >= bbB(1) && cx <= bbB(1)+bbB(3) && ...
               cy >= bbB(2) && cy <= bbB(2)+bbB(4)
                keep(i) = false;
                break;
            end
        end
    end


    for i = 1:numValid
        if ~isBuoy(i) || ~keep(i)
            continue;
        end
        
        bbSmall = bboxes(i,:);
        areaSmall = bbSmall(3)*bbSmall(4);
        
        for j = 1:numValid
            if i == j || ~isBuoy(j) || ~keep(j)
                continue;
            end
            
            bbBig = bboxes(j,:);
            areaBig = bbBig(3)*bbBig(4);
            
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
    bboxes  = bboxes(keep,:);
    idxValid = idxValid(keep);
    
    isBuoy    = YnewBin == 1;
    isSwimmer = YnewBin == 0;
    
    numBuoys    = sum(isBuoy);
    numSwimmers = sum(isSwimmer);
    
    if ~exist('results','dir')
        mkdir('results');
    end
    figDir = fullfile('results','figures');
    logDir = fullfile('results','logs');
    if ~exist(figDir,'dir')
        mkdir(figDir);
    end
    if ~exist(logDir,'dir')
        mkdir(logDir);
    end
end


figure; imshow(I); hold on;
if ~isempty(idxValid)
    for i = 1:numel(YnewBin)
        bb = bboxes(i,:);
        if YnewBin(i)
            rectangle('Position',bb,'EdgeColor','g','LineWidth',2);
        else
            rectangle('Position',bb,'EdgeColor','b','LineWidth',2);
        end
    end
end
title(sprintf('Boje: %d   Ludzie: %d', numBuoys, numSwimmers));


[~,baseName,~] = fileparts(fn);

dt    = datetime('now');
dtStr = char(dt);
ts    = char(datetime('now','Format','yyyyMMdd_HHmmss'));

detFigName = sprintf('%s_detection_%s.png',baseName,ts);
detFigPath = fullfile(figDir,detFigName);
saveas(gcf,detFigPath);

logPath = fullfile(logDir,sprintf('detect_log_%s.txt',ts));
fid = fopen(logPath,'w');
if fid ~= -1
    fprintf(fid,'Data: %s\n',dtStr);
    fprintf(fid,'Plik obrazu: %s\n',imgPath);
    fprintf(fid,'Boje: %d\n',numBuoys);
    fprintf(fid,'Ludzie: %d\n',numSwimmers);
    fclose(fid);
end

disp(['Zapisano ',detFigPath]);
disp(['Zapisano ',logPath]);
