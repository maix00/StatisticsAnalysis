function bool = isthesame(obj1, obj2, opt)
    
    if nargin == 2
        opt = false; % true will make NaN = NaN, also NaT
    end
    ndim = 2;
    % Using isequal (x), issame
    bool1 = []; 
    try 
        if ~opt
            bool1 = all_ndim(issame(obj1, obj2), ndim); 
        end
    catch
    end
    try
        if isnan(obj1) && isnan(obj2) && opt
            bool1 = true;
        end
    catch
    end
    try
        if isnat(obj1) && isnat(obj2) && opt
            bool1 = true;
        end
    catch
    end
    % If bool1 is empty, need further checks; if bool1 is false or true,
    % return false or true.
    if ~isempty(bool1)
        bool = bool1;
    else % Using ==
        bool2 = []; if ~opt, try bool2 = all_ndim(obj1==obj2, ndim); catch; end; end
        % If bool2 is empty, need further checks; if bool2 is false or true,
        % return false or true.
        if ~isempty(bool2)
            bool = bool2;
        else % Size Check
            bool3 = true;
            try
                sizeInfo1 = size(obj1);
                sizeInfo2 = size(obj2);
                bool3 = all(sizeInfo1 == sizeInfo2);
            catch
            end
            % If bool3 is true, need further checks; if bool3 is false,
            % return false.
            if ~bool3
                bool = false;
            else
                % Suppose 1x1 struct
                sizeInfo = size(obj1);
                if all(sizeInfo == [1 1]) % 1x1
                    try 
                        % Check Field Numbers
                        field1 = fieldnames(obj1);
                        field2 = fieldnames(obj2);
                        bool4 = length(field1) == length(field2);
                        % if bool4 is false, one should immediately return 
                        % false; if it is true, one need further checks.
                        if ~bool4
                            bool = false;
                        else
                            % Check Field Names
                            bool5 = true;
                            for index = 1: 1: length(field1)
                                bool5 = bool5 && any(strcmp(field1{index}, field2));
                                % If this field name is one of the field names 
                                % in field2, bool5 would still be true; if this 
                                % name is not one of them, bool5 would become
                                % false. Once bool5 became false, one should 
                                % immediately return false and break the loops.
                                if ~bool5, bool = false; break; end
                            end
                            % If bool5 is true, one need further checks.
                            if bool5
                                % Check Field Values
                                bool6 = true;
                                for index = 1: 1: length(field1)
                                    thisFieldName = field1{index};
                                    bool6 = bool6 && isthesame(obj1.(thisFieldName), obj2.(thisFieldName), opt);
                                    % If this value is true, bool6 would still 
                                    % be true; if false, bool6 would become 
                                    % false. Once bool6 became false, one 
                                    % should immediately return false and
                                    % break the loops.
                                    if ~bool6, bool = false; break; end
                                end
                                % If bool6 is true, return true.
                                if bool6, bool = true; end
                            end
                        end
                    catch
                        error('Fail to compare. isthesame/issame -> == -> size -> 1x1 struct Calls.')
                    end
                else
                    % Can not be supposed as 1x1 struct
                    % Suppose cell-like 2D Structrue
                    try
                        try_catch = obj1{1}; % if not cell-like, this would invoke errors;
                        sizeInfo = size(obj1); try_catch = sizeInfo == [1 1]; % if over 2D, this would invoke errors.
                        bool7 = true;
                        for indx1 = 1: 1: sizeInfo(1)
                            for indx2 = 1: 1: sizeInfo(2)
                                bool7 = bool7 && isthesame(obj1{indx1, indx2}, obj2{indx1, indx2}, opt);
                                % If this value is the same, bool7 
                                % would still be true; if this value 
                                % turns out to be not the same, bool7 
                                % would become false. Once bool7 became 
                                % false, one should immediately return 
                                % false and break the loops.
                                if ~bool7, bool = false; break; end
                            end
                        end
                        % if bool7 is true, one should return true.
                        if bool7, bool = true; end
                    catch
                        % Can not be supposed as array-like 2D Structure
                        % Suppose array-like 2D Structure
                        try
                            try_catch = obj1(1); % if not array-like, this would invoke errors;
                            sizeInfo = size(obj1); try_catch = sizeInfo == [1 1]; % if over 2D, this would invoke errors.
                            if ~all(try_catch) % the struct is nested
                                bool8 = true;
                                for indx1 = 1: 1: sizeInfo(1)
                                    for indx2 = 1: 1: sizeInfo(2)
                                        bool8 = bool8 && isthesame(obj1(indx1, indx2), obj2(indx1, indx2), opt);
                                        % If this sub-struct is the same, bool8
                                        % would still be true; if this
                                        % sub-struct turns out to be not the
                                        % same, bool8 would become false. Once
                                        % bool8 became false, one should
                                        % immediately return false and break
                                        % the loops.
                                        if ~bool8, bool = false; break; end
                                    end
                                end
                                % If bool8 is true, one should return true.
                                if bool8, bool = true; end
                            else 
                            end
                        catch
                            error('Fail to distinguish. isthesame/issame -> == -> size -> 1x1 struct -> 2D array -> 3D cell Calls.')
                        end
                    end
                end
            end
        end
    end

    function bool = all_ndim(bool_array, ndim)
        if ndim == 2
            string1 = "all(all("; string2 = "))";
        else
            string1 = ""; 
            string2 = "";
            for indx = 1: 1: ndim, string1 = strcat(string1, "all("); string2 = strcat(string2, ")"); end
        end
        bool = eval(strcat(string1, "bool_array", string2, ";"));
    end
end