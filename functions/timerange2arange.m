function ar = timerange2arange(tr)
    numelInfo = numel(tr);
    if numelInfo == 1 && isa(tr, 'timerange')
        tr = saveobj(tr);
        if isempty(tr.unitOfTime)
            ar = arange(tr.first, tr.last, tr.type);
        else
            ar = arange(tr.first, tr.last, tr.type, tr.unitOfTime);
        end
    elseif numelInfo == 1 && isa(tr, 'cell')
        ar = cell(1, 1);
        ar{1} = timerange2arange(tr{1});
    elseif numelInfo == 1
        ar = arange.empty;
    else
        ar = [];
        sizeInfo = size(tr);
        for indx2 = 1: 1: sizeInfo(2)
            thisCol = [];
            for indx1 = 1: 1: sizeInfo(1)
                thisObj = timerange2arange(tr{indx1, indx2});
                thisCol = [thisCol; thisObj];
            end
            ar = [ar, thisCol];
        end
    end
end

