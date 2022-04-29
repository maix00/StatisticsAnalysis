# StatisticsAnalysis



## Part I:  Table Import and Visualization

```matlab:Code
path_country = './data/COVID19/country.csv';
path_daily = './data/COVID19/daily_info.csv';
% country = readtable(path_country); daily = readtable(path_country)
```

### **A. COVID-19 Daily Cases Example** ###

**Step 1: _Import Detection_** Initializing ***`StatisticsAnalysis`*** by parameter ***`'TablePath'`*** and operating it with its method **`DetectImport`**, you can get one of its properties, *`DetectedImportOptions`*.

> *`DetectImport`* is realized by the function ***`detectImportOptions`***.

```matlab
DIO = StatisticsAnalysis( ...
    'TablePath', path_daily, ...
    'ImportOptions', { ...
        'VariableTypes', { ...
            'new_vaccinations', 'double'; ...
            'total_vaccinations', 'double' ...
            }...
        } ...
    ).DetectImport.DetectedImportOptions;
[DIO.VariableNames', DIO.VariableTypes']
```

Checking the detected type or class of each variable to be imported by command `[DIO.VariableNames', DIO.VariableTypes']`, one would immediately find out that the class of the variable `new_vaccinations` and `total_vaccinations` were mistakenly detected as `'char'`, mainly because there were plenty of days when no vaccinations were conducted, causing missing values as `0x0 char` in the table. In light of this situation, one can alter the initialization of ***`StatisticsAnalysis`*** with another parameter ***`ImportOptions`***, which accecpts input with class of `'cell'`,  whose first column consists of the properties to be altered in *`obj.DetectedImportOptions`*, and the second column specific new values to these properties, and sometimes a more nested `'cell'`, just as the example above. The final detected class of variables to be imported were listed below.

```text:Output
ans = 13x2 cell    
'location'          'char'      
'continent'         'char'      
'date'              'datetime'  
'new_cases'         'double'    
'total_cases'       'double'    
'new_tests'         'double'    
'total_tests'       'double'    
'positive_rate'     'double'    
'new_vaccinations'  'double'    
'total_vaccinations''double' 
```

**Step 2: _Table Import_** This step can be further divided into three sub-steps, in order to save energies or time for table import, and to cater to the specific requirements we encounter in data analysis.

Suppose we only need to analyze the daily data of France from date `2020-01-01` to date `2020-12-31` and from date `2021-04-01` to date `2022-04-01`. In order to save energies, we decide to import data with only variables `'location'` and `'date'` ( **Step 2.1** ), from which we will find out the row indexes `'FirstLast'` of the tuples that meet our requirements ( **Step 2.2** ). At last we import table of only these rows and with other optional requirements ( **Step 2.3** ).

**Step 2.1**: To do so, we initialize ***`StatisticsAnalysis`*** just as below, with parameters of *`'TablePath'`*, *`'DetectedImportOptions'`* (the `DIO` in Step 1) and *`'ImportOptions'`*, the last one with the property to be altered as `'SelectedVariableNames'`. Then we operate it with its method **`ImportTable`**.

**Step 2.2**: To select table, and to get the row indexes, we use the function ***`selectable`***, with outputs `[table, row_index_logical_map, row_index_from_first_to_last]`. The last one would be the one we will need in the next step, with the form like `{[3, 3], [23, 56], [90, 100]}` of class like `1xN cell`. In  ***`selectable`***, we specify the selection requirements with one cell parameter in form of `{Var1, Req1; Var2, Req2}`. When a specific requirement is of multiple parts, just as the `date` in this example, we put it as `{subReq1; subReq2}`. Class ***`arrange`*** states the class of a range, with default boundary `[]` instead of `[)`, `(]` or `()`.

```matlab
[~, ~, FirstLast] = selecttable( ...
    StatisticsAnalysis( ... Table Import
            'TablePath', path_daily, ...
            'DetectedImportOptions', DIO, ...
            'ImportOptions', {'SelectedVariableNames', {'location', 'date'} } ...
        ).ImportTable, ...
    { ... Table Selection
        'location', 'France'; ... Country
        'date', { ...
            arange(datetime('2020-01-01'), datetime('2020-12-31')); ...
            arange(datetime('2021-04-01'), datetime('2022-04-01')) ...
            } ... Time Range
        } ...
    );
```

**Step 2.3**: Import the Table `CDaily`. Suppose we only need to analyze the variables `new_cases` and `new_vaccinations`. We initialize ***`StatisticsAnalysis`*** with parameters *`'TablePath'`*, *`'DetectedImportOptions'`* the former `DIO`, and *`'ImportOptions'`* with properties of `obj.DetectedImportOptions` to be alted including `'DataLines'` and `'SelectedVariableNames'`. 

**Atention: **Parameter * `'ImportOptions'`*  accepts alteration requirements with multiple parts (e.g. row indexes). When doing so, one need make sure it is a double-nested cell, like `{{[3, 3], [23, 56], [90, 100]}}` or a `1x1 cell` with element of `1xN cell`.

```matlab
CDaily = StatisticsAnalysis( ... Table Import
    'TablePath', path_daily, ...
    'DetectedImportOptions', DIO, ...
    'ImportOptions', { ...
        'DataLines', {FirstLast}; ... 
        'SelectedVariableNames', {'date', 'new_cases', 'new_vaccinations'}...
        }...
    ).TagsGenerate( ... Continuity Tag and Properties Addition
        'CustomTagName', {'sexy', [0 1 1]; 'dance', [1 0 0]}, ...
        'TagContinuity', [0 1 1] ...
    ).addProp;
```

**Step 3: _Statistics Analysis with Tags output, and Append them to Table as its CustomProperties_** We use the method **`TagsGenerate`** to conduct statistics analysis on the whole imported table and then output tags, and use the method **`addProp`** to add them to the Table as its `Properties.CustomProperties`. 

Respectively, we have methods **`OneTagGenerate`** and **`rmProp`**, the former operated on one variable, and the latter remove existing CustomProperties. What's more, `obj.DetecedImportOptions`, `obj.Tags` itself, and table `Size` are also added to the Table as its `Properties.CustomProperties`. These are 'table'-scale custom properties.

As contrast, ***`obj.Tags`*** contains all 'variable'-scale properties and can be output as a `table`, `cell` or a `struct`, default `table`. The first five rows of `Tags` are mandatory -- `TagNames`, `UniqueCount`, `ValueClass`, `MissingCount` and `MissingRatio`. The other rows of `Tags` are automatically generated by ***`StatisticsAnalysis`*** as specified by `TagNames` and its functions.

* Compulsory Tagnames: `'unique'`, `'invariant'`, `'logical'`, `'categorical'`, `'discrete'` and `'continous'`. One variable can only have one of these six tagnames. Only `'categorical'` and `'continous'` can be designated manully, as others can be detected automatically.
* Compulsory Tagname Functions: `'logical'` has `LogicalRatioFirstValue` and `LogicalRatio`; `'categorical'` has `CategoricalRation`, and `'continuous'`has `Min`, `Max`, `Mean`, `Median`, `Mode` and `Variance`.
* Custom Tagnames: Can be added by parameter `'CustomTagNames'` in methods **`TagsGenerate`** and **`OneTagGenerate`**, in the form of `{TagName, logical_map; others}`.
* Custom Tagname Functions: Can be added by parameter `'CustomTagFunction'` in methods **`TagsGenerate`** and **`OneTagGenerate`**, in the form of `{TagName, TagFuncName, func_handle; others}`.

**Step 4: _Visualization_**

```matlab
cdaily = table2timetable(CDaily);
figure(1); plot(usdaily21, 'new_cases'); datetick x;
```

![Project_images/figure_0.png
](./Project_images/figure_0.png
)

```matlab
figure(2); stackedplot(cdaily);
```

![Project_images/figure_1.png
](./Project_images/figure_1.png
)

```matlab
cdaily.Properties
```

The properties of the table of addition looks like this.

```text:Output
ans = 
  TimetableProperties with properties:
               Description: ''
                  UserData: []
            DimensionNames: {'date'  'Variables'}
             VariableNames: {'new_cases'  'new_vaccinations'}
      VariableDescriptions: {}
             VariableUnits: {}
        VariableContinuity: []
                  RowTimes: [709x1 datetime]
                 StartTime: 2020-01-24
                SampleRate: NaN
                  TimeStep: NaN
   Custom Properties (access using t.Properties.CustomProperties.<name>):
     DetectedImportOptions: [1x1 matlab.io.text.DelimitedTextImportOptions]
                      Tags: [14x3 table]
                      Size: [709 3]
                  TagNames: {{2x1 cell}  {2x1 cell}}
               UniqueCount: {[659]  [370]}
                ValueClass: {'double'  'double'}
              MissingCount: {[10]  [339]}
              MissingRatio: {[0.014104372355430]  [0.478138222849083]}
    LogicalRatioFirstValue: {[]  []}
              LogicalRatio: {[]  []}
          CategoricalRatio: {[]  []}
                       Min: {[0]  [369]}
                       Max: {[502507]  [970144]}
                      Mean: {[3.671889984825493e+04]  [3.518466108108108e+05]}
                    Median: {[9635]  [291937]}
                      Mode: {[0]  [369]}
                  Variance: {[5.919111784415486e+09]  [6.422557538565301e+10]}
```

### B. Performance Examples ###

**Example 1: ** Original TagNames and ValueTypes would be preserved amid a second StatisticsAnalysis and conveyed to the second output Tags.

```matlab
% Preserve Original Tags
StatisticsAnalysis('Table', CDaily).TagsGenerate.addProp.Properties
```

```text:Output
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
     DetectedImportOptions: [1x1 matlab.io.text.DelimitedTextImportOptions]
                      Tags: [14x3 table]
                      Size: [709 3]
                  TagNames: {{2x1 cell}  {2x1 cell}  {2x1 cell}}
               UniqueCount: {[709]  [659]  [370]}
                ValueClass: {'datetime'  'double'  'double'}
              MissingCount: {[0]  [10]  [339]}
              MissingRatio: {[0]  [0.014104372355430]  [0.478138222849083]}
    LogicalRatioFirstValue: {[]  []  []}
              LogicalRatio: {[]  []  []}
          CategoricalRatio: {[]  []  []}
                       Min: {[]  [0]  [369]}
                       Max: {[]  [502507]  [970144]}
                      Mean: {[]  [3.671889984825493e+04]  [3.518466108108108e+05]}
                    Median: {[]  [9635]  [291937]}
                      Mode: {[]  [0]  [369]}
                  Variance: {[]  [5.919111784415486e+09]  [6.422557538565301e+10]}
```

**Example 2: ** Some Compulsory TagNames can be altered. Custom TagName Functions can be added to inherited Custom TagNames.

```matlab
% Custom Tag Function
StatisticsAnalysis('Table', CDaily).TagsGenerate( ...
    'TagContinuity', [0 1 1], ...
    'CustomTagFunction', { ...
        'sexy', 'SexyVariance', @(x,y)tsnanvar(x{:,:})/2; ...
        'dance', 'DancingRaio', @(x,y)'p' ...
        } ...
    ).addProp.Properties
```

```text:Output
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
     DetectedImportOptions: [1x1 matlab.io.text.DelimitedTextImportOptions]
                      Tags: [16x3 table]
                      Size: [709 3]
                  TagNames: {{2x1 cell}  {2x1 cell}  {2x1 cell}}
               UniqueCount: {[709]  [659]  [370]}
                ValueClass: {'datetime'  'double'  'double'}
              MissingCount: {[0]  [10]  [339]}
              MissingRatio: {[0]  [0.014104372355430]  [0.478138222849083]}
    LogicalRatioFirstValue: {[]  []  []}
              LogicalRatio: {[]  []  []}
          CategoricalRatio: {[]  []  []}
                       Min: {[]  [0]  [369]}
                       Max: {[]  [502507]  [970144]}
                      Mean: {[]  [3.671889984825493e+04]  [3.518466108108108e+05]}
                    Median: {[]  [9635]  [291937]}
                      Mode: {[]  [0]  [369]}
                  Variance: {[]  [5.919111784415486e+09]  [6.422557538565301e+10]}
              SexyVariance: {[]  [2.825692462706288e+09]  [3.211278769282650e+10]}
               DancingRaio: {'p'  []  []}
```

**Example 3: ** Method **`OneTagGenerate`** can have the same performance as above. What's more, redundant statistical indicators will be removed.

```matlab
% Custom Tag Function (One Tag Generate)
[~,~,temp] = StatisticsAnalysis('Table',CDaily).OneTagGenerate('new_vaccinations', 'TagContinuity', 1)
```

| |1|2|
|:--:|:--:|:--:|
|1|2x1 cell|'TagNames'|
|2|370|'UniqueCount'|
|3|'double'|'ValueClass'|
|4|339|'MissingCount'|
|5|0.478138222849083|'MissingRatio'|
|6|369|'Min'|
|7|970144|'Max'|
|8|3.518466108108108e+0...|'Mean'|
|9|291937|'Median'|
|10|369|'Mode'|
|11|6.422557538565301e+1...|'Variance'|
|12|'new_vaccinations'|'VariableName'|

**Example 4: ** Function ***`selecttable`*** can remove those no-more-applicable tags when the table has damaged row number after selection.

```matlab:Code
selecttable(CDaily, {'date', datetime('2020-01-24')}).Properties.CustomProperties.Tags
```

| |date|new_cases|new_vaccinations|
|:--:|:--:|:--:|:--:|
|1 TagNames|[{'unique'};{'dan...|[{'continuous'};{...|[{'continuous'};{...|
|2 ValueClass|'datetime'|'double'|'double'|



## Part II:  還沒開始想呢
