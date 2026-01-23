clear; clc;

% 1. Ładowanie danych
if ~exist('data/buoy_dataset.mat', 'file')
    error('Brak pliku buoy_dataset.mat! Uruchom najpierw prepare_dataset.m.');
end
load('data/buoy_dataset.mat', 'X', 'T');
Xmat = X.'; % Cechy w wierszach (13 cech)
Trow = T.'; % Etykiety w wierszu

% 2. Parametry eksperymentu
netType = 'patternnet'; 
algo    = 'trainbr'; % Bayesian Regularization (nie wymaga zbioru walidacyjnego)
neuronsRange = [25,26,27,28,29,30,31,32,34,35]; % Testujemy szeroki zakres
numRuns = 10; % Liczba prób dla każdej liczby neuronów (uśrednimy wynik)
trRatio = 0.80; % 80% trening, 20% test

logPath = fullfile('results', 'logs', 'neuron_test_log.txt');
fid = fopen(logPath, 'w'); % 'w' nadpisuje stary plik

resultsSummary = zeros(length(neuronsRange), 1); % Do wykresu

fprintf('Rozpoczynam test optymalnej liczby neuronów...\n');

for i = 1:length(neuronsRange)
    hSize = neuronsRange(i);
    runAcc = zeros(numRuns, 1);
    
    fprintf('Testowanie: %d neuronów... ', hSize);
    
    for r = 1:numRuns
        % Losowy podział danych w każdej próbie
        idx = randperm(size(Xmat, 2));
        X_run = Xmat(:, idx);
        T_run = Trow(:, idx);

        net = patternnet(hSize);
        net.trainFcn = algo;
        
        % trainbr ignoruje valRatio, dzielimy tylko na train i test
        net.divideParam.trainRatio = trRatio;
        net.divideParam.valRatio   = 0.00; 
        net.divideParam.testRatio  = 1 - trRatio;
        
        net.trainParam.showWindow = false;
        net.trainParam.epochs = 500;

        [net, tr] = train(net, X_run, T_run);
        
        % Test na danych, których sieć NIE widziała w trakcie treningu
        X_test = X_run(:, tr.testInd);
        T_test = T_run(:, tr.testInd);
        Y_test = net(X_test);
        acc_test = mean((Y_test > 0.5) == T_test);
        
        runAcc(r) = acc_test;
        
        fprintf(fid, 'Data: %s | Neurony: %d | Proba: %d | Acc: %.4f\n', ...
                datestr(now), hSize, r, acc_test);
    end
    
    avgAcc = mean(runAcc);
    resultsSummary(i) = avgAcc;
    fprintf('Średnie Acc: %.2f%%\n', avgAcc * 100);
end

fclose(fid);

% 3. Generowanie wykresu wynikowego
figure;
plot(neuronsRange, resultsSummary * 100, '-o', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
xlabel('Liczba neuronów w warstwie ukrytej');
ylabel('Średnia dokładność testowa (%)');
title(['Optymalizacja liczby neuronów (', algo, ')']);
saveas(gcf, fullfile('results', 'figures', 'neuron_optimization.png'));

disp('Eksperyment zakończony. Wykres zapisany w results/figures/');