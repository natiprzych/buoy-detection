function feat = compute_region_features(mask)
    mask = logical(mask);
    
    if ~any(mask, 'all')
        feat = [];
        return;
    end
    
    CC = bwconncomp(mask);
    stats = regionprops(CC, 'Area', 'Eccentricity', 'Solidity', ...
                             'Perimeter', 'BoundingBox');
    
    if isempty(stats)
        feat = [];
        return;
    end
    
    areas = [stats.Area];
    [~, idx] = max(areas);
    s = stats(idx);
    
    A   = s.Area;
    ecc = s.Eccentricity;
    sol = s.Solidity;
    P   = s.Perimeter;
    
    if P <= 0
        circ = 0;
    else
        circ = 4*pi*A / (P^2);
    end
    
    bb = s.BoundingBox;
    w  = bb(3);
    h  = bb(4);
    aspect = w / h;
    
    feat = [A, aspect, ecc, sol, circ];
end
