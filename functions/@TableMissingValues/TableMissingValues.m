classdef TableMissingValues < handle

    properties
        Table
        Options
        Missing = struct;
    end

    properties(Hidden)
        OriginalTable
        thisFixName
    end

    methods
        function obj = TableMissingValues(T, varargin)
            ips = inputParser;
            ips.addParameter('Options', struct, @(x)validateattributes(x, {'table', 'cell', 'struct'}, {}));
            ips.parse(varargin{:})

            OptionsName = {'VariableNames', 'Style', 'InterpolationStyle', 'ConstantValues'};
            obj.OriginalTable = T;
            obj.Table = T;

            % Options Convert to struct
            if isa(ips.Results.Options, 'table')
                obj.Options = table2struct(ips.Results.Options);
            elseif isa(ips.Results.Options, 'cell')
                obj.Options = cell2struct(ips.Results.Options, OptionsName, 2);
            elseif isa(ips.Results.Options, 'struct')
                obj.Options = ips.Results.Options;
            end

            % Missing Values Helper
            if isempty(fieldnames(obj.Options))
                obj.Options.VariableNames = obj.Table.Properties.VariableNames;
                obj.Options.Style = 'MissingDetect';
            end
            for idx = 1: numel(obj.Options)
                % Check Option Validity
                % VariableNames initialize
                if ~isfield(obj.Options(idx), 'VariableNames')
                    obj.Options(idx).VariableNames = obj.Table.Properties.VariableNames{1};
                    warning('No fieldname VariableNames, set to first variable.');
                else
                    if isa(obj.Options(idx).VariableNames, 'cell')
                        sz = size(obj.Options(idx).VariableNames);
                        nel = numel(obj.Options(idx).VariableNames);
                        if ~all(sz == [1, nel])
                            tp_VariableNames = cell(1, nel);
                            for idxx = 1: nel
                                tp_VariableNames(idxx) = obj.Options(idx).VariableNames(idxx);
                            end
                            obj.Options(idx).VariableNames = tp_VariableNames;
                        end
                    else
                        obj.Options(idx).VariableName = {obj.Options(idx).VariableName};
                    end
                end
                % VariableNames should match Style
                if isfield(obj.Options(idx), 'Style')
                    switch obj.Options(idx).Style
                        case 'Increment-Addition'
                            if numel(obj.Options(idx).VariableNames) ~= 2
                                error('Increment-Addition Style requires 2 VariableNames.');
                            end
                    end
                else
                    obj.Options(idx).Style = 'MissingDetect';
                end
                % Detect and Fix Missing Values
                obj.MissingValuesHelper(obj.Options(idx));
            end
            
        end
    end

    methods(Access=private)
        function obj = MissingValuesHelper(obj, Option)
            obj.MissingValuesDetect(Option);
            if isfield(Option, 'InterpolationStyle')
                obj.MissingValuesFix(Option);
            end
        end

        function obj = MissingValuesDetect(obj, Option)
            obj.Missing.Map = ismissing(obj.Table);
            for idx = 1: length(obj.Table.Properties.VariableNames)
                obj.Missing.(obj.Table.Properties.VariableNames{idx}) = FirstLastFindTrue(obj.Missing.Map(:,idx));
            end
            switch Option.Style
                case 'Increment-Addition'
                    obj.thisFixName = ['increment_addition_', Option.VariableNames{1}, '_', Option.VariableNames{2}];
                    obj.Missing.(obj.thisFixName) = struct;
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
                    obj.IncrementAddition_RemoveLastLines;
                    obj.IncrementAddition_FixFirstRows(Option);
                    obj.IncrementAddition_GroupBlocks;
                    obj.IncrementAddition_FixingHelper(Option);
                case 'MissingDetect' % do nothing
                case 'Interpolation'
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
                    warning(['Increment-Addition. Addition was decreasing at rows [', sprintf('%i', idxx-1), ',', sprintf('%i', idxx), ']']);
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
            obj.Missing.(obj.thisFixName).MissingBlocks = list;
        end

        function obj = IncrementAddition_RemoveLastLines(obj)
            list = obj.Missing.(obj.thisFixName).MissingBlocks;
            if isempty(list), return; end
            loopBool = true;
            while loopBool
                thisidx = length(list);
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
                    obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                    warning('Increment-Addition. Last lines were missing in Addition or in both Increment and Addition, thus removed.')
                    RemoveLines = [];
                end
            end
            obj.Missing.(obj.thisFixName).MissingBlocks = list;
        end
        
        function obj = IncrementAddition_FixFirstRows(obj, Option)
            list = obj.Missing.(obj.thisFixName).MissingBlocks;
            IncrementWhere = obj.Missing.(obj.thisFixName).IncrementWhere;
            AdditionWhere = obj.Missing.(obj.thisFixName).AdditionWhere;
            if isfield(Option, 'ConstantValues'), ConstantValues = Option.ConstantValues; end
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
                            warning('Increment-Addition. First Increment copied from Addition');
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
                                warning('Increment-Addition. First Addition copied from Increment');
                                for rowN = 2: list(1).TopLines(end)
                                    obj.Table(rowN, AdditionWhere) = {obj.Table{rowN-1, AdditionWhere} + obj.Table{rowN, IncrementWhere}};
                                end
                            end
                            list(1) = [];
                         else
                            obj.Table(1, AdditionWhere) = obj.Table(1, IncrementWhere);
                            warning('Increment-Addition. First Addition copied from Increment');
                            for rowN = 2: list(1).TopLines(end)
                                obj.Table(rowN, AdditionWhere) = {obj.Table{rowN-1, AdditionWhere} + obj.Table{rowN, IncrementWhere}};
                            end
                            list(1).TopLines = []; list(1).Top = 'o';
                         end
                end
            elseif isempty(list(1).TopLines) && ~isempty(list(1).MiddleLines) && (list(1).MiddleLines(1) == 1)
                RemoveLines = list(1).MiddleLines;
                if any(strcmp(list(1).Bottom, {'r', 'l'}))
                    list(1).MiddleLines = [];
                    list(1).Top = list(1).Bottom; list(1).TopLines = list(1).BottomLines;
                end
                if ~isempty(ConstantValues) && numel(ConstantValues) <= 2
                    if numel(ConstantValues) == 1
                        ConstantValues = [ConstantValues, ConstantValues];
                    end
                    for idxx = RemoveLines(1): RemoveLines(end)
                        obj.Table(idxx,IncrementWhere|AdditionWhere) = {ConstantValues(1), ConstantValues(2)};
                    end
                    warning('Increment-Addition. First lines were missing, thus filled with given ConstantValues.')
                else
                    if ~isempty(ConstantValues), warning('Too many ConstantValues'); end
                    obj.Table(RemoveLines(1):RemoveLines(end),:) = [];
                    warning('Increment-Addition. First lines were missing, thus removed.')
                end
                obj.IncrementAddition_MissingBlocksDetect;
            end
            obj.Missing.(obj.thisFixName).MissingBlocks = list;
        end
                    
        function obj = IncrementAddition_GroupBlocks(obj)
            list = obj.Missing.(obj.thisFixName).MissingBlocks;
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
                                        thislistGroup.InterpolationFlag = ']';
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
                                                thislistGroup.InterpolationFlag = ']';
                                                loopBool = false;
                                            case 'l'
                                                if list(thisidx).MiddleLines(1) == list(lastidx).BottomLines(end) + 1
                                                    thislistGroup.GroupLines = [idxx, thisidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).BottomLines(1)]; % Difference
                                                    thislistGroup.InterpolationFlag = ']';
                                                end
                                                loopBool = false;
                                            case 'r'
                                                if list(thisidx).MiddleLines(1) == list(lastidx).BottomLines(end) + 1
                                                    thislistGroup.GroupLines = [idxx, thisidx];
                                                    if thisidx == length(list)
                                                        thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(thisidx).MiddleLines(end)];
                                                        thislistGroup.InterpolationFlag = ']';
                                                        loopBool = false;
                                                    end
                                                else
                                                    thislistGroup.GroupLines = [idxx, lastidx];
                                                    thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(lastidx).MiddleLines(end)];
                                                    thislistGroup.InterpolationFlag = ']';
                                                    loopBool = false;
                                                end
                                        end
                                    else
                                        if times > 1
                                            thislistGroup.GroupLines = [idxx, lastidx];
                                            thislistGroup.InterpolationLines = [list(idxx).MiddleLines(1)-1, list(lastidx).MiddleLines(end)];
                                            thislistGroup.InterpolationFlag = ']';
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
            list = obj.Missing.(obj.thisFixName).MissingBlocks;
            IncrementWhere = obj.Missing.(obj.thisFixName).IncrementWhere;
            AdditionWhere = obj.Missing.(obj.thisFixName).AdditionWhere;
            listgroup = obj.Missing.(obj.thisFixName).MissingBlocksGroup;
            InterpolationStyle = Option.InterpolationStyle;
            T = obj.Table;
            for groupidx = 1: length(listgroup)
                if listgroup(groupidx).GroupLines(1) == listgroup(groupidx).GroupLines(end)
                    % this group has only one line in list
                    thislistidx = listgroup(groupidx).GroupLines(1);
                    T = IncrementAdditionFixingHelperTop(T, list, thislistidx, IncrementWhere, AdditionWhere);
                    T = IncrementAdditionFixingHelperBottom(T, list, thislistidx, IncrementWhere, AdditionWhere);
                    if ~isempty(listgroup(groupidx).InterpolationLines)
                        T = IncrementAdditionFixingHelperInterpolation(T, IncrementWhere, AdditionWhere, listgroup(groupidx).InterpolationLines, listgroup(groupidx).InterpolationFlag, InterpolationStyle);
                    end
                    T = IncrementAdditionFixingHelperSweep(T, list, thislistidx, IncrementWhere, AdditionWhere);
                else
                    T = IncrementAdditionFixingHelperTop(T, list, listgroup(groupidx).GroupLines(1), IncrementWhere, AdditionWhere);
                    T = IncrementAdditionFixingHelperBottom(T, list, listgroup(groupidx).GroupLines(end), IncrementWhere, AdditionWhere);
                    T = IncrementAdditionFixingHelperInterpolation(T, IncrementWhere, AdditionWhere, listgroup(groupidx).InterpolationLines, listgroup(groupidx).InterpolationFlag, InterpolationStyle);
                    for listidx = listgroup(groupidx).GroupLines(1): listgroup(groupidx).GroupLines(end)
                        T = IncrementAdditionFixingHelperSweep(T, list, listidx, IncrementWhere, AdditionWhere);
                    end
                end
            end
            obj.Table = IncrementAdditionFixingHelperRectify(T, IncrementWhere, AdditionWhere, InterpolationStyle);
    
            function T = IncrementAdditionFixingHelperTop(T, list, listidx, IncrementWhere, AdditionWhere)
                switch list(listidx).Top
                    case 'l'
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                        end
                    case 'r'
                        for rowN = list(listidx).TopLines(1): list(listidx).TopLines(end)
                            T(rowN, AdditionWhere) = {T{rowN-1, AdditionWhere} + T{rowN, IncrementWhere}};
                        end
                end
            end
    
            function T = IncrementAdditionFixingHelperBottom(T, list, listidx, IncrementWhere, AdditionWhere)
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
    
            function T = IncrementAdditionFixingHelperInterpolation(T, IncrementWhere, AdditionWhere, InterpolationLines, InterpolationFlag, InterpolationStyle)
                startRow = InterpolationLines(1);
                endRow = InterpolationLines(end);
                scope = endRow - startRow + 1;
                switch InterpolationFlag
                    case 'P'
                        switch InterpolationStyle
                            case 'Linear'
                                increment = (T{endRow, AdditionWhere} - T{startRow, AdditionWhere}) / (scope - 1);
                                for rowidx = startRow + 1: endRow - 1
                                    T(rowidx, AdditionWhere) = {T{startRow, AdditionWhere} + increment * (rowidx - startRow)};
                                end
                            case 'LinearRound'
                                increment = (T{endRow, AdditionWhere} - T{startRow, AdditionWhere}) / (scope - 1);
                                for rowidx = startRow + 1: endRow - 1
                                    T(rowidx, AdditionWhere) = {round(T{startRow, AdditionWhere} + increment * (rowidx - startRow))};
                                end
                        end
                    case ']'
                        tpT = T(startRow:endRow, IncrementWhere|AdditionWhere);
                        if find(IncrementWhere,1) < find(AdditionWhere, 1)
                            tpIncrementWhere = 1; tpAdditionWhere = 2;
                        else
                            tpIncrementWhere = 2; tpAdditionWhere = 1;
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
                                switch InterpolationStyle
                                    case 'Linear'
                                        tpT(rowidx,tpAdditionWhere) = {tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer)};
                                    case 'LinearRound'
                                        tpT(rowidx,tpAdditionWhere) = {round(tpT{tpFormer, tpAdditionWhere} + thisincrement * (rowidx - tpFormer))};
                                end
                            end
                        end
                        T(startRow:endRow, IncrementWhere|AdditionWhere) = tpT;
                end
            end
    
            function T = IncrementAdditionFixingHelperSweep(T, list, listidx, IncrementWhere, AdditionWhere)
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
    
            function T = IncrementAdditionFixingHelperRectify(T, IncrementWhere, AdditionWhere, InterpolationStyle)
                for rowidx = 2: size(T, 1)
                    if T{rowidx, IncrementWhere} < 0
                        T{rowidx, IncrementWhere} = 0;
                        switch InterpolationStyle
                            case {'Linear', 'LinearRound'}
                                T{1:rowidx-1,IncrementWhere|AdditionWhere} = T{1:rowidx-1,IncrementWhere|AdditionWhere} * T{rowidx, AdditionWhere} / T{rowidx-1, AdditionWhere};
                                warning(['Increment-Addition. Data before row ', sprintf('%i', rowidx), ' were linearly scaled, due to decreasing addition.'])
                        end
                    end
                    
                end
                switch InterpolationStyle
                    case 'LinearRound'
                        T{:,AdditionWhere} = round(T{:,AdditionWhere});
                        T{1,IncrementWhere} = T{1,AdditionWhere};
                        for rowidx = 2: size(T, 1)
                            T{rowidx, IncrementWhere} = T{rowidx, AdditionWhere} - T{rowidx-1, AdditionWhere};
                        end
                    otherwise
                        for rowidx = 2: size(T, 1)
                            T{rowidx, AdditionWhere} = T{rowidx-1, AdditionWhere} + T{rowidx, IncrementWhere};
                        end
                end
                % Checking Addition
                for rowidx = 2: size(T, 1)
                    switch InterpolationStyle
                        case 'Linear'
                            if abs(T{rowidx, IncrementWhere} + T{rowidx-1, AdditionWhere} - T{rowidx, AdditionWhere}) < 10*eps
                                % do nothing
                            else
                                warning(['Increment-Addition. Wrong addition in row', sprintf('%i', rowidx)]);
                            end
                        case 'LinearRound'
                            if T{rowidx, IncrementWhere} + T{rowidx-1, AdditionWhere} == T{rowidx, AdditionWhere}
                                % do nothing
                            else
                                warning(['Increment-Addition. Wrong addition in row', sprintf('%i', rowidx)]);
                            end
                    end
                end
            end
        end
    end
    
    % Other methods
end