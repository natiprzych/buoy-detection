clear; clc;

load('data/buoy_dataset.mat','X','T');

[numSamples,numFeatures] = size(X);

Xmat = X.';
Trow = T.';

N = size(Xmat,2);
idx = randperm(N);
Xmat = Xmat(:,idx);
Trow = Trow(:,idx);

hiddenLayerSize = 10;
net = feedforwardnet(hiddenLayerSize);

net.trainFcn = 'trainlm';

net.divideParam.trainRatio = 0.7;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;

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

logPath = fullfile(logDir,['train_log_',ts,'.txt']);
fid = fopen(logPath,'w');
if fid ~= -1
    fprintf(fid,'Data: %s\n',dtStr);
    fprintf(fid,'Liczba probek: %d\n',numSamples);
    fprintf(fid,'Liczba cech: %d\n',numFeatures);
    fprintf(fid,'Train ratio: %.2f\n',net.divideParam.trainRatio);
    fprintf(fid,'Val ratio: %.2f\n',net.divideParam.valRatio);
    fprintf(fid,'Test ratio: %.2f\n',net.divideParam.testRatio);
    fprintf(fid,'Accuracy (all): %.4f\n',acc_all);
    fprintf(fid,'Accuracy (test): %.4f\n',acc_test);
    fclose(fid);
end

disp('Zapisano models/net_buoy.mat');
disp(['Zapisano ',confFigPath]);
disp(['Zapisano ',logPath]);
