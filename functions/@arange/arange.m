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
    %       <a href = "matlab:help arange/eq">eq</a>               aka <a href = "matlab:help arange/eq">==</a>     - <a href = "matlab:help arange/thesame">thesame</a> or optional, <a href = "matlab:help arange/intervalMayIntersect">intervalMayIntersect</a>
    %       <a href = "matlab:help arange/ne">ne</a>               aka <a href = "matlab:help arange/ne">~=</a>     - not <a href = "matlab:help arange/thesame">thesame</a> or optional, not <a href = "matlab:help arange/intervalMayIntersect">intervalMayIntersect</a>
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
    

    properties(Hidden, Access='public')
        itt = IntervalType('ambiguous');
        utn = 1;
    end

    properties(Transient, Access='public')
        bottom = [];
        top = [];
        unit = [];
        duration = [];
        scope = [];
        nar = false;
    end

    properties(Transient, Dependent, Access='public')
        intervalType
    end

    methods
        function [obj, cl] = arange(bottom_or_others, top_or_intervalType_or_unit, intervalType_or_unit, unit, ~)
            obj.itt = IntervalType('{}'); cl = {}; if (nargin == 0); obj.nar = true; return; end
            try
                narginchk(1, 4);
                % bottom, top, intervalType, unit
                if (nargin == 4), obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.itt = IntervalType(intervalType_or_unit); obj.unit = unit;
                    obj = obj.inputRectify;
                elseif (nargin == 3) 
                    % bottom, top, intervalType
                    % bottom, intervalType, unit
                    % bottom, top, unit
                    temp2 = IntervalType(top_or_intervalType_or_unit); temp3 = IntervalType(intervalType_or_unit);
                    if ~isempty(temp3)
                        obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.itt = temp3;
                    elseif ~isempty(temp2)
                            obj.bottom = bottom_or_others; obj.itt = temp2; obj.unit = intervalType_or_unit;
                    else, obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; obj.unit = intervalType_or_unit; 
                    end
                    obj = obj.inputRectify;
                elseif (nargin == 2)
                    % duration or other class, intervalType
                    % bottom, unit
                    % bottom, top
                    temp2 = IntervalType(top_or_intervalType_or_unit);
                    if ~isempty(temp2), obj = obj.inputConvert(bottom_or_others, temp2);
                    else
                       tf1 = ~strcmp(class(bottom_or_others),class(top_or_intervalType_or_unit)); tf2 = false; %try tf2 = ~tf1 && (length(bottom_or_others) ~= length(top_or_intervalType_or_unit)); catch; end
                       if tf1 || tf2, obj.bottom = bottom_or_others; obj.unit = top_or_intervalType_or_unit; 
                       else, obj.bottom = bottom_or_others; obj.top = top_or_intervalType_or_unit; end
                    end
                    obj = obj.inputRectify;
                elseif (nargin == 1), [obj, cl] = obj.inputConvert(bottom_or_others); % duration or other class
                end
            catch ME
                error(ME.message);
            end
        end

        function obj = set.intervalType(obj, ITT)
            num = numel(obj);
            if nargin == 1, ITT = obj.itt; else, for idx = 1: num, obj(idx).itt = ITT; end; end
            if num == 1, obj.intervalType = ITT.name; else, for idx = 1: num, obj(idx).intervalType = ITT.name; end; end
        end

        function it = get.intervalType(obj)
            num = numel(obj); if num == 1, it = obj.itt.name; end
        end

        function obj = intervalTypeUpdate(obj, NewIT)
            if ~isa(NewIT, 'IntervalType'), NewIT = IntervalType(NewIT); end
            for idx = 1: numel(obj), obj(idx).itt = NewIT; end
        end
    end

    methods(Hidden)
        function disp(obj)
            import matlab.internal.display.lineSpacingCharacter
            tab = sprintf('  ');
            sz = size(obj); tp = strcat(int2str(sz'),[arrayfun(@(x)"x",1:length(sz)-1)';""]); sz2cr = strcat(tp{:}); sizeChar = [sz2cr ' <a href = "matlab:help arange">arange</a> array'];
            switch numel(obj)
                case 1
                    strLeft = obj.itt.lbt.li; strRight = obj.itt.rbt.ri;
                    datetimeformat = settings().matlab.datetime.DefaultFormat.ActiveValue;
                    if ~isempty(obj.bottom)
                        if isa(obj.bottom,'datetime'), dispMsg = [strLeft dt2charHelper(obj.bottom, datetimeformat) ', ' dt2charHelper(obj.top, datetimeformat) strRight];
                        else, dispMsg = [strLeft dt2charHelper(obj.bottom) ', ' dt2charHelper(obj.top) strRight]; end
                    else, dispMsg = [obj.intervalType ' intervalType']; 
                    end
                    
                    if ~isempty(obj.duration), dispMsg = [dispMsg ', duration ' dt2charHelper(obj.duration)]; end
                    if ~isempty(obj.scope), dispMsg = [dt2charHelper(obj.scope) '-scope ' dispMsg]; end
                    dispMsg = [dispMsg ' (unit ' dt2charHelper(obj.unit) sprintf('.*%d',obj.utn) ')'];
                    % display
                    if ~isempty(obj)
                        if obj.nar, disp([tab tab '<a href = "matlab:help arange/arange">arange</a> NaR']);
                        else, disp([tab tab 'range of ' dispMsg]); 
                        end
                    else, disp([tab tab 'an <a href = "matlab:help arange/isempty">empty</a> range ' dispMsg]); 
                    end
                case 0, disp([tab sizeChar lineSpacingCharacter]);
                otherwise, disp([tab sizeChar lineSpacingCharacter]);
                    if length(sz) <= 2 && numel(obj), for indx2 = 1: sz(2), disp([tab 'column' int2str(indx2)]); for indx1 = 1: sz(1), disp(obj(indx1, indx2)); end; end; end
            end
            function output = dt2charHelper(input, datetimeformat)
                output = [];
                try if isempty(input), output = ''; end; catch; end
                try if isnan(input), output = '< missing >'; end; catch; end
                if isempty(output), try if isnat(input), output = 'NaT'; end; catch; end; end
                if nargin == 2, if isempty(output), try output = [char(input, datetimeformat) ' ' input.TimeZone]; catch, output = char(input, datetimeformat); end; end; end
                if isempty(output), try output = char(string(input)); catch; end; end
                if isempty(output), output = ''; end
            end
        end

%         function s = saveobj(obj)
%             s(size(obj)) = struct; 
%             for idx = 1: numel(obj)
%                 s(idx).bottom = obj(idx).bottom;
%                 s(idx).top  = obj(idx).top;
%                 s(idx).intervalType = obj(idx).intervalType;
%                 s(idx).unit = obj(idx).unit;
%                 s(idx).duration = obj(idx).duration;
%                 s(idx).scope = obj(idx).scope;
%             end
%         end

        function tf = isnar(obj)
            tf = false(size(obj)); for idx = 1: numel(obj), tf(idx) = isnar1D(obj(idx)); end
            function tf = isnar1D(obj)
                tf = any(emptyNaRArangeList == obj);
                if ~tf, try if isequal(obj.bottom, obj.top) && ~strcmp(obj.itt.iti, '[]'), tf = true; end; catch; end; end
                if ~tf, try if isnan(obj.bottom) || isnan(obj.top), tf = true; end; catch; end; end
                if ~tf, try if isnat(obj.bottom) || isnat(obj.top), tf = true; end; catch; end; end
            end
        end

%         function tf = lt(obj1, obj2, intervalFlag)
%             if nargin == 2, intervalFlag = false; end
%             tf = operateSizeHelper(obj1, obj2, @(x,y)lt1D(x,y,intervalFlag), @false);
%             function tf = lt1D(obj1, obj2, intervalFlag)
%                 if ~intervalFlag, tf = unitSame(obj1, obj2) && compareLength1DLessThan(obj1, obj2, {'()(]', '()[)', '()[]', '[)[]', '(][]', '(}', ''});
%                 else, tf = intervalLessThan(obj1, obj2); end
%             end
%         end
% 
%         function tf = le(obj1, obj2, intervalFlag)
%             if nargin == 2, intervalFlag = false; end
%             tf = operateSizeHelper(obj1, obj2, @(x,y)le1D(x,y,intervalFlag), @false);
%             function tf = le1D(obj1, obj2, intervalFlag)
%                 if ~intervalFlag, tf = unitSame(obj1, obj2) && compareLength1DLessThan(obj1, obj2, {'()()', '()(]', '()[)', '()[]', '[)[)', '[)[]', '(](]', '(][]', '[][]'});
%                 else, tf = intervalLessThan(obj1, obj2) || intervalMayIntersect(obj1, obj2); end
%             end
%         end
% 
%         function tf = gt(obj1, obj2, intervalFlag)
%             if nargin == 2, intervalFlag = false; end
%             tf = lt(obj2, obj1, intervalFlag);
%         end
% 
%         function tf = ge(obj1, obj2, intervalFlag)
%             if nargin == 2, intervalFlag = false; end
%             tf = le(obj2, obj1, intervalFlag);
%         end
        
        function tf = eq(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            tf = operateSizeHelper(obj1, obj2, @(x,y)eq1D(x,y,intervalFlag), @false);
            function tf = eq1D(obj1, obj2, intervalFlag), if ~intervalFlag, tf = isequal(obj1, obj2); else, tf = intervalMayIntersect(obj1, obj2); end; end
        end

        function tf = ne(obj1, obj2, intervalFlag)
            if nargin == 2, intervalFlag = false; end
            tf = ~eq(obj1, obj2, intervalFlag);
        end

        function pd = abs(obj)
            pd(size(obj)) = arange; for idx = 1: numel(obj), pd(idx) = abs1D(obj(idx)); end
            function pd = abs1D(obj)
                pd = obj;
                if ~isempty(pd.duration), flag = 1; elseif ~isempty(pd.scope), flag = 2; else; flag = 0; end
                switch flag
                    case 1, if pd.duration < 0, pd.duration = - pd.duration; pd.intervalType = intervalTypeFlip(pd.intervalType); end
                            if ~isempty(pd.scope), pd.scope = - pd.scope; end
                    case 2, if pd.scope < 0, pd.bottom = obj.top; pd.top = obj.bottom; pd.scope = - pd.scope; pd.intervalType = intervalTypeFlip(pd.intervalType); end
                end
            end
        end

        function pd = uminus(obj)
            pd(size(obj)) = arange; for idx = 1: numel(obj), pd(idx) = uminus1D(obj(idx)); end
            function pd = uminus1D(obj)
                pd = obj;
                if ~isempty(pd.duration), flag = 1; elseif ~isempty(pd.scope), flag = 2; else; flag = 0; end
                switch flag
                    case 1, pd.duration = - pd.duration; pd.intervalType = intervalTypeFlip(pd.intervalType);
                            if ~isempty(pd.scope), pd.scope = - pd.scope; end
                    case 2, pd.bottom = obj.top; pd.top = obj.bottom; pd.scope = - pd.scope; pd.intervalType = intervalTypeFlip(pd.intervalType);
                end
            end
        end

        function obj = plus(obj1, obj2)
            obj = operateSizeHelper(obj1, obj2, @plus1D, @sz2ar);
            function obj = plus1D(obj1, obj2)
                if obj1.nar || obj2.nar, obj = NaR; 
                else
                    numericFlag1 = isnumeric(obj1); numericFlag2 = isnumeric(obj2);
                    if ~numericFlag1 && numericFlag2, obj = plus1D(obj1, arange(obj2, obj2));
                    elseif numericFlag1 && numericFlag2, sum = obj1 + obj2; obj = arange(sum, sum);
                    elseif numericFlag1 && ~numericFlag2, obj = plus1D(arange(obj1,obj1),obj2);
                    else % ~numericFlag1 && ~numericFlag2
                        if ~isa(obj1, 'arange') || ~isa(obj2, 'arange'), try obj = plus(arange(obj1), arange(obj2)); catch; end
                        else
                            duration1 = obj1.duration; duration2 = obj1.duration;
                            if ~isempty(duration1) && ~isempty(duration2), obj = arange(duration1+duration2);
                            else, unit1 = obj1.unit; unit2 = obj2.unit; if ~isempty(unit1) && ~isempty(unit2), if ~strcmp(unit1,unit2), error('Unit does not match.'); end; end
                                positiveFlag1 = obj1 == abs(obj1);
                                positiveFlag2 = obj2 == abs(obj2);
                                additionIntervalType = validIntervalTypePlus(obj1.itt, obj2.itt);
                                if ~positiveFlag1 && positiveFlag2
                                    obj = plus(obj2, obj1);
                                elseif ~positiveFlag1 && ~positiveFlag2
                                    obj = -plus(-obj1, -obj2);
                                elseif positiveFlag1 && positiveFlag2
                                    if ~isempty(obj1.unit), obj = arange(obj1.bottom + obj2.bottom, obj1.top + obj2.top, additionIntervalType, obj1.unit);
                                    else, obj = arange(obj1.bottom + obj2.bottom, obj1.top + obj2.top, additionIntervalType); end
                                elseif positiveFlag1 && ~positiveFlag2
                                    if ~isempty(obj1.unit), obj = arange(obj1.bottom - obj2.bottom, obj1.top + obj2.top, additionIntervalType, obj1.unit);
                                    else, obj = arange(obj1.bottom + obj2.bottom, obj1.top - obj2.top, additionIntervalType); end
                                end
                            end
                        end
                    end
                end
                function itt = validIntervalTypePlus(itt1, itt2)
                    LeftBoundaryPlus = itt1.lbt + itt2.lbt; RightBoundaryPlus = itt1.rbt + itt2.rbt; itt = BoundaryTypes2IntervalType(LeftBoundaryPlus, RightBoundaryPlus);
                end
            end
        end

        function obj = minus(obj1, obj2)
            obj = plus(obj1, -obj2);
        end

        function tf = checkAllHasDuration(obj)
            tf = true; for indx = 1: 1: numel(obj), if isempty(obj(indx).duration), tf = false; end; end
        end

        function tf = checkAllHasScope(obj)
            tf = true; for indx = 1: 1: numel(obj), if isempty(obj(indx).scope), tf = false; end; end
        end

%         function [pd, flag, flagDscb] = times(obj1, obj2)
%             pd = [];
%             numericFlag1 = isnumeric(obj1); numericFlag2 = isnumeric(obj2);
%             if ~numericFlag1 && numericFlag2, [pd, flag, flagDscb] = times(obj2, obj1);
%             elseif numericFlag1 && numericFlag2, [pd, flag, flagDscb] = times(obj1, obj2);
%             elseif numericFlag1 && ~numericFlag2
%                 try pd = operateSizeHelper(obj1, obj2, @scalarDotTimes1D, @sz2ar); flag = 1;
%                 catch, try pd = obj1 .* obj2.arange2scopemat; flag = 2; catch; end
%                 end
%             else % ~numericFlag1 && ~numericFlag2
%                 if ~isa(obj1, 'arange') || ~isa(obj2, 'arange'), try [pd, flag, flagDscb] = times(arange(obj1), arange(obj2)); catch; end
%                 else % isarange && isarange
%                     if numel(obj1) == 1 && numel(obj2) == 1 && ( (~isempty(obj1.duration) && ~isempty(obj2.duration)) || unitSame(obj1, obj2)), pd = [obj1; obj2]; flag = 3;
%                     else, try pd = obj1.arange2scopemat .* obj2.arange2scopemat; flag = 4; catch; end
%                     end
%                 end
%             end
%             if isempty(pd), error('Not supported Inputs.'); end
%             switch flag
%                 case 1, flagDscb = 'numerical dot times arange.';
%                 case 2, flagDscb = 'numerical dot times arange scope.';
%                 case 3, flagDscb = 'arange dot times arange.';
%                 case 4, flagDscb = 'arange scope dot times arange scope.';
%             end
%             function pd = scalarDotTimes1D(obj1, obj2)
%                 pd = [];
%                 if ~isempty(pd.duration), pd = obj2; pd.duration = obj1 .* pd.duration; pd.scope = pd.duration;
%                 else
%                     try pd = obj2;
%                         pd.bottom = pd.bottom .* obj1;
%                         pd.top = pd.top .* obj1;
%                         pd.scope = pd.scope .* obj1;
%                         fd = strfind(pd.unit, '.*');
%                         if fd, pd.unit = pd.unit(1:fd-1); temp = eval(pd.unit(fd+1:end)) / obj1; 
%                         else, temp = 1 / obj1; end
%                         pd.unit = [pd.unit sprintf('.*%d', temp)];
%                         try if obj1 < 0, pd.intervalType = intervalTypeFlip(pd.intervalType); end; catch; end
%                     catch
%                         if isa(obj2.scope, 'duration'), pd = arange((obj2.scope).*obj1, obj2.intervalType); end
%                     end
%                 end
%             end
%         end
% 
%         function prod = mtimes(obj1, obj2)
%             try
% %                 if ~isnumeric(obj1), try dr1 = obj1.ar2dr; flag = 1; catch; try dr1 = obj1.ar2mt; flag = 2; catch; end; end; else, dr1 = obj1; end
% %                 if ~isnumeric(obj2), try dr2 = obj2.ar2dr; flag = 1; catch; try dr1 = obj2.ar2mt; flag = 2; catch; end; end; else, dr2 = obj2; end 
% %                 % prod = dr1 * dr2
%                 prod = mat_times(obj1, obj2);
%             catch
%                 try obj1 = obj1.arange2scopemat; catch; end
%                 try obj2 = obj2.arange2scopemat; catch; end
%                 try prod = mat_times(obj1, obj2);
%                 catch
%                     error('Syntax Error. Expect Mat * ArangeWithDuration -> Arange; Or Mat * Arange2ScopeMat -> Mat. Match Size!')
%                 end
%             end
%             function prod = mat_times(obj1, obj2)
%                 sizeInfo1 = size(obj1); sizeInfo2 = size(obj2); 
%                 prod = [];
%                 if sizeInfo1(2) == sizeInfo2(1)
%                     for indx2 = 1: 1: sizeInfo2(2)
%                         thisCol = [];
%                         for indx1 = 1: 1: sizeInfo1(1)
%                             thisSlice1 = obj1(indx1,:); thisSlice2 = obj2(:,indx2);
%                             length1 = length(thisSlice1); length2 = length(thisSlice2); 
%                             if length1 == length2
%                                 thisCell = cell(1, length1);
%                                 for indx3 = 1: 1: length1
%                                     thisCell{indx3} = thisSlice1(indx3) .* thisSlice2(indx3);
%                                 end
%                                 thisSum = thisCell{1};
%                                 for indx3 = 2: 1: length1
%                                     thisSum = thisSum + thisCell{indx3};
%                                 end
%                             end
%                             thisCol = [thisCol; thisSum];
%                         end
%                         prod = [prod, thisCol];
%                     end
%                 else
%                     error('Match Size!');
%                 end
%             end
%         end
% 
% 
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

%     methods(Hidden, Static)
%         function obj = loadobj(s)
%             if ~isempty(s)
%                 obj = arange();
%                 obj.bottom = s.bottom;
%                 obj.top = s.top;
%                 obj.intervalType = s.intervalType;
%                 obj.unit = s.unit;
%                 obj.duration = s.duration;
%                 obj.scope = s.scope;
%             end
%         end
%     end

    methods(Access=public)
        function tf = intervalLessThan(obj1, obj2)
            tf = operateSizeHelper(obj1, obj2, @intervalLessThan1D, @false);
        end

        function tf = intervalLessThan1D(obj1, obj2)
            if obj1.nar || obj2.nar, tf = false;
            elseif ~isempty(obj1.duration) && ~isempty(obj2.duration), tf = false;
            elseif ~unitSame(obj1,obj2), tf = false;
            else
                if isequal(obj1.bottom, obj1.top) && isequal(obj2.bottom, obj2.top), tf = (obj1.bottom * obj1.utn < obj2.bottom * obj2.utn);
                elseif ~isempty(obj1) && ~isempty(obj2)
                    validList = {')[', ')(', ']('}; % max1 == max
                    max1 = max(obj1.bottom, obj1.top);
                    min2 = min(obj2.bottom, obj2.top);
                    tf = ( max1 < min2 ) || ( (isequal(max1, min2)) && any(strcmp([obj1.itt.rbt.ri, obj2.itt.lbt.li], validList)));
                end
            end
        end

        function tf = intervalGreaterThan(obj1, obj2)
            tf = intervalLessThan(obj2, obj1);
        end

        function tf = unitSame(obj1, obj2) % utn (Unit Number) may not be same
            tf = operateSizeHelper(obj1, obj2, @(x,y)(isempty(x.unit)&&isempty(y.unit))||strcmp(x.unit,y.unit), @false);
        end

        function tf = intervalMayIntersect(obj1, obj2)
            tf = ~intervalGreaterThan(obj1, obj2) & ~intervalLessThan(obj1, obj2) & ~(obj1.nar | obj2.nar);
        end

        function pd = intersect(obj1, obj2)
            pd = operateSizeHelper(obj1, obj2, @intersect1D, @sz2ar);
            
        end
    end
    
    methods(Access=private)
        function obj = inputRectify(obj)
            for indx = 1: 1: numel(obj)
                % check bottom and top
                Error1 = {'arange:ClassNotMatBottomTop', 'Classes of inputs bottom and top do not match.'};
                if ~isempty(obj(indx).top), if ~isequal(class(obj(indx).bottom), class(obj(indx).top)), error(Error1{:}); end; end
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
                % if still not converted to datetime
                if isa(obj(indx).bottom, 'char') || isa(obj(indx).bottom, 'string'), try obj = obj.value2datetime; catch; end; end
                % check is nar
                try if isnar(obj), obj.nar = true; end; catch; end
            end
        end

        function [obj, cl] = inputConvert(obj, in, newIT)
            cl = {}; % Optional Output in class Cell
            try if isa(in, 'numeric'), sz = size(in);
                    if length(sz) > 2 || sz(2) == 1, error('Not Covertable to arange');
                    else, obj(sz(1), sz(2)-1) = NaR; for idx1 = 1: 1: sz(1), for idx2 = 1: 1: sz(2)-1, obj(idx1, idx2) = arange(in(idx1,idx2),in(idx1,idx2+1)); if (nargin == 3), obj(idx1, idx2).itt = newIT; end; end; end; end
                elseif isa(in, 'duration'), if numel(in) == 1, obj.duration = in; else, obj = duration2arange(in, newIT); end
                elseif isa(in, 'timerange'), obj = timerange2arange(in, newIT);
                elseif isa(in, 'datetime'), obj = datetime2arange(in, newIT);
                elseif isa(in, 'cell')
                    sz = size(in); cl = cell(sz); tf = true; num = numel(in);
                    if (nargin == 2),  for idx = 1: num; cl{idx} = arange(in{idx}); if isa(cl{idx}, 'cell'), tf = false; end; end
                    elseif (nargin == 3), for idx = 1: num; cl{idx} = arange(in{idx}, newIT.name); if isa(cl{idx}, 'cell'), tf = false; end; end; end
                    if tf, tp(sz) = NaR; for idx = 1: num; tp(idx) = cl{idx}; end; obj = tp; else; warning('Use [~, Cell] to get the output cell.'); end
                elseif isa(in, 'arange'), obj = in;
                end
                if ~isa(obj, 'cell'), obj = obj.inputRectify; end
            catch ME
                warning(ME.message); obj = arange.empty; warning('Output empty arange. Check inputs.')
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
    end
    

    methods(Access=public)
        function tf = isarange(obj)
            tf = isa(obj, 'arange');
        end

        function flag = issame(obj1, obj2)
            if obj1.nar || obj2.nar, flag = 0;
            else
                if isequal(obj1, obj2), flag = 1;
                elseif eq(obj1, obj2), flag = 2;
                elseif eq(obj1, obj2, true), flag = 3;% May Intersect
                else, flag = 0;
                end
            end
        end

        %% is in arange / is not in arange / is ambiguously in arange
        function tf = ni(obj, mat)
            tf = operateSizeHelper(obj, mat, @ni1D, @false);
            function tf = ni1D(obj, mat)
                if obj.nar, tf = false;
                elseif obj.bottom <= obj.top
                    switch obj.itt.iti
                        case {'[)', '[}'}, tf = obj.bottom <= mat && mat < obj.top;
                        case {'()', '{)', '(}', '{}'}, tf = obj.bottom < mat && mat < obj.top;
                        case '[]', tf = obj.bottom <= mat && mat <= obj.top;
                        case {'(]', '{]'}, tf = obj.bottom_limit < mat && mat <= obj.top_limit;
                    end
                else
                    tp = abs(obj);
                    tf = ni1D(tp, mat);
                end
            end
        end

        function tf = isinarange(obj, mat)
            % the same as the method ni
            tf = obj.ni(mat);
        end

        function tf = notni(obj, mat)
            tf = operateSizeHelper(obj, mat, @notni1D, @false);
            function tf = notni1D(obj, mat)
                if obj.nar, tf = false;
                elseif obj.bottom <= obj.top
                    switch obj.itt.iti
                        case {'[)', '{)'}, tf = mat < obj.top || obj.bottom <= mat;
                        case '()', tf = mat <= obj.bottom || obj.top <= mat;
                        case {'[]', '{]', '[}', '{}'}, tf = mat < obj.bottom || obj.top < mat;
                        case {'(]', '(}'}, tf = mat <= obj.bottom || obj.top < mat;
                    end
                else
                    tp = abs(obj);
                    tf = notni1D(tp, mat);
                end
            end
        end

        function tf = isnotinarange(obj, mat)
            % the same as the method ni
            tf = obj.notni(mat);
        end
        
        function tf = isambiguousinarange(obj, mat)
            tf = operateSizeHelper(obj, mat, @isambiguousinarange1D, @false);
            function tf = isambiguousinarange1D(obj, mat)
                if obj.nar, tf = false;
                elseif obj.bottom <= obj.top
                    tf = false; if any(strcmp({obj.itt.lbti, obj.itt.rbti}, '{')) && (mat == obj.bottom || mat == obj.top), tf = true; end
                else
                    tp = abs(obj);
                    tf = isambiguousinarange1D(tp, mat);
                end
            end
        end
        
        %% Conversion to other classes
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
                    if isempty(obj.unit), try tr = timerange(obj.bottom, obj.top, obj.itt.name); catch, error('Ambiguous interval type.'); end
                    elseif ~isempty(obj.bottom) && ~isempty(obj.top) && any(validatestring(obj.unit, {'years', 'year', 'quarters', 'quarter', 'months', 'month', 'weeks', 'week', 'days', 'day', 'hours', 'hour', 'minutes', 'minute', 'seconds', 'second'}))
                            if isa(obj.bottom, 'datetime')
                                tp = obj.snapTopBackToUnitOfTime(); 
                                tr = timerange(tp.bottom, tp.top, tp.unit); 
                                if any(strcmp(tp.itt.iti,{'[]','()','(]'})), warning('IntervalType change to openright.'); end
                            end
                            if isempty(tr)
                                try
                                    tp = obj.value2duration;
                                    if ~isa(tp.bottom, 'duration'), error('Try value converting to duration failed.');
                                    else, try tr = timerange(tp.bottom, tp.top, tp.itt.name); catch, error('Ambiguous interval type.'); end; end
                                catch ME, error(ME.message);
                                end
                            end
                    elseif ~isempty(obj.bottom) && ~isempty(obj.top) && isa(obj.bottom, 'duation')
                        try tr = timerange(obj.bottom, obj.top, obj.itt.name); catch, error('Ambiguous interval type.'); end
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

function [value, itt, flag] = compareLengthRectify(obj)
    if isnumeric(obj), value = obj; itt = IntervalType('[]'); flag = {'duration', 'scope'};
    else
        try
            if ~isempty(obj.duration)
                value = obj.duration; itt = obj.itt; flag = 'duration';
            elseif ~isempty(obj.scope)
                value = obj.scope; itt = obj.itt; flag = 'scope';
            end
            if value < 0, value = - value; itt = intervalTypeFlip(itt); end
        catch
            error('Compare Rectify Error. Input class may be wrong. May lack of scope or duration.')
        end
    end
end

function tf = compareLength1DLessThan(obj1, obj2, validIntervalTypeRelationship)
    [value1, itt1, flag1] = compareLengthRectify(obj1);
    [value2, itt2, flag2] = compareLengthRectify(obj2);
    if any(strcmp(flag1, flag2))
        try tf = (value1 < value2) || ((value1 == value2) && validIntervalTypeRelationshipCheck(itt1,itt2,validIntervalTypeRelationship));
        catch; end
    else, error('Compare Length Error.')
    end
end

function tf = compareLength1DLessEqual(obj1, obj2, validIntervalTypeRelationship)
    [value1, itt1, flag1] = compareLengthRectify(obj1);
    [value2, itt2, flag2] = compareLengthRectify(obj2);
    if any(strcmp(flag1, flag2))
        try tf = (value1 <= value2) || ((value1 == value2) && validIntervalTypeRelationshipCheck(itt1,itt2,validIntervalTypeRelationship));
        catch; end
    else, error('Compare Length Error.')
    end
end

function tf0 = validIntervalTypeRelationshipCheck(itt1, itt2, validIntervalTypeRelationship)
    tf0 = any(strcmp([itt1.iti, itt2.iti],validIntervalTypeRelationship));
end

function tp = emptyNaRArangeList()
    tp([9 1]) = arange; ls = ["[)" "()" "(]" "[]" "{)" "{]" "(}" "[}"];
    for indx = 2: 9; tp(indx).itt = IntervalType(ls(indx-1)); end
end

function it2 = intervalTypeFlip(it1)
    switch it1
        case '[)', it2 = '(]';
        case '(]', it2 = '[)';
    end
end

function ar = sz2ar(sz)
    sz = arrayfun(@(x){sz(x)},1:length(sz));
    ar(sz{:}) = NaR;
end
