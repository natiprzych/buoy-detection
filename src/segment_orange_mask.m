function mask = segment_orange_mask(I)
    I_double = im2double(I);
    hsv = rgb2hsv(I_double);
    
    orange = (hsv(:,:,1) > 0.03 & hsv(:,:,1) < 0.15) & hsv(:,:,2) > 0.4;
    red = (hsv(:,:,1) < 0.05 | hsv(:,:,1) > 0.95) & hsv(:,:,2) > 0.4;
    
    dark_objects = hsv(:,:,3) < 0.2 & hsv(:,:,2) < 0.3; 
    
    combinedMask = orange | red | dark_objects;
    
    mask = bwareaopen(combinedMask, 20); 
    mask = imclose(mask, strel('disk', 5));
end