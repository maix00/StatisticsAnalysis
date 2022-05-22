%% initilization
clear;clc
format long

XSeq_all = [];
YSeq_all = [];

% Load Data


path = './data/COVID19/country.csv';
properties = StatisticsAnalysis( ...
    'TablePath', path...
    ).Table;
countries = StatisticsAnalysis( ...
    'TablePath', path, ...
    'ImportOptions', { ...
    'SelectedVariableNames', {'location'}...
    }...
    ).Table;

for country_name = {'France','China','Australia'}

    % Load Data: pandemic data
    path_daily = './data/COVID19/daily_info.csv';
    data = StatisticsAnalysis( ...
        'TablePath', path_daily, ...
        'ImportOptions', { ...
            'VariableTypes', {'new_vaccinations', 'double', 'total_vaccinations', 'double'}, ...
            'SelectedVariableNames', {'date', 'new_cases', 'total_cases'} ...
        }, ...
        'SelectTableOptions', { ...
            'location', country_name, ... Country
            'date', arange(["2020-01-01", "2020-12-31"], 'closed') ...
            } ...
        ).Table;
    data = tableMissingValuesHelper(data, ...
        'VariableNames', {'new_cases', 'total_cases'}, ...
        'Style', 'Increment-Addition', ...
        'InterpolationStyle', 'LinearRound'...
        );


    properties = StatisticsAnalysis( ...
        'TablePath', path...
        ).Table;
    countries = StatisticsAnalysis( ...
        'TablePath', path, ...
        'ImportOptions', { 'SelectedVariableNames', {'location'} }...
        ).Table;
    % Dealing with missing data
    for col = 1:13
        row = ismissing(properties(:,col));
        properties(row,:) = [];
        countries(row,:) = [];
    end
    properties = table2array(properties(:,3:end));
    for col = 1:size(properties, 2)
        sigP = std(properties(:, col));
        muP = mean(properties(:, col));
        properties(:,col) = (properties(:,col)-muP)/sigP;
    end

    m = 0;
    for row = 1:size(countries,1)
        a = countries{row,1};
        if strcmp(a{1,1},country_name)
            m = row;
        end
    end
    % obtain relevant values
    values = properties(m,:)';

    % Settings and Training
    % Here using total_cases, values to predict new_cases

    YSeq = table2array(data(:,2))';
    XSeq = zeros(5+size(values,1),size(YSeq,2));
    for col = 1:size(YSeq,2)
        XSeq(6:end, col) = values;
    end

    total_cases = table2array(data(:,3))';
    muX = mean(total_cases);
    sigX = std(total_cases);
    total_cases = (total_cases - muX)/sigX;
    XSeq(1,:) = total_cases;
    for ii = 1:(size(YSeq,2)-3)
        XSeq(2:5,ii) = YSeq(ii:ii+3)';
    end
    XSeq_all = [XSeq_all,XSeq];
    YSeq_all = [YSeq_all,YSeq];
end

muY = mean(YSeq_all);
sigY = std(YSeq_all);
YSeq_all = (YSeq_all - muY)/sigY;

% Randomize
r = randperm(size(XSeq_all,2));
XSeq_all = XSeq_all(:,r);
YSeq_all = YSeq_all(:,r);
%%
trainLength = floor(0.95*size(XSeq,2));
XtrainSeq = XSeq_all(:,1:trainLength);
YtrainSeq = YSeq_all(1,5:trainLength+4);
XtestSeq = XSeq_all(:,trainLength+1:end-4);
YtestSeq = YSeq_all(1,trainLength+5:end);

net = PredictNet(XtrainSeq,YtrainSeq);

%% Testing
net = resetState(net);
net = predictAndUpdateState(net,XtrainSeq);
numTimeStepsTest = size(XtestSeq,2);
YPred = zeros(1,numTimeStepsTest);
for i = 1:numTimeStepsTest
    [net,YPred(1,i)] = predictAndUpdateState(net,XtestSeq(:,i),'ExecutionEnvironment','gpu');
end

YtestSeq = (YtestSeq*sigY) + muY;
YPred = (YPred*sigY) + muY;

plot(YPred);
hold on;
plot(YtestSeq);
legend('Pred','Real')