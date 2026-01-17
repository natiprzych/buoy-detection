function anns = read_yolo_annotations(labelPath, imageWidth, imageHeight)
    anns = struct('classId', {}, 'bbox', {});
    
    if ~exist(labelPath, 'file')
        return;
    end
    
    data = readmatrix(labelPath);
    
    if isempty(data)
        return;
    end
    
    if size(data, 2) ~= 5
        error('Plik %s nie wygląda na format YOLO (5 kolumn).', labelPath);
    end
    
    numObjs = size(data, 1);
    anns(numObjs).classId = [];
    anns(numObjs).bbox    = [];
    
    for i = 1:numObjs
        classId = data(i, 1); % class ID
        cxRel   = data(i, 2); % bbox: wspolrzedna x lewego gornego rogu
        cyRel   = data(i, 3); % bbox: wspolrzedna y lewego gornego rogu
        wRel    = data(i, 4); % bbox: szerokosc w pikselach
        hRel    = data(i, 5); % bbox: wysokosc w pikselach
        
        cx = cxRel * imageWidth;
        cy = cyRel * imageHeight;
        bw = wRel  * imageWidth;
        bh = hRel  * imageHeight;
        
        x = cx - bw/2;
        y = cy - bh/2;
        
        anns(i).classId = classId;
        anns(i).bbox    = [x, y, bw, bh];
    end
end
