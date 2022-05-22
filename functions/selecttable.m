function [thisTable, cmp, cmpFL] = selecttable(thisTable, theRequest, QuickStyle)
    % selecttable selects tuples of table from request
    %   Input [table, {FieldName: char/string, Value: numeric/char/string/arange/cell; other_requests}]

    %   WANG Yi-yang 28-Apr-2022
    %   v20220430

    if nargin == 2, QuickStyle = false; end
    cmpFL = {[]};
    RequestSize = size(theRequest, 1);
    if RequestSize > 1
        for index = 1: 1: RequestSize
            [thisTable, thiscmp, ~] = selecttable(thisTable, theRequest(index, :));
            if index == 1
                lastcmp = thiscmp;
            else
                lastcmp(lastcmp) = thiscmp;
            end
            if index == RequestSize && ~QuickStyle
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
            if ~QuickStyle, cmpFL = FirstLastFindTrue(cmp); end
        catch
            cmp = arrayfun(@(x) 1, 1:size(thisTable, 1));
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
            case 'char'
                Return = strcmp(thisTable.(thisField), thisValue);
            case 'string'
                Return = false(size(thisTable.(thisField)));
                for indx = 1: 1: numel(thisValue)
                    Return = Return | strcmp(thisTable.(thisField), thisValue(indx));
                end
            case 'datetime'
                Return = arange(thisValue, thisValue).ni(thisTable.(thisField));
            case 'timerange'
                thisValue = arange(thisValue);
                Return = thisValue.ni(thisTable.(thisField));
            case 'arange'
                Return = any(thisValue.ni(thisTable.(thisField)));
            case 'cell'
                Return = false(size(thisTable.(thisField)));
                for indx = 1: 1: numel(thisValue)
                    Return = Return | cmp_generation(thisTable, thisField, thisValue{indx});
                end
            otherwise
                Return = thisTable.(thisField) == thisValue;
        end
    end

end