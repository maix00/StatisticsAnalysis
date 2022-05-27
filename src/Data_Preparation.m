function [XSeq_train, YSeq_train, XSeq_test, YSeq_test, muY, sigY] = Data_Preparation(country_names, ...
                                                            smoothen)

% Some preparation
[~, properties] = Divide_types(3,6);

% Load Data: training set
XSeq_train = cell(size(country_names,2),1);
YSeq_train = cell(size(country_names,2),1);
XSeq_test = cell(size(country_names,2),1);
YSeq_test = cell(size(country_names,2),1);
muY = cell(1,size(country_names,2));
sigY = cell(1,size(country_names,2));

for t = 1:size(country_names,2)
    country_name = country_names{1,t};

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
    if smoothen
        kernel = [1/4,1/4,1/4,1/4];
        YSeq = conv(kernel,YSeq);
        YSeq = YSeq(:,1:end-3);
    end
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

    muY{1,t} = mean(YSeq);
    sigY{1,t} = std(YSeq);
    YSeq = (YSeq - muY{1,t})/sigY{1,t};
    XSeq(2:5,:) = (XSeq(2:5,:) - muY{1,t})/sigY{1,t};
    XSeq = XSeq(:,1:end-4);
    YSeq = YSeq(:,5:end);
    length = 0.8*size(XSeq,2);
    XSeq_train{t, 1} = XSeq(:,1:length);
    YSeq_train{t, 1} = YSeq(:,1:length);
    XSeq_test{t, 1} = XSeq(:,length+1:end);
    YSeq_test{t, 1} = YSeq(:,length+1:end);
end
end