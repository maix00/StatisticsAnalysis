classdef StatisticsAnalysis < handle
    % STATISTICSANALYSIS analyzes tables/timetables.
    %
    %  %-------------------------------------------------------------------
    %   STATISTICSANALYSIS Properties:
    %     Import Settings Properties:
    %       TablePath
    %       ImportOptions
    %       DetectedImportOptions
    %       Table % tables can be directly imported.
    %       
    %     Analysis Report Properties:
    %       Tags
    %       
    %  %-------------------------------------------------------------------
    %   STATISTICSANALYSIS Methods and Functions (Outside):
    %     Creation:
    %       <a href = "matlab:help StatisticsAnalysis/StatisticsAnalysis">StatisticsAnalysis</a>(varargin) -> obj
    %
    %     Table Import and its Setting:
    %       <a href = "matlab:help DetectImport">DetectImport</a>(obj) -> obj
    %       <a href = "matlab:help ImportTable">ImportTable</a>(obj) -> table
    %     
    %     Statistics Analysis and Table Properties Addition:
    %       obj.<a href = "matlab:help TagsGenerate">TagsGenerate</a>(varargin) -> obj
    %       obj.<a href = "matlab:help OneTagGenerate">OneTagGenerate</a>(thisFieldName, varargin) -> [thisTag, thisTagHelper, thisCell]
    %       obj.<a href = "matlab:help addProp">addProp</a> -> table
    %           OR obj.addProp(table1) -> table2
    %       obj.<a href = "matlab:help rmProp">rmProp</a>(varargin) -> [obj, table]
    %
    %   Operation Examples see <a href = "matlab:help StatisticsAnalysis/StatisticsAnalysis">StatisticsAnalysis</a>.
    %
    %  %-------------------------------------------------------------------
    %   Default Tags include:
    %       - TagNames: 'unique', 'invariant', 'logical', 'categorical',
    %                    'discrete', 'continuous'
    %       - UniqueCount 
    %       - ValueClass
    %       - MissingCount & MissingRatio
    %       - LogicalRatioFirstValue & LogicalRatio
    %       - CategoricalRatio
    %       - Min, Max, Mean, Median, Mode, Variance (for Continuous Variable)
    %   
    %   % These Values were automatically calculated by <a href = "matlab:help TagsGenerate">TagsGenerate</a>.
    %       - Custom tags supported by parameters in <a href = "matlab:help TagsGenerate">TagsGenerate</a> and <a href = "matlab:help OneTagGenerate">OneTagGenerate</a>
    %         as CustomTagNames and CustomTagFunction.
    %
    %  %-------------------------------------------------------------------
    %    Author: WANG Yi-yang
    %      Date: 28-Apr-2022
    %   Version: v20220429

    properties
        TablePath
        Table
        ImportOptions
        DetectedImportOptions % detectImportOptions(TablePath)
        Tags = {};
        OneTagFlag = true;
    end

    methods
        function obj = StatisticsAnalysis(varargin)
            % StatisticsAnalysis/StatisticsAnalysis starts a statistics analysis of 
            %   a table/timetable.
            %   
            %   obj = StatisticsAnalysis(varargin)
            %       'TablePath', 'Table', 'ImportOptions', 'DetectedImportOptions'
            %
            % ---------------------------------------------------------------------
            %   Parameters Example:    
            %       - TablePath:                              './Project/table.csv'
            %       - Table:                                   table (in Workspace)
            %       - ImportOptions:                  {'DateLines', {{[2, 3]}}; ...
            %                                   'SelectedVariableNames', {'date'} }
            %       - DetectedImportOptions:                     DIO (in Workspace)
            %
            % ---------------------------------------------------------------------
            %   Operation Examples:
            %    (Step 1) Edit Import Options.
            %       DIO = StatisticsAnalysis( ...
            %               'TablePath', PATH, ...
            %               'ImportOptions', OPTION_CELL ...
            %           ).DetectImport.DetectedImportOptions;
            %       % To preview VariableTypes, use
            %       %   [DIO.VariableNames', DIO.VariableTypes'];
            %   
            %    (Step 2) Import Table (and Selection)
            %       Table = StatisticsAnalysis( ...
            %               'TablePath', PATH, ...
            %               'DetectedImportOptions', DIO, ...
            %               'ImportOptions', OPTION_CELL ...
            %           ).<a href = "matlab:help ImportTable">ImportTable</a>
            %       % To select tuples, use <a href = "matlab:help selecttable">selecttable</a>.
            %       %   [Table, Logical, Range] = <a href = "matlab:help selecttable">selecttable</a>(Table, Request);
            %   
            %    (Step 3) Import Table based on former Selection, and undertake 
            %             Statistics Analysis, with outputs added in form of Tags.
            %       Table = StatisticsAnalysis( ...
            %               'TablePath', PATH, ...
            %               'DetectedImportOptions', DIO, ...
            %               'ImportOpions', {'DataLines', {Range}} ...
            %           ).<a href = "matlab:help TagsGenerate">TagsGenerate</a>( ...
            %                   'TagContinuity', [0 1 0] ...
            %               ).<a href = "matlab:help addProp">addProp</a>
            %       % To preview Tags, use
            %       %   Table.Properties; or,
            %       %   Table.Properties.CustomPropertis.Tags

            %   WANG Yi-yang 28-Apr-2022

            ips = inputParser;
            ips.addParameter('TablePath', {}, @(x)validateattributes(x, {'char', 'string'}, {}));
            ips.addParameter('Table', {}, @(x)validateattributes(x, {'table'}, {}));
            ips.addParameter('ImportOptions', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('DetectedImportOptions', {}, @(x)true);
            ips.addParameter('SelectTableOptions', {}, @(x)true);
            ips.addParameter('SelectTableBeforeImport', false, @(x)true);
            ips.addParameter('TagsGenerate', false, @(x)true);
            ips.addParameter('TagsGenerateOptions', {}, @(x)true);
            ips.parse(varargin{:})
            %
            obj.TablePath = ips.Results.TablePath;
            obj.Table = ips.Results.Table;
            % DetectedImportOptions Initialize
            if isempty(ips.Results.DetectedImportOptions), if ~isempty(obj.TablePath), obj.DetectedImportOptions = detectImportOptions(obj.TablePath); end
            else, obj.DetectedImportOptions = ips.Results.DetectedImportOptions; end
            % Import Options
            obj.ImportOptions = ips.Results.ImportOptions;
            % Select Table and Update ImportOptions before Import the required Table
            if ~isempty(ips.Results.SelectTableOptions) && ips.Results.SelectTableBeforeImport, obj = obj.DetectedImportOptionsUpdateFromSelectTable(ips.Results.SelectTableOptions); end
            % Import Options Un-nest
            obj = obj.ImportOptionsUnnest;
            % Tags Generation
            if ~isempty(ips.Results.TagsGenerateOptions), temp = transpose(ips.Results.TagsGenerateOptions); obj.Table = obj.TagsGenerate(temp{:}).addProp;
            elseif ips.Results.TagsGenerate, obj.Table = obj.TagsGenerate.addProp; end
        end
    end

    methods(Access = private)
        %% Select Table Before Import
        % ---------------------------------------------------------------
        function obj = DetectedImportOptionsUpdateFromSelectTable(obj, SelectTableOptions)
            if ~isempty(SelectTableOptions) && ~isempty(obj.DetectedImportOptions)
                try obj.DetectedImportOptions.SelectedVariableNames = SelectTableOptions(:,1)'; catch; end
                try tempTable = readtable(obj.TablePath, obj.DetectedImportOptions); catch; end
                try tempTable = addprop(tempTable, 'DetectedImportOptions', {'table'}); 
                    tempTable.Properties.CustomProperties.DetectedImportOptions = obj.DetectedImportOptions; catch; end
                try [~, ~, FirstLast] = selecttable(tempTable, SelectTableOptions); 
                    DataLinesOptions = {'DataLines', {FirstLast}}; catch; end
                if isempty(obj.ImportOptions), obj.ImportOptions = DataLinesOptions;
                else, DataLinesMapInImportOptions = strcmp(obj.ImportOptions(:,1), 'DataLines');
                    if ~any(DataLinesMapInImportOptions), obj.ImportOptions = [obj.ImportOptions; DataLinesOptions];
                    else, RowNum = find(DataLinesMapInImportOptions, 1); OldDataLinesOptions = obj.ImportOptions(RowNum, 2);
                        obj.ImportOptions(RowNum, :) = UpdateDataLinesOptionsHelper(OldDataLinesOptions, FirstLast);
                    end
                end
            end
            function New = UpdateDataLinesOptionsHelper(Old, FL) % Old is a 1x1 cell with [n1 n2] 1x2 int matrix.
                ITT = IntervalType('closed'); NewFL = cell(size(FL)); od = arange(); od.bottom = Old{1}(1); od.top = Old{1}(2); od.itt = ITT; od.nar = false; tp = arange(); tp.itt = ITT; tp.nar = false;
                for idx = 1: numel(FL), tp.bottom = FL{idx}(1); tp.top = FL{idx}(2);
                    [~, btm, top] = intersect1D(tp, od, true); if ~isempty(btm) && ~isempty(top), NewFL{idx} = [btm, top]; else, error('No Rows Selected.'); end
                end
                % ar = arange(FL).intervalTypeUpdate('closed'); oldar = arange(Old).intervalTypeUpdate('closed'); newar = intersect(oldar, ar);
                % NewFL = {}; for indx = 1: 1: numel(newar), if ~isempty(newar(indx)), NewFL = [NewFL, {[newar(indx).bottom, newar(indx).top]}]; end; end
                New = {'DataLines', {NewFL}};
            end
        end
    end


    methods
         %% Import Options
         % ---------------------------------------------------------------
        function obj = ImportOptionsUnnest(obj)
            % ImportOptionsUnnest un-nests the ImportOptions.
            %   
            %   obj = ImportOptionsUnnest(obj)
            %
            %   Inside usage. Invoked by <a href = "matlab:help StatisticsAnalysis/StatisticsAnalysis">StatisticsAnalysis</a>.

            %   WANG Yi-yang 28-Apr-2022

            if isempty(obj.ImportOptions)
                % do nothing
            else
                NewCell = {};
                theMap = [];
                theLengthMap = [];
                for indx = 1: 1: size(obj.ImportOptions, 1)
                    thisValue = obj.ImportOptions{indx, 2};
                    if iscell(thisValue)
                        if iscell(thisValue{1})
                            thisValue = thisValue{1}; % {{optA, optB}}, thisValue = {optA, optB}
                            theMap = [theMap, indx];
                            theLengthMap = [theLengthMap, length(thisValue)];
                            obj.ImportOptions{indx, 2} = thisValue; % {opt, optB}
                        end
                    end
                end
                StringFor = "";
                StringEnd = "";
                for indx = 1: 1: size(theMap, 2)
                    thisIndexName = strcat("indx", string(indx));
                    thisStringFor = strcat("for ", thisIndexName, " = 1: 1: ", string(theLengthMap(indx)), "; ");
                    StringFor = strcat(StringFor, thisStringFor);
                    StringEnd = strcat("end; ", StringEnd);
                end
                StringCore = "";
                % thisSettings = obj.ImportOptions; 
                String1 = "thisSettings = obj.ImportOptions; ";
                StringCore = strcat(StringCore, String1);
                String2 = "";
                for indx = 1: 1: size(theMap, 2)
                    thisIndexName = strcat("indx", string(indx));
                    % thisSettings{theMap(indx), 2} = thisSettings{theMap(indx), 2}{thisIndexName};
                    thisString = strcat("thisSettings{", string(theMap(indx)), ", 2} = thisSettings{", string(theMap(indx)), ", 2}{", thisIndexName, "}; ");
                    String2 = strcat(String2, thisString);
                end
                StringCore = strcat(StringCore, String2);
                % NewCell = [NewCell, {thisSettings}];
                StringCore = strcat(StringCore, "NewCell = [NewCell, {thisSettings}]; ");
                AllString = strcat(StringFor, StringCore, StringEnd);
                eval(AllString);
                obj.ImportOptions = NewCell;
            end
        end

        function obj = ImportOptionsUpdate(obj, thisOptionCell)
            % ImportOptionsUpdate updates the DetectedImportOptions.
            %   
            %   obj = ImportOptionsUpdate(obj, OptionCell)
            %
            %   Inside usage. Invoked by <a href = "matlab:help DetectImport">DetectImport</a> and <a href = "matlab:help ImportTable">ImportTable</a>.

            %   WANG Yi-yang 28-Apr-2022

            for subindx = 1: 1: size(thisOptionCell, 1)
                thisProperty = thisOptionCell{subindx, 1};
                thisValue = thisOptionCell{subindx, 2};
                if strcmp(thisProperty, 'VariableTypes')
                    if iscell(thisValue)
                        for indx = 1: 1: size(thisValue, 1)
                            thisField = thisValue{indx, 1};
                            thisType = thisValue{indx, 2};
                            FieldMap = strcmp(obj.DetectedImportOptions.VariableNames, thisField);
                            obj.DetectedImportOptions.(thisProperty){FieldMap} = thisType;
                        end
                    else
                        beep; warning('Syntax Error Warning. ImportOptionsUpdate.');
                    end
                else
                    obj.DetectedImportOptions.(thisProperty) = thisValue;
                end
            end
        end
        
        function obj = DetectImport(obj)
            % DetectImport detects import options.
            %
            %   obj = DetectImport(obj)
            %   obj = obj.DetectImport

            %   WANG Yi-yang 28-Apr-2022

            if ~isempty(obj.TablePath)
                obj.DetectedImportOptions = detectImportOptions(obj.TablePath);
            end
            if ~isempty(obj.ImportOptions)
                Length = length(obj.ImportOptions);
                for indx = 1: 1: Length
                    obj = obj.ImportOptionsUpdate(obj.ImportOptions{indx});
                end
            end
        end


         %% Import Table
         % ---------------------------------------------------------------
        function table = ImportTable(obj)
            % ImportTable imports the table.
            %   
            %   table = ImportTable(obj)
            %   table = obj.ImportTable

            %   WANG Yi-yang 28-Apr-2022
            
            if ~isempty(obj.TablePath)
                if ~isempty(obj.ImportOptions)
                    if isempty(obj.DetectedImportOptions)
                        obj = obj.DetectImport;
                    end
                    Length = length(obj.ImportOptions);
                    union_flag = true;
                    obj = obj.ImportOptionsUpdate(obj.ImportOptions{1});
                    former_variable_names = obj.DetectedImportOptions.SelectedVariableNames;
                    thistable = readtable(obj.TablePath, obj.DetectedImportOptions);
                    tableCell = {thistable};
                    if Length > 1
                        for indx = 2: 1: Length
                            obj = obj.ImportOptionsUpdate(obj.ImportOptions{indx});
                            this_variable_names = obj.DetectedImportOptions.SelectedVariableNames;
                            if ~all(size(former_variable_names)==size(this_variable_names)) || ~all(strcmp(former_variable_names, this_variable_names))
                                union_flag = false;
                            end
                            former_variable_names = this_variable_names;
                            thistable = readtable(obj.TablePath, obj.DetectedImportOptions);
                            tableCell = [tableCell, {thistable}];
                        end
                    end
                    if union_flag
                        table = tableCell{1};
                        for indx = 2: 1: length(tableCell)
                            table = union(table, tableCell{indx}, 'stable');
                        end
                    else
                        table = tableCell;
                    end
                elseif ~isempty(obj.DetectedImportOptions)
                    table = readtable(obj.TablePath, obj.DetectedImportOptions);
                else
                    table = readtable(obj.TablePath);
                end
                if ~isempty(obj.Tags)
                    table = obj.addProp(table);
                end
                if ~iscell(table)
                    try
                        table = addprop(table, 'DetectedImportOptions', {'table'});
                    catch
                        table = rmprop(table, 'DetectedImportOptions');
                        table = addprop(table, 'DetectedImportOptions', {'table'});
                    end
                    table.Properties.CustomProperties.DetectedImportOptions = obj.DetectedImportOptions;
                end
            else
                beep; warning('TablePath is empty.');
            end
        end


         %% Properties Addition and Removal
         % ---------------------------------------------------------------
        function table = addProp(obj, varargin)
            % addProp adds properties from obj.Tags to table.
            %
            %   table = addProp(obj, table)
            %   table = obj.addProp 
            %       (where table is optional, default obj.Tables)

            %   WANG Yi-yang 28-Apr-2022

            ips = inputParser;
            ips.addOptional('table', obj.Table, @(x)true);
            ips.parse(varargin{:})
            table = ips.Results.table;
            if ~isempty(obj.Tags)
                % Adding whole table tags
                try
                    table = rmprop(table, 'Tags');
                    table = rmprop(table, 'Size');
                catch
                    % do nothing
                end
                table = addprop(table, 'Tags', {'table'});
                table = addprop(table, 'Size', {'table'});
                table.Properties.CustomProperties.Tags = obj.Tags;
                table.Properties.CustomProperties.Size = size(obj.Table);
                % Adding variable tags
                AddPropSize = size(obj.Tags.Properties.RowNames,1);
                for indx = 1: 1: AddPropSize
                    thisFieldName = obj.Tags.Properties.RowNames{indx};
                    try
                        table = addprop(table, thisFieldName, 'variable');
                    catch
                        table = rmprop(table, thisFieldName);
                        table = addprop(table, thisFieldName, 'variable');
                    end
                    table.Properties.CustomProperties.(thisFieldName) = obj.Tags{thisFieldName, :};
                end
            else
                warning('Syntax Error Warning. No Tags to add.');
            end
        end

        function [obj, table] = rmProp(obj, varargin)
            % rmProp removes properties from obj.Tables.Properties.CustomProperties.
            %
            %   table = rmProp(obj, varargin)
            %   table = obj.rmProp(varargin)
            %           - 'PreserveTagNames'    default: false

            %   WANG Yi-yang 29-Apr-2022

            ips = inputParser;
            ips.addParameter('PreserveTagNames', false, @(x)true);
            ips.parse(varargin{:})
            Bool = ~isempty(obj.Table) && ~isempty(obj.Table.Properties.CustomProperties.Tags);
            if Bool
                RmList = obj.Table.Properties.CustomProperties.Tags.Properties.RowNames';
                if ips.Results.PreserveTagNames
                    RmList = RmList(2:end);
                end
                obj.Table = rmprop(obj.Table, RmList);
                table = obj.Table;
            end
        end
        
        %% Tags Generation
        % ---------------------------------------------------------------
        function obj = TagsGenerate(obj, varargin)
            % TagsGenerate does statisticsAnalysis and generate tags.
            %
            %   Tags include:
            %       - TagNames: 'unique', 'invariant', 'logical', 'categorical',
            %                    'discrete', 'continuous'
            %       - UniqueCount 
            %       - NaNCount & NaNRatio
            %       - EmptyCount & EmptyRatio
            %       - LogicalRatio
            %       - CategoricalRatio & CategoricalVariance
            %       - Min, Max, Mean, Median, Mode, Variance (for Continuous Tag)
            %
            %   % These Values were automatically calculated by TagsGenerate.
            %       - Custom tags not supported for now.
            %
            %   obj = obj.TagsGenerate(varargin)
            %       'CategoryUpperLimit', 'TagContinuity', 'TagCategory', 'OutputClass'
            %
            %   Examples:
            %       - CategoryUpperLimit:                                            10
            %       - TagContinuity / TagCategory:                          [0 1 0 1 1]
            %       - CustomTagName:                {'TagName', [0 1 0 1 1]; otherName}
            %       - OutputClass:                        'table' or 'cell' or 'struct'
            %       - CustomTagFunction:
            %                           {'TagName', 'funcName', func_handle; otherfunc}
            %                   'TagName' can be 'table' which applied to all TagNames.
            %
            %   For each variable, TagsGenerate would invoke <a href = "matlab:help OneTagGenerate">OneTagGenerate</a>.
            %   Warning: TagsGenerate(obj, varargin) not accepted.

            %   WANG Yi-yang 28-Apr-2022

            ips = inputParser;
            ips.addParameter('CategoryUpperLimit', Inf, @(x)validateattributes(x, {'numeric'}, {}));
            ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
            ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
            ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('OutputClass', 'table', @(x)validateattributes(x, {'char', 'string'}, {}));
            ips.parse(varargin{:})

            % Import Table 
            if isempty(obj.Table)
                obj.Table = obj.ImportTable;
            end
            
            % For each variable, Run OneTagGenerate
            variable_count = length(obj.Table.Properties.VariableNames);
            for indx = 1: 1: variable_count
                obj.OneTagFlag = false;
                % TagContinuity
                if isempty(ips.Results.TagContinuity)
                    TagContinuity = arrayfun(@(x) 0, 1:variable_count);
                else
                    TagContinuity = ips.Results.TagContinuity;
                end
                % TagCategory
                if isempty(ips.Results.TagCategory)
                    TagCategory = arrayfun(@(x) 1, 1:variable_count);
                else
                    TagCategory = ips.Results.TagCategory;
                end
                % CustomTagName
                thisCustomTagName = {};
                if ~isempty(ips.Results.CustomTagName)
                    CustomTagName = ips.Results.CustomTagName;
                    for subindx = 1: 1: size(CustomTagName, 1)
                        thisCustomTagName = [thisCustomTagName; {CustomTagName{subindx,1}, CustomTagName{subindx,2}(indx)}];
                    end
                end
                [temp1, temp2] = obj.OneTagGenerate(obj.Table.Properties.VariableNames{indx}, ... thisFieldName
                    'CategoryUpperLimit', ips.Results.CategoryUpperLimit, ...
                    'TagContinuity', TagContinuity(indx), ...
                    'TagCategory', TagCategory(indx), ...
                    'CustomTagName', thisCustomTagName, ...
                    'CustomTagFunction', ips.Results.CustomTagFunction ...
                    );
                obj.Tags = [obj.Tags; temp1];
                % Recover
                obj.OneTagFlag = true;
            end
            % Output
            try
                switch ips.Results.OutputClass
                    case 'table'
                        obj.Tags = cell2struct(obj.Tags(:,1:end-1), obj.Table.Properties.VariableNames, 1);
                        obj.Tags = struct2table(obj.Tags);
                        obj.Tags.Properties.RowNames = temp2;
                    case 'struct'
                        obj.Tags = cell2struct(obj.Tags(:,1:end-1), obj.Table.Properties.VariableNames, 1);
                    case 'cell'
                        % do nothing
                end
            catch
                warning('Output Tags Syntax Error Warning. TagsGenerate.')
            end
        end

        function [thisTag, thisTagHelper, thisCell] = OneTagGenerate(obj, thisFieldName, varargin)
            % OneTagGenerate generates one tag from one field/variable.
            %
            %   [thisTag, thisTagHelper, thisCell] = obj.OneTagGenerate(thisFieldName, varargin)
            %       'CategoryUpperLimit', 'TagContinuity', 'TagCategory', 'CustomTagName', 'CustomTagFunction'
            %   
            %   Outside and Inside usage. Invoked by <a href = "matlab:help TagsGenerate">TagsGenerate</a>.
            %   Warning: OneTagGenerate(obj, thisFieldName, varargin) not accepted.

            %   WANG Yi-yang 28-Apr-2022

            ips = inputParser;
            ips.addRequired('thisFieldName', @(x)true);
            ips.addParameter('CategoryUpperLimit', Inf, @(x)validateattributes(x, {'numeric'}, {}));
            ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
            ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
            ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.parse(thisFieldName, varargin{:})

            % Preservation
            formerTagsFlag = false;
            if ~isempty(obj.Table)
                try
                    Bool = ~isempty(obj.Table.Properties.CustomProperties.TagNames) ...
                        && ~isempty(obj.Table.Properties.CustomProperties.Tags) ...
                        && any(strcmp(obj.Table.Properties.VariableNames, thisFieldName));
                    if Bool
                        formerTagsFlag = true;
                        formerTagNames = obj.Table.Properties.CustomProperties.Tags{'TagNames',thisFieldName};
                        if iscell(formerTagNames{1})
                            formerTagNames = formerTagNames{1};
                        end
                        try
                            obj.Table = convertvars(obj.Table, thisFieldName, obj.Table.Properties.CustomProperties.Tags{'ValueClass',thisFieldName});
                        catch
                        end
                    end
                catch
                    % do nothing
                end
            end

            % CustomTagFunction
            NoMissing = @(x,y)y{:,1}(~ismissing(string(y{:,1}))&~strcmp(string(y{:,1}),""));
            UniqueCount = @(x,y)size(NoMissing(x,y),1);
            ValueClass = @(x,y)class(nest_index(NoMissing(x,y),1));
            MissingCount = @(x,y)(size(y,1)-size(NoMissing(x,y),1));
            NoMissingSize = @(x,y)size(x,1)-MissingCount(x,y);
            SerialValueString = @(x,y,z)nest_index(string(NoMissing(x,y)),z);
            StringValueRatio = @(x,y,z)sum(strcmp(string(x{:,1}),z))/NoMissingSize(x,y);
            LogicalRatioFirstValue = @(x,y)StringValueRatio(x,y,SerialValueString(x,y,1));
            LogicalRatio = @(x,y){SerialValueString(x,y,1),LogicalRatioFirstValue(x,y);SerialValueString(x,y,2),1-LogicalRatioFirstValue(x,y)};
            CategoricalRatio = @(x,y)[arrayfun(@(w)SerialValueString(x,y,w), 1:NoMissingSize(x,y), 'UniformOutput', false)', arrayfun(@(w){StringValueRatio(x,y,SerialValueString(x,y,w))}, 1:NoMissingSize(x,y))'];
            DefaultTagFunction = {
                'table', 'UniqueCount', UniqueCount;
                'table', 'ValueClass', ValueClass;
                'table', 'MissingCount', MissingCount;
                'table', 'MissingRatio', @(x,y)MissingCount(x,y)/size(x,1);
                'logical', 'LogicalRatioFirstValue', LogicalRatioFirstValue;
                'logical', 'LogicalRatio', LogicalRatio;
                'categorical', 'CategoricalRatio', CategoricalRatio;
                'continuous', 'Min', @(x,y)tsnanmin(double(string(y{:,1})));
                'continuous', 'Max', @(x,y)tsnanmax(double(string(y{:,1})));
                'continuous', 'Mean', @(x,y)tsnanmean(double(string(y{:,1})));
                'continuous', 'Median', @(x,y)tsnanmedian(double(string(y{:,1})));
                'continuous', 'Mode', @(x,y)tsnanmode(double(string(y{:,1})));
                'continuous', 'Variance', @(x,y)tsnanvar(double(string(y{:,1})))
                };
            CustomTagFunction = [DefaultTagFunction; ips.Results.CustomTagFunction];

            % Import Table
            if isempty(obj.Table) || (~isempty(obj.Table) && ~any(strcmp(obj.Table.Properties.VariableNames, thisFieldName)))
                ImportOptionsEmptyFlag = false;
                if isempty(obj.ImportOptions)
                    ImportOptionsEmptyFlag = true;
                    obj.ImportOptions = {{'SelectedVariableNames', {thisFieldName}}};
                else
                    NonEmptyLog = obj.ImportOptions;
                    thisIndx = [];
                    for indx = 1: 1: size(obj.ImportOptions{1}, 1)
                        if strcmp(obj.ImportOptions{1}{indx,1}, 'SelectedVariableNames')
                            thisIndx = indx;
                        end
                    end
                    for indx = 1: 1: size(obj.ImportOptions, 2)
                        if ~isempty(thisIndx)
                            obj.ImportOptions{indx}(thisIndx,:) = [];
                        end
                        obj.ImportOptions{indx} = [obj.ImportOptions{indx}; {'SelectedVariableNames', {thisFieldName}}];
                    end
                end
                obj.Table = obj.ImportTable;
                % Recover
                if ImportOptionsEmptyFlag
                    obj.ImportOptions = {};
                else
                    obj.ImportOptions = NonEmptyLog;
                end
            end
            thisColumnTable = obj.Table(:, thisFieldName);
            thisUniqueColumnTable = unique(thisColumnTable);
            unique_count = UniqueCount(thisColumnTable, thisUniqueColumnTable);
            tuple_count = size(thisColumnTable, 1);
            
            % Tag Names
            if ~formerTagsFlag
                if (ips.Results.TagContinuity == 1) 
                    thisTagName = 'continuous';
                elseif unique_count == 2
                    thisTagName = 'logical';
                elseif unique_count == tuple_count
                    thisTagName = 'unique';
                elseif (unique_count > 2) && (unique_count <= ips.Results.CategoryUpperLimit) && (ips.Results.TagCategory == 1)
                    thisTagName = 'categorical';
                elseif (unique_count > ips.Results.CategoryUpperLimit) && (ips.Results.TagCategory == 0)
                    thisTagName = 'discrete';
                elseif unique_count == 1
                    thisTagName = 'invariant';
                end
            else
                NameCell = {'continuous', 'logical', 'unique', 'categorical', 'discrete', 'invariant'};
                for indx = 1: 1: size(NameCell, 2)
                    if any(strcmp(formerTagNames, NameCell{indx}))
                        thisTagName = NameCell{indx};
                    end
                end
            end
            % Custom Tag Names
            if ~isempty(ips.Results.CustomTagName)
                CustomTagName = ips.Results.CustomTagName;
                if any(cell2mat(CustomTagName(:,2)))
                    thisTagName = {thisTagName};
                    for indx = 1: 1: size(CustomTagName,1)
                        if CustomTagName{indx,2} == 1
                            thisTagName = [thisTagName; CustomTagName(indx,1)];
                        end
                    end
                end
            end
            if formerTagsFlag
                for indx = 1: 1: length(formerTagNames)
                    if ~all(strcmp(thisTagName, formerTagNames{indx}))
                        thisTagName = [thisTagName; formerTagNames(indx)];
                    end
                end
            end
            thisTag = {thisTagName}; thisTagHelper = {'TagNames'};

            % Custom Tag Function
            if ~isempty(CustomTagFunction)
                for indx = 1: 1: size(CustomTagFunction, 1)
                    thisTargetTagName = CustomTagFunction{indx, 1};
                    thisTagHelperName = CustomTagFunction{indx, 2};
                    thisFunction = CustomTagFunction{indx, 3};
                    if strcmp(thisTargetTagName, 'table') || any(strcmp(thisTagName, thisTargetTagName))
                        try
                            thisValue = thisFunction(thisColumnTable, thisUniqueColumnTable);
                        catch
                            warning(strcat('Variable Input Class / Function Handle Syntax Error Warning: ', thisTargetTagName, '/', thisTagHelperName, '.'));
                            thisValue = [];
                        end
                    else
                        thisValue = [];
                    end
                    % Append
                    if obj.OneTagFlag
                        Bool1 = ~any(isempty(thisValue));
                        try 
                            Bool2 = ~any(isnan(thisValue));
                            Bool = Bool1 && Bool2;
                        catch
                            Bool = Bool1;
                        end
                        if Bool
                            thisTag = [thisTag, {thisValue}];
                            thisTagHelper = [thisTagHelper, {thisTagHelperName}];
                        end
                    else
                        thisTag = [thisTag, {thisValue}];
                        thisTagHelper = [thisTagHelper, {thisTagHelperName}];
                    end
                end
            end
            % Field Name
            thisTag = [thisTag, {thisFieldName}];
            thisCell = [thisTag', [thisTagHelper, 'VariableName']'];
            
            % Utility Function
            function Return = nest_index(theformer, thelaterindexstring)
                thelaterindexstring = string(thelaterindexstring);
                try
                    Return = eval(strcat("theformer", thelaterindexstring));
                catch
                    try
                        Return = eval(strcat("theformer{", thelaterindexstring, "}"));
                    catch
                        Return = eval(strcat("theformer(", thelaterindexstring, ")"));
                    end
                end
            end

        end


        %% ---------------------------------------------------------------
        % function
        
    end
end