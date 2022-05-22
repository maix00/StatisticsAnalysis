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
        SelectTableOptions
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

            ips = inputParser;
            ips.addParameter('TablePath', {}, @(x)validateattributes(x, {'char', 'string'}, {}));
            ips.addParameter('Table', {}, @(x)validateattributes(x, {'table'}, {}));
            ips.addParameter('ImportOptions', {}, @(x)validateattributes(x, {'cell'}, {}));
            ips.addParameter('DetectedImportOptions', {}, @(x)true);
            ips.addParameter('SelectTableOptions', {}, @(x)true);
            ips.addParameter('TagsGenerate', false, @(x)true);
            ips.addParameter('TagsGenerateOptions', {}, @(x)true);
            ips.parse(varargin{:})
            
            obj.TablePath = ips.Results.TablePath;
            obj.Table = ips.Results.Table;
            obj.ImportOptions = OptionsSizeHelper(ips.Results.ImportOptions);
            obj.SelectTableOptions = OptionsSizeHelper(ips.Results.SelectTableOptions);
            
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
            % Import and Select Table
            obj = obj.TableImportAndSelection;
            % Tags Generation
            if isempty(ips.Results.TagsGenerateOptions) && (isa(ips.Results.TagsGenerate, 'cell') || isa(ips.Results.TagsGenerate, 'struct') )
                TagsGenerateOptions = OptionsSizeHelper(ips.Results.TagsGenerate);
            else
                TagsGenerateOptions = OptionsSizeHelper(ips.Results.TagsGenerateOptions);
                TagsGenerate = ips.Results.TagsGenerate;
            end
            if ~isempty(TagsGenerateOptions)
                tp = transpose(TagsGenerateOptions);
                obj.Table = obj.TagsGenerate(tp{:}).addProp;
            elseif TagsGenerate
                obj.Table = obj.TagsGenerate.addProp; 
            end
            % Table if Empty
            if isempty(obj.Table)
                error('Table Empty. Try obj.ImportTable. Remove strict SelectTableOptions.');
            end
        end
        
        function TT = get.TimeTable(obj)
            % Try Converting to timetable
            try 
                TT = table2timetable(obj.Table); 
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

        function obj = UpdateImportOptions(obj, AmmendOptions, flag)
            if nargin == 2, flag = 'substitute'; end
            AmmendOptions = OptionsSizeHelper(AmmendOptions);
            for idxx = 1: size(AmmendOptions, 1)
                map = strcmp(obj.ImportOptions(:,1), AmmendOptions{idxx, 1});
                if any(map)
                    switch flag
                        case 'append'
                            obj.ImportOptions{map,2} = unique([obj.ImportOptions{map,2}, AmmendOptions{idxx, 2}]);
                        case 'or'
                            warning('Not supported for now. Try substitue.')
                        case 'substitute'
                            obj.ImportOptions(map,2) = AmmendOptions(idxx,2);
                    end
                else
                end
            end
        end

        function obj = TableImportAndSelection(obj)
            copyImportOptions = obj.ImportOptions;
            copySelectTableOptions = obj.SelectTableOptions;
            if ~isempty(obj.TablePath) && ~isempty(obj.SelectTableOptions)
                selectionVariables = obj.SelectTableOptions(:,1)';
                if ~isempty(obj.ImportOptions)
                    if any(strcmp(obj.ImportOptions(:,1), 'SelectedVariableNames'))
                        tpmap = strcmp(obj.ImportOptions(:,1), 'SelectedVariableNames');
                        tpVariables = obj.ImportOptions{tpmap,2};
                        obj.ImportOptions{tpmap,2} = unique([tpVariables, selectionVariables]);
                    end
                end
                obj.Table = obj.ImportTable;
                for idx = 1: size(obj.SelectTableOptions, 1)
                    switch class(obj.SelectTableOptions{idx, 2})
                        case 'arange'
                            if isa(obj.SelectTableOptions{idx, 2}(1).range{1}, 'datetime') || isa(obj.SelectTableOptions{idx, 2}(1).range{1}, 'duration')
                                thisTimeRange = obj.SelectTableOptions{idx, 2}.ar2tr;
                                obj.SelectTableOptions(idx, :) = [];
                            end
                            break
                        case 'timerange'
                            thisTimeRange = obj.SelectTableOptions{idx, 2};
                            obj.SelectTableOptions(idx, :) = [];
                            break
                        case 'cell'
                            flag = true;
                            for idxx = 1: numel(obj.SelectTableOptions{idx, 2})
                                switch class(obj.SelectTableOptions{idx, 2}{idxx})
                                    case 'arange', obj.SelectTableOptions{idx, 2}{idxx} = obj.SelectTableOptions{idx, 2}{idxx}.ar2tr;
                                    case 'timerange' % do nothing
                                    otherwise, flag = false; break
                                end
                            end
                            if flag
                                thisTimeRange = obj.SelectTableOptions{idx, 2};
                            end
                    end
                end
                obj.Table = selecttable(obj.Table, obj.SelectTableOptions, true);
                if exist('thisTimeRange', 'var')
                    try obj.Table = table2timetable(obj.Table); catch; end
                    try 
                        switch class(thisTimeRange)
                            case 'timerange'
                                obj.Table = obj.Table(thisTimeRange, :);
                            case 'cell'
                                tp = obj.Table;
                                obj.Table(:,:) = [];
                                for idxx = 1: numel(thisTimeRange)
                                    obj.Table = [obj.Table; tp(thisTimeRange{idxx}, :)];
                                end
                        end
                        obj.Table = timetable2table(obj.Table);
                    catch
                    end
                end
                if exist('tpVariables', 'var')
                    obj.Table = obj.Table(:, tpVariables);
                end
            elseif isempty(obj.TablePath) && ~isempty(obj.SelectTableOptions)
                try 
                    obj.Table = selecttable(obj.Table, obj.SelectTableOptions); 
                    if isempty(obj.Table)
                        error('No rows were selected. StatisticsAnalysis ceased.');
                    end
                catch ME
                    error(ME.message);
                end
            elseif ~isempty(obj.TablePath)
                obj.Table = obj.ImportTable;
            end
            % Restore Options
            obj.ImportOptions = copyImportOptions;
            obj.SelectTableOptions = copySelectTableOptions;
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
                    opt = cell.empty;
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
                            val = OptionsSizeHelper(val);
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
                    case {'Name', 'FillValue', 'TreatAsMissing', 'EmptyFieldRule', 'QuateRule', 'Prefixes', 'Suffixes'}
                        if isa(val, 'cell')
                            val = OptionsSizeHelper(val);
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

% Helpers
function Options = OptionsSizeHelper(Options, numOneLine)
    if nargin == 1, numOneLine = 2; end
    if ~isempty(Options)
        sz = size(Options);
        if isa(Options, 'cell') && sz(1) == 1
            if sz(2) == numOneLine
                % do nothing
            elseif mod(sz(2), numOneLine) == 0
                tp = cell(sz(2)/numOneLine, numOneLine);
                for idx = 1: sz(2)/numOneLine
                    tp(idx, :) = Options(1, numOneLine*(idx-1)+1: numOneLine*idx);
                end
                Options = tp;
            else
                error('Check Input. Length not match.');
            end
        end
    end
end