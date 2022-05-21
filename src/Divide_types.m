% Load Data and Dealing with missing values
clc; clear;
format long
path_daily = './data/COVID19/daily_info.csv';
record_countries = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'SelectedVariableNames', {'location'} ...
        }...
    ).Table;
record_countries = unique(table2array(record_countries));

path = './data/COVID19/country.csv';
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

% PCA, picking the first five characters 
coeff = pca(data);

char = data*coeff;
char_cut = char(:,5);
num_types = 5;
idx = kmeans(char_cut,num_types);
histogram(idx);

country_type = cell(num_types,1);
for ii = 1:size(idx,1)
    type = idx(ii,1);
    if ismember(countries(ii,1),record_countries)
        country_type{type,1} = [country_type{type,1}, countries(ii,1)];
    end
end