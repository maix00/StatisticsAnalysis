function [thisTag, thisTagHelper, thisCell] = OneTagGenerate(obj, thisFieldName, varargin)
    % OneTagGenerate generates one tag from one field/variable.
    %
    %   obj = obj.<a href = "matlab:help TagsGenerate">TagsGenerate</a>(varargin)
    %   [tag, tag_name, cell] = OneTagGenerate(obj, field_name, varargin)
    %
    %   Tag names will be assigned to each variable. For different tag 
    %   names, different tag functions would be applied to calculate
    %   statistical indicators.
    %
    %   Default tag names and indicators:
    %       - TagNames: 
    %             Default: 'unique', 'invariant', 'logical', 'categorical',
    %                      'discrete', 'continuous'
    %       - UniqueCount
    %       - MissingCount, MissingRatio, MissingMap
    %       - LogicalRatio
    %       - CategoricalRatio & CategoricalVariance
    %       - Min, Max, Mean, Median, Mode, Variance (for Continuous Tag)
    %
    %   Parameters Example:
    %       - TagContinuity / TagCategory:                          [0 1 0 1 1]
    %       - CustomTagName:                {'TagName', [0 1 0 1 1]; otherName}
    %       - CustomTagFunction:
    %                           {'TagName', 'funcName', func_handle; otherfunc}
    %             'TagName' can be set as 'table' which applied to all TagNames.
    %

    %   WANG Yi-yang 28-Apr-2022

    ips = inputParser;
    ips.addRequired('thisFieldName', @(x)true);
    ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('QuickStyle', [], @(x)true); % Value be the CustomTagNames to be analysed
    ips.parse(thisFieldName, varargin{:})

    CustomTagName = OptionsSizeHelper(ips.Results.CustomTagName);
    CustomTagFunction = OptionsSizeHelper(ips.Results.CustomTagFunction, 3);

    % Preservation
    formerTagsFlag = false;
    if ~isempty(obj.Table)
        try
            Bool = ~isempty(obj.Table.Properties.CustomProperties.TagNames) ...
                && ~isempty(obj.Table.Properties.CustomProperties.Tags) ...
                && any(strcmp(obj.Table.Properties.VariableNames, thisFieldName));
            if Bool
                formerTagsFlag = true;
                formerTagNames = obj.Table.Properties.CustomProperties.Tags{'TagNames',thisFieldName};
                if iscell(formerTagNames{1})
                    formerTagNames = formerTagNames{1};
                end
                try
                    obj.Table = convertvars(obj.Table, thisFieldName, obj.Table.Properties.CustomProperties.Tags{'ValueClass',thisFieldName});
                catch
                end
            end
        catch
            % do nothing
        end
    end

    % CustomTagFunction
    MissingMap = @(x,y)ismissing(x{:,1});
    NoMissing = @(x,y)rmmissing(y{:,1});
    UniqueCount = @(x,y)size(NoMissing(x,y),1);
    ValueClass = @(x,y)class(nest_index(NoMissing(x,y),1));
    MissingCount = @(x,y)(size(y,1)-size(NoMissing(x,y),1));
    NoMissingSize = @(x,y)size(x,1)-MissingCount(x,y);
    SerialValueString = @(x,y,z)nest_index(string(NoMissing(x,y)),z);
    StringValueRatio = @(x,y,z)sum(strcmp(string(x{:,1}),z))/NoMissingSize(x,y);
    LogicalRatioFirstValue = @(x,y)StringValueRatio(x,y,SerialValueString(x,y,1));
    LogicalRatio = @(x,y){SerialValueString(x,y,1),LogicalRatioFirstValue(x,y);SerialValueString(x,y,2),1-LogicalRatioFirstValue(x,y)};
    CategoricalRatio = @(x,y)[arrayfun(@(w)SerialValueString(x,y,w), 1:NoMissingSize(x,y), 'UniformOutput', false)', arrayfun(@(w){StringValueRatio(x,y,SerialValueString(x,y,w))}, 1:NoMissingSize(x,y))'];
    DefaultTagFunction = {
        'table', 'UniqueCount', UniqueCount;
        'table', 'ValueClass', ValueClass;
        'table', 'MissingCount', MissingCount;
        'table', 'MissingRatio', @(x,y)MissingCount(x,y)/size(x,1);
        'table', 'MissingMap', MissingMap;
        'logical', 'LogicalRatioFirstValue', LogicalRatioFirstValue;
        'logical', 'LogicalRatio', LogicalRatio;
        'categorical', 'CategoricalRatio', CategoricalRatio;
        'continuous', 'Min', @(x,y)tsnanmin(double(string(y{:,1})));
        'continuous', 'Max', @(x,y)tsnanmax(double(string(y{:,1})));
        'continuous', 'Mean', @(x,y)tsnanmean(double(string(y{:,1})));
        'continuous', 'Median', @(x,y)tsnanmedian(double(string(y{:,1})));
        'continuous', 'Mode', @(x,y)tsnanmode(double(string(y{:,1})));
        'continuous', 'Variance', @(x,y)tsnanvar(double(string(y{:,1})))
        };
    CustomTagFunction = [DefaultTagFunction; CustomTagFunction];

    % Import Table
    if isempty(obj.Table) || (~isempty(obj.Table) && ~any(strcmp(obj.Table.Properties.VariableNames, thisFieldName)))
        ImportOptionsEmptyFlag = false;
        if isempty(obj.ImportOptions)
            ImportOptionsEmptyFlag = true;
            obj.ImportOptions = {{'SelectedVariableNames', {thisFieldName}}};
        else
            NonEmptyLog = obj.ImportOptions;
            thisIndx = [];
            for indx = 1: 1: size(obj.ImportOptions{1}, 1)
                if strcmp(obj.ImportOptions{1}{indx,1}, 'SelectedVariableNames')
                    thisIndx = indx;
                end
            end
            for indx = 1: 1: size(obj.ImportOptions, 2)
                if ~isempty(thisIndx)
                    obj.ImportOptions{indx}(thisIndx,:) = [];
                end
                obj.ImportOptions{indx} = [obj.ImportOptions{indx}; {'SelectedVariableNames', {thisFieldName}}];
            end
        end
        obj.Table = obj.ImportTable;
        % Recover
        if ImportOptionsEmptyFlag
            obj.ImportOptions = {};
        else
            obj.ImportOptions = NonEmptyLog;
        end
    end
    thisColumnTable = obj.Table(:, thisFieldName);
    thisUniqueColumnTable = unique(thisColumnTable);
    unique_count = UniqueCount(thisColumnTable, thisUniqueColumnTable);
    tuple_count = size(thisColumnTable, 1);
    
    % Tag Names
    NameCell = {'continuous', 'logical', 'unique', 'categorical', 'discrete', 'invariant'};
    if ~formerTagsFlag
        if (ips.Results.TagContinuity == 1) 
            thisTagName = {'continuous'};
        elseif (ips.Results.TagCategory == 1)
            thisTagName = {'categorical'};
        else
            switch unique_count
                case 2, thisTagName = {'logical'};
                case tuple_count, thisTagName = {'unique'};
                case 1, thisTagName = {'invariant'};
                otherwise, thisTagName = {'discrete'};
            end
        end
    else
        for indx = 1: 6
            if any(strcmp(formerTagNames, NameCell{indx}))
                thisTagName = NameCell(indx);
                break
            end
        end
        formerTagNames(strcmp(formerTagNames, NameCell{indx})) = [];
    end
    % Custom Tag Names
    if ~isempty(CustomTagName)
        OnTagName = CustomTagName(logical(cell2mat(CustomTagName(:,2))),1);
        if ~isempty(OnTagName)
            for indx = 1: 6
                if any(strcmp(OnTagName, NameCell{indx}))
                    thisTagName = NameCell(indx);
                end
            end
            thisTagName = unique([thisTagName; OnTagName]);
        end
        OffTagName = CustomTagName(~logical(cell2mat(CustomTagName(:,2))),1);
        if ~isempty(OffTagName)
            for idxx = 1: numel(OffTagName)
                map = strcmp(thisTagName, OffTagName{idxx});
                if any(map), thisTagName(map) = []; end
            end
        end
    end
    if (ips.Results.TagContinuity == 0)
        map = strcmp(thisTagName, 'continuous');
        if any(map), thisTagName(map) = {'discrete'}; end
    elseif (ips.Results.TagCategory == 0)
        map = strcmp(thisTagName, 'category');
        if any(map), thisTagName(map) = {'discrete'}; end
    end
    if formerTagsFlag
        thisTagName = unique([thisTagName; formerTagNames]);
    end
    thisTag = {thisTagName}; thisTagHelper = {'TagNames'};

    % Custom Tag Function
    if ~isempty(ips.Results.QuickStyle)
        try
            list = ips.Results.QuickStyle;
            if size(list, 2)>1
                list = list';
            end
            tab = cell2table(CustomTagFunction);
            tab = selecttable(tab, {'CustomTagFunction2', list});
            CustomTagFunction = table2cell(tab);
        catch
        end
    elseif (isempty(ips.Results.QuickStyle) && iscell(ips.Results.QuickStyle))
        CustomTagFunction = {};
    end
    for indx = 1: 1: size(CustomTagFunction, 1)
        thisTargetTagName = CustomTagFunction{indx, 1};
        thisTagHelperName = CustomTagFunction{indx, 2};
        thisFunction = CustomTagFunction{indx, 3};
        if strcmp(thisTargetTagName, 'table') || any(strcmp(thisTagName, thisTargetTagName))
            try
                thisValue = thisFunction(thisColumnTable, thisUniqueColumnTable);
            catch
                warning(strcat('Variable Input Class / Function Handle Syntax Error Warning: ', thisTargetTagName, '/', thisTagHelperName, '.'));
                thisValue = [];
            end
        else
            thisValue = [];
        end
        % Append
        if obj.OneTagFlag
            Bool1 = ~any(isempty(thisValue));
            try 
                Bool2 = ~any(isnan(thisValue));
                Bool = Bool1 && Bool2;
            catch
                Bool = Bool1;
            end
            if Bool
                thisTag = [thisTag, {thisValue}];
                thisTagHelper = [thisTagHelper, {thisTagHelperName}];
            end
        else
            thisTag = [thisTag, {thisValue}];
            thisTagHelper = [thisTagHelper, {thisTagHelperName}];
        end
    end
    % Field Name
    thisTag = [thisTag, {thisFieldName}];
    thisCell = [thisTag', [thisTagHelper, 'VariableName']'];
    
    % Utility Function
    function Return = nest_index(theformer, thelaterindexstring)
        thelaterindexstring = string(thelaterindexstring);
        try
            Return = eval(strcat("theformer", thelaterindexstring));
        catch
            try
                Return = eval(strcat("theformer{", thelaterindexstring, "}"));
            catch
                Return = eval(strcat("theformer(", thelaterindexstring, ")"));
            end
        end
    end
    
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
end