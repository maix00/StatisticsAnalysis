# StatisticsAnalysis

Note: This repository was initially intended for a course project for COMP110031@ Fudan University. See [this project page](https://github.com/users/maix00/projects/1).

## Part I:  Table Import and Visualization

```matlab:Code
path_country = './data/COVID19/country.csv';
path_daily = './data/COVID19/daily_info.csv';
% country = readtable(path_country); daily = readtable(path_country)
```

### **COVID-19 Daily Cases Example** ###

***---------------------------------- ALL IN ONE STEP ----------------------------------***

**Step 1: _Select Table Rows + Revise detectImportOptions + Import Table + Statistics Analysis + Tags Generation and Properties Apend_** ***ALL IN ONE STEP***

```matlab
SA = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'VariableTypes', { ...
            'new_vaccinations', 'double';
            'total_vaccinations', 'double' ...
            }; ...
        'SelectedVariableNames', {'date', 'new_cases', 'new_vaccinations'}; ...
        'DataLines', [4850, Inf] ...
        }, ...
    'SelectTableOptions', { ...
        'location', 'France'; ... Country
        'date', { ...
            arange(["2020-01-01", "2020-12-31"], 'openright'); ...
            arange(["2021-04-01", "2022-04-01"], 'openright') ...
            } ... Time Range
        }, ... % Will Automatically Select Table Before Importing Table
     'TagsGenerateOptions', { ...
        'CustomTagName', {'sexy', [0 1 1]; 'dance', [1 0 0]}; ...
        'TagContinuity', [0 1 1]; ...
        'CustomTagFunction', { ...
            'sexy', 'SexyVariance', @(x,y)tsnanvar(x{:,:})/2; ...
            'dance', 'DancingRatio', @(x,y)'p' ...
            } ...
        }...
    )
```

The output would be:

```matlab
SA =
  StatisticsAnalysis with properties:

                     Tags: [16x3 table]
                    Table: [680x3 table]
                TablePath: './data/COVID19/daily_info.csv'
            ImportOptions: {2x2 cell}
    detectedImportOptions: [1x1 matlab.io.text.DelimitedTextImportOptions]
```

With Table Properties:

```matlab
SA.Table.Properties
```

```matlab
ans =
  TableProperties with properties:
               Description: ''
                  UserData: []
            DimensionNames: {'Row'  'Variables'}
             VariableNames: {'date'  'new_cases'  'new_vaccinations'}
      VariableDescriptions: {}
             VariableUnits: {}
        VariableContinuity: []
                  RowNames: {}
   Custom Properties (access using t.Properties.CustomProperties.<name>):
     detectedImportOptions: [1x1 matlab.io.text.DelimitedTextImportOptions]
                      Tags: [16x3 table]
                      Size: [680 3]
                  TagNames: {{2x1 cell}  {2x1 cell}  {2x1 cell}}
               UniqueCount: {[680]  [655]  [368]}
                ValueClass: {'datetime'  'double'  'double'}
              MissingCount: {[0]  [10]  [312]}
              MissingRatio: {[0]  [0.014705882352941]  [0.458823529411765]}
    LogicalRatioFirstValue: {[]  []  []}
              LogicalRatio: {[]  []  []}
          CategoricalRatio: {[]  []  []}
                       Min: {[]  [0]  [369]}
                       Max: {[]  [502507]  [970144]}
                      Mean: {[]  [3.668579083969466e+04]  [3.536070027173913e+05]}
                    Median: {[]  [9635]  [294834]}
                      Mode: {[]  [0]  [369]}
                  Variance: {[]  [5.931609913000527e+09]  [6.399656932431878e+10]}
              SexyVariance: {[]  [2.913312163955580e+09]  [3.199828466215940e+10]}
              DancingRatio: {'p'  []  []}
```

![Performance1
](./readme/readme_images/figure_-1.png
)

**Step 2: _Visualization_**

```matlab
daily = table2timetable(SA.Table);
figure(1); plot(daily, 'new_cases'); datetick x;
```

![timetable_plot1
](./readme/readme_images/figure_0.png
)

```matlab
figure(2); stackedplot(daily);
```

![timetable_stackedplot
](./readme/readme_images/figure_1.png
)

## Part II:  ??????????????????
