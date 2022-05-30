classdef TableMissingValues_IncrementAdditionMissingBlocks < handle
    properties
        Increment
        Addition
        IncrementWhere
        AdditionWhere
        IncrementMissingMap
        AdditionMissingMap
        DecreasingAddition
        MissingBlocks
        tpMissingBlocks
        MissingBlocksGroups
    end
    methods
        function obj = TableMissingValues_IncrementAdditionMissingBlocks(Table, Increment, Addition, flag)
            if nargin == 3, flag = []; end
            obj.Increment = Increment;
            obj.Addition = Addition;
            obj.IncrementWhere = strcmp(Table.Properties.VariableNames, Increment);
            obj.AdditionWhere = strcmp(Table.Properties.VariableNames, Addition);
            obj.IncrementMissingMap = ismissing(Table(:,Increment));
            obj.AdditionMissingMap = ismissing(Table(:,Addition));
            if isempty(flag)
                [obj.MissingBlocks, obj.MissingBlocksGroups] = IncrementAddition_MissingBlocksDetect(obj.IncrementMissingMap, obj.AdditionMissingMap);
            else
                [obj.tpMissingBlocks, obj.MissingBlocksGroups] = IncrementAddition_MissingBlocksDetect(obj.IncrementMissingMap, obj.AdditionMissingMap);
                if isa(flag, 'TableMissingValues_IncrementAdditionMissingBlocks')
                    obj.MissingBlocks = flag.MissingBlocks;
                end
            end
            obj.DecreasingAddition = IncrementAddition_DecreasingAdditionDetect(Table, obj.AdditionWhere, Addition);
        end
    end
end

% Helper
function [MB, MBG] = IncrementAddition_MissingBlocksDetect(IncrementMissingMap, AdditionMissingMap)
    MB = struct.empty; MBG = struct.empty;
    for row = 1: size(IncrementMissingMap, 1)
        boolIncrement = IncrementMissingMap(row);
        boolAddition = AdditionMissingMap(row);
        if ~(boolIncrement || boolAddition), continue; end
        if ~isempty(MB)
            if ~isempty(MB(end).BottomLines), lastLine = MB(end).BottomLines(end);
            else, lastLine = MB(end).MiddleLines(end);
            end
        end
        if (isempty(MB) || (~isempty(MB) && lastLine ~= row - 1))
            if boolIncrement && ~boolAddition
                MB(length(MB)+1, 1).Top = 'I';
                MB(end).TopLines = [row, row];
                MB(end).MiddleLines = [];
                MB(end).Bottom = 'I';
                MB(end).BottomLines = [row, row];
            elseif ~boolIncrement && boolAddition
                MB(length(MB)+1, 1).Top = 'A';
                MB(end).TopLines = [row, row];
                MB(end).MiddleLines = [];
                MB(end).Bottom = 'A';
                MB(end).BottomLines = [row, row];
            elseif boolIncrement && boolAddition
                MB(length(MB)+1, 1).Top = 'F';
                MB(end).TopLines = [];
                MB(end).MiddleLines = [row, row];
                MB(end).Bottom = 'F';
                MB(end).BottomLines = [];
            end
            MBG(length(MBG)+1, 1).Range = [length(MB), length(MB)];
            if row == 1, MBG(end).FirstLine = true; end
        else
            if boolIncrement && ~boolAddition
                switch MB(end).Bottom
                    case 'F'
                        MB(end).Bottom = 'I';
                        MB(end).BottomLines = [row, row];
                        if (isfield(MBG(end), 'Interpolation') && isempty(MBG(end).Interpolation)) || ~isfield(MBG(end), 'Interpolation')
                            if MB(end).MiddleLines(1) ~= 1
                                MBG(end).Interpolation = struct;
                                MBG(end).Interpolation(end).Lines = MB(end).MiddleLines;
                                MBG(end).Interpolation(end).Style = 'P';
                            end
                        end
                    case 'I'
                        if isempty(MB(end).MiddleLines)
                            MB(end).TopLines(end) = row;
                        end
                        MB(end).BottomLines(end) = row;
                    case 'A'
                        MB(length(MB)+1, 1) = struct('Top', 'I', 'TopLines', [row, row], 'MiddleLines', [], 'Bottom', 'I', 'BottomLines', [row, row]);
                        MBG(end).Range(end) = length(MB);
                        if (isfield(MBG(end), 'Interpolation') && ~isempty(MBG(end).Interpolation))
                            MBG(end).Interpolation(end).Lines(end) = row - 1;
                            MBG(end).Interpolation(end).Style = 'C';
                        elseif (isfield(MBG(end), 'Interpolation') && isempty(MBG(end).Interpolation)) || ~isfield(MBG(end), 'Interpolation')
                            if MB(end-1).MiddleLines(1) ~= 1
                                MBG(end).Interpolation = struct;
                                MBG(end).Interpolation(end).Lines = [MB(end-1).MiddleLines(1),row-1];
                                MBG(end).Interpolation(end).Style = 'C';
                            end
                        end
                end
            elseif ~boolIncrement && boolAddition
                switch MB(end).Bottom
                    case 'F'
                        MB(end).Bottom = 'A';
                        MB(end).BottomLines = [row, row];
                        scope = MB(end).MiddleLines(end) - MB(end).MiddleLines(1) + 1;
                        if scope == 1 % do nothing
                        else
                            if MBG(end).Range(1) == MBG(end).Range(end)
                                MBG(end).Interpolation(end).Lines(end) = row - 2;
                            else
                                MBG(end).Interpolation(end).Lines(end) = row - 2;
                                MBG(end).Interpolation(end).Style = 'P';
                            end
                        end
                    case 'A'
                        MB(end).BottomLines(end) = row;
                        if isempty(MB(end).MiddleLines)
                            MB(end).TopLines(end) = row;
                        else
                            if MBG(end).Range(1) == MBG(end).Range(end)
                                % do nothing
                            else
                                MBG(end).Interpolation(end).Lines(end) = row;
                            end
                        end
                    case 'I'
                        MB(length(MB)+1, 1) = struct('Top', 'A', 'TopLines', [row, row], 'MiddleLines', [], 'Bottom', 'A', 'BottomLines', [row, row]);
                        MBG(length(MBG)+1, 1).Range = [length(MB), length(MB)];
                end
            elseif boolIncrement && boolAddition
                switch MB(end).Bottom
                    case 'F'
                        MB(end).MiddleLines(end) = row;
                        if MBG(end).Range(1) == MBG(end).Range(end)
                            if (isfield(MBG(end), 'Interpolation') && ~isempty(MBG(end).Interpolation))
                                MBG(end).Interpolation(end).Lines(end) = row - 1;
                            elseif (isfield(MBG(end), 'Interpolation') && isempty(MBG(end).Interpolation)) || ~isfield(MBG(end), 'Interpolation')
                                if MB(end).MiddleLines(1) ~= 1
                                    MBG(end).Interpolation = struct;
                                    MBG(end).Interpolation(end).Lines = [MB(end).MiddleLines(1),row-1];
                                    MBG(end).Interpolation(end).Style = 'P';
                                end
                            end
                        else
                            if strcmp(MB(end).Top, 'I')
                                MBG(end).Interpolation(length(MBG(end).Interpolation)+1,1).Lines = [MB(end).MiddleLines(1), row-1];
                                MBG(end).Interpolation(end).Style = 'P';
                            else
                                MBG(end).Interpolation(end).Lines(end) = row - 1;
                            end
                        end
                    case 'I'
                        if ~isempty(MB(end).MiddleLines)
                            MB(length(MB)+1, 1) = struct('Top', 'F', 'TopLines', [], 'MiddleLines', [row, row], 'Bottom', 'F', 'BottomLines', []);
                            MBG(length(MBG)+1, 1).Range = [length(MB), length(MB)];
                        else
                            if MBG(end).Range(1) == MBG(end).Range(end)
                                MB(end).BottomLines = [];
                                MB(end).Bottom = 'F';
                                MB(end).MiddleLines = [row, row];
                            else
                                if MB(end).BottomLines(1) == MB(end).BottomLines(end)
                                    MB(end).BottomLines = [];
                                    MB(end).Bottom = 'F';
                                    MB(end).MiddleLines = [row, row];
                                else
                                    MB(length(MB)+1, 1) = struct('Top', 'F', 'TopLines', [], 'MiddleLines', [row, row], 'Bottom', 'F', 'BottomLines', []);
                                    MBG(length(MBG)+1, 1).Range = [length(MB), length(MB)];
                                end
                            end
                        end
                    case 'A'
                        MB(length(MB)+1, 1) = struct('Top', 'F', 'TopLines', [], 'MiddleLines', [row, row], 'Bottom', 'F', 'BottomLines', []);
                        MBG(end).Range(end) = length(MB);
                        if (isfield(MBG(end), 'Interpolation') && ~isempty(MBG(end).Interpolation))
                            MBG(end).Interpolation(end).Lines(end) = row - 1;
                            MBG(end).Interpolation(end).Style = 'C';
                        elseif (isfield(MBG(end), 'Interpolation') && isempty(MBG(end).Interpolation)) || ~isfield(MBG(end), 'Interpolation')
                            if ~isempty(MB(end-1).MiddleLines) && (MB(end-1).MiddleLines(1) ~= 1)
                                MBG(end).Interpolation = struct;
                                MBG(end).Interpolation(end).Lines = [MB(end-1).MiddleLines(1),row-1];
                                MBG(end).Interpolation(end).Style = 'C';
                            end
                        end
                end
            end
        end
        if row == size(IncrementMissingMap, 1)
            MBG(end).LastLine = true;
        end
    end
end

function DA = IncrementAddition_DecreasingAdditionDetect(T, AW, A)
    DA = cell.empty;
    for idxx = 2: size(T, 1)
        if T{idxx, AW} < T{idxx-1, AW}
            DA = [DA, [idxx-1, idxx]];
            warning([A, '. Addition was decreasing at rows [', sprintf('%i', idxx-1), ',', sprintf('%i', idxx), ']']);
        end
    end
end