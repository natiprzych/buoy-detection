clear; clc;

load('data/buoy_dataset.mat','X','T');

[numSamples,numFeatures] = size(X);

Xmat = X.';
Trow = T.';

N = size(Xmat,2);
idx = randperm(N);
Xmat = Xmat(:,idx);
Trow = Trow(:,idx);

hiddenLayerSize = 8; 
net = patternnet(hiddenLayerSize); 

net.trainFcn = 'trainbr'; 

net.divideParam.trainRatio = 0.8;
net.divideParam.testRatio  = 0.2;

[net,tr] = train(net,Xmat,Trow);

Y_all    = net(Xmat);
Y_allbin = Y_all > 0.5;
acc_all  = mean(Y_allbin == Trow);

fprintf('Calowita accuracy: %.2f %%\n',100*acc_all);

testInd = tr.testInd;
Xtest   = Xmat(:,testInd);
Ttest   = Trow(:,testInd);

Ytest    = net(Xtest);
Ytestbin = Ytest > 0.5;

acc_test = mean(Ytestbin == Ttest);
fprintf('Test accuracy: %.2f %%\n',100*acc_test);

if ~exist('models','dir')
    mkdir('models');
end
save(fullfile('models','net_buoy.mat'),'net');

if ~exist('results','dir')
    mkdir('results');
end
figDir = fullfile('results','figures');
logDir = fullfile('results','logs');
if ~exist(figDir,'dir')
    mkdir(figDir);
end
if ~exist(logDir,'dir')
    mkdir(logDir);
end

figure;
Tcat = categorical(Ttest);
Ycat = categorical(Ytestbin);
confusionchart(Tcat,Ycat);
title(sprintf('Macierz pomylek (accuracy test = %.2f %%)',100*acc_test));
confFigPath = fullfile(figDir,'confusion_matrix.png');
saveas(gcf,confFigPath);

dt    = datetime('now');
dtStr = char(dt);
ts    = char(datetime('now','Format','yyyyMMdd_HHmmss'));


logPath = fullfile(logDir, 'history_log.txt');
fid = fopen(logPath, 'a'); 
if fid ~= -1
    algName = net.trainFcn;
   
    fprintf(fid, '\n====================================================\n');
    fprintf(fid, 'SESJA TRENINGOWA: %s\n', datestr(now));
    fprintf(fid, '----------------------------------------------------\n');
    
    fprintf(fid, 'KONFIGURACJA:\n');
    fprintf(fid, '  Algorytm:      %s\n', algName);
    fprintf(fid, '  Liczba neuronow: %d\n', hiddenLayerSize); 
    fprintf(fid, '  Liczba probek:   %d\n', numSamples);
    fprintf(fid, '  Liczba cech:     %d\n', numFeatures);

    fprintf(fid, '  Podzial (T/V/T): %.2f / %.2f / %.2f\n', ...
        net.divideParam.trainRatio, net.divideParam.valRatio, net.divideParam.testRatio);
    
    fprintf(fid, 'WYNIKI:\n');
    fprintf(fid, '  Accuracy (ALL):  %.4f\n', acc_all);
    fprintf(fid, '  Accuracy (TEST): %.4f\n', acc_test);
    
    fclose(fid);
end

fprintf('Dopisano wyniki do: %s\n', logPath);
disp('Zapisano models/net_buoy.mat');
disp(['Zapisano ',confFigPath]);
