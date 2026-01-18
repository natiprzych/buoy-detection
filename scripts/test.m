clear; clc;

if ~exist('data/buoy_dataset.mat', 'file')
    error('Brak pliku buoy_dataset.mat! Uruchom najpierw prepare_dataset.m.');
end
load('data/buoy_dataset.mat', 'X', 'T');
Xmat = X.';
Trow = T.';

netTypes = {'patternnet', 'feedforwardnet', 'cascadeforwardnet'}; % 3 typy sieci
algos    = {'trainbr', 'trainlm', 'trainscg'};                   % 3 algorytmy
neurons  = [4, 5, 8];                                            % 3 warianty neuronów
trainRatios = 0.70:0.05:0.80;                                    % Skok co 5% (70%, 75%, 80%)
numRuns  = 30;                                                   % 30 prób na każde ustawienie

logPath = fullfile('results', 'logs', 'ultimate_experiment_log.txt');
fid = fopen(logPath, 'a');
if fid == -1, error('Błąd pliku logowania.'); end

totalCombos = numel(netTypes) * numel(algos) * numel(neurons) * numel(trainRatios) * numRuns;
fprintf('Rozpoczynam %d treningów. To potrwa kilka godzin.\n', totalCombos);

for nType = netTypes
    for aType = algos
        for hSize = neurons
            for trRatio = trainRatios
                
                if strcmp(aType{1}, 'trainbr')
                    vRatio = 0.00; 
                    teRatio = 1 - trRatio;
                else
                    vRatio = 0.10; 
                    teRatio = 1 - trRatio - vRatio;
                end
                
                fprintf('Test: %s | %s | N:%d | T:%.2f\n', nType{1}, aType{1}, hSize, trRatio);
                
                for r = 1:numRuns
                    idx = randperm(size(Xmat, 2));
                    X_run = Xmat(:, idx);
                    T_run = Trow(:, idx);

                    if strcmp(nType{1}, 'patternnet')
                        net = patternnet(hSize);
                    elseif strcmp(nType{1}, 'feedforwardnet')
                        net = feedforwardnet(hSize);
                    else
                        net = cascadeforwardnet(hSize);
                    end

                    net.trainFcn = aType{1};
                    net.divideParam.trainRatio = trRatio;
                    net.divideParam.valRatio   = vRatio;
                    net.divideParam.testRatio  = teRatio;
                    net.trainParam.showWindow  = false;

                    [net, tr] = train(net, X_run, T_run);
                    
                    acc_all = mean((net(X_run) > 0.5) == T_run);
                    X_test = X_run(:, tr.testInd);
                    T_test = T_run(:, tr.testInd);
                    acc_test = mean((net(X_test) > 0.5) == T_test);
                    
                    fprintf(fid, '====================================================\n');
                    fprintf(fid, 'DATA: %s | PROBA: %d/30\n', datestr(now), r);
                    fprintf(fid, 'KONFIGURACJA:\n');
                    fprintf(fid, '  Siec:      %s\n', nType{1});
                    fprintf(fid, '  Algorytm:  %s\n', aType{1});
                    fprintf(fid, '  Neurony:   %d\n', hSize);
                    fprintf(fid, '  Ratio:     %.2f / %.2f / %.2f\n', trRatio, vRatio, teRatio);
                    fprintf(fid, 'WYNIKI:\n');
                    fprintf(fid, '  ACC_ALL:   %.4f\n', acc_all);
                    fprintf(fid, '  ACC_TEST:  %.4f\n', acc_test);
                    fprintf(fid, '\n');
                end
            end
        end
    end
end

fclose(fid);
disp('EKSPERYMENT ZAKOŃCZONY. Wyniki w ultimate_experiment_log.txt');