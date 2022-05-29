function [obj, table] = rmProp(obj, varargin)
    % rmProp removes properties from obj.Tables.Properties.CustomProperties.
    %
    %   table = rmProp(obj, varargin)
    %   table = obj.rmProp(varargin)
    %           - 'PreserveTagNames'    default: false

    %   WANG Yi-yang 29-Apr-2022

    ips = inputParser;
    ips.addParameter('PreserveTagNames', false, @(x)true);
    ips.parse(varargin{:})
    Bool = ~isempty(obj.Table) && ~isempty(obj.Table.Properties.CustomProperties.Tags);
    if Bool
        RmList = obj.Table.Properties.CustomProperties.Tags.Properties.RowNames';
        if ips.Results.PreserveTagNames
            RmList = RmList(2:end);
        end
        obj.Table = rmprop(obj.Table, RmList);
        table = obj.Table;
    end
end