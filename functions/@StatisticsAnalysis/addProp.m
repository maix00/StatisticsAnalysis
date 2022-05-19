function table = addProp(obj, varargin)
    % addProp adds properties from obj.Tags to table.
    %
    %   table = addProp(obj, table)
    %   table = obj.addProp 
    %       (where table is optional, default obj.Tables)

    %   WANG Yi-yang 28-Apr-2022

    ips = inputParser;
    ips.addOptional('table', obj.Table, @(x)true);
    ips.parse(varargin{:})
    table = ips.Results.table;
    if ~isempty(obj.Tags)
        % Adding whole table tags
        try
            table = rmprop(table, 'Tags');
            table = rmprop(table, 'Size');
        catch
            % do nothing
        end
        table = addprop(table, 'Tags', {'table'});
        table = addprop(table, 'Size', {'table'});
        table.Properties.CustomProperties.Tags = obj.Tags;
        table.Properties.CustomProperties.Size = size(obj.Table);
        % Adding variable tags
        AddPropSize = size(obj.Tags.Properties.RowNames,1);
        for indx = 1: 1: AddPropSize
            thisFieldName = obj.Tags.Properties.RowNames{indx};
            try
                table = addprop(table, thisFieldName, 'variable');
            catch
                table = rmprop(table, thisFieldName);
                table = addprop(table, thisFieldName, 'variable');
            end
            table.Properties.CustomProperties.(thisFieldName) = table2cell(obj.Tags(thisFieldName, :));
        end
    else
        warning('Syntax Error Warning. No Tags to add.');
    end
end