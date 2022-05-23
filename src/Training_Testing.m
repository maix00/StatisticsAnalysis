%% initilization
clear;clc
format long

% Some preparation
path = './data/COVID19/country.csv';
[country_types, properties] = Divide_types();
countries = StatisticsAnalysis( ...
    'TablePath', path, ...
    'ImportOptions', { ...
    'SelectedVariableNames', {'location'}...
    }...
    ).Table;

%% Load Data: training set
XSeq_train = [];
YSeq_train = [];

for country_name = {'France','Germany','Hungary','Japan'}

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
    m = 0;
    for row = 1:size(properties,1)
        name = properties{row,1};
        if strcmp(name,country_name)
            m = row;
        end
    end
    % obtain relevant values
    values = properties{m,2}';

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
    XSeq_train = [XSeq_train,XSeq];
    YSeq_train = [YSeq_train,YSeq];
end

muY = mean(YSeq_train);
sigY = std(YSeq_train);
YSeq_train = (YSeq_train - muY)/sigY;
XSeq_train(2:5,:) = (XSeq_train(2:5,:) - muY)/sigY;
XSeq_train = XSeq_train(:,1:end-4);
YSeq_train = YSeq_train(:,5:end);
%% Load Data: testing set
XSeq_test = [];
YSeq_test = [];

for country_name = {'Sweden'}

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
    m = 0;
    for row = 1:size(properties,1)
        name = properties{row,1};
        if strcmp(name,country_name)
            m = row;
        end
    end
    % obtain relevant values
    values = properties{m,2}';

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
    XSeq_test = [XSeq_test,XSeq];
    YSeq_test = [YSeq_test,YSeq];
end

muY = mean(YSeq_test);
sigY = std(YSeq_test);
YSeq_test = (YSeq_test - muY)/sigY;
XSeq_test(2:5,:) = (XSeq_test(2:5,:) - muY)/sigY;
XSeq_test = XSeq_test(:,1:end-4);
YSeq_test = YSeq_test(:,5:end);
%% Training

net = PredictNet(XSeq_train,YSeq_train);

%% Testing

net = resetState(net);
net = predictAndUpdateState(net,XSeq_train);
numTimeStepsTest = size(XSeq_test,2);
YPred = zeros(1,numTimeStepsTest);
for i = 1:numTimeStepsTest
    [net,YPred(1,i)] = predictAndUpdateState(net,XSeq_test(:,i),'ExecutionEnvironment','gpu');
end

rmse = norm(YPred-YSeq_test)/norm(YSeq_test);
disp(rmse)

plot(YPred);
hold on;
plot(YSeq_test);
legend('Pred','Real')