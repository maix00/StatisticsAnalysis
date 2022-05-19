function [thisTable, cmp, cmpFL] = selecttable(thisTable, theRequest)
    % selecttable selects tuples of table from request
    %   Input [table, {FieldName: char/string, Value: numeric/char/string/arange/cell; other_requests}]

    %   WANG Yi-yang 28-Apr-2022
    %   v20220430

    RequestSize = size(theRequest, 1);
    if RequestSize > 1
        for index = 1: 1: RequestSize
            [thisTable, thiscmp, ~] = selecttable(thisTable, theRequest(index, :));
            if index == 1
                lastcmp = thiscmp;
            else
                lastcmp(lastcmp) = thiscmp;
            end
            if index == RequestSize
                cmpFL = FirstLastFindTrue(lastcmp);
            end
        end
        cmp = lastcmp;
    elseif RequestSize == 1
        % Selection
        try
            cmp = logical(cmp_generation(thisTable, theRequest{1, 1}, theRequest{1, 2}));
            thisTable = thisTable(cmp, :);
            if any(size(thisTable) == 0)
                beep; warning('No matching tuples.');
            end
            cmpFL = FirstLastFindTrue(cmp);
        catch
            cmp = arrayfun(@(x) 1, 1:size(thisTable, 1));
            cmpFL = {[]};
            beep; warning('Input Error Warning. Input [table, {FieldName: char/string, Value: numeric/char/string/arange/cell; other_requests}].');
        end
    else
        beep; warning('Syntax Error Warning. The size of the Request Cell does not match.');
    end
    % Remove Properties
    try
        [~, thisTable] = StatisticsAnalysis('Table', thisTable).rmProp('PreserveTagNames', true);
    catch
    end
    try
        thisTable.Properties.CustomProperties.Tags = thisTable.Properties.CustomProperties.Tags({'TagNames', 'ValueClass'},:);
    catch
    end
    % Update Properties
    try
        thisTable.Properties.CustomProperties.Size = size(thisTable);
    catch
    end
    
    function Return = cmp_generation(thisTable, thisField, thisValue)
        switch class(thisValue)
            case {'char', 'string'}
                Return = strcmp(thisTable.(thisField), thisValue);
            case 'datetime'
                Return = arange(thisValue, thisValue).ni(thisTable.(thisField));
            case 'timerange'
                thisValue = arange(thisValue);
                Return = thisValue.ni(thisTable.(thisField));
            case 'arange'
                Return = thisValue.ni(thisTable.(thisField));
            case 'cell'
                Return = zeros(size(thisTable.(thisField)));
                for indx = 1: 1: numel(thisValue)
                    Return = Return | cmp_generation(thisTable, thisField, thisValue{indx});
                end
            otherwise
                Return = thisTable.(thisField) == thisValue;
        end
    end

    function cmpFL = FirstLastFindTrue(cmp)
        cmpFL = {};
        formerLast = 0;
        while ~isempty(find(cmp, true))
            thisFirst = find(cmp,true,'first');
            for thisLast = thisFirst: length(cmp) - formerLast
                if cmp(thisLast + 1) == 0
                    break
                end
            end
            cmpFL = [cmpFL, {[formerLast + thisFirst, formerLast + thisLast]}];
            formerLast = formerLast + thisLast;
            cmp = cmp(thisLast+1:end);
        end
        try
            cmpFL = cellfun(@(x) x + thisTable.Properties.CustomProperties.detectedImportOptions.VariableNamesLine, cmpFL, 'UniformOutput', false);
        catch
            % do nothing
        end
    end

end