classdef BoundaryType < handle
    properties(Dependent, Access='public')
        name
        leftImage
        rightImage
    end
    properties(Hidden, Dependent)
        ri
    end
    properties(Hidden)
        li
    end
    methods
        function obj = BoundaryType(in, flag, ~)
            if (nargin == 1)
                switch in
                    case {'(', '[', '{'}, obj.li = in;
                    case {')', ']', '}'}, obj.li = imageFlipR2L(in);
                    otherwise, obj.li = name2leftImage(in);
                end
                return;
            elseif (nargin == 2)
                switch flag
                    case 'name', obj.li = name2leftImage(in);
                    case 'left', obj.li = in;
                    case 'right', obj.li = imageFlipR2L(in);
                end
                return;
            elseif (nargin == 0)
                obj.li = '{'; return;
            end
        end

        function val = get.ri(obj)
            val = imageFlipL2R(obj.li);
        end

        function val = get.rightImage(obj)
            val = imageFlipL2R(obj.li);
        end

        function val = get.leftImage(obj)
            val = obj.li;
        end

        function val = get.name(obj)
            switch obj.li
                case '[', val = 'closed'; 
                case '(', val = 'open';
                case '{', val = 'ambiguous';
            end
        end

        function tf = eq(obj1, obj2)
            if numel(obj1) == 1 && numel(obj2) == 1, tf = isequal(obj1, obj2);
            else, tf = operateSizeHelper(obj1, obj2, @isequal, @false);
            end
        end

        function tf = ne(obj1, obj2)
            tf = ~eq(obj1, obj2);
        end

        function pd = plus(obj1, obj2)
            cbt = BoundaryType('['); abt = BoundaryType('{');
            if all([obj1 obj2] == cbt), pd = cbt;
            elseif any([obj1 obj2] == abt), pd = abt;
            else, pd = BoundaryType('(');
            end
        end

        function itt = BoundaryTypes2IntervalType(obj1, obj2)
            itt = IntervalType(strcat(obj1.li,obj2.ri));
        end
    end
end

%% Helper
function li = name2leftImage(bnm)
    li = [];
    switch bnm
        case 'open',        li = '(';
        case 'closed',      li = '[';
        case 'ambiguous',   li = '{';
    end
end

function im2 = imageFlipL2R(im1)
    switch im1
        case '(', im2 = ')';
        case '[', im2 = ']';
        case '{', im2 = '}';
    end
end

function im2 = imageFlipR2L(im1)
    switch im1
        case ')', im2 = '(';
        case ']', im2 = '[';
        case '}', im2 = '{';
    end
end