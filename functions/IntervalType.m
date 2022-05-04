classdef IntervalType < handle
    properties
        name
        intervalTypeImage
        leftBoundaryTypeImage
        rightBoundaryTypeImage
    end
    properties(Hidden, Access='public')
        iti
        lbti
        lbt
        rbti
        rbt
    end
    methods
        function obj = IntervalType(in)
            narginchk(1,1);
            [tf, obj.name, obj.intervalTypeImage, obj.leftBoundaryTypeImage, obj.rightBoundaryTypeImage] = validCheckIntervalType(in);
            if ~tf, obj = IntervalType.empty; return
            else, obj.iti = obj.intervalTypeImage; obj.lbti = obj.leftBoundaryTypeImage; obj.rbti = obj.rightBoundaryTypeImage;
                obj.lbt = BoundaryType(obj.leftBoundaryTypeImage); obj.rbt = BoundaryType( obj.rightBoundaryTypeImage);
            end
        end
    end
end

%% Helper
function [tf, iT, itt, itl, itr] = validCheckIntervalType(str)
    iT = []; itt = []; itr = []; itl = [];
    ls1 = ["openright" "closedleft" "openleft" "closedright" "open" "closed" "ambiguous"]; 
    ls2 = ["open-open" "open-closed" "closed-open" "closed-closed" "ambiguous-open" "ambiguous-closed" "open-ambiguous" "closed-ambiguous"];
    ls3 = ["()" "(]" "(}" "[)" "[]" "[}" "{)" "{]" "{}"];
    map1 = strcmp(str, ls1); map2 = strcmp(str, ls2); map3 = strcmp(str, ls3);
    if ~any(map1) && ~any(map2) && ~any(map3), tf = false; return; end; tf = true;
    if any(map1), iT = str; [itt, itl, itr] = iT2all(iT);
    elseif any(map2), [itt, itl, itr, iT] = iT2all(str);
    elseif any(map3), itt = str; [itl, itr, iT] = itt2all(str);
    end
end

function [itt, itl, itr, iT] = iT2all(iT)
    flag = strfind(iT, "-");
    if isempty(flag)
        switch iT
            case 'openright',   itt = '[)'; itl = '['; itr = '(';
            case 'closedleft',  itt = '[)'; itl = '['; itr = '(';
            case 'openleft',    itt = '(]'; itl = '('; itr = '[';
            case 'closedright', itt = '(]'; itl = '('; itr = '[';
            case 'open',        itt = '()'; itl = '('; itr = '(';
            case 'closed',      itt = '[]'; itl = '['; itr = '[';
            case 'ambiguous',   itt = '{}'; itl = '{'; itr = '{';
        end
    else, itl = nm2imL(iT(1: flag-1)); itr = nm2imR(iT(flag+1, end)); itt = [itl, imFlip(itr)]; iT = lr2iT(itr, itl);
    end
end

function [itl, itr, iT] = itt2all(itt)
    itt =char(itt);
    itl = itt(1); itr = imFlip(itt(2)); iT = lr2iT(itl, itr);
end

function iT = itt2iT(itt)
    [~, ~, iT] = itt2all(itt);
end

function im = nm2imL(nm)
    switch nm
        case 'open', im = '(';
        case 'closed', im = '[';
        case 'ambiguous', im = '{';
    end
end

function im = nm2imR(nm)
    switch nm
        case 'open', im = ')';
        case 'closed', im = ']';
        case 'ambiguous', im = '}';
    end
end

function im2 = imFlip(im1)
    switch im1
        case ')', im2 = '(';
        case ']', im2 = '[';
        case '}', im2 = '{';
        case '(', im2 = ')';
        case '[', im2 = ']';
        case '{', im2 = '}';
    end
end

function iT = lr2iT(itl, itr)
    switch itl
        case '['
            switch itr
                case '[', iT = 'closed';
                case '(', iT = 'openright';
                case '{', iT = 'closed-ambiguous';
            end
        case '('
            switch itr
                case '[', iT = 'openleft';
                case '(', iT = 'open';
                case '{', iT = 'open-ambiguous';
            end
        case '{'
            switch itr
                case '[', iT = 'ambiguous-closed';
                case '(', iT = 'ambiguous-open';
                case '{', iT = 'ambiguous';
            end
    end
end