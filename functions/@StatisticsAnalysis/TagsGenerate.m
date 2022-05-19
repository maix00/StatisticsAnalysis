function obj = TagsGenerate(obj, varargin)
    % TagsGenerate does statisticsAnalysis and generate tags.
    %
    %   Tags include:
    %       - TagNames: 'unique', 'invariant', 'logical', 'categorical',
    %                    'discrete', 'continuous'
    %       - UniqueCount 
    %       - NaNCount & NaNRatio
    %       - EmptyCount & EmptyRatio
    %       - LogicalRatio
    %       - CategoricalRatio & CategoricalVariance
    %       - Min, Max, Mean, Median, Mode, Variance (for Continuous Tag)
    %
    %   % These Values were automatically calculated by TagsGenerate.
    %       - Custom tags not supported for now.
    %
    %   obj = obj.TagsGenerate(varargin)
    %
    %   varargin Examples:
    %       - TagContinuity / TagCategory:                          [0 1 0 1 1]
    %       - CustomTagName:                {'TagName', [0 1 0 1 1]; otherName}
    %       - OutputClass:                        'table' or 'cell' or 'struct'
    %       - CustomTagFunction:
    %                           {'TagName', 'funcName', func_handle; otherfunc}
    %                   'TagName' can be 'table' which applied to all TagNames.
    %
    %   For each variable, TagsGenerate would invoke <a href = "matlab:help OneTagGenerate">OneTagGenerate</a>.
    %   Warning: TagsGenerate(obj, varargin) not accepted.

    %   WANG Yi-yang 28-Apr-2022

    ips = inputParser;
    ips.addParameter('TagContinuity', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('TagCategory', [], @(x)validateattributes(x, {'numeric', 'logical'}, {}));
    ips.addParameter('CustomTagName', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('CustomTagFunction', {}, @(x)validateattributes(x, {'cell'}, {}));
    ips.addParameter('OutputClass', 'table', @(x)validateattributes(x, {'char', 'string'}, {}));
    ips.addParameter('QuickStyle', [], @(x)true);
    ips.parse(varargin{:})

    % Import Table 
    if isempty(obj.Table)
        obj.Table = obj.ImportTable;
    end

    % For each variable, Run OneTagGenerate
    variable_count = length(obj.Table.Properties.VariableNames);
    for idx = 1: 1: variable_count
        obj.OneTagFlag = false;
        % TagContinuity
        if isempty(ips.Results.TagContinuity)
            TagContinuity = arrayfun(@(x) 0, 1:variable_count);
        else
            TagContinuity = ips.Results.TagContinuity;
        end
        % TagCategory
        if isempty(ips.Results.TagCategory)
            TagCategory = arrayfun(@(x) 0, 1:variable_count);
        else
            TagCategory = ips.Results.TagCategory;
        end
        % CustomTagName
        thisCustomTagName = {};
        if ~isempty(ips.Results.CustomTagName)
            CustomTagName = ips.Results.CustomTagName;
            for subindx = 1: 1: size(CustomTagName, 1)
                thisCustomTagName = [thisCustomTagName; {CustomTagName{subindx,1}, CustomTagName{subindx,2}(idx)}];
            end
        end
        [temp1, temp2] = obj.OneTagGenerate(obj.Table.Properties.VariableNames{idx}, ... thisFieldName
            'TagContinuity', TagContinuity(idx), ...
            'TagCategory', TagCategory(idx), ...
            'CustomTagName', thisCustomTagName, ...
            'CustomTagFunction', ips.Results.CustomTagFunction, ...
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