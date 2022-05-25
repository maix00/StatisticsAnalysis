classdef StatisticsAnalysis < handle
    % STATISTICSANALYSIS analyzes tables/timetables.
    %
    %  %-------------------------------------------------------------------
    %   STATISTICSANALYSIS Properties:
    %     Settings Properties:
    %       TablePath
    %       ImportOptions
    %       SelectTableOptions
    %       TagsGenerateOptions
    %       SelectedVariableNames
    %       detectedImportOptions
    %       
    %     Analysis Report Properties:
    %       Tags
    %       Table
    %       
    %  %-------------------------------------------------------------------
    %   STATISTICSANALYSIS Creation Methods:
    %     obj = StatisticsAnalysis(varargin)
    %
    %   Parameters Example:    
    %       - TablePath                               './Project/table.csv'
    %       - Table                                    table (in Workspace)
    %       - ImportOptions                       {'DateLines', [2, 3], ...
    %                                   'SelectedVariableNames', {'date'} }
    %       - DetectedImportOptions                      DIO (in Workspace)
    %       - SelectTableOptions               {'Var1', Val1, 'Var2', Val2}
    %       - TagsGenerate                                             true
    %       - TagsGenerateOptions                      same as <a href = "matlab:help TagsGenerate">TagsGenerate</a>
    %
    %  %-------------------------------------------------------------------
    %       Author: WANG Yi-yang
    %      Created: 28-Apr-2022
    %   LastEdited: 23-May-2022

    properties
        Tags
        Table
        TablePath
        ImportOptions
        SelectTableOptions
        TagsGenerateOptions
        MissingValuesReport
        MissingValuesOptions
        SelectedVariableNames
    end
    
    properties(Hidden)
        WholeTable
        FullVarTable
    end

    properties(Hidden, Access=private)
        OneTagFlag = true;
        UnnestedImportOptions
        DetectedImportOptions % detectImportOptions(TablePath)
        originalDetectedImportOptions
    end

    properties(Dependent)
        detectedImportOptions
    end

    properties(Dependent, Hidden)
        lastDetectedImportOptions
        TimeTable
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
            
            obj.Update(varargin{:});
        end
        
        function obj = Update(obj, varargin)
            ips = inputParser;
            ips.addParameter('TablePath', {}, @(x)validateattributes(x, {'char', 'string'}, {}));
            ips.addParameter('Table', {}, @(x)validateattributes(x, {'table'}, {}));
            ips.addParameter('ImportOptions', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('DetectedImportOptions', {}, @(x)true);
            ips.addParameter('SelectTableOptions', {}, @(x)true);
            ips.addParameter('MissingValuesOptions', {}, @(x)true);
            ips.addParameter('TagsGenerate', false, @(x)true);
            ips.addParameter('TagsGenerateOptions', {}, @(x)true);
            ips.parse(varargin{:})
            
            if ~isempty(ips.Results.TablePath), obj.TablePath = ips.Results.TablePath; end
            if ~isempty(ips.Results.Table), obj.WholeTable = ips.Results.Table; end

            % DetectedImportOptions Initialize
            if ~isempty(ips.Results.TablePath)
                obj.originalDetectedImportOptions = detectImportOptions(obj.TablePath); 
                if isempty(ips.Results.DetectedImportOptions)
                    obj.DetectedImportOptions = obj.originalDetectedImportOptions;
                end
            end
            if ~isempty(ips.Results.DetectedImportOptions)
                obj.DetectedImportOptions = ips.Results.DetectedImportOptions; 
            end

            % Update Options
            if ~isempty(ips.Results.MissingValuesOptions)
                obj.MissingValuesOptions = ips.Results.MissingValuesOptions;
            end
            for OptionName_idx = {'ImportOptions', 'SelectTableOptions', 'TagsGenerateOptions'}
                OptionName = OptionName_idx{1};
                if ~isempty(ips.Results.(OptionName))
                    if isempty(obj.(OptionName))
                        obj.(OptionName) = OptionsSizeHelper(ips.Results.(OptionName), 2, true);
                    else
                        obj.UpdateOptions(OptionName, ips.Results.(OptionName));
                    end
                end
            end
            
            % SelectedVariableNames
            if ~isempty(obj.ImportOptions)
                map = strcmp(fieldnames(obj.ImportOptions), 'SelectedVariableNames');
                if any(map)
                    obj.SelectedVariableNames = obj.ImportOptions.SelectedVariableNames;
                    obj.ImportOptions = rmfield(obj.ImportOptions, 'SelectedVariableNames');
                end
            end

            % Import Table
            if isempty(obj.WholeTable)
                obj.WholeTable = obj.ImportTable;
            elseif ~isempty(ips.Results.ImportOptions)
                % Import table when Import Options were updated more than
                % just SelectedVariableNames.
                tp_ImportOptions = fieldnames(OptionsSizeHelper(ips.Results.ImportOptions, 2, true));
                tp_ImportOptions(strcmp(tp_ImportOptions, 'SelectedVariableNames')) = [];
                if numel(tp_ImportOptions) > 0
                    obj.WholeTable = obj.ImportTable;
                end
            end

            % Select Table Rows
            if ~isempty(ips.Results.SelectTableOptions)
                obj.TableSelect;
            elseif isempty(obj.FullVarTable)
                obj.FullVarTable = obj.WholeTable;
            end

            % Select Variable Names
            if ~isempty(obj.SelectedVariableNames)
                obj.Table = obj.FullVarTable(:,obj.SelectedVariableNames);
            else
                obj.Table = obj.FullVarTable;
            end
            
            % Table if Empty
            if isempty(obj.FullVarTable)
                error('Table Empty.');
            end
            
            % Missing Values Helper
            % This Option is not reversible.
            if ~isempty(ips.Results.MissingValuesOptions)
                TMV = TableMissingValues(obj.Table, obj.MissingValuesOptions);
                obj.Table = TMV.Table;
                obj.MissingValuesReport = TMV.Missing;
            else
                TMV = TableMissingValues(obj.Table);
                obj.MissingValuesReport = TMV.Missing;
            end

            % Tags Generation
            if ips.Results.TagsGenerate || ~isempty(ips.Results.TagsGenerateOptions)
                obj.TagsGenerate(obj.TagsGenerateOptions);
            end
        end

        function TT = get.TimeTable(obj, varargin)
            % Try Converting to timetable
            try 
                TT = table2timetable(obj.Table, varargin{:}); 
            catch
                error('Fail to convert to timetable.');
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

        function obj = UpdateOptions(obj, whichOption, AmmendOptions, flag)
            if nargin == 3, flag = 'substitute'; end
            AmmendOptions = OptionsSizeHelper(AmmendOptions, 2, true);
            orifn = fieldnames(obj.(whichOption));
            switch class(AmmendOptions)
                case 'struct'
                    for fn_idx = fieldnames(AmmendOptions)'
                        fn = fn_idx{1};
                        bool = any(strcmp(fn, orifn));
                        switch flag
                            case 'substitute'
                                obj.(whichOption).(fn) = AmmendOptions.(fn);
                            case 'append'
                                if bool
                                    obj.(whichOption).(fn) = unique([obj.(whichOption).(fn), AmmendOptions.(fn)]);
                                else
                                    obj.(whichOption).(fn) = AmmendOptions.(fn);
                                end
                            otherwise
                                error('Not supported flag. Try "substitute".');
                        end
                    end
                otherwise
                    error('Check Syntax.')
            end
        end

        function obj = UpdateImportOptions(obj, AmmendOptions, flag)
            obj.UpdateOptions('ImportOptions', AmmendOptions, flag);
        end

        function obj = UpdateSelectTableOptions(obj, AmmendOptions, flag)
            obj.UpdateOptions('SelectTableOptions', AmmendOptions, flag);
        end

        function obj = UpdateTagsGenerateOptions(obj, AmmendOptions, flag)
            obj.UpdateOptions('TagsGenerateOptions', AmmendOptions, flag);
        end

        function obj = RenewSelectedVariableNames(obj)
            obj.SelectedVariableNames = obj.originalDetectedImportOptions.VariableNames;
        end
        
        function obj = TableSelect(obj)
            if isempty(obj.SelectTableOptions), error('Empty obj.SelectTableOptions.'); end
            % SelectTableOptions -> Options & TimeOptions
            Options = obj.SelectTableOptions;
            TimeOptions = struct;
            for fn_idx = fieldnames(Options)'
                fn = fn_idx{1};
                switch class(Options.(fn))
                    case 'arange'
                        if ismember(class(Options.(fn).range{1}), {'datetime', 'duration'})
                            TimeOptions.(fn) = Options.(fn).ar2tr;
                            Options = rmfield(Options, fn);
                        end
                    case 'timerange'
                        TimeOptions.(fn) = Options.(fn);
                        Options = rmfield(Options, fn);
                    case 'cell'
                        flag = true; flagArange = true;
                        for idxx = 1: numel(Options.(fn))
                            switch class(Options.(fn){idxx})
                                case 'arange' % do nothing
                                case 'timerange', flagArange = false;
                                otherwise, flag = false; flagArange = false; break
                            end
                        end
                        if flag && flagArange
                            TimeOptions.(fn) = Options.(fn).ar2tr;
                            Options = rmfield(Options, fn);
                        elseif flag
                            TimeOptions.(fn) = Options.(fn);
                            Options = rmfield(Options, fn);
                        end
                end
            end
            % Select Table from Options
            obj.FullVarTable = selecttable(obj.WholeTable, Options, true);
            % Select Table from TimeOptions
            for fn_idx = fieldnames(TimeOptions)'
                fn = fn_idx{1};
                obj.FullVarTable = table2timetable(obj.FullVarTable, 'RowTimes', fn);
                switch class(TimeOptions.(fn))
                    case 'timerange'
                        obj.FullVarTable = obj.FullVarTable(TimeOptions.(fn), :);
                    case 'cell'
                        for idxx = 1: numel(TimeOptions.(fn))
                            obj.FullVarTable = obj.FullVarTable(TimeOptions.(fn){idxx}, :);
                        end
                end
                obj.FullVarTable = timetable2table(obj.FullVarTable);
            end
        end
    end
    
    methods(Access = private)
        function obj = ImportOptionsUnnest(obj)
            % ImportOptionsUnnest un-nests the ImportOptions.
            %   
            %   obj = ImportOptionsUnnest(obj)
            %
            %   Inside usage. Invoked by <a href = "matlab:help StatisticsAnalysis/StatisticsAnalysis">StatisticsAnalysis</a>.

            %   WANG Yi-yang 28-Apr-2022

            if ~isempty(obj.ImportOptions)
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
                cmd = arrayfun(@(x)strcat("idx",num2str(x),','), 1:lg);
                if ~isempty(cmd)
                    cmd = strcat(cmd{:}); cmd = cmd(1:end-1); cmd1 = ['[', cmd, ']'];
                    for idx = 1: numel(opt)
                        tp1 = [cmd1, ' = ind2sub(lgMap, idx);']; eval(tp1);
                        for idxx = 1: lg, numstr = num2str(idxx);
                            tp2 = ['opt(idx).(fn{' numstr '}) = obj.ImportOptions.(fn{' numstr '}){1}{idx' numstr '};']; eval(tp2);
                        end
                    end
                else
                    opt = [];
                end
                obj.UnnestedImportOptions = struct('Invariant', copy, 'Variant', opt);
            end
        end

        function obj = ImportOptionsUpdate(obj, idx)
            % ImportOptionsUpdate updates the DetectedImportOptions.
            %   
            %   obj = ImportOptionsUpdate(obj, OptionCell)
            %
            %   Inside usage. Invoked by <a href = "matlab:help DetectImport">DetectImport</a> and <a href = "matlab:help ImportTable">ImportTable</a>.

            %   WANG Yi-yang 28-Apr-2022
            if isempty(obj.UnnestedImportOptions); error('Empty obj.UnnestedImportOptions. Use obj.ImportOptionsUnnest first.'); end
            if (nargin == 1), idx = 0; end
            fn1 = fieldnames(obj.UnnestedImportOptions.Invariant); 
            for idx1 = 1: length(fn1)
                obj = IOUHelper(obj, fn1{idx1}, obj.UnnestedImportOptions.Invariant.(fn1{idx1}));
            end
            if idx > 0
                fn2 = fieldnames(obj.UnnestedImportOptions.Variant(idx));
                for idx2 = 1: length(fn2)
                    obj = IOUHelper(obj, fn2{idx2}, obj.UnnestedImportOptions.Variant(idx).(fn2{idx2}));
                end
            end

            function obj = IOUHelper(obj, fn, val)
                switch fn
                    case 'VariableTypes'
                        if isa(val, 'cell')
                            obj = IOUHelper(obj, fn, OptionsSizeHelper(val, 2, true));
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
                    case {'Name', 'FillValue', 'TreatAsMissing', 'EmptyFieldRule', 'QuateRule', 'Prefixes', 'Suffixes'}
                        if isa(val, 'cell')
                            val = OptionsSizeHelper(val, 2, true);
                            obj = IOUHelper(obj, fn, cell2struct(val(:,2), val(:,1), 1));
                        elseif isa(val, 'struct')
                            fnl = fieldnames(val);
                            for idxx = 1: length(fnl)
                                map = strcmp(obj.DetectedImportOptions.VariableNames, fnl{idxx});
                                if any(map)
                                    obj.DetectedImportOptions = setvaropts(obj.DetectedImportOptions, fnl{idxx}, fn, val.(fnl{idxx}));
                                else
                                    error(['VariableNames to be altered not found.', fnl{idxx} ]);
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