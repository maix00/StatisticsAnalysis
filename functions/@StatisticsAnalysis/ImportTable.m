function table = ImportTable(obj)
    % ImportTable imports the table.
    %   
    %   table = ImportTable(obj)
    %   table = obj.ImportTable

    %   WANG Yi-yang 28-Apr-2022
    
    if ~isempty(obj.TablePath)
        if ~isempty(obj.ImportOptions)
            obj = obj.ImportOptionsUnnest; % Import Options Un-nest
            if isempty(obj.DetectedImportOptions)
                obj = obj.DetectImport;
            end
            Length = length(obj.UnnestedImportOptions.Variant);
            if Length == 0, obj = obj.ImportOptionsUpdate(0);
                % Only Invariant Import Options
                table = readtable(obj.TablePath, obj.DetectedImportOptions);
            elseif Length > 0
                % Exist Variant Import Options -> Will Import and Union
                tableCell = cell(size(obj.UnnestedImportOptions.Variant)); union_flag = true;
                for idx = 1: Length
                    tableCell{idx} = readtable(obj.TablePath, obj.ImportOptionsUpdate(idx).DetectedImportOptions);
                    this_variable_names = tableCell{idx}.Properties.VariableNames;
                    if idx > 2
                        if length(this_variable_names) ~= length(former_variable_names)
                            union_flag = false;
                        else, flag = true;
                            for idxx = 1: length(this_variable_names)
                                flag = flag && any(strcmp(this_variable_names{idxx}, former_variable_names));
                                if ~flag, union_flag = false; break; end
                            end
                        end
                    end
                    former_variable_names = this_variable_names;
                end
                if union_flag
                    table = tableCell{1};
                    for indx = 2: 1: length(tableCell)
                        table = union(table, tableCell{indx}, 'stable');
                    end
                else
                    table = tableCell;
                end
            end
        elseif ~isempty(obj.DetectedImportOptions)
            table = readtable(obj.TablePath, obj.DetectedImportOptions);
        else
            table = readtable(obj.TablePath);
        end
        if ~iscell(table)
            try
                table = addprop(table, 'detectedImportOptions', {'table'});
            catch
                table = rmprop(table, 'detectedImportOptions');
                table = addprop(table, 'detectedImportOptions', {'table'});
            end
            table.Properties.CustomProperties.detectedImportOptions = obj.originalDetectedImportOptions;
        end
    else
        beep; warning('TablePath is empty.');
    end
end

