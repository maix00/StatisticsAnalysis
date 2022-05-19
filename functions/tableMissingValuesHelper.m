function [T, list] = tableMissingValuesHelper(T, varargin)

    ips = inputParser;
    ips.addParameter('VariableNames', [], @(x)true);
    ips.addParameter('Style', [], @(x)any(validatestring(x,{'Increment-Addition','Interpolation','Constant'})));
    ips.addParameter('InterpolationStyle', 'Linear', @(x)any(validatestring(x,{'Linear'})));
    ips.addParameter('ConstantValues', [], @(x)true);
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
        case 'Constant'
            if ~isempty(ips.Results.ConstantValues), StyleFlag = 'C';
            else
                error('Constant Style requires inputing parameter ConstantValues')
            end
    end

    % List Generation
    switch StyleFlag
        case 'IA'
            Increment = VariableNames(1);
            Addition = VariableNames(end);
            IncrementWhere = strcmp(T.Properties.VariableNames, Increment);
            AdditionWhere = strcmp(T.Properties.VariableNames, Addition);
            SA = StatisticsAnalysis('Table', T).TagsGenerate('QuickStyle', {'MissingMap'});
            IncrementMissingMap = SA.Table.Properties.CustomProperties.MissingMap{IncrementWhere};
            AdditionMissingMap = SA.Table.Properties.CustomProperties.MissingMap{AdditionWhere};
            list = struct.empty;
            for idx = 1: length(IncrementMissingMap)
                boolIncrement = IncrementMissingMap(idx);
                boolAddition = AdditionMissingMap(idx);
                bool = boolIncrement || boolAddition;
                if bool && (isempty(list) || (~isempty(list) && list(end).Lines(end) ~= idx - 1))
                    if boolIncrement && ~boolAddition
                        list = [list; struct('Lines', [idx, idx], 'Top', 'l', 'Bottom', 'l')];
                    elseif ~boolIncrement && boolAddition
                        list = [list; struct('Lines', [idx, idx], 'Top', 'r', 'Bottom', 'r')];
                    elseif boolIncrement && boolAddition
                        list = [list; struct('Lines', [idx, idx], 'Top', 'o', 'Bottom', 'o')];
                    end
                elseif bool
                    if boolIncrement && ~boolAddition
                        switch list(end).Bottom
                            case 'o', list(end).Lines(end) = idx; list(end).Bottom = 'p';
                            case 'l', list(end).Lines(end) = idx;
                            case {'r', 'q', 'p'}, list = [list; struct('Lines', [idx, idx], 'Top', 'l', 'Bottom', 'x')];
                        end
                    elseif ~boolIncrement && boolAddition
                        switch list(end).Bottom
                            case 'o', list(end).Lines(end) = idx; list(end).Bottom = 'q';
                            case {'l', 'q', 'p'}, list = [list; struct('Lines', [idx, idx], 'Top', 'r', 'Bottom', 'x')];
                            case 'r', list(end).Lines(end) = idx;
                        end
                    elseif boolIncrement && boolAddition
                        switch list(end).Bottom
                            case 'o', list(end).Lines(end) = idx;
                            case 'l', list(end).Lines(end) = idx; list(end).Top = 'b'; list(end).Bottom = 'o';
                            case 'r', list(end).Lines(end) = idx; list(end).Top = 'd'; list(end).Bottom = 'o';
                            case 'q', list = [list; struct('Lines', [idx, idx], 'Top', 'qc', 'Bottom', 'o')];
                            case 'p', list = [list; struct('Lines', [idx, idx], 'Top', 'pc', 'Bottom', 'o')];
                        end
                    end
                end
            end
        case {'I', 'C'}
            list = struct;
            SA = StatisticsAnalysis('Table', T).TagsGenerate('QuickStyle', {'MissingMap'});
            for idx = 1: length(VariableNames)
                thisWhere = strcmp(T.Properties.VariableNames, VariableNames(idx));
                thisMissingMap = SA.Table.Properties.CustomProperties.MissingMap{thisWhere};
                [list(:).(VariableNames{idx})] = deal(FirstLastFindTrue(thisMissingMap));
            end
    end

    % Missing Values Fixing
    switch StyleFlag
        case 'IA'
            for idx = 1: length(list)
                switch list(idx).Top
                    case 'l'
                        for rowN = list(idx).Lines(1): list(idx).Lines(end)
                            if list(idx).Lines(1) == 1
                                T(rowN, IncrementWhere) = T(rowN, AdditionWhere);
                            else
                                T(rowN, IncrementWhere) = {T{rowN, AdditionWhere} - T{rowN-1, AdditionWhere}};
                            end
                        end
                end
            end
        case 'I'
        case 'C'
    end
end