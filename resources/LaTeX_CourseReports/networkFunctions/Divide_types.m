function [country_type, properties] = Divide_types(cut, num_types)
% Load Data and Dealing with missing values

path_daily = './testdata/COVID19/daily_info.csv';
record_countries = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'SelectedVariableNames', {'location'} ...
        }...
    ).Table;
record_countries = unique(table2array(record_countries));

path = './testdata/COVID19/country.csv';
data = StatisticsAnalysis( ...
    'TablePath', path...
    ).Table;
countries = StatisticsAnalysis( ...
    'TablePath', path, ...
    'ImportOptions', { ...
        'SelectedVariableNames', {'location'}...
        }...
    ).Table;

for col = 1:13
    row = ismissing(data(:,col));
    data(row,:) = [];
    countries(row,:) = [];
end

data = table2array(data(:,3:end));
countries = table2array(countries);

for col = 1:size(data,2)
    data(:,col) = (data(:,col)-mean(data(:,col)))/std(data(:,col));
end

% PCA, picking the first five characters 
coeff = pca(data);

char = data*coeff;
char_cut = char(:,1:cut);
idx = kmeans(char_cut,num_types);

properties = cell(size(char,1),2);
for ii = 1:size(char,1)
    properties{ii,1} = countries{ii,1};
    properties{ii,2} = char_cut(ii,:);
end

country_type = cell(num_types,1);
for ii = 1:size(idx,1)
    type = idx(ii,1);
    if ismember(countries(ii,1),record_countries)
        country_type{type,1} = [country_type{type,1}, countries(ii,1)];
    end
end
end

