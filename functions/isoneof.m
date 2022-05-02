function [anybool, bool] = isoneof(obj, cell)
    sizeInfo = size(cell);
    bool = [];
    for indx2 = 1: 1: sizeInfo(2)
        thisCollumn = [];
        for indx1 = 1: 1: sizeInfo(1)
            thisBool = isa(obj, cell{indx1, indx2});
            thisCollumn = [thisCollumn; thisBool];
        end
        bool = [bool, thisCollumn];
    end
    anybool = any(any(bool));
    % cell should be a 2D cell
end