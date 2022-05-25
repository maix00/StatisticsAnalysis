classdef TableMissingValues < handle

    properties
        Table
        GeneralOptions = struct;
        Missing = struct;
    end

    properties(Hidden)
        OriginalTable
        thisFixName
    end

    methods
        function obj = TableMissingValues(T, GeneralOptions, varargin)
            obj.OriginalTable = T;
            obj.Table = T;
            
            if nargin == 1
                len = length(T.Properties.VariableNames);
                obj.GeneralOptions(len, 1) = struct;
                for idx = 1: len
                    obj.GeneralOptions(idx, 1).VariableNames = T.Properties.VariableNames{idx};
                    obj.GeneralOptions(idx, 1).Style = 'MissingDetect';
                end
            else
                obj.TableMissingValues_InputRectify(GeneralOptions);
            end
            
            for idx = 1: numel(obj.GeneralOptions)
                obj.MissingValuesHelper(obj.GeneralOptions(idx));
            end
        end
    end

    methods(Access=private)
        function obj = TableMissingValues_InputRectify(obj, GeneralOptions)
            validateattributes(GeneralOptions, {'tabular', 'cell', 'struct'}, {}); 
            if isa(GeneralOptions, 'tabular')
                vn = GeneralOptions.Properties.VariableNames;
                if any(strcmp(vn, 'VariableNames')) && any(strcmp(vn, 'Style'))
                    vn(strcmp(vn, 'VariableNames')) = [];
                    vn(strcmp(vn, 'Style')) = [];
                    bool = isempty(vn);
                    for idx = 1: size(GeneralOptions, 1)
                        thisVN = string(GeneralOptions{idx, 'VariableNames'});
                        thisStyle = string(GeneralOptions{idx, 'Style'});
                        if bool, ValidateStyleOptions(thisStyle, thisVN);
                        else, ValidateStyleOptions(thisStyle, thisVN, vn);
                        end
                    end
                    obj.GeneralOptions = table2struct(GeneralOptions);
                elseif length(vn) == 1 && strcmp(vn{1}, 'VariableNames')
                    len = size(GeneralOptions, 1);
                    obj.GeneralOptions(len, 1) = struct;
                    for idx = 1: len
                        obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                        obj.GeneralOptions(idx, 1).Style = 'MissingDetect';
                    end
                else
                    error('Check syntax. TableMissingValues');
                end
            elseif isa(GeneralOptions, 'cell')
                % ColNames = {'VariableNames', 'Style', 'Options'};
                sz = size(GeneralOptions);
                if length(sz) == 2 && sz(2) == 1
                    obj.GeneralOptions(sz(1), 1) = struct;
                    for idx = 1: sz(1)
                        obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                        obj.GeneralOptions(idx, 1).Style = 'MissingDetect';
                    end
                elseif length(sz) == 2 && sz(2) == 2
                    obj.GeneralOptions(sz(1), 1) = struct;
                    for idx = 1: sz(1)
                        thisVN = string(GeneralOptions{idx, 1});
                        thisStyle = string(GeneralOptions{idx, 2});
                        ValidateStyleOptions(thisStyle, thisVN);
                        obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                        obj.GeneralOptions(idx, 1).Style = char(thisStyle);
                    end
                elseif length(sz) == 2 && sz(2) == 3
                    obj.GeneralOptions(sz(1), 1) = struct;
                    for idx = 1: sz(1)
                        thisVN = string(GeneralOptions{idx, 1});
                        thisStyle = string(GeneralOptions{idx, 2});
                        if isempty(GeneralOptions{idx, 3})
                            ValidateStyleOptions(thisStyle, thisVN);
                            obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                            obj.GeneralOptions(idx, 1).Style = char(thisStyle);
                        else
                            if isa(GeneralOptions{idx, 3}, 'tabular')
                                vn = GeneralOptions{idx, 3}.Properties.VariableNames;
                                ValidateStyleOptions(thisStyle, thisVN, vn);
                                if size(GeneralOptions{idx, 3}, 1) ~= 1, error('Too many inputs in Cell.Options.Tabular.'); end
                                obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                                obj.GeneralOptions(idx, 1).Style = char(thisStyle);
                                for opt_idx = vn
                                    opt = opt_idx{1};
                                    obj.GeneralOptions(idx, 1).(opt) = GeneralOptions{idx, 3}{1, opt};
                                end
                            elseif isa(GeneralOptions{idx, 3}, 'struct')
                                vn = fieldnames(GeneralOptions{idx, 3});
                                ValidateStyleOptions(thisStyle, thisVN, vn);
                                obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                                obj.GeneralOptions(idx, 1).Style = char(thisStyle);
                                for opt_idx = vn'
                                    opt = opt_idx{1};
                                    obj.GeneralOptions(idx, 1).(opt) = GeneralOptions{idx, 3}.(opt);
                                end
                            else
                                error('Ambiguous inputs in Cell.Options, use Struct or Tabular.')
                            end
                        end
                    end
                else
                    error('Too many inputs in Cell.');
                end
            elseif isa(GeneralOptions, 'struct')
                sz = size(GeneralOptions);
                if ~(length(sz) <= 2 && sz(2) == 1)
                    nel = numel(GeneralOptions);
                    tp(nel, 1) = struct;
                    for idx = 1: nel
                        for fn_idx = fieldnames(GeneralOptions(idx))
                            fn = fn_idx{1};
                            tp(idx).(fn) = GeneralOptions(idx).(fn);
                        end
                    end
                    GeneralOptions = tp;
                end
                fn = fieldnames(GeneralOptions);
                if any(strcmp(fn, 'VariableNames')) && any(strcmp(fn, 'Style'))
                    fn(strcmp(fn, 'VariableNames')) = [];
                    fn(strcmp(fn, 'Style')) = [];
                    bool = isempty(fn);
                    for idx = 1: numel(GeneralOptions)
                        thisVN = GeneralOptions(idx).VariableNames;
                            thisStyle = GeneralOptions(idx).Style;
                        if bool, ValidateStyleOptions(thisStyle, thisVN);
                        else, ValidateStyleOptions(thisStyle, thisVN, fn);
                        end
                    end
                    obj.GeneralOptions = GeneralOptions;
                elseif length(fn) == 1 && strcmp(fn{1}, 'VariableNames')
                    obj.GeneralOptions = GeneralOptions;
                    for idx = 1: numel(GeneralOptions)
                        obj.GeneralOptions(idx).Style = 'MissingDetect';
                    end
                else
                    error('Check syntax. TableMissingValues');
                end
            end

            function ValidateStyleOptions(S, VN, ON)
                S = validatestring(S, {'Increment-Addition', 'MissingDetect', 'Interpolation', 'ConstantValues'});
                if ~strcmp(S, 'Increment-Addition') && nargin <= 2, return; end
                switch S
                    case 'Increment-Addition'
                        if numel(VN) ~= 2, error('Increment-Addition requires 2 variables.'); end
                        if nargin > 2
                            IAOptionsList = {'RemoveLastRows', 'ConstantValues_FirstRows', ...
                                'RemoveFirstRows', 'InterpolationStyle', ...
                                'InterpolationFunction', 'InterpolationStyle_P', 'InterpolationFunction_P', 'InterpolationStyle_C', 'InterpolationFunction_C', ...
                                'DecreasingAdditionStyle', 'DecreasingAdditionParameters'};
                            for idxx = 1: length(ON), validatestring(ON{idxx}, IAOptionsList); end
                        end
                    case 'Interpolation'
                        IOptionsList = {'InterpolationStyle', 'InterpolationFunction'};
                        for idxx = 1: length(ON), validatestring(ON{idxx}, IOptionsList); end
                    case 'ConstantValues'
                        FOptionsList = {'ConstantValues', 'ConstantValues_FirstRows', 'ConstantValues_LastRows', 'ConstantValues_Middle'};
                        for idxx = 1: length(ON), validatestring(ON{idxx}, FOptionsList); end
                end
            end
        end

        function obj = MissingValuesHelper(obj, Option)
            obj.MissingValuesDetect(Option);
            obj.MissingValuesFix(Option);
        end

        function obj = MissingValuesDetect(obj, Option)
            obj.Missing.Map = ismissing(obj.Table);
            for idx = 1: length(obj.Table.Properties.VariableNames)
                obj.Missing.(obj.Table.Properties.VariableNames{idx}) = FirstLastFindTrue(obj.Missing.Map(:,idx));
            end
            switch Option.Style
                case 'Increment-Addition'
                    obj.thisFixName = ['increment_addition_', Option.VariableNames{1}, '_', Option.VariableNames{2}];
                    if ~isfield(obj.Missing, obj.thisFixName)
                        obj.Missing.(obj.thisFixName) = struct;
                    end
                    obj.Missing.(obj.thisFixName).Increment = Option.VariableNames{1};
                    obj.Missing.(obj.thisFixName).Addition = Option.VariableNames{2};
                    obj.Missing.(obj.thisFixName).IncrementWhere = strcmp(obj.Table.Properties.VariableNames, Option.VariableNames{1});
                    obj.Missing.(obj.thisFixName).AdditionWhere = strcmp(obj.Table.Properties.VariableNames, Option.VariableNames{2});
                    obj.Missing.(obj.thisFixName).IncrementMissingMap = obj.Missing.Map(:, obj.Missing.(obj.thisFixName).IncrementWhere);
                    obj.Missing.(obj.thisFixName).AdditionMissingMap = obj.Missing.Map(:, obj.Missing.(obj.thisFixName).AdditionWhere);
                    obj.IncrementAddition_DecreasingAdditionDetect;
                    obj.IncrementAddition_MissingBlocksDetect;
            end
        end

        function obj = MissingValuesFix(obj, Option)
            switch Option.Style
                case 'Increment-Addition'
                    if isempty(obj.Missing.(obj.thisFixName).MissingBlocks)
                        return
                    end
                    obj.IncrementAddition_FixFirstRows(Option);
                    obj.IncrementAddition_RemoveLastRows(Option);
                    obj.IncrementAddition_GroupBlocks;
                    obj.IncrementAddition_FixingHelper(Option);
                case 'MissingDetect' % do nothing
                case 'Interpolation'
                    for idx = 1: length(obj.Table.Properties.VariableNames)
                        Map = strcmp(obj.Table.Properties.VariableNames{idx}, obj.Table.Properties.VariableNames);
                        FirstLast = obj.Missing.(obj.Table.Properties.VariableNames{idx});
                        for idxx = 1: length(FirstLast)
                            startRow = FirstLast(1)-1; endRow = FirstLast(2)+1;
                            obj.Table = Interpolation_Helper(obj.Table, startRow, endRow, Map, Option);
                        end
                    end
                case 'ConstantValues'
                    if ~isempty(Option.ConstantValues)
                        obj.Table = fillmissing(T, 'constant', Option.ConstantValues);
                    else
                        error('No parameter ConstantValues input.')
                    end
            end
        end
    end
    
    % IncrementAddition
    methods(Access=private)
        function obj = IncrementAddition_DecreasingAdditionDetect(obj)
            AdditionWhere = obj.Missing.(obj.thisFixName).AdditionWhere;
            obj.Missing.(obj.thisFixName).DecreasingAddition = cell.empty;
            for idxx = 2: size(obj.Table, 1)
                if obj.Table{idxx, AdditionWhere} < obj.Table{idxx-1, AdditionWhere}
                    obj.Missing.(obj.thisFixName).DecreasingAddition = [obj.Missing.(obj.thisFixName).DecreasingAddition, [idxx-1, idxx]];
                    warning([obj.thisFixName, ' Addition was decreasing at rows [', sprintf('%i', idxx-1), ',', sprintf('%i', idxx), ']']);
                end
            end
        end

        function obj = IncrementAddition_MissingBlocksDetect(obj)
            IncrementMissingMap = obj.Missing.(obj.thisFixName).IncrementMissingMap;
            AdditionMissingMap = obj.Missing.(obj.thisFixName).AdditionMissingMap;
            list = struct.empty;
            for idxx = 1: size(obj.Table, 1)
                boolIncrement = IncrementMissingMap(idxx);
                boolAddition = AdditionMissingMap(idxx);
                bool = boolIncrement || boolAddition;
                if ~isempty(list)
                    if ~isempty(list(end).BottomLines)
                        lastLine = list(end).BottomLines(end);
                        if ~isempty(list(end).MiddleLines)
                            lastLine = max(lastLine, list(end).MiddleLines(end));
                        end
                    else
                        lastLine = list(end).MiddleLines(end);
                    end
                end
                if bool && (isempty(list) || (~isempty(list) && lastLine ~= idxx - 1))
                    if boolIncrement && ~boolAddition
                        list = [list; struct('Top', 'l', 'TopLines', [idxx, idxx], 'MiddleLines', [], 'Bottom', 'l', 'BottomLines', [idxx, idxx])];
                    elseif ~boolIncrement && boolAddition
                        list = [list; struct('Top', 'r', 'TopLines', [idxx, idxx], 'MiddleLines', [], 'Bottom', 'r', 'BottomLines', [idxx, idxx])];
                    elseif boolIncrement && boolAddition
                        list = [list; struct('Top', 'o', 'TopLines', [], 'MiddleLines', [idxx, idxx], 'Bottom', 'o', 'BottomLines', [])];
                    end
                elseif bool
                    if boolIncrement && ~boolAddition
                        switch list(end).Bottom
                            case 'o'
                                list(end).Bottom = 'l';
                                list(end).BottomLines = [idxx, idxx];
                            case 'l'
                                if isempty(list(end).MiddleLines)
                                    list(end).TopLines(end) = idxx;
                                end
                                list(end).BottomLines(end) = idxx;
                            case 'r'
                                list = [list; struct('Top', 'l', 'TopLines', [idxx, idxx], 'MiddleLines', [], 'Bottom', 'l', 'BottomLines', [idxx, idxx])];
                        end
                    elseif ~boolIncrement && boolAddition
                        switch list(end).Bottom
                            case 'o'
                                list(end).Bottom = 'r';
                                list(end).BottomLines = [idxx, idxx];
                            case 'r'
                                if isempty(list(end).MiddleLines)
                                    list(end).TopLines(end) = idxx;
                                end
                                list(end).BottomLines(end) = idxx;
                            case 'l'
                                list = [list; struct('Top', 'r', 'TopLines', [idxx, idxx], 'MiddleLines', [], 'Bottom', 'r', 'BottomLines', [idxx, idxx])];
                        end
                    elseif boolIncrement && boolAddition
                        switch list(end).Bottom
                            case 'o'
                                list(end).MiddleLines(end) = idxx;
                            case {'l', 'r'}
                                list = [list; struct('Top', 'o', 'TopLines', [], 'MiddleLines', [idxx, idxx], 'Bottom', 'o', 'BottomLines', [])];
                        end
                    end
                end
            end
            if ~isfield(obj.Missing.(obj.thisFixName), 'MissingBlocks')
                obj.Missing.(obj.thisFixName).MissingBlocks = list;
            else
                obj.Missing.(obj.thisFixName).tpMissingBlocks = list;
            end
        end

        function obj = IncrementAddition_RemoveLastRows(obj, Option)
            list = obj.Missing.(obj.thisFixName).tpMissingBlocks;
            len = size(obj.Table, 1);
            if isempty(list), return; end
            loopBool = true;
            while loopBool
                thisidx = length(list);
                if thisidx == 0, break; end
                switch list(thisidx).Bottom
                    case 'o'
                        if list(thisidx).MiddleLines(end) == len
                            RemoveLines = list(thisidx).MiddleLines;
                            list(thisidx) = [];
                        else, loopBool = false;
                        end
                    case 'r'
                        if ~isempty(list(thisidx).MiddleLines) && list(thisidx).BottomLines(end) == len
                            RemoveLines = [list(thisidx).MiddleLines(1), len];
                            list(thisidx) = [];
                        else, loopBool = false;
                        end
                    otherwise, loopBool = false;
                end
                if exist('RemoveLines', 'var') && ~isempty(RemoveLines)
                    if isfield(Option, 'RemoveLastRows') && ~Option.RemoveLastRows
                        warning([obj.thisFixName, ' Last lines were missing in Addition or in both Increment and Addition.']);
                    else
                        obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                        warning([obj.thisFixName, ' Last lines were missing in Addition or in both Increment and Addition, thus removed.']);
                        RemoveLines = [];
                    end
                end
            end
            obj.Missing.(obj.thisFixName).tpMissingBlocks = list;
        end
        
        function obj = IncrementAddition_FixFirstRows(obj, Option)
            list = obj.Missing.(obj.thisFixName).MissingBlocks;
            IncrementWhere = obj.Missing.(obj.thisFixName).IncrementWhere;
            AdditionWhere = obj.Missing.(obj.thisFixName).AdditionWhere;
            if isfield(Option, 'ConstantValues_FirstRows') && ~isempty(Option.ConstantValues_FirstRows), ConstantValues = Option.ConstantValues_FirstRows; 
            elseif isfield(Option, 'ConstantValues') && ~isempty(Option.ConstantValues), ConstantValues = Option.ConstantValues;
            end
            if isempty(list), return; end
            if ~isempty(list(1).TopLines) && (list(1).TopLines(1) == 1)
                switch list(1).Top
                    case 'l'
                        if isempty(list(1).MiddleLines)
                            if list(1).TopLines(end) == 1
                                obj.Table(1, IncrementWhere) = obj.Table(1, AdditionWhere);
                            else
                                for rowN = list(1).TopLines(end): -1: 1
                                    obj.Table(rowN, IncrementWhere) = {obj.Table{rowN, AdditionWhere} - obj.Table{rowN-1, AdditionWhere}};
                                end
                            end
                            list(1) = [];
                        else
                            obj.Table(1, IncrementWhere) = obj.Table(1, AdditionWhere);
                            warning([obj.thisFixName, ' First Increment copied from Addition']);
                            for rowN = 2: list(1).TopLines(end)
                                obj.Table(rowN, IncrementWhere) = {obj.Table{rowN, AdditionWhere} - obj.Table{rowN-1, AdditionWhere}};
                            end
                            list(1).TopLines = []; list(1).Top = 'o';
                        end
                    case 'r'
                         if isempty(list(1).MiddleLines)
                            if ~ismissing(obj.Table{list(1).TopLines(end)+1, AdditionWhere}) && ...
                                    ~ismissing(obj.Table{list(1).TopLines(end)+1, IncrementWhere})
                                for rowN = list(1).TopLines(end): -1: 1
                                    obj.Table(rowN, AdditionWhere) = {obj.Table{rowN+1, AdditionWhere} - obj.Table{rowN+1, IncrementWhere}};
                                end
                            else
                                obj.Table(1, AdditionWhere) = obj.Table(1, IncrementWhere);
                                warning([obj.thisFixName, ' First Addition copied from Increment']);
                                for rowN = 2: list(1).TopLines(end)
                                    obj.Table(rowN, AdditionWhere) = {obj.Table{rowN-1, AdditionWhere} + obj.Table{rowN, IncrementWhere}};
                                end
                            end
                            list(1) = [];
                         else
                            obj.Table(1, AdditionWhere) = obj.Table(1, IncrementWhere);
                            warning([obj.thisFixName, ' First Addition copied from Increment']);
                            for rowN = 2: list(1).TopLines(end)
                                obj.Table(rowN, AdditionWhere) = {obj.Table{rowN-1, AdditionWhere} + obj.Table{rowN, IncrementWhere}};
                            end
                            list(1).TopLines = []; list(1).Top = 'o';
                         end
                end
            elseif isempty(list(1).TopLines) && ~isempty(list(1).MiddleLines) && (list(1).MiddleLines(1) == 1)
                if list(1).MiddleLines(end) == 1, obj.Missing.(obj.thisFixName).tpMissingBlocks = list; return; end
                % Define RemoveLines and Revise list (if to be filled with Constant Values)
                switch list(1).Bottom
                    case {'o', 'r'} % for 'o', MiddleLines >= 2
                        RemoveLines = [list(1).MiddleLines(1), list(1).MiddleLines(end) - 1];
                        list(1).MiddleLines = [list(1).MiddleLines(end), list(1).MiddleLines(end)];
                    case 'l'
                        RemoveLines = list(1).MiddleLines;
                        list(1).MiddleLines = [];
                        list(1).Top = list(1).Bottom; list(1).TopLines = list(1).BottomLines;
                end
                if exist('ConstantValues', 'var') && numel(ConstantValues) <= 2
                    if numel(ConstantValues) == 1
                        ConstantValues = [ConstantValues, ConstantValues];
                    end
                    for idxx = RemoveLines(1): RemoveLines(end)
                        obj.Table(idxx,IncrementWhere|AdditionWhere) = {ConstantValues(1), ConstantValues(2)};
                    end
                    warning([obj.thisFixName, ' First lines were missing, thus filled with given ConstantValues.']);
                elseif exist('ConstantValues', 'var'), warning('Too many ConstantValues');
                else
                    if isfield(Option, 'RemoveFirstRows') && ~Option.RemoveFirstRows
                        warning([obj.thisFixName, ' First lines were missing.']);
                    else
                        obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                        warning([obj.thisFixName, 'First lines were missing, thus removed.']);
                        obj.MissingValuesDetect(Option);
                        return
                    end
                end
            end
            obj.Missing.(obj.thisFixName).tpMissingBlocks = list;
        end
                    
        function obj = IncrementAddition_GroupBlocks(obj)
            list = obj.Missing.(obj.thisFixName).tpMissingBlocks;
            listGroup = struct.empty;
            for idxx = 1: length(list)
                if ~isempty(listGroup) && listGroup(end).GroupLines(1) <= idxx && idxx <= listGroup(end).GroupLines(end)
                    % do nothing
                else
                    thislistGroup = struct;
                    thislistGroup.GroupLines = [idxx, idxx];
                    thislistGroup.InterpolationLines = [];
                    thislistGroup.InterpolationFlag = [];
                    if ~isempty(list(idxx).MiddleLines)
                        switch list(idxx).Bottom
                            case 'o'
                                if list(idxx).MiddleLines(end) > list(idxx).MiddleLines(1)
                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(idxx).MiddleLines(end)];
                                    thislistGroup.InterpolationFlag = 'P';
                                end
                            case 'l'
                                thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(idxx).BottomLines(1)];
                                thislistGroup.InterpolationFlag = 'P';
                            case 'r'
                                if list(idxx).MiddleLines(end) > list(idxx).MiddleLines(1)
                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(idxx).MiddleLines(end)];
                                    thislistGroup.InterpolationFlag = 'P';
                                end
                                loopBool = true; times = 0;
                                while loopBool && (idxx + times + 1 <= length(list))
                                    times = times + 1; thisidx = idxx + times; lastidx = idxx + times - 1;
                                    if any(strcmp(list(thisidx).Top, 'l')) && ...
                                            list(lastidx).BottomLines(end) + 1 == list(thisidx).TopLines(1)
                                        thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).TopLines(1)];
                                        thislistGroup.InterpolationFlag = 'C';
                                        loopBool = false;
                                    elseif any(strcmp(list(thisidx).Top, 'o'))
                                        switch list(thisidx).Bottom
                                            case 'o'
                                                if list(thisidx).MiddleLines(1) == list(lastidx).BottomLines(end) + 1
                                                    thislistGroup.GroupLines = [idxx, thisidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).MiddleLines(end)];
                                                else
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(lastidx).MiddleLines(end)];
                                                end
                                                thislistGroup.InterpolationFlag = 'C';
                                                loopBool = false;
                                            case 'l'
                                                if list(thisidx).MiddleLines(1) == list(lastidx).BottomLines(end) + 1
                                                    thislistGroup.GroupLines = [idxx, thisidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).BottomLines(1)]; % Difference
                                                    thislistGroup.InterpolationFlag = 'C';
                                                end
                                                loopBool = false;
                                            case 'r'
                                                if list(thisidx).MiddleLines(1) == list(lastidx).BottomLines(end) + 1
                                                    thislistGroup.GroupLines = [idxx, thisidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).MiddleLines(end)];
                                                    thislistGroup.InterpolationFlag = 'C';
                                                else
                                                    thislistGroup.GroupLines = [idxx, lastidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(lastidx).MiddleLines(end)];
                                                    thislistGroup.InterpolationFlag = 'C';
                                                    loopBool = false;
                                                end
                                        end
                                    else
                                        if times > 1
                                            thislistGroup.GroupLines = [idxx, lastidx];
                                            thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(lastidx).MiddleLines(end)];
                                            thislistGroup.InterpolationFlag = 'C';
                                        end
                                        loopBool = false;
                                    end
                                end
                        end
                    end
                    listGroup = [listGroup; thislistGroup];
                end
            end
            obj.Missing.(obj.thisFixName).MissingBlocksGroup = listGroup;
        end

        function obj = IncrementAddition_FixingHelper(obj, Option)
            list = obj.Missing.(obj.thisFixName).tpMissingBlocks;
            IncrementWhere = obj.Missing.(obj.thisFixName).IncrementWhere;
            AdditionWhere = obj.Missing.(obj.thisFixName).AdditionWhere;
            listgroup = obj.Missing.(obj.thisFixName).MissingBlocksGroup;
            T = obj.Table;
            for groupidx = 1: length(listgroup)
                if listgroup(groupidx).GroupLines(1) == listgroup(groupidx).GroupLines(end)
                    % this group has only one line in list
                    thislistidx = listgroup(groupidx).GroupLines(1);
                    T = IncrementAddition_FixingHelper_Top(T, list, thislistidx, IncrementWhere, AdditionWhere);
                    T = IncrementAddition_FixingHelper_Bottom(T, list, thislistidx, IncrementWhere, AdditionWhere);
                    if ~isempty(listgroup(groupidx).InterpolationLines)
                        T = IncrementAddition_FixingHelper_Interpolation(T, IncrementWhere, AdditionWhere, listgroup(groupidx).InterpolationLines, listgroup(groupidx).InterpolationFlag, Option);
                    end
                    T = IncrementAddition_FixingHelper_Sweep(T, list, thislistidx, IncrementWhere, AdditionWhere);
                else
                    T = IncrementAddition_FixingHelper_Top(T, list, listgroup(groupidx).GroupLines(1), IncrementWhere, AdditionWhere);
                    T = IncrementAddition_FixingHelper_Bottom(T, list, listgroup(groupidx).GroupLines(end), IncrementWhere, AdditionWhere);
                    T = IncrementAddition_FixingHelper_Interpolation(T, IncrementWhere, AdditionWhere, listgroup(groupidx).InterpolationLines, listgroup(groupidx).InterpolationFlag, Option);
                    for listidx = listgroup(groupidx).GroupLines(1): listgroup(groupidx).GroupLines(end)
                        T = IncrementAddition_FixingHelper_Sweep(T, list, listidx, IncrementWhere, AdditionWhere);
                    end
                end
            end
            obj.Table = IncrementAddition_FixingHelper_Rectify(T, IncrementWhere, AdditionWhere, Option);
    
            function T = IncrementAddition_FixingHelper_Top(T, list, listidx, IncrementWhere, AdditionWhere)
                switch list(listidx).Top
                    case 'l' % TopLines(1) ~= 1, this case was handled in IncrementAddition_FixFirstRows
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                        end
                    case 'r' % TopLines(1) ~= 1, this case was handled in IncrementAddition_FixFirstRows
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T(rowN, AdditionWhere) = {T{rowN-1, AdditionWhere} + T{rowN, IncrementWhere}};
                        end
                    case 'o' % This case was handled elsewhere mostly.
                        % For listgroup input, this should not be operated.
                        % For single list input, this should be operated.
                        for rowidx = 1: size(obj.Missing.(obj.thisFixName).MissingBlocksGroup, 1)
                            if obj.Missing.(obj.thisFixName).MissingBlocksGroup(rowidx).GroupLines(1) == listidx
                                break
                            end
                        end
                        if obj.Missing.(obj.thisFixName).MissingBlocksGroup(rowidx).GroupLines(end) ~= listidx
                            return
                        end
                        % Then make sure there is only one middle line, or
                        % there need to have an interpolation, which is not
                        % covered here.
                        if list(listidx).MiddleLines(1) ~= list(listidx).MiddleLines(end)
                            return
                        end
                        switch list(listidx).Bottom
                            case 'o' % There is only one middle list which is missing
                                rowN = list(listidx).MiddleLines(1);
                                T(rowN, AdditionWhere) = {T{rowN+1, AdditionWhere} - T{rowN+1, IncrementWhere}};
                                if rowN == 1
                                    T(rowN, IncrementWhere) = T(rowN, AdditionWhere);
                                    warning([obj.thisFixName, ' First Increment copied from Addition']);
                                else
                                    T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                                end
                            case 'l' % This case was demolished in FirstRowsFix or needs interpolation
                            case 'r'
                                for rowN = list(listidx).BottomLines(end): -1: list(listidx).BottomLines(1) - 1 % = list(listidx).MiddleLines(1)
                                    T(rowN, AdditionWhere) = {T{rowN+1, AdditionWhere} - T{rowN+1, IncrementWhere}};
                                end % now, rowN = list(listidx).MiddleLines(1)
                                if rowN == 1
                                    T(rowN, IncrementWhere) = T(rowN, AdditionWhere);
                                    warning([obj.thisFixName, ' First Increment copied from Addition']);
                                else
                                    T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                                end
                        end
                end
            end
    
            function T = IncrementAddition_FixingHelper_Bottom(T, list, listidx, IncrementWhere, AdditionWhere)
                if listidx == 1, return; end
                switch list(listidx).Bottom
                    case 'l'
                        for rowN = list(listidx).BottomLines(end): -1: list(listidx).BottomLines(1) + 1
                            T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                        end
                    case 'r'
                        for rowN = list(listidx).BottomLines(end): -1: list(listidx).BottomLines(1) - 1
                            T(rowN, AdditionWhere) = {T{rowN+1, AdditionWhere} - T{rowN+1, IncrementWhere}};
                        end
                    case 'o'
                        rowN = list(listidx).MiddleLines(end);
                        T(rowN, AdditionWhere) = {T{rowN+1, AdditionWhere} - T{rowN+1, IncrementWhere}};
                        T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                end
            end
    
            function T = IncrementAddition_FixingHelper_Interpolation(T, IncrementWhere, AdditionWhere, InterpolationLines, InterpolationFlag, Option)
                startRow = InterpolationLines(1);
                endRow = InterpolationLines(end);
                scope = endRow - startRow + 1;
                switch InterpolationFlag
                    case 'P'
                        tpOption = Option;
                        if isfield(tpOption, 'InterpolationStyle_P') && ~isempty(tpOption.InterpolationStyle_P), tpOption.InterpolationStyle = tpOption.InterpolationStyle_P; end
                        if isfield(tpOption, 'InterpolationFunction_P') && ~isempty(tpOption.InterpolationStyle_P), tpOption.InterpolationFunction = tpOption.InterpolationFunction_P; end
                        T = Interpolation_Helper(T, startRow, endRow, AdditionWhere, tpOption);
                    case 'C'
                        tpOption = Option;
                        if isfield(tpOption, 'InterpolationStyle_C') && ~isempty(tpOption.InterpolationStyle_C), tpOption.InterpolationStyle = tpOption.InterpolationStyle_C; end
                        if isfield(tpOption, 'InterpolationFunction_C') && ~isempty(tpOption.InterpolationStyle_C), tpOption.InterpolationFunction = tpOption.InterpolationFunction_C; end
                        if (isfield(tpOption, 'InterpolationStyle') && ~isempty(tpOption.InterpolationStyle) && ~any(strcmp(tpOption.InterpolationStyle, {'Linear', 'LinearRound'}))) || (~isfield(tpOption.InterpolationStyle) && ~isfield(tpOption.InterpolationFunction))
                            tpOption.InterpolationStyle = 'Linear';
                            warning('C-interpolation using Linear style.');
                        end
                        tpT = T(startRow:endRow, IncrementWhere|AdditionWhere);
                        if find(IncrementWhere,1) < find(AdditionWhere, 1), tpIncrementWhere = 1; tpAdditionWhere = 2;
                        else, tpIncrementWhere = 2; tpAdditionWhere = 1;
                        end
                        if isfield(tpOption, 'InterpolationFunction') && ~isempty(tpOption.InterpolationFunction)
                            try
                                T = InterpolationFunction(T, startRow, endRow, IncrementWhere, AdditionWhere);
                                return
                            catch
                                error('InterpolationFunction_C not supported. Syntax: T = InterpolationFunction_C(T, startRow, endRow, IncrementWhere, AdditionWhere).');
                            end
                        end
                        valueScope = T{endRow, AdditionWhere} - T{startRow, AdditionWhere};
                        blockNum = 0;
                        blockRowList = [];
                        blockValueScopeList = [];
                        lastMissing = true;
                        for idxx = 2: size(tpT, 1)
                            if lastMissing && ~ismissing(tpT{idxx, tpIncrementWhere})
                                blockNum = blockNum + 1;
                                thisBlock = [idxx, idxx];
                                lastMissing = false;
                            elseif lastMissing && ismissing(tpT{idxx, tpIncrementWhere})
                                lastMissing = true;
                            elseif ~lastMissing && ~ismissing(tpT{idxx, tpIncrementWhere})
                                thisBlock(end) = idxx;
                                lastMissing = false;
                            elseif ~lastMissing && ismissing(tpT{idxx, tpIncrementWhere})
                                blockRowList = [blockRowList, thisBlock(1):thisBlock(end)];
                                blockValueScopeList = [blockValueScopeList, sum(tpT{thisBlock(1):thisBlock(end), 1})];
                                lastMissing = true;
                            end
                        end
                        diffScope = valueScope - sum(blockValueScopeList);
                        increment = diffScope / (blockNum + 1);
                        for rowidx = 2: size(tpT, 1) - 1
                            if any(blockRowList == rowidx)
                                tpT(rowidx,tpAdditionWhere) = {tpT{rowidx-1,tpAdditionWhere} + tpT{rowidx,tpIncrementWhere}};
                            else
                                tp = find(blockRowList < rowidx, 1, 'last');
                                if isempty(tp)
                                    tpFormer = 1;
                                else
                                    tpFormer = blockRowList(tp);
                                end
                                if tp == size(blockRowList, 2)
                                    tpLast = size(tpT, tpIncrementWhere);
                                elseif isempty(tp)
                                    tpLast = blockRowList(1);
                                else
                                    tpLast = blockRowList(tp + 1);
                                end
                                thisincrement = increment / (tpLast - tpFormer - 1);
                                switch tpOption.InterpolationStyle
                                    case 'LinearRound'
                                        tpT(rowidx,tpAdditionWhere) = {round(tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer))};
                                    otherwise
                                        tpT(rowidx,tpAdditionWhere) = {tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer)};
                                end
                            end
                        end
                        T(startRow:endRow, IncrementWhere|AdditionWhere) = tpT;
                end
            end
    
            function T = IncrementAddition_FixingHelper_Sweep(T, list, listidx, IncrementWhere, AdditionWhere)
                if ~isempty(list(listidx).TopLines)
                    startRow = list(listidx).TopLines(1);
                else
                    startRow = list(listidx).MiddleLines(1);
                end
                if ~isempty(list(listidx).BottomLines)
                    endRow = list(listidx).BottomLines(end);
                else
                    endRow = list(listidx).MiddleLines(end);
                end
                tpT = T(startRow:endRow, IncrementWhere);
                theMissingMap = ismissing(tpT);
                if any(any(theMissingMap))
                    theMissingIncrement = find(theMissingMap) + startRow - 1;
                    for idxx = 1: length(theMissingIncrement)
                        thisRow = theMissingIncrement(idxx);
                        try
                            T(thisRow, IncrementWhere) = {T{thisRow, AdditionWhere} - T{thisRow-1, AdditionWhere}};
                        catch
                        end
                        thisRow = theMissingIncrement(length(theMissingIncrement) - idxx + 1);
                        try
                            T(thisRow, IncrementWhere) = {T{thisRow, AdditionWhere} - T{thisRow-1, AdditionWhere}};
                        catch
                        end
                    end
                end
            end
    
            function T = IncrementAddition_FixingHelper_Rectify(T, IncrementWhere, AdditionWhere, Option)
                % Decreasing Addition Fixing
                if isfield(Option, 'DecreasingAdditionStyle') && ~isempty(Option.DecreasingAdditionStyle)
                    DAS = Option.DecreasingAdditionStyle;
                    if isa(DAS, 'function_handle')
                        try
                            T = DAS(T, IncrementWhere, AdditionWhere);
                            return
                        catch ME
                            warning('DecreasingAdditionStyle not supported. Syntax: T = DecreasingAdditionStyle(T, IncrementWhere, AdditionWhere).');
                            error(ME.message);
                        end
                    end
                else
                    DAS = 'Exponential';
                end
                if isfield(Option, 'DecreasingAdditionParameter') && ~isempty(Option.DecreasingAdditionParameter)
                    DAP = Option.DecreasingAdditionParameter;
                else
                    DAP = struct;
                    DAP.RoundingWindowAhead = -2;
                    DAP.RoundingWindowBehind = 2;
                    DAP.RoundingStrategy = @tsnanmean;
                    DAP.RoundingScale = 0.8;
                    DAP.ExponentialRate = 0.1;
                    DAP.AcceptedRatioMinimum = 0.1;
                    DAP.AcceptedRatioMaximum = 0.4;
                    DAP.SpanAheadSkip = 3;
                end
                for rowidx = 2: size(T, 1)
                    if T{rowidx, IncrementWhere} < 0
                        switch DAS
                            case 'Exponential'
                                tpT = T{max(rowidx+DAP.RoundingWindowAhead,1):min(size(T,1),rowidx+DAP.RoundingWindowBehind), IncrementWhere};
                                map = tpT(:,1) > 0;
                                roundIncrement = DAP.RoundingStrategy(tpT(map,:)) * DAP.RoundingScale;
                                T{rowidx, IncrementWhere} = roundIncrement;
                                delta = roundIncrement + T{rowidx-1, AdditionWhere} - T{rowidx, AdditionWhere};
                                for idx = rowidx-1: -1: 1
                                    rho = max(DAP.AcceptedRatioMaximum  * ((idx + 1) / rowidx)^(DAP.ExponentialRate), DAP.AcceptedRatioMinimum);
                                    if delta > 0 && idx <= max(rowidx - DAP.SpanAheadSkip, 1)
                                        if T{idx, IncrementWhere} * rho < delta 
                                            delta = delta - T{idx, IncrementWhere} * rho;
                                            T{idx, IncrementWhere} = (1-rho) * T{idx, IncrementWhere};
                                        elseif T{idx, IncrementWhere} * rho >= delta 
                                            T{idx, IncrementWhere} = T{idx, IncrementWhere} - delta;
                                            delta = 0;
                                        end
                                    end
                                    T{idx, AdditionWhere} = T{idx + 1, AdditionWhere} - T{idx + 1, IncrementWhere};
                                end
                                warning([obj.thisFixName, ' Data before row ', sprintf('%i', rowidx), ' were edited exponentially, due to decreasing addition.'])
                            case 'LinearScale'
                                ratio = T{rowidx, AdditionWhere} / T{rowidx-1, AdditionWhere};
                                T{1:rowidx-1,IncrementWhere|AdditionWhere} = T{1:rowidx-1,IncrementWhere|AdditionWhere} * ratio;
                                T{rowidx, IncrementWhere} = T{rowidx, AdditionWhere} - T{rowidx - 1, AdditionWhere};
                                warning([obj.thisFixName, ' Data before row ', sprintf('%i', rowidx), ' were linearly scaled, due to decreasing addition.'])
                            case 'DoNothing' % do nothing
                            otherwise, error('DecreaseAdditionStyle not supported. Try Exponential, LinearScale, or DoNothing.')
                        end
                    end
                end
                % Rounding and Adding Up
                if isfield(Option, 'InterpolationStyle') && strcmp(Option.InterpolationStyle, 'LinearRound')
                    T{:,AdditionWhere} = round(T{:,AdditionWhere});
                    T{1,IncrementWhere} = T{1,AdditionWhere};
                    for rowidx = 2: size(T, 1)
                        T{rowidx, IncrementWhere} = T{rowidx, AdditionWhere} - T{rowidx-1, AdditionWhere};
                    end
                else
                    for rowidx = 2: size(T, 1)
                        T{rowidx, AdditionWhere} = T{rowidx-1, AdditionWhere} + T{rowidx, IncrementWhere};
                    end
                end
                % Checking Addition
                for rowidx = 2: size(T, 1)
                    if isfield(Option, 'InterpolationStyle') && strcmp(Option.InterpolationStyle, 'Linear')
                        if abs(T{rowidx, IncrementWhere} + T{rowidx-1, AdditionWhere} - T{rowidx, AdditionWhere}) < 10*eps
                            % do nothing
                        else
                            warning([obj.thisFixName, ' Wrong addition in row', sprintf('%i', rowidx)]);
                        end
                    else
                        if T{rowidx, IncrementWhere} + T{rowidx-1, AdditionWhere} == T{rowidx, AdditionWhere}
                            % do nothing
                        else
                            warning([obj.thisFixName, ' Wrong addition in row', sprintf('%i', rowidx)]);
                        end
                    end
                end
            end
        end
    end
    
    % Other methods
end

% Helper
function T = Interpolation_Helper(T, startRow, endRow, Map, Option)
    scope = endRow - startRow + 1;
    if isfield(Option, 'InterpolationStyle')
        switch Option.InterpolationStyle
            case 'Linear'
                increment = (T{endRow, Map} - T{startRow, Map}) / (scope - 1);
                for rowidx = startRow + 1: endRow - 1
                    T(rowidx, Map) = {T{startRow, Map} + increment * (rowidx - startRow)};
                end
            case 'LinearRound'
                increment = (T{endRow, Map} - T{startRow, Map}) / (scope - 1);
                for rowidx = startRow + 1: endRow - 1
                    T(rowidx, Map) = {round(T{startRow, Map} + increment * (rowidx - startRow))};
                end
            otherwise
                try
                    InterpolationStyle = eval(['@', Option.InterpolationStyle]);
                    arr = arrayfun(@(x)x, 1:scope)';
                    arr = arr(2:end-1);
                    T{startRow+1:endRow-1, Map} = InterpolationStyle([1 scope], [T{startRow,Map},T{endRow,Map}], arr);
                catch
                    error('InterpolationStyle not supported. Syntax: T{startRow+1,endRow-1,VariableMap} = @InterpolationStyle(x_value, y_value, interpolation_value).');
                end
        end
    elseif isfield(Option, 'InterpolationFunction')
        try
            T = InterpolationFunction(T, startRow, endRow, Map);
        catch
            error('InterpolationFunction not supported. Syntax: T = InterpolationFunction(T, startRow, endRow, VariableMap).');
        end
    end
end