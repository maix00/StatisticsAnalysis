classdef StatisticsAnalysis < handle
    % STATISTICSANALYSIS analyzes tables/timetables.
    %
    %  %-------------------------------------------------------------------
    %   STATISTICSANALYSIS Properties:
    %     Import Settings Properties:
    %       TablePath
    %       ImportOptions
    %       detectedImportOptions
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
        Tags = {};
        Table
        TablePath
        ImportOptions
    end

    properties(Hidden, Access=private)
        OneTagFlag = true;
        DetectedImportOptions % detectImportOptions(TablePath)
        originalDetectedImportOptions
    end

    properties(Dependent)
        detectedImportOptions
    end

    properties(Dependent, Hidden)
        lastDetectedImportOptions
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
            ips.addParameter('TagsGenerate', false, @(x)true);
            ips.addParameter('TagsGenerateOptions', {}, @(x)true);
            ips.parse(varargin{:})
            %
            obj.TablePath = ips.Results.TablePath;
            obj.Table = ips.Results.Table;
            % DetectedImportOptions Initialize
            if ~isempty(obj.TablePath)
                obj.originalDetectedImportOptions = detectImportOptions(obj.TablePath); 
                if isempty(ips.Results.DetectedImportOptions)
                    obj.DetectedImportOptions = obj.originalDetectedImportOptions;
                end
            end
            if ~isempty(ips.Results.DetectedImportOptions)
                obj.DetectedImportOptions = ips.Results.DetectedImportOptions; 
            end
            % Import Options
            obj.ImportOptions = ips.Results.ImportOptions;
            % Select Table and Update ImportOptions before Import the required Table
            if ~isempty(ips.Results.SelectTableOptions)
                obj = obj.DetectedImportOptionsUpdateFromSelectTable(ips.Results.SelectTableOptions); 
            end
            % Import Options Un-nest
            obj = obj.ImportOptionsUnnest;
            % Tags Generation
            if ~isempty(ips.Results.TagsGenerateOptions)
                temp = transpose(ips.Results.TagsGenerateOptions);
                obj.Table = obj.TagsGenerate(temp{:}).addProp;
            elseif ips.Results.TagsGenerate
                obj.Table = obj.TagsGenerate.addProp; 
            end
        end

        function dIO = get.detectedImportOptions(obj)
            if ~isempty(obj.TablePath) && ~isempty(obj.originalDetectedImportOptions)
                dIO = obj.originalDetectedImportOptions; return;
            elseif ~isempty(obj.TablePath)
                dIO = detectImportOptions(obj.TablePath); return;
            else
                dIO = [];
            end
        end

        function lDIO = get.lastDetectedImportOptions(obj)
            if ~isempty(obj.DetectedImportOptions)
                lDIO = obj.DetectedImportOptions; return;
            elseif ~isempty(obj.originalDetectedImportOptions)
                lDIO = obj.originalDetectedImportOptions; return;
            else
                lDIO = [];
            end
        end
    end

    methods(Access = private)
        %% Select Table Before Import
        % ---------------------------------------------------------------
        function obj = DetectedImportOptionsUpdateFromSelectTable(obj, SelectTableOptions)
            if ~isempty(SelectTableOptions) && ~isempty(obj.DetectedImportOptions)
                obj.DetectedImportOptions.SelectedVariableNames = SelectTableOptions(:,1)';
                tempTable = readtable(obj.TablePath, obj.DetectedImportOptions);
                tempTable = addprop(tempTable, 'detectedImportOptions', {'table'});
                tempTable.Properties.CustomProperties.detectedImportOptions = obj.originalDetectedImportOptions;
                [~, ~, FirstLast] = selecttable(tempTable, SelectTableOptions); 
                DataLinesOptions = {'DataLines', {FirstLast}};
                if isempty(obj.ImportOptions), obj.ImportOptions = struct('DataLines', {FirstLast});
                else
                    if isa(obj.ImportOptions, 'cell')
                        DataLinesMapInImportOptions = strcmp(obj.ImportOptions(:,1), 'DataLines');
                        tf = ~any(DataLinesMapInImportOptions);
                        if tf, obj.ImportOptions = [obj.ImportOptions; DataLinesOptions]; 
                        else
                            RowNum = find(DataLinesMapInImportOptions, 1); 
                            OldDataLinesOptions = obj.ImportOptions(RowNum, 2);
                            NewFL = UpdateDataLinesOptionsHelper(OldDataLinesOptions, FirstLast);
                            obj.ImportOptions(RowNum, :) = {'DataLines', {NewFL}};
                        end
                    elseif isa(obj.ImportOptions, 'struct')
                        if ~isfield(obj.ImportOptions, 'DataLines')
                            obj.ImportOptions.DataLinesOptions = {FirstLast}; 
                        else
                            obj.ImportOptions.DataLines = UpdateDataLinesOptionsHelper(obj.ImportOptions.DataLines, FirstLast);
                        end
                    else
                        error('Input ImportOptions should be cell or struct.')
                    end
                end
            end
            function NewFL = UpdateDataLinesOptionsHelper(Old, FL) % Old is a 1x1 cell with [n1 n2] 1x2 int matrix.
                [LB, RB] = IntervalTypeName2BoundaryTypes('closed'); 
                NewFL = cell(size(FL)); od = arange(); 
                od.range = {Old{1}(1), Old{1}(2)}; od.lb = LB; od.rb = RB; od.nar = false; 
                tp = arange(); tp.lb = LB; tp.rb = RB; tp.nar = false;
                for idx = 1: numel(FL), tp.range = {FL{idx}(1), FL{idx}(2)};
                    [~, btm, top] = intersect1D(tp, od, true); 
                    if ~isempty(btm) && ~isempty(top), NewFL{idx} = [btm, top]; else, error('No Rows Selected.'); end
                end
                % ar = arange(FL).intervalTypeUpdate('closed'); oldar = arange(Old).intervalTypeUpdate('closed'); newar = intersect(oldar, ar);
                % NewFL = {}; for indx = 1: 1: numel(newar), if ~isempty(newar(indx)), NewFL = [NewFL, {[newar(indx).bottom, newar(indx).top]}]; end; end
                % New = {'DataLines', {NewFL}};
            end
        end
    
         %% Import Options
         % ---------------------------------------------------------------
        function obj = ImportOptionsUnnest(obj)
            % ImportOptionsUnnest un-nests the ImportOptions.
            %   
            %   obj = ImportOptionsUnnest(obj)
            %
            %   Inside usage. Invoked by <a href = "matlab:help StatisticsAnalysis/StatisticsAnalysis">StatisticsAnalysis</a>.

            %   WANG Yi-yang 28-Apr-2022

            if ~isempty(obj.ImportOptions)
                if isa(obj.ImportOptions, 'cell')
                    obj.ImportOptions = cell2struct(obj.ImportOptions(:,2), obj.ImportOptions(:,1), 1);
                end
                copy = obj.ImportOptions;
                fn = fieldnames(copy); lg = length(fn);
                map = true(lg, 1); lgMap = ones(1, lg);
                for idx = 1: lg
                    this = copy.(fn{idx});
                    if isa(this, 'cell')
                        % May have two situations: (1) {ValueA, ValueB, ...};
                        % (2) {SettingA, ValueA; SettingB, ValueB}; To
                        % avoid this ambiguity, we ask the first case to
                        % be {{ValueA, ValueB}}. And the second case can be
                        % a struct.
                        if numel(this) == 1 && isa(this{1}, 'cell')
                            map(idx) = false; lgMap(idx) = numel(this{1});
                        elseif all(size(this) == [1 2])
                            warning('Check Input. Make Sure (1) {ValA ,and ValB} as it is; (2) {ValA ,or ValB} -> {{ValA, ValB}}; (3) {Setting, Val} as it is, or-> struct(Setting, Val).')
                        end
                    end
                end
                fn(map) = []; lgMap(map') = []; copy = rmfield(copy, fn); opt(lgMap) = struct; lg = length(lgMap);
                cmd = arrayfun(@(x)strcat("idx",num2str(x),','), 1:lg); cmd = strcat(cmd{:}); cmd = cmd(1:end-1); cmd1 = ['[', cmd, ']'];
                for idx = 1: numel(opt)
                    tp1 = [cmd1, ' = ind2sub(lgMap, idx);']; eval(tp1);
                    for idxx = 1: lg, numstr = num2str(idxx);
                        tp2 = ['opt(idx).(fn{' numstr '}) = obj.ImportOptions.(fn{' numstr '}){1}{idx' numstr '};']; eval(tp2);
                    end
                end
                obj.ImportOptions = {copy, 'Invariant'; opt, 'Variant'};
            end
        end

        function obj = ImportOptionsUpdate(obj, idx)
            % ImportOptionsUpdate updates the DetectedImportOptions.
            %   
            %   obj = ImportOptionsUpdate(obj, OptionCell)
            %
            %   Inside usage. Invoked by <a href = "matlab:help DetectImport">DetectImport</a> and <a href = "matlab:help ImportTable">ImportTable</a>.

            %   WANG Yi-yang 28-Apr-2022
            if (nargin == 1), idx = 0; end
            fn1 = fieldnames(obj.ImportOptions{1}); 
            for idx1 = 1: length(fn1)
                obj = IOUHelper(obj, fn1{idx1}, obj.ImportOptions{1}.(fn1{idx1}));
            end
            if idx > 0
                fn2 = fieldnames(obj.ImportOptions{2}(idx));
                for idx2 = 1: length(fn2)
                    obj = IOUHelper(obj, fn2{idx2}, obj.ImportOptions{2}(idx).(fn2{idx2}));
                end
            end

            function obj = IOUHelper(obj, fn, val)
                switch fn
                    case 'VariableTypes'
                        if isa(val, 'cell')
                            obj = IOUHelper(obj, fn, cell2struct(val(:,2), val(:,1), 1));
                        elseif isa(val, 'struct')
                            fnl = fieldnames(val);
                            for idxx = 1: length(fnl)
                                map = strcmp(obj.DetectedImportOptions.VariableNames, fnl{idxx});
                                if any(map)
                                    obj.DetectedImportOptions.(fn){map} = val.(fnl{idxx});
                                else
                                    error('VariableNames to be altered not found.')
                                end
                            end
                        end
                    otherwise
                        obj.DetectedImportOptions.(fn) = val;
                end
            end
        end
    end
end