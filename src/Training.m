%% Load Data
clc; clear;
format long
path_daily = './data/COVID19/daily_info.csv';
data = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'VariableTypes', { ...
            'new_vaccinations', 'double';
            'total_vaccinations', 'double' ...
            }; ...
        'SelectedVariableNames', {'date', 'new_cases', 'total_cases'} ...
        }, ...
    'SelectTableOptions', { ...
        'location', 'China'; ... Country
        'date', { ...
            arange(["2020-01-01", "2020-12-31"], 'closed')
            } ... Time Range
        } ... % Will Automatically Select Table Before Importing Table
    ).Table;

%% Settings and Training
% Here using total_cases to predict new_cases
data = tableMissingValuesHelper(data, ...
    'VariableNames', {'new_cases', 'total_cases'}, ...
    'Style', 'Increment-Addition' ...
    );
data = StatisticsAnalysis( ...
    'Table', data, ...
    'TagsGenerateOptions', { ...
        'TagContinuity', [0 1 1]; ...
        'CustomTagName', {'centralization', [0 1 1]}; ...
        'CustomTagFunction', { ...
            'centralization', 'Centralized', @(x,y)(x{:,1}-tsnanmean(x{:,1}))/tsnanstd(x{:,1}); ...
            }; ...
        'QuickStyle', {'MissingCount'; 'Centralized'} ...
        }...
    ).Table;
Centralized = data.Properties.CustomProperties.Centralized;
XSeq = Centralized{3}';
YSeq = Centralized{2}';

%%
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