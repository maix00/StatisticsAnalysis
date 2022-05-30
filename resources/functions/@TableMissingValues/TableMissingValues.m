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
                            elseif isa(GeneralOptions{idx, 3}, 'cell')
                                try
                                    tpO = OptionsSizeHelper(GeneralOptions{idx, 3}, 2, true);
                                    vn = fieldnames(tpO);
                                    ValidateStyleOptions(thisStyle, thisVN, vn);
                                    obj.GeneralOptions(idx, 1).VariableNames = GeneralOptions{idx, 1};
                                    obj.GeneralOptions(idx, 1).Style = char(thisStyle);
                                    for opt_idx = vn'
                                        opt = opt_idx{1};
                                        obj.GeneralOptions(idx, 1).(opt) = tpO.(opt);
                                    end
                                catch ME
                                    warning('Ambiguous inputs in Cell.Options, use Struct or Tabular.');
                                    error(ME.message);
                                end
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
                        IOptionsList = {'InterpolationStyle', 'InterpolationFunction', 'ConstantValues'};
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
                    obj.thisFixName = ['IA_', Option.VariableNames{1}, '_', Option.VariableNames{2}];
                    obj.Missing.(obj.thisFixName) = TableMissingValues_IncrementAdditionMissingBlocks(obj.Table, Option.VariableNames{:});
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
                    obj.IncrementAddition_FixingHelper(Option);
                case 'MissingDetect' % do nothing
                case 'Interpolation'
                    for idx = 1: length(obj.Table.Properties.VariableNames)
                        Map = strcmp(obj.Table.Properties.VariableNames{idx}, obj.Table.Properties.VariableNames);
                        FirstLast = obj.Missing.(obj.Table.Properties.VariableNames{idx});
                        for idxx = 1: length(FirstLast)
                            startRow = FirstLast{idxx}(1)-1; endRow = FirstLast{idxx}(2)+1;
                            if all(ismissing(obj.Table(startRow:endRow, Map)))
                                obj.Table = fillmissing(T, 'constant', Option.ConstantValues);
                            elseif (startRow == 1) || (endRow == size(obj.Table,1))
                            else
                                obj.Table = Interpolation_Helper(obj.Table, startRow, endRow, Map, Option);
                            end
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
        function obj = IncrementAddition_FixFirstRows(obj, Option)
            if ~isfield(obj.Missing.(obj.thisFixName).MissingBlocksGroups, 'FirstLine')
                obj.Missing.(obj.thisFixName).tpMissingBlocks = obj.Missing.(obj.thisFixName).MissingBlocks;
                return
            end
            MB = obj.Missing.(obj.thisFixName).MissingBlocks; if isempty(MB), return; end
            IW = obj.Missing.(obj.thisFixName).IncrementWhere;
            AW = obj.Missing.(obj.thisFixName).AdditionWhere;
            if isfield(Option, 'ConstantValues_FirstRows') && ~isempty(Option.ConstantValues_FirstRows), ConstantValues = Option.ConstantValues_FirstRows; 
            elseif isfield(Option, 'ConstantValues') && ~isempty(Option.ConstantValues), ConstantValues = Option.ConstantValues;
            end
            switch MB(1).Top
                case 'I'
                    obj.Table(1, IW) = obj.Table(1, AW);
                    warning([obj.thisFixName, '. First Increment copied from Addition.']);
                    for rowN = 2: MB(1).TopLines(end)
                        obj.Table{rowN, IW} = obj.Table{rowN, AW} - obj.Table{rowN-1, AW};
                    end
                case 'A'
                    if isempty(MB(1).MiddleLines) && obj.Missing.(obj.thisFixName).tpMissingBlocksGroup(1).Range(1) == obj.Missing.(obj.thisFixName).tpMissingBlocksGroup(1).Range(end)
                        for rowN = MB(1).TopLines(end): -1: 1
                            obj.Table{rowN, AW} = obj.Table{rowN+1, AW} - obj.Table{rowN+1, IW};
                        end
                    else
                        obj.Table(1, AW) = obj.Table(1, IW);
                        warning([obj.thisFixName, '. First Addition copied from Increment.']);
                        for rowN = 2: MB(1).TopLines(end)
                            obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                        end
                    end
                case 'F'
                    if MB(1).MiddleLines(end) == 1
                        switch MB(1).Bottom
                            case 'I'
                                RemoveLines = [1 1];
                                obj.Table(2, IW) = obj.Table(2, AW);
                                warning([obj.thisFixName, '. Second Increment copied from Addition.']);
                                for rowN = 3: MB(1).BottomLines(end)
                                    obj.Table{rowN, IW} = obj.Table{rowN, AW} - obj.Table{rowN-1, AW};
                                end
                            case 'A'
                                if obj.Missing.(obj.thisFixName).MissingBlocksGroups(1).Range(1) == obj.Missing.(obj.thisFixName).MissingBlocksGroups(1).Range(end)
                                    for rowN = MB(1).BottomLines(end): -1: 2
                                        obj.Table{rowN, AW} = obj.Table{rowN+1, AW} - obj.Table{rowN+1, IW};
                                    end
                                else
                                    RemoveLines = [1 1];
                                    obj.Table(2, AW) = obj.Table(2, IW);
                                    warning([obj.thisFixName, '. Second Addition copied from Increment.']);
                                    for rowN = 3: MB(1).BottomLines(end)
                                        obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                                    end
                                end
                            case 'F'
                                obj.Table{1, AW} = obj.Table{2, AW} - obj.Table{2, IW};
                                obj.Table(1, IW) = obj.Table(1, AW);
                                warning([obj.thisFixName, '. First Increment copied from Addition.']);
                        end
                    else
                        switch MB(1).Bottom
                            case 'I'
                                RemoveLines = MB(1).MiddleLines;
                                tp = MB(1).BottomLines(1);
                                obj.Table(tp, IW) = obj.Table(tp, AW);
                                warning([obj.thisFixName, '. Increment at row ', sprintf('%i',tp), ' copied from Addition.']);
                                for rowN = tp+1: MB(1).BottomLines(end)
                                    obj.Table{rowN, IW} = obj.Table{rowN, AW} - obj.Table{rowN-1, AW};
                                end
                            case 'A'
                                if obj.Missing.(obj.thisFixName).MissingBlocksGroups(1).Range(1) == obj.Missing.(obj.thisFixName).MissingBlocksGroups(1).Range(end)
                                    RemoveLines = [MB(1).MiddleLines(1), MB(1).MiddleLines(end) - 1];
                                    for rowN = MB(1).BottomLines(end): -1: MB(1).MiddleLines(end)
                                        obj.Table{rowN, AW} = obj.Table{rowN+1, AW} - obj.Table{rowN+1, IW};
                                    end
                                else
                                    RemoveLines = MB(1).MiddleLines;
                                    tp = MB(1).BottomLines(1);
                                    obj.Table(tp, AW) = obj.Table(tp, IW);
                                    warning([obj.thisFixName, '. Addition at row ', sprintf('%i',tp), ' copied from Increment.']);
                                    for rowN = tp+1: MB(1).BottomLines(end)
                                        obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                                    end
                                end
                            case 'F'
                                tp = MB(1).MiddleLines(end);
                                RemoveLines = [MB(1).MiddleLines(1), tp - 1];
                                obj.Table{tp, AW} = obj.Table{2, AW} - obj.Table{tp, IW};
                                obj.Table(tp, IW) = obj.Table(tp, AW);
                                warning([obj.thisFixName, '. Increment at row ', sprintf('%i',tp), ' copied from Addition.']);
                        end
                    end
            end
            if exist('RemoveLines', 'var')
                if exist('ConstantValues', 'var') && numel(ConstantValues) <= 2
                    if numel(ConstantValues) == 1
                        ConstantValues = [ConstantValues, ConstantValues];
                    end
                    for idxx = RemoveLines(1): RemoveLines(end)
                        obj.Table(idxx,IW|AW) = {ConstantValues(1), ConstantValues(2)};
                    end
                    warning([obj.thisFixName, '. First lines were missing, thus filled with given ConstantValues.']);
                elseif exist('ConstantValues', 'var'), warning('Too many ConstantValues');
                else
                    if isfield(Option, 'RemoveFirstRows') && ~Option.RemoveFirstRows
                        warning([obj.thisFixName, ' First lines were missing.']);
                    else
                        obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                        warning([obj.thisFixName, '. First lines were missing, thus removed.']);
                    end
                end
            end
            obj.Missing.(obj.thisFixName) = TableMissingValues_IncrementAdditionMissingBlocks( ...
                obj.Table, ...
                obj.Missing.(obj.thisFixName).Increment, ...
                obj.Missing.(obj.thisFixName).Addition, ...
                obj.Missing.(obj.thisFixName) ...
                );
        end

        function obj = IncrementAddition_RemoveLastRows(obj, Option)
            if ~isfield(obj.Missing.(obj.thisFixName).MissingBlocksGroups, 'LastLine'), return; end
            MB = obj.Missing.(obj.thisFixName).tpMissingBlocks; if isempty(MB), return; end
            IW = obj.Missing.(obj.thisFixName).IncrementWhere;
            AW = obj.Missing.(obj.thisFixName).AdditionWhere;
            if obj.Missing.(obj.thisFixName).MissingBlocksGroups(end).Range(1) == obj.Missing.(obj.thisFixName).MissingBlocksGroups(end).Range(end)
                switch MB(end).Bottom
                    case 'F', RemoveLines = MB(end).MiddleLines;
                        if ~isempty(MB(end).TopLines)
                            switch MB(end).TopLines
                                case 'A'
                                    for rowN = MB(end).TopLines(1): MB(end).TopLines(end)
                                        obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                                    end
                                case 'I'
                                    for rowN = MB(end).TopLines(1): MB(end).TopLines(end)
                                        obj.Table{rowN, IW} = obj.Table{rowN, AW} - obj.Table{rowN-1, AW};
                                    end
                            end
                        else
%                             if (length(MB) >= 2) && (MB(end-1).BottomLines(end) == MB(end-1).MiddleLines(1)) && (strcmp(MB(end-1).Bottom, 'I')) ...
%                                     && (obj.Missing.(obj.thisFixName).MissingBlocksGroups(end-1).Range(1) ~= obj.Missing.(obj.thisFixName).MissingBlocksGroups(end-1).Range(end))
%                                 DO NOTHING
%                             end
                        end
                    case 'A'
                        if ~isempty(MB(end).MiddleLines)
                            RemoveLines = [MB(end).MiddleLines(1), MB(end).BottomLines(end)];
                            if ~isempty(MB(end).TopLines)
                                for rowN = MB(end).TopLines(1): MB(end).TopLines(end)
                                    obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                                end
                            end
                        else
                            for rowN = MB(end).TopLines(1): MB(end).TopLines(end)
                                obj.Table{rowN, AW} = obj.Table{rowN-1, AW} + obj.Table{rowN, IW};
                            end
                        end
                    case 'I'
                        for rowN = MB(end).TopLines(1): MB(end).TopLines(end)
                            obj.Table{rowN, IW} = obj.Table{rowN, AW} - obj.Table{rowN-1, AW};
                        end
                end
            else
                if strcmp(obj.Missing.(obj.thisFixName).MissingBlocksGroups(end).Interpolation(end).Style, 'C')
                    RemoveLines = [obj.Missing.(obj.thisFixName).MissingBlocksGroups(end).Interpolation(end).Lines(1), size(obj.Table,1)];
                end
            end
            if exist('RemoveLines', 'var') && ~isempty(RemoveLines)
                if isfield(Option, 'RemoveLastRows') && ~Option.RemoveLastRows
                    warning([obj.thisFixName, '. Last lines were somehow missing.']);
                else
                    obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                    warning([obj.thisFixName, '. Last lines were somehow missing, thus removed.']);
                end
            end
            obj.Missing.(obj.thisFixName) = TableMissingValues_IncrementAdditionMissingBlocks( ...
                obj.Table, ...
                obj.Missing.(obj.thisFixName).Increment, ...
                obj.Missing.(obj.thisFixName).Addition, ...
                obj.Missing.(obj.thisFixName) ...
                );
        end
        
        function obj = IncrementAddition_FixingHelper(obj, Option)
            L = obj.Missing.(obj.thisFixName).tpMissingBlocks;
            IW = obj.Missing.(obj.thisFixName).IncrementWhere;
            AW = obj.Missing.(obj.thisFixName).AdditionWhere;
            G = obj.Missing.(obj.thisFixName).MissingBlocksGroups;
            for groupidx = 1: length(G)
                if G(groupidx).Range(1) == G(groupidx).Range(end)
                    % this group has only one line in list
                    thislistidx = G(groupidx).Range(1);
                    obj.Table = IncrementAddition_FixingHelper_Top(obj.Table, L, thislistidx, IW, AW);
                    obj.Table = IncrementAddition_FixingHelper_Bottom(obj.Table, L, thislistidx, IW, AW);
                    if isfield(G, 'Interpolation') && ~isempty(G(groupidx).Interpolation)
                        obj.Table = IncrementAddition_FixingHelper_Interpolation(obj.Table, IW, AW, G(groupidx).Interpolation, Option);
                    end
                    obj.Table = IncrementAddition_FixingHelper_Sweep(obj.Table, L, thislistidx, IW, AW);
                else
                    obj.Table = IncrementAddition_FixingHelper_Top(obj.Table, L, G(groupidx).Range(1), IW, AW);
                    obj.Table = IncrementAddition_FixingHelper_Bottom(obj.Table, L, G(groupidx).Range(end), IW, AW);
                    if isfield(G, 'Interpolation') && ~isempty(G(groupidx).Interpolation)
                        obj.Table = IncrementAddition_FixingHelper_Interpolation(obj.Table, IW, AW, G(groupidx).Interpolation, Option);
                    end
                    for listidx = G(groupidx).Range(1): G(groupidx).Range(end)
                        obj.Table = IncrementAddition_FixingHelper_Sweep(obj.Table, L, listidx, IW, AW);
                    end
                end
                
            end
            obj.Table = IncrementAddition_FixingHelper_Rectify(obj.Table, IW, AW, Option);
    
            function T = IncrementAddition_FixingHelper_Top(T, list, listidx, IW, AW)
                switch list(listidx).Top
                    case 'I'
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T{rowN, IW} = T{rowN, AW} - T{rowN-1, AW};
                        end
                    case 'A'
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T{rowN, AW} = T{rowN-1, AW} + T{rowN, IW};
                        end
                end
            end
    
            function T = IncrementAddition_FixingHelper_Bottom(T, list, listidx, IW, AW)
                switch list(listidx).Bottom
                    case 'I'
                        for rowN = list(listidx).BottomLines(end): -1: list(listidx).BottomLines(1) + 1
                            T{rowN, IW} = T{rowN, AW} - T{rowN-1, AW};
                        end
                    case 'A'
                        for rowN = list(listidx).BottomLines(end): -1: list(listidx).BottomLines(1) - 1
                            T{rowN, AW} = T{rowN+1, AW} - T{rowN+1, IW};
                        end
                    case 'F'
                        rowN = list(listidx).MiddleLines(end);
                        T{rowN, AW} = T{rowN+1, AW} - T{rowN+1, IW};
                        T{rowN, IW} = T{rowN, AW} - T{rowN-1, AW};
                end
            end
    
            function T = IncrementAddition_FixingHelper_Interpolation(T, IW, AW, IP, Option)
                for idx = 1: length(IP)
                    startRow = IP(idx).Lines(1) - 1;
                    endRow = IP(idx).Lines(end) + 1;
                    scope = endRow - startRow + 1;
                    switch IP(idx).Style
                        case 'P'
                            T = Interpolation_Helper(T, startRow, endRow, AW, Option);
                        case 'C'
                            if isfield(Option, 'InterpolationStyle_C') && ~isempty(Option.InterpolationStyle_C), SC = Option.InterpolationStyle_C; end
                            if ~exist('SC', 'var') && isfield(Option, 'InterpolationStyle') && ~isempty(Option.InterpolationStyle), SC = Option.InterpolationStyle; end
                            if isfield(Option, 'InterpolationFunction_C') && ~isempty(Option.InterpolationStyle_C), FC = Option.InterpolationFunction_C; end
                            if ~exist('SC', 'var') || (exist('SC', 'var') && ~any(strcmp(SC, {'Linear', 'LinearRound'}))), SC = 'Linear'; warning('C-interpolation using Linear style.'); end
                            tpT = T(startRow:endRow, IW|AW);
                            if find(IW,1) < find(AW, 1), tpIncrementWhere = 1; tpAdditionWhere = 2;
                            else, tpIncrementWhere = 2; tpAdditionWhere = 1;
                            end
                            if isfield(Option, 'InterpolationFunction') && ~isempty(Option.InterpolationFunction)
                                try
                                    T = InterpolationFunction(T, startRow, endRow, IW, AW);
                                    return
                                catch
                                    error('InterpolationFunction_C not supported. Syntax: T = InterpolationFunction_C(T, startRow, endRow, IncrementWhere, AdditionWhere).');
                                end
                            end
                            valueScope = T{endRow, AW} - T{startRow, AW};
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
                                    switch SC
                                        case 'LinearRound'
                                            tpT(rowidx,tpAdditionWhere) = {round(tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer))};
                                        otherwise
                                            tpT(rowidx,tpAdditionWhere) = {tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer)};
                                    end
                                end
                            end
                            T(startRow:endRow, IW|AW) = tpT;
                    end
                end
            end

            function T = IncrementAddition_FixingHelper_Sweep(T, list, listidx, IW, AW)
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
                tpT = T(startRow:endRow, IW);
                theMissingMap = ismissing(tpT);
                if any(any(theMissingMap))
                    theMissingIncrement = find(theMissingMap) + startRow - 1;
                    for idxx = 1: length(theMissingIncrement)
                        thisRow = theMissingIncrement(idxx);
                        try
                            T(thisRow, IW) = {T{thisRow, AW} - T{thisRow-1, AW}};
                        catch
                        end
                        thisRow = theMissingIncrement(length(theMissingIncrement) - idxx + 1);
                        try
                            T(thisRow, IW) = {T{thisRow, AW} - T{thisRow-1, AW}};
                        catch
                        end
                    end
                end
            end
    
            function T = IncrementAddition_FixingHelper_Rectify(T, IW, AW, Option)
                % Decreasing Addition Fixing
                if isfield(Option, 'DecreasingAdditionStyle') && ~isempty(Option.DecreasingAdditionStyle)
                    DAS = Option.DecreasingAdditionStyle;
                    if isa(DAS, 'function_handle')
                        try
                            T = DAS(T, IW, AW);
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
                    if T{rowidx, IW} < 0
                        switch DAS
                            case 'Exponential'
                                tpT = T{max(rowidx+DAP.RoundingWindowAhead,1):min(size(T,1),rowidx+DAP.RoundingWindowBehind), IW};
                                map = tpT(:,1) > 0;
                                roundIncrement = DAP.RoundingStrategy(tpT(map,:)) * DAP.RoundingScale;
                                T{rowidx, IW} = roundIncrement;
                                delta = roundIncrement + T{rowidx-1, AW} - T{rowidx, AW};
                                for idx = rowidx-1: -1: 1
                                    rho = max(DAP.AcceptedRatioMaximum  * ((idx + 1) / rowidx)^(DAP.ExponentialRate), DAP.AcceptedRatioMinimum);
                                    if delta > 0 && idx <= max(rowidx - DAP.SpanAheadSkip, 1)
                                        if T{idx, IW} * rho < delta 
                                            delta = delta - T{idx, IW} * rho;
                                            T{idx, IW} = (1-rho) * T{idx, IW};
                                        elseif T{idx, IW} * rho >= delta 
                                            T{idx, IW} = T{idx, IW} - delta;
                                            delta = 0;
                                        end
                                    end
                                    T{idx, AW} = T{idx + 1, AW} - T{idx + 1, IW};
                                end
                                warning([obj.thisFixName, ' Data before row ', sprintf('%i', rowidx), ' were edited exponentially, due to decreasing addition.'])
                            case 'LinearScale'
                                ratio = T{rowidx, AW} / T{rowidx-1, AW};
                                T{1:rowidx-1,IW|AW} = T{1:rowidx-1,IW|AW} * ratio;
                                T{rowidx, IW} = T{rowidx, AW} - T{rowidx - 1, AW};
                                warning([obj.thisFixName, ' Data before row ', sprintf('%i', rowidx), ' were linearly scaled, due to decreasing addition.'])
                            case 'DoNothing' % do nothing
                            otherwise, error('DecreaseAdditionStyle not supported. Try Exponential, LinearScale, or DoNothing.')
                        end
                    end
                end
                switch DAS
                    case 'DoNothing' % do nothing
                    otherwise
                       warning('Decreasing Addition Fix. To turn off this feature, set parameter "DecreasingAdditionStyle" as "DoNothing".');
                end
                % Rounding and Adding Up
                if isfield(Option, 'InterpolationStyle') && strcmp(Option.InterpolationStyle, 'LinearRound')
                    T{:,AW} = round(T{:,AW});
                    T{1,IW} = T{1,AW};
                    for rowidx = 2: size(T, 1)
                        tp = T{rowidx, AW} - T{rowidx-1, AW};
                        if ~ismissing(tp),  T{rowidx, IW} = tp; end
                    end
                else
                    for rowidx = 2: size(T, 1)
                        tp = T{rowidx-1, AW} + T{rowidx, IW};
                        if ~ismissing(tp), T{rowidx, AW} = tp; end
                    end
                end
                % Checking Addition
                for rowidx = 2: size(T, 1)
                    if isfield(Option, 'InterpolationStyle') && strcmp(Option.InterpolationStyle, 'Linear')
                        if abs(T{rowidx, IW} + T{rowidx-1, AW} - T{rowidx, AW}) < 10*eps
                            % do nothing
                        else
                            warning([obj.thisFixName, ' Wrong addition in row', sprintf('%i', rowidx)]);
                        end
                    else
                        if T{rowidx, IW} + T{rowidx-1, AW} == T{rowidx, AW}
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
    if startRow == 0, error('Interpolation at Row 0'); end
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
                    tpStartRow = startRow + 1; tpEndRow = endRow - 1;
                    for row = startRow: -1: 1
                        if ~ismissing(T{row,Map})
                            startRow = row;
                        else
                            break
                        end
                    end
                    for row = endRow: size(T, 1)
                        if ~ismissing(T{row,Map})
                            endRow = row;
                        else
                            break
                        end
                    end
                    scope = endRow - startRow + 1;
                    InterpolationStyle = eval(['@', Option.InterpolationStyle]);
                    arr = arrayfun(@(x)x, 1:scope)';
                    arr1 = arr; arr1(tpStartRow-startRow+1:tpEndRow-startRow+1) = [];
                    arr2 = arr(tpStartRow-startRow+1:tpEndRow-startRow+1);
                    tpT = T{startRow:endRow,Map};
                    tpT(tpStartRow-startRow+1:tpEndRow-startRow+1) = [];
                    T{tpStartRow:tpEndRow, Map} = InterpolationStyle(arr1, tpT, arr2);
                catch
                    error('InterpolationStyle not supported. Syntax: T{startLines,endLines,VariableMap} = @InterpolationStyle(x_value, y_value, interpolation_value).');
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