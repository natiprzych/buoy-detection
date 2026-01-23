function feat = compute_region_features(mask, I_crop)

    mask = logical(mask);
    if ~any(mask, 'all') || isempty(I_crop)
        feat = []; return;
    end

    stats = regionprops(mask, 'Area', 'Eccentricity', 'Solidity', 'Perimeter', 'BoundingBox');
    if isempty(stats), feat = []; return; end
    [~, idx] = max([stats.Area]);
    s = stats(idx);

    geom_feat = [s.Area, s.BoundingBox(3)/s.BoundingBox(4), s.Eccentricity, s.Solidity, (4*pi*s.Area)/(s.Perimeter^2 + eps)];

    I_hsv = rgb2hsv(im2double(I_crop));
    h_channel = I_hsv(:,:,1);
    s_channel = I_hsv(:,:,2);
    v_channel = I_hsv(:,:,3);

    pixels_h = h_channel(mask);
    pixels_s = s_channel(mask);
    pixels_v = v_channel(mask);

    color_feat = [mean(pixels_h), mean(pixels_s), mean(pixels_v), std(pixels_h)];

    I_res = imresize(I_crop, [32 32]);
    
    if size(I_res, 3) == 3
        I_gray = rgb2gray(I_res);
    else
        I_gray = I_res;
    end
    
    glcm = graycomatrix(I_gray, 'Offset', [0 1; -1 1]);
    stats_glcm = graycoprops(glcm, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});
    texture_feat = [mean(stats_glcm.Contrast), mean(stats_glcm.Correlation), mean(stats_glcm.Energy), mean(stats_glcm.Homogeneity)];

    feat = [geom_feat, color_feat, texture_feat];
end