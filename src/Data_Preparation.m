function [XSeq_all, YSeq_all] = Data_Preparation(country_names, randomize)

% Some preparation
path = './data/COVID19/country.csv';
[~, properties] = Divide_types();

% Load Data: training set
XSeq_all = [];
YSeq_all = [];

for country_name = country_names

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
    XSeq_all = [XSeq_all,XSeq];
    YSeq_all = [YSeq_all,YSeq];
end

muY = mean(YSeq_all);
sigY = std(YSeq_all);
YSeq_all = (YSeq_all - muY)/sigY;
XSeq_all(2:5,:) = (XSeq_all(2:5,:) - muY)/sigY;
XSeq_all = XSeq_all(:,1:end-4);
YSeq_all = YSeq_all(:,5:end);

% Randomize
if randomize
    r = randperm(size(XSeq_all,2));
    XSeq_all = XSeq_all(:,r);
    YSeq_all = YSeq_all(:,r);
end
end