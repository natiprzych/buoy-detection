function visualize_results(ax, bboxes, labels)
% VISUALIZE_RESULTS Rysuje TYLKO ramki (bez legendy, bo jest w GUI)

    % 1. Naprawa proporcji (to zostawiamy, bo jest ważne)
    axis(ax, 'image'); 
    disableDefaultInteractivity(ax);
    
    if isempty(bboxes)
        return;
    end

    hold(ax, 'on');

    % --- USUNIĘTO SEKCJĘ "DUMMY PLOTS" I "LEGEND" ---
    % Nie potrzebujemy jej, bo legendę zrobisz "na sztywno" w App Designerze

    % 2. Rysowanie ramek
    for i = 1:size(bboxes, 1)
        bb = bboxes(i, :);
        
        if labels(i) == 1
            % BOJA
            rectangle(ax, 'Position', bb, 'EdgeColor', 'g', ...
                      'LineWidth', 2, 'LineStyle', '-');
            
        else
            % PŁYWAK
            rectangle(ax, 'Position', bb, 'EdgeColor', 'b', ...
                      'LineWidth', 2, 'LineStyle', '-');
           
        end
    end

    hold(ax, 'off');
end