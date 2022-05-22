%% initilization
clear;clc
format long
country_name = 'China';

%% Load Data: pandemic data
path_daily = './data/COVID19/daily_info.csv';
data = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'VariableTypes', {'new_vaccinations', 'double', 'total_vaccinations', 'double'}, ...
        'SelectedVariableNames', {'date', 'new_cases', 'total_cases'} ...
        }, ...
    'SelectTableOptions', { ...
        'location', 'China', 'date', arange(["2020-01-01", "2020-12-31"], 'closed')
        } ...
    ).Table;
data = tableMissingValuesHelper(data, ...
    'VariableNames', {'new_cases', 'total_cases'}, ...
    'Style', 'Increment-Addition' ...
    );
data = StatisticsAnalysis( ...
    'Table', data, ...
    'TagsGenerateOptions', { ...
        'CustomTagFunction', {[0 1 1], 'Centralized', @(x,y)(x{:,1}-tsnanmean(x{:,1}))/tsnanstd(x{:,1})}, ...
        'QuickStyle', {'MissingCount'; 'Centralized'} ...
        }...
    ).Table;
Centralized = data.Properties.CustomProperties.Centralized;

%% Load Data: country data
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

% Dealing with missing data
for col = 1:13
    row = ismissing(properties(:,col));
    properties(row,:) = [];
    countries(row,:) = [];
end
properties = table2array(properties(:,3:end));
[properties, ~] = mapminmax(properties');
properties = properties';

m = 0;
for row = 1:size(countries,1)
    a = countries{row,1};
    if strcmp(a{1,1},country_name)
        m = row;
    end
end
% obtain relevant values
values = properties(m,:)';

%% Settings and Training
% Here using total_cases, values to predict new_cases

YSeq = Centralized{2}';
XSeq = zeros(1+size(values,1),size(Centralized{3}',2));
for col = 1:size(Centralized{3}',2)
    XSeq(2:end, col) = values;
end
XSeq(1,:) = Centralized{3}';
%%
trainLength = floor(0.5*size(XSeq,2));
XtrainSeq = XSeq(:,1:trainLength);
YtrainSeq = YSeq(1:trainLength);
XtestSeq = XSeq(:,trainLength+1:end);
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