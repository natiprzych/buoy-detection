function visualize_results(ax, bboxes, labels)
    axis(ax, 'image'); 
    disableDefaultInteractivity(ax);
    
    if isempty(bboxes)
        return;
    end

    hold(ax, 'on');

    for i = 1:size(bboxes, 1)
        bb = bboxes(i, :);
        
        if labels(i) == 1
            % boja
            rectangle(ax, 'Position', bb, 'EdgeColor', 'g', 'LineWidth', 2, 'LineStyle', '-');
            
        else
            % plywak
            rectangle(ax, 'Position', bb, 'EdgeColor', 'b', 'LineWidth', 2, 'LineStyle', '-');
           
        end
    end

    hold(ax, 'off');
end