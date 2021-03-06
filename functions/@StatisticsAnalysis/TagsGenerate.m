function obj = TagsGenerate(obj, varargin)
    % TagsGenerate does statistics analyses (designates tag names to each
    % variable and calculates given statistical indicators under some tag
    % names). TagsGenerate also adds these calculation results to Table via
    % Table.Properties.CustomProperties.
    %
    %   obj = obj.TagsGenerate(varargin)
    %
    %   For each variable, TagsGenerate would invoke <a href = "matlab:help OneTagGenerate">OneTagGenerate</a>.
    %   Warning: TagsGenerate(obj, varargin) not accepted.

    %   WANG Yi-yang 28-Apr-2022
    
    if isa(varargin, 'struct')
        tp_varargin = [fieldnames(varargin), struct2cell(varargin)]';
        varargin = tp_varargin(:)';
    end
    ips = inputParser;
    ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('OutputClass', 'table', @(x)validateattributes(x, {'char', 'string'}, {}));
    ips.addParameter('QuickStyle', [], @(x)true);
    ips.parse(varargin{:})
    
    CustomTagName = OptionsSizeHelper(ips.Results.CustomTagName);
    CustomTagFunction = OptionsSizeHelper(ips.Results.CustomTagFunction, 3);

    % Check Table 
    if isempty(obj.Table), error('No Table.'); end

    % For each variable, Run OneTagGenerate
    variable_count = length(obj.Table.Properties.VariableNames);
    for idx = 1: 1: variable_count
        obj.OneTagFlag = false;
        % TagContinuity
        if isempty(ips.Results.TagContinuity)
            TagContinuity = arrayfun(@(x) NaN, 1:variable_count);
        else
            TagContinuity = ips.Results.TagContinuity;
        end
        % TagCategory
        if isempty(ips.Results.TagCategory)
            TagCategory = arrayfun(@(x) NaN, 1:variable_count);
        else
            TagCategory = ips.Results.TagCategory;
        end
        % CustomTagName
        thisCustomTagName = {};
        if ~isempty(CustomTagName)
            for subidx = 1: size(CustomTagName, 1)
                thisCustomTagName = [thisCustomTagName; {CustomTagName{subidx,1}, CustomTagName{subidx,2}(idx)}];
            end
        end
        % CustomTagFunction
        for subidx = 1: size(CustomTagFunction, 1)
            if isnumeric(CustomTagFunction{subidx})
                if CustomTagFunction{subidx}(idx)
                    CustomTagFunction{subidx} = 'table';
                end
            end
        end
        % Tag Generation
        [temp1, temp2] = obj.OneTagGenerate(obj.Table.Properties.VariableNames{idx}, ... thisFieldName
            'TagContinuity', TagContinuity(idx), ...
            'TagCategory', TagCategory(idx), ...
            'CustomTagName', thisCustomTagName, ...
            'CustomTagFunction', CustomTagFunction, ...
            'QuickStyle', ips.Results.QuickStyle ...
            );
        % Clear obj.Tags
        if (idx == 1) && ~isempty(obj.Tags)
            obj.Tags = [];
        end
        % New obj.Tags
        obj.Tags = [obj.Tags; temp1];
        % Recover
        obj.OneTagFlag = true;
    end
    % Output
    try
        switch ips.Results.OutputClass
            case 'table'
                obj.Tags = cell2struct(obj.Tags(:,1:end-1), obj.Table.Properties.VariableNames, 1);
                obj.Tags = struct2table(obj.Tags);
                obj.Tags.Properties.RowNames = temp2;
            case 'struct'
                obj.Tags = cell2struct(obj.Tags(:,1:end-1), obj.Table.Properties.VariableNames, 1);
            case 'cell'
                % do nothing
        end
    catch
        warning('Output Tags Syntax Error Warning. TagsGenerate.')
    end
    % Add Properties
    obj.Table = obj.addProp;
end