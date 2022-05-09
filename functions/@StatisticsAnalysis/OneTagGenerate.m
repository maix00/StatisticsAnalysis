function [thisTag, thisTagHelper, thisCell] = OneTagGenerate(obj, thisFieldName, varargin)
    % OneTagGenerate generates one tag from one field/variable.
    %
    %   [thisTag, thisTagHelper, thisCell] = obj.OneTagGenerate(thisFieldName, varargin)
    %       'CategoryUpperLimit', 'TagContinuity', 'TagCategory', 'CustomTagName', 'CustomTagFunction'
    %   
    %   Outside and Inside usage. Invoked by <a href = "matlab:help TagsGenerate">TagsGenerate</a>.
    %   Warning: OneTagGenerate(obj, thisFieldName, varargin) not accepted.

    %   WANG Yi-yang 28-Apr-2022

    ips = inputParser;
    ips.addRequired('thisFieldName', @(x)true);
    ips.addParameter('CategoryUpperLimit', Inf, @(x)validateattributes(x, {'numeric'}, {}));
    ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.parse(thisFieldName, varargin{:})

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
    NoMissing = @(x,y)y{:,1}(~ismissing(string(y{:,1}))&~strcmp(string(y{:,1}),""));
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
    CustomTagFunction = [DefaultTagFunction; ips.Results.CustomTagFunction];

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
    if ~formerTagsFlag
        if (ips.Results.TagContinuity == 1) 
            thisTagName = 'continuous';
        elseif unique_count == 2
            thisTagName = 'logical';
        elseif unique_count == tuple_count
            thisTagName = 'unique';
        elseif (unique_count > 2) && (unique_count <= ips.Results.CategoryUpperLimit) && (ips.Results.TagCategory == 1)
            thisTagName = 'categorical';
        elseif (unique_count > ips.Results.CategoryUpperLimit) && (ips.Results.TagCategory == 0)
            thisTagName = 'discrete';
        elseif unique_count == 1
            thisTagName = 'invariant';
        end
    else
        NameCell = {'continuous', 'logical', 'unique', 'categorical', 'discrete', 'invariant'};
        for indx = 1: 1: size(NameCell, 2)
            if any(strcmp(formerTagNames, NameCell{indx}))
                thisTagName = NameCell{indx};
            end
        end
    end
    % Custom Tag Names
    if ~isempty(ips.Results.CustomTagName)
        CustomTagName = ips.Results.CustomTagName;
        if any(cell2mat(CustomTagName(:,2)))
            thisTagName = {thisTagName};
            for indx = 1: 1: size(CustomTagName,1)
                if CustomTagName{indx,2} == 1
                    thisTagName = [thisTagName; CustomTagName(indx,1)];
                end
            end
        end
    end
    if formerTagsFlag
        for indx = 1: 1: length(formerTagNames)
            if ~all(strcmp(thisTagName, formerTagNames{indx}))
                thisTagName = [thisTagName; formerTagNames(indx)];
            end
        end
    end
    thisTag = {thisTagName}; thisTagHelper = {'TagNames'};

    % Custom Tag Function
    if ~isempty(CustomTagFunction)
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

end