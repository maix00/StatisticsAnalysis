data = readtable('../data/COVID19/daily_info.csv');
outputSeq = table2array(data(1:818,5))';
inputSeq = table2array(data(1:818,13))';

trainLength = floor(0.4*size(inputSeq,2));
XtrainSeq = zeros(2,trainLength);
XtrainSeq(1,:) = inputSeq(1:trainLength);
XtrainSeq(2,:) = inputSeq(trainLength:2*trainLength-1);
YtrainSeq = outputSeq(2:trainLength+1);
XtestSeq = inputSeq(trainLength+1:end-1);
YtestSeq = outputSeq(trainLength+2:end);

numFeatures = 2;
numResponses = 1;

numHiddenUnits = 96*3;

layers = [...
sequenceInputLayer(numFeatures)
lstmLayer(numHiddenUnits)
fullyConnectedLayer(10)
reluLayer
fullyConnectedLayer(numResponses)
regressionLayer];

options = trainingOptions('adam', ...
'MaxEpochs',500, ...
'GradientThreshold',1, ...
'InitialLearnRate',0.005, ...
'LearnRateSchedule','piecewise', ...
'LearnRateDropPeriod',125, ...
'LearnRateDropFactor',0.2, ...
'ExecutionEnvironment','gpu',...
'Verbose',0, ...
'Plots','training-progress');

% Training
net = trainNetwork(XtrainSeq,YtrainSeq,layers,options);

% Testing
