%% Load Data
clc;clear;
data = readtable('../data/COVID19/daily_info.csv');

%% Settings and Training
% Here using total_cases to predict new_cases
XSeq = table2array(data(:,5));
YSeq = table2array(data(:,4));
[nx,~] = find(isnan(XSeq));
[ny,~] = find(isnan(YSeq));
DelN = unique([nx;ny]);
for ii = DelN
    XSeq(ii,:) = [];
    YSeq(ii,:) = [];
end
XSeq = XSeq';
YSeq = YSeq';
muX = mean(XSeq);
sigX = std(XSeq);
XSeq = (XSeq-muX)/sigX;
muY = mean(YSeq);
sigY = std(YSeq);
YSeq = (YSeq-muY)/sigY;


trainLength = floor(0.5*size(XSeq,2));
XtrainSeq = XSeq(:,1:trainLength);
YtrainSeq = YSeq(1:trainLength);
XtestSeq = XSeq(1,trainLength+1:end);
YtestSeq = YSeq(1,trainLength+1:end);

net = PredictNet(XtrainSeq,YtrainSeq);

%% Testing
net = resetState(net);
net = predictAndUpdateState(net,XtrainSeq);
numTimeStepsTest = numel(XtestSeq);
YPred = zeros(1,numTimeStepsTest);
for i = 1:numTimeStepsTest
[net,YPred(1,i)] = predictAndUpdateState(net,XtestSeq(1,i),'ExecutionEnvironment','gpu');
end

YtestSeq = (YtestSeq*sigY) + muY;
YPred = (YPred*sigY) + muY;

plot(YPred);
hold on;
plot(YtestSeq);
legend('Pred','Real')