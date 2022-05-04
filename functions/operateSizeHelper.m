function ot = operateSizeHelper(obj1, obj2, fc1, fc2) % fc1: how to operate 1D; fc2: initialize
    if isempty(obj1) || isempty(obj2), ot = fc2([1 1]);
    else
        sz1 = size(obj1); sz2 = size(obj2); num1 = numel(obj1); num2 = numel(obj2);
        if isequal(sz1, sz2), ct = 2; if num1 == 1, ct = 1; end; sz = sz1; num = num1; % 1 <- same 1D, 2 <- same
        elseif num1 == 1, ct = -1; sz = sz2; num = num2; elseif num2 == 1, ct = -2; sz = sz1; num = num1; % -1 <- obj1 1D, -2 <- obj2 1D
        elseif num1 == num2, ct = -3; sz = sz1; num = num1;% -3 <- same numel
        elseif length(sz1) == 2 && length(sz2) == 2
            if any(sz1 == 1) && any(sz2 == 1), ct = 3; % 3 <- span
                if sz1(1) == 1, sz = [sz2(1), sz1(2)]; flag = 2; else, sz = [sz1(1) sz2(2)]; flag = 1; end
            end
        else
            error('Arrays have incompatible sizes for this operation.');
        end
        ot = fc2(sz);
        switch ct
            case 3
                switch flag
                    case 1, for idx1 = 1: num1, for idx2 = 1: num2, ot(idx1, idx2) = fc1(obj1(idx1), obj2(idx2)); end; end
                    case 2, for idx2 = 1: num2, for idx1 = 1: num1, ot(idx2, idx1) = fc1(obj2(idx2), obj1(idx1)); end; end
                end
            case [2, -3], for idx = 1: num; ot(idx) = fc1(obj1(idx), obj2(idx)); end
            case 1, ot = fc1(obj1, obj2);
            case -1, for idx = 1: num; ot(idx) = fc1(obj1, obj2(idx)); end
            case -2, for idx = 1: num; ot(idx) = fc1(obj1(idx), obj2); end
        end
    end
end