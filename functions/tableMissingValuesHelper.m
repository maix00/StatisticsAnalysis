function [T, list] = tableMissingValuesHelper(T, varargin)

    ips = inputParser;
    ips.addParameter('VariableNames', [], @(x)true);
    ips.addParameter('Style', 'Constant', @(x)any(validatestring(x,{'Increment-Addition','Interpolation','Constant'})));
    ips.addParameter('InterpolationStyle', 'LinearRound', @(x)any(validatestring(x,{'Linear', 'LinearRound'})));
    ips.addParameter('ConstantValues', [], @(x)true);
    ips.addParameter('OtherOptions', [], @(x)true);
    ips.parse(varargin{:})
    
    % Variable Names To Be Operated
    if isempty(ips.Results.VariableNames)
        VariableNames = T.Properties.VariableNames;
    else
        if size(ips.Results.VariableNames, 1) > 1
            VariableNames = ips.Results.VariableNames';
        else
            VariableNames = ips.Results.VariableNames;
        end
    end

    % Operation Flags and Input Checks
    switch ips.Results.Style
        case 'Increment-Addition'
            if numel(VariableNames) == 2, StyleFlag = 'IA';
            else
                error('Increment-Addition Style requires 2 VariableNames.')
            end
        case 'Interpolation', StyleFlag = 'I';
        case 'Constant', StyleFlag = 'C';
    end

    % List Generation
    switch StyleFlag
        case 'IA'
            T = IncrementAdditionRemoveCracksHelper(T, VariableNames);
            [list, IncrementWhere, AdditionWhere, len] = IncrementAdditionListGenerateHelper(T, VariableNames);
            [T, tplist] = IncrementAdditionRemoveLastLinesHelper(T, list, len);
            [T, tplist] = IncrementAdditionFirstRowHelper(T, tplist, IncrementWhere, AdditionWhere, VariableNames, ips.Results.ConstantValues);
            tplistgroup = IncrementAdditionListGroupHelper(tplist);
        case {'I', 'C'}
            list = struct;
            if isa(VariableNames, 'char')
                for idx = 1: size(VariableNames, 1)
                    thisWhere = strcmp(T.Properties.VariableNames, VariableNames(idx,:));
                    thisMissingMap = ismissing(T(:,thisWhere));
                    list.(VariableNames(idx,:)) = FirstLastFindTrue(thisMissingMap);
                end
            else
                for idx = 1: length(VariableNames)
                    thisWhere = strcmp(T.Properties.VariableNames, VariableNames{idx});
                    thisMissingMap = ismissing(T(:,thisWhere));
                    list.(VariableNames{idx}) = FirstLastFindTrue(thisMissingMap);
                end
            end
    end

    % Missing Values Fixing
    switch StyleFlag
        case 'IA'
            T = IncrementAdditionFixingHelper(T, tplist, tplistgroup, IncrementWhere, AdditionWhere, ips.Results.InterpolationStyle);
        case 'I'
        case 'C'
            if ~isempty(ips.Results.ConstantValues)
                if isempty(ips.Results.OtherOptions)
                    T = fillmissing(T, 'constant', ips.Results.ConstantValues);
                else
                    T = fillmissing(T, 'constant', ips.Results.ConstantValues, ips.Results.OtherOptions{:});
                end
            else
                warning('No parameter ConstantValues input -> Will Remove missing rows.')
            end
    end
    
    function T = IncrementAdditionRemoveCracksHelper(T, VariableNames)
        thisIncrementWhere = strcmp(T.Properties.VariableNames, VariableNames(1));
        thisAdditionWhere = strcmp(T.Properties.VariableNames, VariableNames(end));
        lastVal = T{1, thisAdditionWhere};
        lastRow = 1;
%         map = false([size(T,1),1]);
        NaNFlag = false;
        for idxx = 2: size(T, 1)
            if T{idxx, thisAdditionWhere} < lastVal
%                 T{idxx, thisIncrementWhere|thisAdditionWhere} = NaN;
%                 map(idxx) = true;
                NaNFlag = true;
            else
                if NaNFlag
%                     T{idxx, thisIncrementWhere} = NaN;
                    warning(['Increment-Addition. Addition was decreasing at rows (', sprintf('%i', lastRow), ',', sprintf('%i', idxx), ')']); %, '), thus setting Increment & Addition to be NaN.']);
                end
                lastVal = T{idxx, thisAdditionWhere};
                lastRow = idxx;
                NaNFlag = false;
            end
        end
%         T(map,:) = [];
%         warning('Addition was decreasing, thus removed.');
    end

    function [list, IncrementWhere, AdditionWhere, len] = IncrementAdditionListGenerateHelper(T, VariableNames)
        Increment = VariableNames(1);
        Addition = VariableNames(end);
        IncrementWhere = strcmp(T.Properties.VariableNames, Increment);
        AdditionWhere = strcmp(T.Properties.VariableNames, Addition);
        IncrementMissingMap = ismissing(T(:,IncrementWhere));
        AdditionMissingMap = ismissing(T(:,AdditionWhere));
        len = length(IncrementMissingMap);
        list = struct.empty;
        for idxx = 1: length(IncrementMissingMap)
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
    end

    function [T, list] = IncrementAdditionRemoveLastLinesHelper(T, list, len)
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
                T(RemoveLines(1):RemoveLines(end),:) = [];
                warning('Increment-Addition. Last lines were missing in Addition or in both Increment and Addition, thus removed.')
                RemoveLines = [];
            end
        end
    end
    
    function [T, list] = IncrementAdditionFirstRowHelper(T, list, IncrementWhere, AdditionWhere, VariableNames, ConstantValues)
        if isempty(list), return; end
        if ~isempty(list(1).TopLines) && (list(1).TopLines(1) == 1)
            switch list(1).Top
                case 'l'
                    if isempty(list(1).MiddleLines)
                        if list(1).TopLines(end) == 1
                            T(1, IncrementWhere) = T(1, AdditionWhere);
                        else
                            for rowN = list(1).TopLines(end): -1: 1
                                T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                            end
                        end
                        list(1) = [];
                    else
                        T(1, IncrementWhere) = T(1, AdditionWhere);
                        warning('Increment-Addition. First Increment copied from Addition');
                        for rowN = 2: list(1).TopLines(end)
                            T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                        end
                        list(1).TopLines = []; list(1).Top = 'o';
                    end
                case 'r'
                     if isempty(list(1).MiddleLines)
                        if ~ismissing(T{list(1).TopLines(end)+1, AdditionWhere}) && ...
                                ~ismissing(T{list(1).TopLines(end)+1, IncrementWhere})
                            for rowN = list(1).TopLines(end): -1: 1
                                T(rowN, AdditionWhere) = {T{rowN+1, AdditionWhere} - T{rowN+1, IncrementWhere}};
                            end
                        else
                            T(1, AdditionWhere) = T(1, IncrementWhere);
                            warning('Increment-Addition. First Addition copied from Increment');
                            for rowN = 2: list(1).TopLines(end)
                                T(rowN, AdditionWhere) = {T{rowN-1, AdditionWhere} + T{rowN, IncrementWhere}};
                            end
                        end
                        list(1) = [];
                     else
                        T(1, AdditionWhere) = T(1, IncrementWhere);
                        warning('Increment-Addition. First Addition copied from Increment');
                        for rowN = 2: list(1).TopLines(end)
                            T(rowN, AdditionWhere) = {T{rowN-1, AdditionWhere} + T{rowN, IncrementWhere}};
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
                    T(idxx,IncrementWhere|AdditionWhere) = {ConstantValues(1), ConstantValues(2)};
                end
                warning('Increment-Addition. First lines were missing, thus filled with given ConstantValues.')
            else
                if ~isempty(ConstantValues), warning('Too many ConstantValues'); end
                T(RemoveLines(1):RemoveLines(end),:) = [];
                warning('Increment-Addition. First lines were missing, thus removed.')
            end
            list = IncrementAdditionListGenerateHelper(T, VariableNames);
            [T, list] = IncrementAdditionFirstRowHelper(T, list, IncrementWhere, AdditionWhere);
        end
    end

    function listGroup = IncrementAdditionListGroupHelper(list)
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
    end

    function T = IncrementAdditionFixingHelper(T, list, listgroup, IncrementWhere, AdditionWhere, InterpolationStyle)
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
        T = IncrementAdditionFixingHelperRectify(T, IncrementWhere, AdditionWhere, InterpolationStyle);

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