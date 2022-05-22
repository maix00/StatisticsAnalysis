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
    
    CustomTagName = OptionsSizeHelper(ips.Results.CustomTagName);
    CustomTagFunction = OptionsSizeHelper(ips.Results.CustomTagFunction, 3);

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

    % Helper
    function Options = OptionsSizeHelper(Options, numOneLine)
        if nargin == 1, numOneLine = 2; end
        if ~isempty(Options)
            sz = size(Options);
            if isa(Options, 'cell') && sz(1) == 1
                if sz(2) == numOneLine
                    % do nothing
                elseif mod(sz(2), numOneLine) == 0
                    tp = cell(sz(2)/numOneLine, numOneLine);
                    for idxx = 1: sz(2)/numOneLine
                        tp(idxx, :) = Options(1, numOneLine*(idxx-1)+1: numOneLine*idxx);
                    end
                    Options = tp;
                else
                    error('Check Input. Length not match.');
                end
            end
        end
    end
end