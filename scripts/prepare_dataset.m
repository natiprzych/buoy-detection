clear; clc;

imageDir = fullfile('data','images');
labelDir = fullfile('data','labels');
imageExt = '*.jpg';

imageFiles = dir(fullfile(imageDir, imageExt));

buoyClassId    = 0;
swimmerClassId = 1;

allFeatures = [];
allLabels   = [];

for i = 1:numel(imageFiles)
    imgName = imageFiles(i).name;
    imgPath = fullfile(imageDir, imgName);
    
    I = imread(imgPath);
    [H, W, ~] = size(I);
    
    [~, baseName, ~] = fileparts(imgName);
    labelPath = fullfile(labelDir, [baseName, '.txt']);
    
    anns = read_yolo_annotations(labelPath, W, H);
    if isempty(anns)
        continue;
    end
    
    orangeMask = segment_orange_mask(I);
    
    for a = 1:numel(anns)
        classId = anns(a).classId;
        
        if classId ~= buoyClassId && classId ~= swimmerClassId
            continue;
        end
        
        bbox = anns(a).bbox;
        
        x0 = max(1, round(bbox(1)));
        y0 = max(1, round(bbox(2)));
        x1 = min(W, round(bbox(1) + bbox(3) - 1));
        y1 = min(H, round(bbox(2) + bbox(4) - 1));
        
        if x1 <= x0 || y1 <= y0
            continue;
        end
        
        objMaskCrop = orangeMask(y0:y1, x0:x1);
        feat = compute_region_features(objMaskCrop);
        if isempty(feat)
            continue;
        end
        
        allFeatures(end+1, :) = feat;
        
        if classId == buoyClassId
            allLabels(end+1, 1) = 1;
        else
            allLabels(end+1, 1) = 0;
        end
    end
end

X = allFeatures;
T = allLabels;

save('buoy_dataset.mat', 'X', 'T');

disp('Zapisano buoy_dataset.mat');
disp(['Liczba próbek: ', num2str(size(X,1))]);
disp(['Liczba cech na próbkę: ', num2str(size(X,2))]);
