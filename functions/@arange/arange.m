classdef arange
    % ARANGE Arange is a class of range data.
    %   R = ARANGE(bottom, top, intervalType, unit)
    %   R = ARANGE(bottom, top, intervalType)
    %   R = ARANGE(bottom, top, unit)
    %   R = ARANGE(bottom, unit)
    %   R = ARANGE(bottom, top)
    %   R = ARANGE(duration, intervalType)
    %   R = ARANGE(duration)
    %   R = ARANGE(timerange_OR_cell_OR_datetime_OR_duration)
    %
    %   Property intervalType is one of the following:
    %       'open'
    %       'closed'
    %       'openleft'  = 'closedright'
    %       'openright' = 'closedleft'
    %
    %   Property unit can be set customly. When specified as the following, ARANGE would automatically interact with <a href = "matlab:help timerange">timerange</a>
    %    and <a href = "matlab:help duration">duration</a>.
    %       'year'      or    'years'
    %       'quarter'   or    'quarters'
    %       'month'     or    'months'
    %       'week'      or    'weeks'
    %       'day'       or    'days'
    %       'hour'      or    'hours'
    %       'minute'    or    'minutes'
    %       'second'    or    'seconds'
    % 
    %   Property scope would be automatically calculated according to rectified properties bottom and top.
    % 
    % ARANGE methods and functions:
    %   Construction and conversion as a whole:
    %       <a href = "matlab:help arange/arange">arange</a>
    %           - <a href = "matlab:help timerange2arange">timerange2arange</a>
    %           - <a href = "matlab:help duration2arange">duration2arange</a>
    %           - <a href = "matlab:help datetime2arange">datetime2arange</a>
    %       <a href = "matlab:help isarange">isarange</a>
    %       <a href = "matlab:help arange2timerange">arange2timerange</a> aka <a href = "matlab:help ar2tr">ar2tr</a>
    %       <a href = "matlab:help arange2duration">arange2duration</a>  aka <a href = "matlab:help ar2dr">ar2dr</a>
    %       <a href = "matlab:help arange2datetime">arange2datetime</a>  aka <a href = "matlab:help ar2dt">ar2dt</a>
    %       <a href = "matlab:help arange2cell">arange2cell</a>
    %
    %   Value convertion:
    %       <a href = "matlab:help value2str">value2str</a>
    %       <a href = "matlab:help value2datetime">value2datetime</a>
    %       <a href = "matlab:help value4datestr">value4datestr</a>
    %       <a href = "matlab:help value2duration">value2duration</a>
    %
    %   Relationship:
    %       <a href = "matlab:help arange/isempty">isempty</a>                     - 0x0, or contains NaN and NaT, or no limits, or not closed intervalType on one value
    %       <a href = "matlab:help arange/issame">issame</a>                      - isequal or both isempty
    %       <a href = "matlab:help arange/isinarange">isinarange</a>       aka <a href = "matlab:help arange/ni">ni</a>     - check whether an instance is between the bottom and top limits of the ARANGE
    %       <a href = "matlab:help arange/eq">eq</a>               aka <a href = "matlab:help arange/eq">==</a>     - <a href = "matlab:help arange/thesame">thesame</a> or optional, <a href = "matlab:help arange/intervalIntersects">intervalIntersects</a>
    %       <a href = "matlab:help arange/ne">ne</a>               aka <a href = "matlab:help arange/ne">~=</a>     - not <a href = "matlab:help arange/thesame">thesame</a> or optional, not <a href = "matlab:help arange/intervalIntersects">intervalIntersects</a>
    %       <a href = "matlab:help arange/lt">lt</a>               aka <a href = "matlab:help arange/lt"><</a>      - whether the former's scope is less than or equals the latter's (when equal, 
    %                                     smaller intervalType), or optional, interval whole comparison without intersection
    %                                     [Require Same Unit]
    %       <a href = "matlab:help arange/le">le</a>               aka <a href = "matlab:help arange/le"><=</a>     - whether the former's scope is less than or equals the latter's, or optional, interval
    %                                     whole comparison with intersection [Require Same Unit]
    %       <a href = "matlab:help arange/gt">gt</a>               aka <a href = "matlab:help arange/gt">></a>      - likewise
    %       <a href = "matlab:help arange/ge">ge</a>               aka <a href = "matlab:help arange/ge">>=</a>     - likewise
    %
    %   Calculations:
    %       <a href = "matlab:help arange/abs">abs</a>                         - unary operation of any ARANGE array
    %       <a href = "matlab:help arange/uminus">uminus</a>           aka <a href = "matlab:help arange/uminus">-</a>      - unary operation of any ARANGE array
    %       <a href = "matlab:help arange/plus">plus</a>             aka <a href = "matlab:help arange/plus">+</a>      - between any ARANGE arrays with same unit or between ARANGE durations
    %       <a href = "matlab:help arange/minus">minus</a>            aka <a href = "matlab:help arange/minus">-</a>      - between any ARANGE arrays with same unit or between ARANGE durations
    %       <a href = "matlab:help arange/times">times</a>            aka <a href = "matlab:help arange/times">.*</a>     - between scalar matrix and any ARANGE array
    %       <a href = "matlab:help arange/mtimes">mtimes</a>           aka <a href = "matlab:help arange/mtimes">*</a>      - between scalar matrix and ARANGE duration or ARANGE scope matrix
    %
    %   Examples:
    %
    %   >> A = arange('2022-04-08', "second"); disp(A);
    %           a range [ 08-Apr-2021 00:00:00 , 08-Apr-2021 00:00:01 ) in seconds, which has scope 00:00:01
    %   >> B = arange(minutes(3), minutes(5), 'closed').ar2tr; disp(B);
    %	        timetable timerange subscript:
	%	            Select timetable rows with times in the closed interval:
	%	            [3 min, 5 min]
    %   >> C = arange('now','tomorrow','quarters'); disp(C);
    %           a range [ 01-Apr-2022 00:00:00 , 01-Jul-2022 00:00:00 ) in quarters, which has scope 2184:00:00
    %   >> D = arange.empty; E = arange(NaN, NaN); F = arange(NaT, NaT); tf = [D E] == [D F]; disp(tf);
    %           1
    %   >> G = arange(1,3,'closed','pigs'); H = arange(2,3,'openleft','pigs'); tf1 = G <= H; tf2 = le(G, H, true); disp([tf1 tf2]);
    %           0    1
    %       The former compares the length of scope. The latter compares the intersection and the surpassing of intervals.
    %   >> disp([[G+H; G-H], [3 4].*[G;H]]);
    %         2x2 arange array
    %         column1
    %           a range ( 3 , 6 ] in pigs, which has scope 3
    %           a range [ -2 , 1 ) in pigs, which has scope 3
    %         column2
    %           a range [ 3 , 9 ] in pigs/3, which has scope 6
    %           a range ( 8 , 12 ] in pigs/4, which has scope 4
    %   >> disp([G,H]*[4 3; 2 1])
    %           10  7
    %   >> disp([3;2]*A)
    %       2x1 arange array
    %       column1
    %           a range of openright duration 00:00:03, which has scope 00:00:03
    %           a range of openright duration 00:00:02, which has scope 00:00:02

    %  %-------------------------------------------------------------------
    %    Author: WANG Yi-yang
    %      Date: 27-Apr-2022
    %   Version: v20220502
    

    properties(Transient, Access='public')
        bottom = [];
        top = [];
        intervalType = 'openright';
        unit = [];
        duration = [];
        scope = [];
    end

    methods
        function [obj, optionalCell] = arange(bottom_or_others, top_or_intervalType_or_unit, intervalType_or_unit, unit, ~)
            optionalCell = {};
            try
                narginchk(1, 4);
                validIntervalType = ["openright" "closedleft" "openleft" "closedright" "open" "closed"];
                % bottom, top, intervalType, unit
                if (nargin == 4), obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.intervalType = intervalType_or_unit; obj.unit = unit;
                    obj = obj.inputRectify;
                elseif (nargin == 3) 
                    % bottom, top, intervalType
                    % bottom, intervalType, unit
                    % bottom, top, unit
                    if any(strcmp(intervalType_or_unit, validIntervalType))
                        obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.intervalType = intervalType_or_unit;
                    elseif any(strcmp(top_or_intervalType_or_unit, validIntervalType))
                            obj.bottom = bottom_or_others; obj.intervalType = obj.top_or_intervalType_or_unit; obj.unit = intervalType_or_unit;
                    else, obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.unit = intervalType_or_unit; 
                    end
                    obj = obj.inputRectify;
                elseif (nargin == 2)
                    % duration or other class, intervalType
                    % bottom, unit
                    % bottom, top
                    if any(strcmp(top_or_intervalType_or_unit, validIntervalType)), obj = obj.inputConvert(bottom_or_others, top_or_intervalType_or_unit);
                    else
                       tf1 = ~strcmp(class(bottom_or_others),class(top_or_intervalType_or_unit)); tf2 = false; %try tf2 = ~tf1 && (length(bottom_or_others) ~= length(top_or_intervalType_or_unit)); catch; end
                       if tf1 || tf2, obj.bottom = bottom_or_others; obj.unit = top_or_intervalType_or_unit; 
                       else, obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; end
                    end
                    obj = obj.inputRectify;
                elseif (nargin == 1), [obj, optionalCell] = obj.inputConvert(bottom_or_others); % duration or other class
                end
            catch ME
                if (nargin == 0), return; end
                error(ME.message);
            end
        end
    end

    methods(Hidden)        
        function disp(obj)
            import matlab.internal.display.lineSpacingCharacter
            tab = sprintf('  ');
            sizeInfo = size(obj);
            sizeChar = [char(string(sizeInfo(1))) 'x' char(string(sizeInfo(2))) ' <a href = "matlab:help arange">arange</a> array'];
            if all(sizeInfo==[1 1])
                switch obj.intervalType
                    case 'openright', stringLeft = '['; stringRight = ')';
                    case 'open', stringLeft = '('; stringRight = ')';
                    case 'closed', stringLeft = '['; stringRight = ']';
                    case 'openleft', stringLeft = '('; stringRight = ']';
                end
                datetimeformat = settings().matlab.datetime.DefaultFormat.ActiveValue;
                if ~isempty(obj.bottom)
                    if isa(obj.bottom,'datetime'), dispMsg = [stringLeft ' ' convert2CharHelper(obj.bottom, datetimeformat) ', ' convert2CharHelper(obj.top, datetimeformat) stringRight];
                    else, dispMsg = [stringLeft ' ' convert2CharHelper(obj.bottom) ' , ' convert2CharHelper(obj.top) ' ' stringRight];
                    end
                else, dispMsg = obj.intervalType; 
                end
                if ~isempty(obj.duration), dispMsg = ['of ' dispMsg ' duration ' convert2CharHelper(obj.duration)]; end
                if ~isempty(obj.unit), dispMsg = [dispMsg ' in ' convert2CharHelper(obj.unit)]; end
                if ~isempty(obj.scope), dispMsg = [dispMsg ', which has scope ' convert2CharHelper(obj.scope)]; end
                if ~isempty(obj), disp([tab tab 'a range ' dispMsg]); else, disp([tab tab 'an <a href = "matlab:help arange/isempty">empty</a> range ' dispMsg]); end
            else
                disp([tab sizeChar lineSpacingCharacter])
                for indx2 = 1: 1: sizeInfo(2)
                    disp([tab 'column' char(string(indx2))]);
                    for indx1 = 1: sizeInfo(1), disp(obj(indx1, indx2)); end
                end
            end
            function output = convert2CharHelper(input, datetimeformat)
                output = [];
                try if isempty(input), output = '< missing >'; end; catch; end
                try if isnan(input), output = 'NaN'; end; catch; end
                if isempty(output), try if isnat(input), output = 'NaT'; end; catch; end; end
                if nargin == 2, if isempty(output), try output = [char(input, datetimeformat) ' ' input.TimeZone]; catch output = char(input, datetimeformat); end; end; end
                if isempty(output), try output = char(string(input)); catch; end; end
                if isempty(output), output = ''; end
            end
        end
        function s = saveobj(obj)
            s = struct;
            if ~isempty(obj)
                sizeInfo = size(obj);
                s = [];
                for indx2 = 1: 1: sizeInfo(2)
                    thisCol = [];
                    for indx1 = 1: 1: sizeInfo(1)
                        t = struct;
                        thisObj = obj(indx1, indx2);
                        t.bottom = thisObj.bottom;
                        t.top  = thisObj.top;
                        t.intervalType = thisObj.intervalType;
                        t.unit = thisObj.unit;
                        t.duration = thisObj.duration;
                        t.scope = thisObj.scope;
                        thisCol = [thisCol; t];
                    end
                    s = [s, thisCol];
                end
            end
        end

        function gp = gap(obj)
            numelInfo = numel(obj);
            if numelInfo == 1
                gp = obj.scope;
            elseif numelInfo > 1
                sizeInfo = size(obj);
                gp = cell(sizeInfo);
                for indx = 1: 1: numelInfo
                    gp{indx} = obj(indx).scope;
                end
            end
        end

        function tf = isempty(obj)
            tempArange = arange();
            tf1 = isequal(obj, tempArange);
            tempArange = tempArange.intervalTypeUpdate('open');
            tf2 = isequal(obj, tempArange);
            tempArange = tempArange.intervalTypeUpdate('closed');
            tf3 = isequal(obj, tempArange);
            tempArange = tempArange.intervalTypeUpdate('openleft');
            tf4 = isequal(obj, tempArange);
            tf5 = isequal(obj, arange.empty);
            tf = any([tf1 tf2 tf3 tf4 tf5]);
            if ~tf, try if isnan(obj.bottom) || isnan(obj.top), tf = true; end; catch; end; end
            if ~tf, try if isnat(obj.bottom) || isnat(obj.top), tf = true; end; catch; end; end
            if ~tf, try if isempty(obj.duration) && isequal(obj.bottom, obj.top) && ~strcmp(obj.intervalType, 'closed'), tf = true; end; catch; end; end
        end

        function tf = lt(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            if ~intervalFlag
                if all(size(obj1) == size(obj2)), numelInfo = numel(obj1);
                    tf = false(size(obj1));
                    validIntervalTypeRelationship = {'openopenleft', 'openopenright', 'openclosed', 'openrightclosed', 'openleftclosed'};
                    for indx = 1: 1: numelInfo
                        tf(indx) = compareLength1DLessThan(obj1(indx), obj2(indx), validIntervalTypeRelationship);
                    end
                elseif numel(obj1) == 1
                    tf = false(size(obj2)); for indx = 1: 1: numel(obj2), tf(indx) = lt(obj1, obj2(indx), intervalFlag); end
                elseif numel(obj2) == 1
                    tf = false(size(obj1)); for indx = 1: 1: numel(obj1), tf(indx) = lt(obj1(indx), obj2, intervalFlag); end
                else
                    tf = false;
                end
                if all([isnumeric(obj1), isnumeric(obj2)]), tf = tf & unitSame(obj1, obj2); end
            else
                tf = intervalLessThan(obj1, obj2);
            end
        end

        function tf = le(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            if ~intervalFlag
                if all(size(obj1) == size(obj2)), numelInfo = numel(obj1);
                    tf = false(size(obj1));
                    validIntervalTypeRelationship = {'openopen', 'openopenleft', 'openopenright', 'openclosed', 'openrightopenright', 'openrightclosed', 'openleftopenleft', 'openleftclosed', 'closedclosed'};
                    for indx = 1: 1: numelInfo
                        tf(indx) = compareLength1DLessEqual(obj1(indx), obj2(indx), validIntervalTypeRelationship);
                    end
                elseif numel(obj1) == 1
                    tf = false(size(obj2)); for indx = 1: 1: numel(obj2), tf(indx) = lt(obj1, obj2(indx), intervalFlag); end
                elseif numel(obj2) == 1
                    tf = false(size(obj1)); for indx = 1: 1: numel(obj1), tf(indx) = lt(obj1(indx), obj2, intervalFlag); end
                else
                    tf = false;
                end
                if all([isnumeric(obj1), isnumeric(obj2)]), tf = tf & unitSame(obj1, obj2); end
            else
                tf = intervalLessThan(obj1, obj2) | intervalIntersects(obj1, obj2);
            end
        end

        function tf = gt(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            tf = lt(obj2, obj1, intervalFlag);
        end

        function tf = ge(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            tf = le(obj2, obj1, intervalFlag);
        end
        
        function tf = eq(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            if ~intervalFlag
                tf = issame(obj1, obj2);
            else
                tf = intervalIntersects(obj1, obj2);
            end
        end

        function tf = ne(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            tf = ~eq(obj1, obj2, intervalFlag);
        end

        function tempObj = abs(obj)
            sizeInfo = size(obj);
            tempObj = [];
            for indx2 = 1: 1: sizeInfo(2)
                thisCol = [];
                for indx1 = 1: 1: sizeInfo(1)
                    thisObj = abs1D(obj(indx1, indx2));
                    thisCol = [thisCol; thisObj];
                end
                tempObj = [tempObj, thisCol];
            end
            function tempObj = abs1D(obj)
                tempObj = [];
                if ~isempty(obj.duration)
                    if obj.duration < 0
                        obj.duration = - obj.duration;
                        switch obj.intervalType
                            case 'openright', obj.intervalType = 'openleft';
                            case 'openleft', obj.intervalType = 'openright';
                        end
                    end
                    if ~isempty(obj.scope)
                        obj.scope = - obj.scope;
                    end
                    tempObj = obj;
                else
                    if ~isempty(obj.scope)
                        if obj.scope < 0
                            tempObj = obj;
                            tempObj.bottom = obj.top;
                            tempObj.top = obj.bottom;
                            tempObj.scope = - obj.scope;
                            switch obj.intervalType
                                case 'openright', tempObj.intervalType = 'openleft';
                                case 'openleft', tempObj.intervalType = 'openright';
                            end
                        end
                    end
                end
                if isempty(tempObj), tempObj = obj; end
            end
        end

        function tempObj = uminus(obj)
            sizeInfo = size(obj);
            tempObj = [];
            for indx2 = 1: 1: sizeInfo(2)
                thisCol = [];
                for indx1 = 1: 1: sizeInfo(1)
                    thisObj = uminus1D(obj(indx1, indx2));
                    thisCol = [thisCol; thisObj];
                end
                tempObj = [tempObj, thisCol];
            end
            function tempObj = uminus1D(obj)
                if ~isempty(obj.duration)
                    obj.duration = - obj.duration;
                    if ~isempty(obj.scope)
                        obj.scope = - obj.scope;
                    end
                    tempObj = obj;
                    switch obj.intervalType
                        case 'openright', tempObj.intervalType = 'openleft';
                        case 'openleft', tempObj.intervalType = 'openright';
                    end
                else
                    if ~isempty(obj.scope)
                        tempObj = obj;
                        tempObj.bottom = obj.top;
                        tempObj.top = obj.bottom;
                        tempObj.scope = - obj.scope;
                        switch obj.intervalType
                            case 'openright', tempObj.intervalType = 'openleft';
                            case 'openleft', tempObj.intervalType = 'openright';
                        end
                    end
                end
            end
        end

        function obj = plus(obj1, obj2)
            sizeInfo1 = size(obj1); sizeInfo2 = size(obj2);
            if all(sizeInfo1 == sizeInfo2)
                obj = [];
                for indx2 = 1: 1: sizeInfo1(2)
                    thisCol = [];
                    for indx1 = 1: 1: sizeInfo1(1)
                        thisObj = plus1DHelper(obj1(indx1, indx2), obj2(indx1, indx2));
                        thisCol = [thisCol; thisObj];
                    end
                    obj = [obj, thisCol];
                end
            elseif numel(obj1) == 1
                obj = obj2; for indx = 1: 1: numel(obj2), obj(indx) = plus(obj1, obj2(indx)); end
            elseif numel(obj2) == 1
                obj = obj1; for indx = 1: 1: numel(obj1), obj(indx) = plus(obj1(indx), obj2); end
            else
                error('Input size does not match.')
            end
            function obj = plus1DHelper(obj1, obj2)
                numericFlag1 = isnumeric(obj1);numericFlag2 = isnumeric(obj2);
                if ~numericFlag1 && numericFlag2, obj = plus1DHelper(obj1, arange(obj2, obj2));
                elseif numericFlag1 && numericFlag2, sum = obj1 + obj2; obj = arange(sum, sum);
                elseif numericFlag1 && ~numericFlag2, obj = plus1DHelper(arange(obj1,obj1),obj2);
                else % ~numericFlag1 && ~numericFlag2 % Suppose Arange
                    duration1 = obj1.duration; duration2 = obj1.duration;
                    if ~isempty(duration1) && ~isempty(duration2), obj = arange(duration1+duration2);
                    else, unit1 = obj1.unit; unit2 = obj2.unit; if ~isempty(unit1) && ~isempty(unit2), if ~strcmp(unit1,unit2), error('Unit does not match.'); end; end
                        positiveFlag1 = obj1 == abs(obj1);
                        positiveFlag2 = obj2 == abs(obj2);
                        additionIntervalType = intervalTypePlus(obj1.intervalType, obj2.intervalType);
                        if ~positiveFlag1 && positiveFlag2
                            obj = plus(obj2, obj1);
                        elseif ~positiveFlag1 && ~positiveFlag2
                            obj = -plus(-obj1, -obj2);
                        elseif positiveFlag1 && positiveFlag2
                            obj = arange(obj1.bottom + obj2.bottom, obj1.top + obj2.top, additionIntervalType, obj1.unit);
                        elseif positiveFlag1 && ~positiveFlag2
                            obj = arange(obj1.bottom - obj2.bottom, obj1.top - obj2.top, additionIntervalType, obj1.unit);
                        end
                    end
                end
                function intervalType = intervalTypePlus(intervalType1, intervalType2)
                    [leftFlag1, rightFlag1] = intervalType2flag(intervalType1);
                    [leftFlag2, rightFlag2] = intervalType2flag(intervalType2);
                    intervalType = flag2intervalType(flagPlus(leftFlag1, leftFlag2), flagPlus(rightFlag1, rightFlag2));
                    function [leftFlag, rightFlag] = intervalType2flag(intervalType)
                        switch intervalType
                            case 'openright', leftFlag = '['; rightFlag = '(';
                            case 'open', leftFlag = '('; rightFlag = '(';
                            case 'closed', leftFlag = '['; rightFlag = '[';
                            case 'openleft', leftFlag = '('; rightFlag = '[';
                        end
                    end
                    function additionFlag = flagPlus(flag1, flag2)
                        if all(strcmp({flag1, flag2}, '[')), additionFlag = '[';
                        else, additionFlag = '('; end
                    end
                    function intervalType = flag2intervalType(leftFlag, rightFlag)
                        flag = [leftFlag, rightFlag];
                        switch flag
                            case '[(', intervalType = 'openright';
                            case '((', intervalType = 'open';
                            case '[[', intervalType = 'closed';
                            case '([', intervalType = 'openleft';
                        end
                    end
                end
            end
        end

        function obj = minus(obj1, obj2)
            obj = plus(obj1, -obj2);
        end

        function tf = checkAllHasDuration(obj)
            tf = true;
            for indx = 1: 1: numel(obj), if isempty(obj(indx).duration), tf = false; end; end
        end

        function tf = checkAllHasScope(obj)
            tf = true;
            for indx = 1: 1: numel(obj), if isempty(obj(indx).scope), tf = false; end; end
        end

        function prod = times(obj1, obj2)
            numericFlag1 = isnumeric(obj1); numericFlag2 = isnumeric(obj2);
            if ~numericFlag1 && numericFlag2, prod = times(obj2, obj1);
            elseif numericFlag1 && numericFlag2, prod = times(obj1, obj2);
            elseif numericFlag1 && ~numericFlag2
                numelInfo1 = numel(obj1); numelInfo2 = numel(obj2);
                if numelInfo1 == numelInfo2
                    prod = obj2;
                    for indx = 1: 1: numelInfo1
                        if ~isempty(prod(indx).duration), prod(indx).duration = obj1(indx) .* prod(indx).duration; prod(indx).scope = prod(indx).duration;
                        else
                            try 
                                prod(indx).bottom = prod(indx).bottom .* obj1(indx);
                                prod(indx).top = prod(indx).top .* obj1(indx);
                                prod(indx).scope = prod(indx).scope .* obj1(indx);
                                prod(indx).unit = [prod(indx).unit sprintf('/%d',obj1(indx))];
                                try
                                    if obj1(indx) < 0
                                        switch prod(indx).intervalType
                                            case 'openright', prod(indx).intervalType = 'openleft';
                                            case 'openleft', prod(indx).intervalType = 'openright';
                                        end
                                    end
                                catch
                                end
                            catch
                                if isa(prod(indx).scope, 'duration'), tempObj = arange((prod(indx).scope).*obj1(indx), prod(indx).intervalType); prod(indx) = tempObj;
                                else, try prod = prod(indx).arange2scopemat .* obj1(indx); catch; end; end
                            end
                        end
                    end
                elseif numelInfo1 == 1, prod = times(obj1*ones(size(obj2)),obj2);
                else
                    error('Not supported. Only: arange times scalar or matrix of same size.')
                end
            else % ~numericFlag1 && ~numericFlag2
                error('Not supported: arange times arange. Only: arange times scalar or matrix of same size.')
            end
        end

        function prod = mtimes(obj1, obj2)
            try
%                 if ~isnumeric(obj1), try dr1 = obj1.ar2dr; flag = 1; catch; try dr1 = obj1.ar2mt; flag = 2; catch; end; end; else, dr1 = obj1; end
%                 if ~isnumeric(obj2), try dr2 = obj2.ar2dr; flag = 1; catch; try dr1 = obj2.ar2mt; flag = 2; catch; end; end; else, dr2 = obj2; end 
%                 % prod = dr1 * dr2
                prod = mat_times(obj1, obj2);
            catch
                try obj1 = obj1.arange2scopemat; catch; end
                try obj2 = obj2.arange2scopemat; catch; end
                try prod = mat_times(obj1, obj2);
                catch
                    error('Syntax Error. Expect Mat * ArangeWithDuration -> Arange; Or Mat * Arange2ScopeMat -> Mat. Match Size!')
                end
            end
            function prod = mat_times(obj1, obj2)
                sizeInfo1 = size(obj1); sizeInfo2 = size(obj2); 
                prod = [];
                if sizeInfo1(2) == sizeInfo2(1)
                    for indx2 = 1: 1: sizeInfo2(2)
                        thisCol = [];
                        for indx1 = 1: 1: sizeInfo1(1)
                            thisSlice1 = obj1(indx1,:); thisSlice2 = obj2(:,indx2);
                            length1 = length(thisSlice1); length2 = length(thisSlice2); 
                            if length1 == length2
                                thisCell = cell(1, length1);
                                for indx3 = 1: 1: length1
                                    thisCell{indx3} = thisSlice1(indx3) .* thisSlice2(indx3);
                                end
                                thisSum = thisCell{1};
                                for indx3 = 2: 1: length1
                                    thisSum = thisSum + thisCell{indx3};
                                end
                            end
                            thisCol = [thisCol; thisSum];
                        end
                        prod = [prod, thisCol];
                    end
                else
                    error('Match Size!');
                end
            end
        end


%         function tf = min(obj1, obj2)
%             if ~isempty(obj1.duration) && ~isempty(obj2.duration)
%                 tf = min(obj1.duration, obj2.duration);
%             end
%         end
% 
%         function tf = max(obj1, obj2)
%             if ~isempty(obj1.duration) && ~isempty(obj2.duration)
%                 tf = max(obj1.duration, obj2.duration);
%             end
%         end
% 
%         function tf = mink(obj1, obj2, k)
%             if ~isempty(obj1.duration) && ~isempty(obj2.duration)
%                 tf = mink(obj1.duration, obj2.duration, k);
%             end
%         end
    end

    methods(Hidden, Static)
        function obj = loadobj(s)
            if ~isempty(s)
                obj = arange();
                obj.bottom = s.bottom;
                obj.top = s.top;
                obj.intervalType = s.intervalType;
                obj.unit = s.unit;
                obj.duration = s.duration;
                obj.scope = s.scope;
            end
        end
    end

    methods(Access=public)
        function tf = intervalLessThan(obj1, obj2)
            if all(size(obj1) == size(obj2)), numelInfo = numel(obj1);
                tf = false(size(obj1));
                for indx = 1: 1: numelInfo
                    if isempty(obj1(indx).duration) && isempty(obj2(indx).duration)
                        if issame(obj1(indx).bottom, obj1(indx).top) && issame(obj2(indx).bottom, obj2(indx).top) && ~isempty(obj1(indx)) && ~isempty(obj2(indx)) && (strcmp(obj1(indx).unit, obj2(indx).unit) || (isempty(obj1(indx).unit) && isempty(obj2(indx).unit)))
                            tf(indx) = (obj1(indx).bottom < obj2(indx).bottom);
                        elseif ~isempty(obj1(indx)) && ~isempty(obj2(indx)) && (strcmp(obj1(indx).unit, obj2(indx).unit) || (isempty(obj1(indx).unit) && isempty(obj2(indx).unit)))
                            validIntervalTypeRelationship = {'openrightopenright', 'openleftopenleft', 'openopen'};
                            max1 = max(obj1(indx).bottom, obj1(indx).top);
                            min2 = min(obj2(indx).bottom, obj2(indx).top);
                            tf(indx) = ( max1 < min2 ) || ( (isequal(max1, min2)) && any(strcmp([obj1.intervalType, obj2.intervalType], validIntervalTypeRelationship)));
                        end
                    end
                end
            elseif numel(obj1) == 1
                tf = false(size(obj2)); for indx = 1: 1: numel(obj2), tf(indx) = intervalLessThan(obj1, obj2(indx)); end
            elseif numel(obj2) == 1
                tf = false(size(obj1)); for indx = 1: 1: numel(obj1), tf(indx) = intervalLessThan(obj1(indx), obj2); end
            else
                tf = false;
            end
        end

        function tf = intervalGreaterThan(obj1, obj2)
            tf = intervalLessThan(obj2, obj1);
        end

        function tf = unitSame(obj1, obj2)
            if all(size(obj1) == size(obj2)), numelInfo = numel(obj1);
                tf = false(size(obj1));
                for indx = 1: 1: numelInfo
                    if isempty(obj1(indx).unit) && isempty(obj2(indx).unit)
                        tf(indx) = true;
                    elseif ~isempty(obj1(indx).unit) && ~isempty(obj2(indx).unit)
                        if strcmp(obj1(indx).unit, obj2(indx).unit)
                            tf(indx) = true;
                        end
                    end
                end
            elseif numel(obj1) == 1
                tf = false(size(obj2)); for indx = 1: 1: numel(obj2), tf(indx) = unitSame(obj1, obj2(indx)); end
            elseif numel(obj2) == 1
                tf = false(size(obj1)); for indx = 1: 1: numel(obj1), tf(indx) = unitSame(obj1(indx), obj2); end
            else
                tf = false;
            end
        end

        function tf = intervalIntersects(obj1, obj2)
            tf = ~intervalGreaterThan(obj1, obj2) & ~intervalLessThan(obj1, obj2) & unitSame(obj1, obj2);
        end
    end
    
    methods(Access=private)
        function obj = inputRectify(obj)
            for indx = 1: 1: numel(obj)
                % check bottom and top
                Error1 = {'arange:ClassNotMatBottomTop', 'Classes of inputs bottom and top do not match.'};
                if ~isempty(obj(indx).top), if ~isequal(class(obj(indx).bottom), class(obj(indx).top)), error(Error1{:}); end; end
                % intervalType rectify
                switch obj(indx).intervalType, case 'closedright', obj(indx).intervalType = 'openleft'; case 'closedleft', obj(indx).intervalType = 'openright'; end
                % fix unitOfTime
                try if any(validatestring(obj(indx).unit, {'years', 'year', 'quarters', 'quarter', 'months', 'month', 'weeks', 'week', 'days', 'day', 'hours', 'hour', 'minutes', 'minute', 'seconds', 'second'}))
                    if ~strcmp(obj(indx).unit(end), 's'), obj(indx).unit = [char(string(obj(indx).unit)), 's']; end; end
                catch
                end
                % endpoints to timetype
                topTraits = endpointTraits(obj(indx).top);
                try if topTraits.isInvalid, obj(indx).top = obj(indx).bottom; obj(indx) = obj(indx).endpoints2Timetype(); end
                catch, obj(indx) = obj(indx).bottomAddToTopFromUnit; end
                % snap endpoints
                if ~isempty(obj(indx).unit), try obj(indx) = obj(indx).snapEndpointsToUnitOfTime(); catch; end; end
                % scope calculation
                try obj(indx).scope = obj(indx).arange2duration; catch; end
                % intervalType standardize
                if ~isempty(obj(indx).top), if isthesame(obj(indx).top, obj(indx).bottom), obj(indx).intervalType = 'closed'; end; end
                % if still not converted to datetime
                if isa(obj(indx).bottom, 'char') || isa(obj(indx).bottom, 'string'), try obj = obj.value2datetime; catch; end; end
            end
        end

        function [obj, optionalCell] = inputConvert(obj, input, newIntervalType)
            optionalCell = {};
            try
                if isa(input, 'duration'), if numel(input) == 1, obj.duration = input; else, obj = duration2arange(input); end
                elseif isa(input, 'timerange'), obj = timerange2arange(input);
                elseif isa(input, 'datetime'), obj = datetime2arange(input);
                elseif isa(input, 'cell')
                    sizeInfo = size(input);
                    obj = {};
                    tf = true;
                    for indx2 = 1: 1: sizeInfo(2)
                        thisCol = {};
                        for indx1 = 1: 1: sizeInfo(1)
                            thisObj = arange(input{indx1, indx2});
                            tf = tf && isarange(thisObj);
                            if isa(thisObj, 'cell')
                                thisCol = [thisCol; thisObj];
                            else
                                thisCol = [thisCol; {thisObj}];
                            end
                        end
                        obj = [obj, thisCol];
                    end
                elseif isa(input, 'arange'), obj = input;
                end
                if (nargin == 3) && ~isa(obj, 'cell'), obj = obj.intervalTypeUpdate(newIntervalType); end
                if ~isa(obj, 'cell'), obj = obj.inputRectify; end
                if isa(obj, 'cell'), optionalCell = obj; obj = arange.empty; 
                    if tf
                        obj = [];
                        sizeInfo = size(optionalCell);
                        for indx2 = 1: 1: sizeInfo(2)
                            thisCol = [];
                            for indx1 = 1: 1: sizeInfo(1)
                                thisCol = [thisCol; optionalCell{indx1, indx2}];
                            end
                            obj = [obj, thisCol];
                        end
                    else
                        warning('Use [~, Cell] to get the output cell.'); 
                    end
                end
            catch
                obj = arange.empty;
                warning('Output empty arange. Check inputs.')
            end
        end

        function obj = endpoints2Timetype(obj)
            bottomTraits = endpointTraits(obj.bottom);
            topTraits  = endpointTraits(obj.top);
            if bottomTraits.isText
                obj.bottom = text2Timetype_helper(obj.bottom, obj.top, obj.unit);
                obj.bottom = handleTimeZone(obj.bottom, obj.top, topTraits);
            end
            if topTraits.isText
                obj.top = text2Timetype_helper(obj.top, obj.bottom, obj.unit);
                obj.top = handleTimeZone(obj.top, obj.bottom, bottomTraits);
            end
        end

        function obj = snapEndpointsToUnitOfTime(obj)
            try % DATESHIFT only works if both FIRST and LAST are datetime.
                obj.bottom = dateshift(obj.bottom, 'start', obj.unit);
                if obj.top ~= dateshift(obj.top, 'end', obj.unit, 'previous') || obj.top == obj.bottom
                    obj.top  = dateshift(obj.top, 'start', obj.unit, 'next');
                end
            catch ME
                if isa(obj.top,'duration') || isa(obj.bottom,'duration') % Duration endpoint(s) not compatible with UNITOFTIME semantics
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    rethrow(ME)
                end
            end
        end
                
        function obj = snapTopBackToUnitOfTime(obj)
            try % DATESHIFT only works if both FIRST and LAST are datetime.
                obj.bottom = dateshift(obj.bottom, 'start', obj.unit);
                obj.top  = dateshift(obj.top,  'start', obj.unit, 'previous');
            catch ME
                if isa(obj.top,'duration') || isa(obj.bottom,'duration') % Duration endpoint(s) not compatible with UNITOFTIME semantics
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    rethrow(ME)
                end
            end
        end

        function obj = bottomAddToTopFromUnit(obj, addNum)
            if nargin == 1, addNum = 1; end
            bottomTraits = endpointTraits(obj.bottom);
            topTraits = endpointTraits(obj.top);
            if topTraits.isInvalid, try if ~bottomTraits.isDatetime || ~bottomTraits.isDuration, obj.top = obj.bottom + addNum; end; catch; end; end
        end

        function obj = intervalTypeUpdate(obj, newIntervalType)
            numelInfo = numel(obj);
            if numelInfo > 1, for indx = 1: 1: numelInfo, obj(indx) = intervalTypeUpdate(obj(indx), newIntervalType); end
            else, obj.intervalType = newIntervalType; end
        end
    end
    

    methods(Access=public)
        function tf = isarange(obj)
            tf = isa(obj, 'arange');
        end

        function tf = issame(obj1, obj2)
            tf = isequal(obj1, obj2);
            if ~tf, try if isempty(obj1) && isempty(obj2), tf = true; end; catch; end; end
            % if ~tf, try tf = isthesame(obj1, obj2, true); catch; end; end % array-like -> 1x1 struct -> NaN ignored
        end

        function tf = ni(obj, themat)
            numelInfo1 = numel(obj);
            numelInfo2 = numel(themat);
            if numelInfo1 > 1 && numelInfo2 == 1
                tf = false(size(obj));
                for indx = 1: 1: numelInfo1
                    tf(indx) = ni(obj(indx), themat);
                end
            elseif numelInfo1 > 1 && numelInfo2 == numelInfo1
                tf = false(size(themat));
                for indx = 1: 1: numelInfo1
                    tf(indx) = ni(obj(indx), themat(indx));
                end
            elseif numelInfo1 == 1 && numelInfo2 > 1
                tf = false(size(themat));
                for indx = 1: 1: numelInfo2
                    tf(indx) = ni(obj, themat(indx));
                end
            elseif numelInfo1 == 1 && numelInfo2 == 1
                if obj.bottom <= obj.top
                    switch obj.intervalType
                        case 'openright', tf = obj.bottom <= themat & themat < obj.top;
                        case 'open', tf = obj.bottom < themat & themat < obj.top;
                        case 'closed', tf = obj.bottom <= themat & themat <= obj.top;
                        case 'openleft', tf = obj.bottom_limit < themat & themat <= obj.top_limit;
                    end
                else
                    tempObj = abs(obj);
                    tf = ni(tempObj, themat);
                end
            else
                error('Input size does not match.')
            end
        end

        function tf = isinarange(obj, themat)
            % the same as the method ni
            tf = obj.ni(themat);
        end
        
        function obj = value2datetime(obj, varargin)
            numelInfo = numel(obj);
            if numelInfo == 1
                try
                    obj.bottom = datetime(obj.bottom, varargin{:});
                    if ~isempty(obj.top)
                        obj.top = datetime(obj.top, varargin{:});
                    end
                    obj = obj.inputRectify;
                catch
                    error('Value convert to datetime failed.')
                end
            elseif numelInfo > 1
                for indx = 1: 1: numelInfo, obj(indx) = value2dtatime(obj(indx)); end
            end
        end

        function obj = value4datestr(obj, varargin)
            numelInfo = numel(obj);
            if numelInfo == 1
                try
                    obj.bottom = datestr(obj.bottom, varargin{:});
                    if ~isempty(obj.top)
                        obj.top = datestr(obj.top, varargin{:});
                    end
                catch
                    error('Value convert to string failed.')
                end
            elseif numelInfo > 1
                for indx = 1: 1: numelInfo, obj(indx) = value2dtatime(obj(indx)); end
            end
        end

        function obj = value2str(obj, varargin)
            numelInfo = numel(obj);
            if numelInfo == 1
                try
                    switch class(obj.bottom)
                        case 'datetime'
                            obj = obj.value4datestr(varargin{:});
                        otherwise
                            obj.bottom = string(obj.bottom, varargin{:});
                            if ~isempty(obj.top)
                                obj.top = string(obj.top, varargin{:});
                            end
                    end
                catch
                    error('Value convert to string failed.')
                end
            elseif numelInfo > 1
                for indx = 1: 1: numelInfo, obj(indx) = value2dtatime(obj(indx)); end
            end
        end

        function obj = value2duration(obj)
            numelInfo = numel(obj);
            if numelInfo == 1
                try
                    if ~isempty(obj.bottom) && ~isempty(obj.top)
                        switch obj.unit
                            case {'seconds', 'second'}, obj.bottom = seconds(obj.bottom); obj.top = seconds(obj.top);
                            case {'minutes', 'minute'}, obj.bottom = minutes(obj.bottom); obj.top = minutes(obj.top);
                            case {'hours', 'hour'}, obj.bottom = hours(obj.bottom); obj.top = hours(obj.top);
                            case {'days', 'day'}, obj.bottom = days(obj.bottom); obj.top = days(obj.top);
                        end
                    end
                catch
                    error('Value convert to duration failed.')
                end
            elseif numelInfo > 1
                for indx = 1: 1: numelInfo, obj(indx) = value2dtatime(obj(indx)); end
            end
        end

        function tr = arange2timerange(obj)
            if numel(obj) == 1, tr = [];
                try
                    if isempty(obj.unit)
                        tr = timerange(obj.bottom, obj.top, obj.intervalType);
                    elseif ~isempty(obj.bottom) && ~isempty(obj.top) && any(validatestring(obj.unit, {'years', 'year', 'quarters', 'quarter', 'months', 'month', 'weeks', 'week', 'days', 'day', 'hours', 'hour', 'minutes', 'minute', 'seconds', 'second'}))
                            if isa(obj.bottom, 'datetime')
                                tempObj = obj.snapTopBackToUnitOfTime(); 
                                tr = timerange(tempObj.bottom, tempObj.top, tempObj.unit); 
                                if any(strcmp(tempObj.intervalType,{'closed','open','openleft'})), warning('IntervalType change to openright.'); end
                            end
                            if isempty(tr)
                                try
                                    tempObj = obj.value2duration;
                                    if ~isa(tempObj.bottom, 'duration'), error('Try value converting to duration failed.');
                                    else, tr = timerange(tempObj.bottom, tempObj.top, tempObj.intervalType); end
                                catch ME
                                    error(ME.message);
                                end
                            end
                    elseif ~isempty(obj.bottom) && ~isempty(obj.top) && isa(obj.bottom, 'duation')
                        tr = timerange(obj.bottom, obj.top, obj.intervalType);
                    end
                catch
                    if isempty(tr), error('Convert to timerange failed.'); end
                end
            else
                tr = cell(size(obj));
                for indx = 1: 1: numel(obj)
                    tr{indx} = arange2timerange(obj(indx));
                end
            end
        end

        function tr = ar2tr(obj)
            tr = arange2timerange(obj);
        end

        function mt = arange2scopemat(obj)
            mt = zeros(size(obj));
            for indx = 1: 1: numel(obj)
                thisScope = obj(indx).scope;
                if ~isempty(thisScope) && ~isa(thisScope,'duration'), mt(indx) = obj(indx).scope;
                else, mt(indx) = NaN; end
            end
        end

%         function mt = ar2mt(obj)
%             mt = arange2scopemat(obj);
%         end
        
        function dt = arange2datetime(obj, varargin)
            if numel(obj) == 1
                try
                    switch class(obj.bottom)
                        case 'datetime'
                            if ~isempty(obj.top)
                                dt = [obj.bottom; obj.top];
                            else
                                dt = obj.bottm;
                            end
                        case {'string', 'char'}
                            obj = obj.value2datetime(varargin{:});
                            dt = obj.arange2datetime;
                        otherwise
                            error('Convert to datetime stopped. arange/arange2datetime/switch_class(obj.bottom) Calls.');
                    end
                catch
                    error('Convert to datetime failed. arange/arange2datetime Calls.');
                end
            else
                dt = [];
                for indx2 = 1: 1: size(obj, 2)
                    thisCol = [];
                    for indx1 = 1: 1: size(obj, 1)
                        thisDt = arange2datetime(obj(indx1, indx2), varargin{:});
                        thisCol = [thisCol; thisDt];
                    end
                    dt = [dt, thisCol];
                end
            end
        end
        
        function dt = ar2dt(obj, varargin)
            dt = arange2datetime(obj, varargin{:});
        end

        function dr = arange2duration(obj)
            if numel(obj) == 1
                if ~isempty(obj.duration)
                    dr = obj.duration;
                else
                    try
                        dr = obj.top - obj.bottom;
                        if ~isduration(dr) && any(strcmp(obj.unit,{'seconds','second','minute','minutes','hours','hour','days','day','weeks','week','years','year'}))
                            switch obj.unit
                                case {'seconds', 'second'}, dr = seconds(dr);
                                case {'minutes', 'minute'}, dr = minutes(dr);
                                case {'hours', 'hour'}, dr = hours(dr);
                                case {'days', 'day'}, dr = days(dr);
                                case {'weeks', 'week'}, dr = days(7*dr);
                                case {'years', 'year'}, dr = days(dr);
                            end
                        end
                    catch
                        error('Convert to duration failed. Check units in seconds/minutes/hours/days.')
                    end
                end
            else
                dr = [];
                for indx2 = 1: 1: size(obj, 2)
                    thisCol = [];
                    for indx1 = 1: 1: size(obj, 1)
                        thisDr = arange2duration(obj(indx1, indx2));
                        thisCol = [thisCol; thisDr];
                    end
                    dr = [dr, thisCol];
                end
            end
        end

        function dr = ar2dr(obj)
            dr = arange2duration(obj);
        end

        function cl = arange2cell(obj)
            sizeInfo = size(obj);
            cl = {};
            for indx2 = 1: 1: sizeInfo(2)
                columncl = {};
                for indx1 = 1: 1: sizeInfo(1)
                    columncl = [columncl, {obj(indx1, indx2)}];
                end
                cl = [cl; columncl];
            end
        end

        % function

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% helpers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = text2Timetype_helper(val, template, unitOfTime)
% TEXT2TIMETYPE_HELPER parse the text in VAL to a timetype
% (datetime/duration) by using TEMPLATE as the reference type 
import matlab.internal.datetime.text2timetype
import matlab.internal.datatypes.isScalarText

try
    if isa(template,'datetime') || isa(template,'duration')
        % Parse VAL into a timetype using TEMPLATE as reference type
        val = text2timetype(val,'MATLAB:datetime:InvalidTextInput',template);
    else
        timerFmtPattern = '^\d+:\d+:\d+:\d+$|^\d+:\d+:\d+$';
        if isScalarText(val) && ((strlength(val) == 0) || isscalar(regexp(val,timerFmtPattern)))
            if isempty(unitOfTime)
                val = duration(val);
            else % Unit-of-Time semantic: parse text to datetime
                val = datetime(val);
            end
        elseif isScalarText(template) && ((strlength(template) == 0) || isscalar(regexp(template,timerFmtPattern)))
            if isempty(unitOfTime)
                val = text2timetype(val,'MATLAB:datetime:InvalidTextInput',duration);
            else % Unit-of-Time semantic: parse text to datetime
                val = datetime(val);
            end
        else
            val = text2timetype(val,'MATLAB:datetime:InvalidTextInput');
        end
    end
catch ME
    if isempty(unitOfTime) % Not a construction with the UNITOFTIME syntax
        rethrow(ME);  % preserve stack
    else % Unit-of-Time semantic: try additional format
        timeUnitFmts.years    = "uuuu"; % Year
        timeUnitFmts.quarters = ["QQQ-uuuu","uuuu-QQQ","QQQ/uuuu","uuuu/QQQ","QQQ.uuuu","uuuu.QQQ","uuuuQQQ"];
        timeUnitFmts.months   = ["MMM-uuuu","uuuu-MMM","MMM/uuuu","uuuu/MMM","MMM.uuuu","uuuu.MMM"];
        timeUnitFmts.weeks    = []; % No anchored format to try
        timeUnitFmts.days     = ["MMM-dd-uuuu","uuuu-dd-MMM","uuuu-MMM-dd","dd/MMM/uuuu","uuuu/dd/MMM","uuuu/MMM/dd","dd.MMM.uuuu","MMM.dd.uuuu","uuuu.dd.MMM","uuuu.MMM.dd"];
        timeUnitFmts.hours    = timeUnitFmts.days(:) + " " + ["HH:mm" "hh:mm aa"];
        timeUnitFmts.minutes  = timeUnitFmts.hours;
        timeUnitFmts.seconds  = timeUnitFmts.days(:) + " " + ["HH:mm:ss" "hh:mm:ss aa"];
        
        % UNITOFTIME was passed in from the object (a non-empty value _must_ be one of the valid values)
        % Get the list of formats to try, for this particular UNITOFTIME, on parsing the text into datetime.
        % Note there is no need to try parsing the text into duration -- the UNITOFTIME syntax only support 
        % datetime/datetime-text endpoints.
        fmts = timeUnitFmts.(unitOfTime);
        numFmts = numel(fmts);
        trialCount = 0;
        while ~isa(val,'datetime')
            trialCount = trialCount + 1;
            try
                val = datetime(val,'InputFormat',fmts(trialCount));
            catch
                if (trialCount < numFmts)
                    continue; % try the next format
                else % no more to try
                    rethrow(ME);
                end
            end
        end
    end
end
end

function [this, matchTimeZoneOnSubscript] = handleTimeZone(this, other, otherTraits)
% If the other edge is a datetime, match its TimeZone;
% If both are text, match TimeZone of the subscripting context
matchTimeZoneOnSubscript = false;
if isa(this,'datetime')
    if otherTraits.isDatetime
        this.TimeZone = other.TimeZone;
    elseif otherTraits.isText
        matchTimeZoneOnSubscript = true;
    end
end
end

function traits = endpointTraits(in)
    traits.isText     = matlab.internal.datatypes.isScalarText(in);
    traits.isScalar   = traits.isText || isscalar(in);
    traits.isDatetime = ~traits.isText && isa(in,'datetime'); % isText<=>not-a-datetime: avoid isa() - it's slow to return FALSE.
    traits.isDuration = ~traits.isText && ~traits.isDatetime && isa(in,'duration'); % similarly, avoid isa() if established FALSE otherwise.
    traits.isNonFiniteNum = (traits.isScalar && isnumeric(in) && ~isfinite(in))...
        || traits.isText && matches(in,["inf","+inf","-inf"],"IgnoreCase",true); % +/- Inf or NaN
    % traits.isInvalid = ~(traits.isText || traits.isDatetime || traits.isDuration || traits.isScalar);
    traits.isInvalid = isempty(in);
end

function [value, intervalType, flag] = compareRectify(obj)
    if isnumeric(obj), value = obj; intervalType = 'openright'; flag = {'duration', 'scope'};
    else
        try
            if ~isempty(obj.duration)
                value = obj.duration; intervalType = obj.intervalType; flag = 'duration';
            elseif ~isempty(obj.scope)
                value = obj.scope; intervalType = obj.intervalType; flag = 'scope';
            end
            if value < 0
                value = - value;
                switch intervalType
                    case 'openright', intervalType = 'openleft';
                    case 'openleft', intervalType = 'openright';
                end
            end
        catch
            error('Compare Rectify Error. Input class may be wrong. May lack of scope or duration.')
        end
    end
end

function tf = compareLength1DLessThan(obj1, obj2, validIntervalTypeRelationship)
    [value1, intervalType1, flag1] = compareRectify(obj1);
    [value2, intervalType2, flag2] = compareRectify(obj2);
    if any(strcmp(flag1, flag2))
        try tf = (value1 < value2) || ((value1 == value2) && validIntervalTypeRelationshipCheck(intervalType1,intervalType2,validIntervalTypeRelationship));
        catch; end
    else, error('Compare Length Error.')
    end
end

function tf = compareLength1DLessEqual(obj1, obj2, validIntervalTypeRelationship)
    [value1, intervalType1, flag1] = compareRectify(obj1);
    [value2, intervalType2, flag2] = compareRectify(obj2);
    if any(strcmp(flag1, flag2))
        try tf = (value1 <= value2) || ((value1 == value2) && validIntervalTypeRelationshipCheck(intervalType1,intervalType2,validIntervalTypeRelationship));
        catch; end
    else, error('Compare Length Error.')
    end
end

function tf0 = validIntervalTypeRelationshipCheck(intervalType1, intervalType2, validIntervalTypeRelationship)
    tf0 = any(strcmp([intervalType1, intervalType2],validIntervalTypeRelationship));
end