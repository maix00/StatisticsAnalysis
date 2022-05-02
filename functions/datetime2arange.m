function ar = datetime2arange(dt, varargin)
    sizeInfo = size(dt);
    if sizeInfo(2) == 1
        dt = [dt, dt];
    elseif sizeInfo(2) > 2
        dt = [dt(:,1), dt(:, end)];
    end
    ar = [];
    for indx = 1: 1: sizeInfo(1)
        thisAr = arange(dt(indx,1), dt(indx,2), varargin{:});
        ar = [ar; thisAr];
    end
end