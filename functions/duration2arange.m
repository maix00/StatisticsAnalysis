function obj = duration2arange(dr)
    sizeInfo = size(dr);
    obj = [];
    for indx2 = 1: 1: sizeInfo(2)
        thisCol = [];
        for indx1 = 1: 1: sizeInfo(1)
            thisObj = arange(dr(indx1, indx2));
            thisCol = [thisCol; thisObj];
        end
        obj = [obj, thisCol];
    end
end