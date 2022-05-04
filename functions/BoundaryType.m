classdef BoundaryType < handle
    properties
        name
        leftImage
        rightImage
    end
    properties(Hidden)
        li
        ri
    end
    methods
        function obj = BoundaryType(in)
            narginchk(1,1);
            [tf, obj.name, obj.leftImage, obj.rightImage] = validCheckBoundaryType(in);
            if ~tf, obj = BoundaryType.empty; return
            else, obj.li = obj.leftImage; obj.ri = obj.rightImage; end
        end

        function tf = eq(obj1, obj2)
            tf = operateSizeHelper(obj1, obj2, @isequal, @false);
        end

        function tf = ne(obj1, obj2)
            tf = ~eq(obj1, obj2);
        end

        function pd = plus(obj1, obj2)
            if all([obj1 obj2] == ClosedBoundaryType), pd = ClosedBoundaryType;
            elseif any([obj1 obj2] == AmbiguousBoundaryType), pd = AmbiguousBoundaryType;
            else, pd = OpenBoundaryType; 
            end
        end

        function itt = BoundaryTypes2IntervalType(obj1, obj2)
            itt = IntervalType(strcat(obj1.li,obj2.ri));
        end
    end
end

%% Helper
function [tf, bnm, biml, bimr] = validCheckBoundaryType(str)
    bnm = []; biml = []; bimr = [];
    ls1 = ["open" "closed" "ambiguous"];
    ls2 = ["(" "[" "{" ];
    ls3 = [")" "]" "}" ];
    map1 = strcmp(str, ls1); map2 = strcmp(str, ls2); map3 = strcmp(str, ls3);
    if ~any(map1) && ~any(map2) && ~any(map3), tf = false; return; end; tf = true;
    if any(map1), bnm = str; [biml, bimr] = nm2all(bnm);
    elseif any(map2), biml = str; bnm = iml2nm(biml); bimr = imFlip(biml);
    elseif any(map3), bimr = str; biml = imFlip(bimr); bnm = iml2nm(biml); 
    end
end

function [biml, bimr] = nm2all(bnm)
    switch bnm
        case 'open',        biml = '('; bimr = ')';
        case 'closed',      biml = '['; bimr = ']';
        case 'ambiguous',   biml = '{'; bimr = '}';
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

function nm = iml2nm(im)
    switch im
        case '[', nm = 'closed'; 
        case '(', nm = 'open';
        case '{', nm = 'ambiguous';
    end
end

function pd = ClosedBoundaryType()
    pd = BoundaryType('closed');
end

function pd = OpenBoundaryType()
    pd = BoundaryType('open');
end

function pd = AmbiguousBoundaryType()
    pd = BoundaryType('ambiguous');
end