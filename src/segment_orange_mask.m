function mask = segment_orange_mask(I)
    if ~isa(I, 'double')
        I = im2double(I);
    end
    
    hsv = rgb2hsv(I);
    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);
    
    red1   = (H < 0.05);
    red2   = (H > 0.95);
    orange = (H > 0.03 & H < 0.15);
    
    colorMask = (red1 | red2 | orange) & S > 0.4 & V > 0.2;
    
    mask = bwareaopen(colorMask, 30);
    se = strel('disk', 2);
    mask = imopen(mask, se);
    mask = imclose(mask, se);
end
