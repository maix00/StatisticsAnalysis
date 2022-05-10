classdef arange
    % ARANGE Arange is a class of range data.
    %   R = ARANGE(M_by_xxx_by_2, intervalType, unit)
    %   R = ARANGE(M_by_xxx_by_2, intervalType)
    %   R = ARANGE(M_by_xxx_by_2, unit)
    % 
    %   Properties: range, starts, ends, scope, unit
    % 
    % ARANGE methods and functions:
    %   Construction and conversion as a whole:
    %       <a href = "matlab:help arange/arange">arange</a>
    %       <a href = "matlab:help isarange">isarange</a>
    %       <a href = "matlab:help arange2timerange">arange2timerange</a> aka <a href = "matlab:help ar2tr">ar2tr</a>
    %
    %   Value convertion:
    %       <a href = "matlab:help value2str">value2str</a>
    %       <a href = "matlab:help value2datetime">value2datetime</a>
    %       <a href = "matlab:help value4datestr">value4datestr</a>
    %       <a href = "matlab:help value2duration">value2duration</a>
    %
    %   Relationship:
    %       <a href = "matlab:help arange/isempty">isempty</a>                     - 0x0, or contains NaN and NaT, or no limits, or not closed intervalType on one value
    %       <a href = "matlab:help arange/issame">issame</a>                      - isequal return 1, intersects return 2
    %       <a href = "matlab:help arange/isinarange">isinarange</a>       aka <a href = "matlab:help arange/ni">ni</a>     - check whether an instance is between the bottom and top limits of the ARANGE
    %       <a href = "matlab:help arange/eq">eq</a>               aka <a href = "matlab:help arange/eq">==</a>     - same as <a href = "matlab:help arange/intervalMayIntersect">intervalMayIntersect</a>
    %       <a href = "matlab:help arange/ne">ne</a>               aka <a href = "matlab:help arange/ne">~=</a>     - not <a href = "matlab:help arange/intervalMayIntersect">intervalMayIntersect</a>
    %       <a href = "matlab:help arange/lt">lt</a>               aka <a href = "matlab:help arange/lt"><</a>      - true when the latter fully surpasses the former
    %       <a href = "matlab:help arange/le">le</a>               aka <a href = "matlab:help arange/le"><=</a>     - true when surpassing or may-intersecting
    %       <a href = "matlab:help arange/gt">gt</a>               aka <a href = "matlab:help arange/gt">></a>      - likewise
    %       <a href = "matlab:help arange/ge">ge</a>               aka <a href = "matlab:help arange/ge">>=</a>     - likewise
    %
    %   Calculations:
    %       <a href = "matlab:help arange/abs">abs</a>                         - unary operation, return rectified aranges
    %                                     e.g. [2,3) -> [2,3); (3,2] -> [2,3) 
    %       <a href = "matlab:help arange/uminus">uminus</a>           aka <a href = "matlab:help arange/uminus">-</a>      - unary operation, flip endpoints
    %                                     e.g. [2,3) -> (3,2]
    %       <a href = "matlab:help arange/plus">plus</a>             aka <a href = "matlab:help arange/plus">+</a>      - endpoints and boundary plus
    %       <a href = "matlab:help arange/minus">minus</a>            aka <a href = "matlab:help arange/minus">-</a>      - endpoints cross minus and boundary plus (range minus)
    %                                     e.g. [2,3) - (3,4] = [2,3) + [-4,-3) = [-2,0)
    %       <a href = "matlab:help arange/times">times</a>            aka <a href = "matlab:help arange/times">.*</a>     - value times
    %       <a href = "matlab:help arange/mtimes">mtimes</a>           aka <a href = "matlab:help arange/mtimes">*</a>      - cat
    %       <a href = "matlab:help arange/intersect">intersect</a>                   - intersection
    %  %-------------------------------------------------------------------
    %    Author: WANG Yi-yang
    %      Date: 27-Apr-2022
    %   Version: v20220505
    

    properties(Hidden, SetAccess={?StatisticsAnalysis})
        lb = BoundaryType('{');
        rb = BoundaryType('{');
        nar = false;
    end

    properties(Hidden)
        range = cell(1,2);
    end
 
    properties
        unit = sym('1');
    end

    properties(Dependent)
        starts
        ends
        type
        scope
    end

    methods
        function [obj, optCell] = arange(in, ITorUnit, Unit, ~)
            if (nargin == 0), obj.nar = true; return;
            else
                try
                    narginchk(1,3);
                    sz = size(in); num = numel(in);
                    UniformFlag2 = []; UniformFlag3 = [];
                    if (nargin > 1)
                        UniformFlag2 = CheckSettingsSize(ITorUnit, num);
                        if UniformFlag2, [lb, rb] = IntervalTypeName2BoundaryTypes(ITorUnit);
                            if isempty(lb), flag = 'Unit'; else, flag = 'IT'; end
                        end
                        if (nargin == 3), UniformFlag3 = CheckSettingsSize(Unit, num); end
                    end
                    if isa(in, 'timerange')
                        s = saveobj(in);
                        obj.range = {s.first, s.last};
                        [obj.lb, obj.rb] = IntervalTypeName2BoundaryTypes(s.type);
                        obj.unit = UnitRectifyUtility(s.unitOfTime);
                    elseif isa(in, 'cell')
                        optCell = cell(sz); tf = true;
                        for idx = 1: num
                            if (nargin == 1)
                                tp = arange(in{idx}{:});
                            else
                                if (nargin == 2)
                                    if UniformFlag2
                                        tp = arange(in{idx}, ITorUnit);
                                    else, try tp = arange(in{idx}, ITorUnit{idx}); catch, tp = arange(in{idx}, ITorUnit(idx)); end
                                    end
                                elseif (nargin == 3)
                                    if UniformFlag2 && UniformFlag3
                                        tp = arange(in{idx}, ITorUnit, Unit);
                                    elseif UniformFlag2 && ~UniformFlag3
                                        try tp = arange(in{idx}, ITorUnit, Unit{idx}); catch, tp = arange(in{idx}, ITorUnit, Unit(idx)); end
                                    elseif ~UniformFlag2 && UniformFlag3
                                        try tp = arange(in{idx}, ITorUnit{idx}, Unit); catch, tp = arange(in{idx}, ITorUnit(idx), Unit(idx)); end
                                    else
                                        try tp = arange(in{idx}, ITorUnit{idx}, Unit{idx}); catch; end
                                        try tp = arange(in{idx}, ITorUnit{idx}, Unit(idx)); catch; end
                                        try tp = arange(in{idx}, ITorUnit(idx), Unit{idx}); catch; end
                                        try tp = arange(in{idx}, ITorUnit(idx), Unit(idx)); catch; end
                                    end
                                end
                            end
                            if isa(tp, 'cell'), tf = false; end
                            optCell{idx} = tp;
                        end
                        if tf, obj(sz) = arange();
                            for idx = 1: num, obj(idx) = optCell{idx}; end
                        else, warning('Use [~, Cell] to get the output cell.');
                        end
                    else
                        try
                            if sz(:,end) == 2
                                obj(sz(:,1:end-1)) = arange();
                                for idx = 1: num/2
                                    obj(idx).range = {in(idx), in(idx+num/2)};
                                    if UniformFlag2
                                        switch flag
                                            % To be updated
                                            case 'Unit', obj(idx).unit = UnitRectifyUtility(ITorUnit);
                                            case 'IT', obj(idx).lb = lb; obj(idx).rb = rb;
                                        end
                                    elseif ~UniformFlag2
                                        thisITorUnit = ITorUnit(idx);
                                        [lb, rb] = IntervalTypeName2BoundaryTypes(thisITorUnit);
                                        if isempty(lb), obj(idx).unit = UnitRectifyUtility(thisITorUnit);
                                        else, obj(idx).lb = lb; obj(idx).rb = rb;
                                        end
                                    end
                                    if (nargin == 3)
                                        if UniformFlag3, obj(idx).unit = UnitRectifyUtility(Unit);
                                        else, obj(idx).unit = UnitRectifyUtility(Unit(idx));
                                        end
                                    end
                                    obj(idx) = obj(idx).inputRectify;
                                end
                            else % Arange be a fix point
                                obj(sz) = arange();
                                for idx = 1: num
                                    obj(idx).range = {in(idx), in(idx)};
                                    obj(idx).lb = ClosedBoundaryType;
                                    obj(idx).rb = ClosedBoundaryType;
                                    if (nargin > 1), warning('Fix Point Output. Check Syntax.'); end
                                    if (nargin == 3)
                                        if UniformFlag3, obj(idx).unit = UnitRectifyUtility(Unit);
                                        else, obj(idx).unit = UnitRectifyUtility(Unit(idx));
                                        end
                                    end
                                    try if isnar(obj(idx)), obj(idx).nar = true; else, obj(idx).nar = false; end; catch; end
                                end
                            end
                        catch ME
                            warning('Input Class not Supported.');
                            error(ME.message);
                        end
                    end
                catch ME
                    warning('Expect input [left, right], intervalType, unit.');
                    warning(ME.message); obj.nar = true; return
                end
            end
            
            function tf = CheckSettingsSize(in, num)
                if numel(string(in)) == 1 && ~isa(in, 'cell'), tf = true;
                elseif numel(in) == num, tf = false;
                elseif isempty(in), tf = true;
                else, error('Settings Size do not Match. Check Syntax.')
                end
            end
        end

        function val = get.type(obj)
            switch obj.lb.li
                case '{'
                    switch obj.rb.ri
                        case ')', val = 'ambiguous-open';
                        case ']', val = 'ambiguous-closed';
                        case '}', val = 'ambiguous';
                    end
                case '('
                    switch obj.rb.ri
                        case ')', val = 'open';
                        case ']', val = 'openleft';
                        case '}', val = 'open-ambiguous';
                    end
                case '['
                    switch obj.rb.ri
                        case ')', val = 'openright';
                        case ']', val = 'closed';
                        case '}', val = 'closed-ambiguous';
                    end
            end
        end

        function val = get.scope(obj)
            if isa(obj.range, 'cell')
                try val = obj.range{2} - obj.range{1}; 
                catch
                    if isa(obj.range{1}, 'datetime'), val = 'NaD';
                    else, val = NaN; end
                end
            elseif isa(obj.range, 'duration') || isa(obj.range, 'timerange')
                val = obj.range;
            else
                val = NaN;
            end
        end

        function val = get.starts(obj)
            if isa(obj.range, 'cell')
                val = obj.range{1};
            end
        end

        function val = get.ends(obj)
            if isa(obj.range, 'cell')
                val = obj.range{2};
            end
        end
    end

    methods % Get Properties as Cells or Arrays
        function val = getStarts(obj)
            num = numel(obj);
            if num == 1, val = obj.starts;
            else
                val = cell(size(obj));
                for idx = 1: num
                    val{idx} = obj(idx).starts;
                end
            end
            try val = cell2mat(val); catch; end
        end

        function val = getEnds(obj)
            num = numel(obj);
            if num == 1, val = obj.ends;
            else
                val = cell(size(obj));
                for idx = 1: num
                    val{idx} = obj(idx).ends;
                end
            end
            try val = cell2mat(val); catch; end
        end

        function val = getTypes(obj)
            val(size(obj)) = string;
            for idx = 1: numel(obj)
                val(idx) = obj(idx).type;
            end
        end

        function val = getScopes(obj)
            num = numel(obj);
            if num == 1, val = obj.scope;
            else
                val = cell(size(obj));
                for idx = 1: num
                    val{idx} = obj(idx).scope;
                end
            end
            try val = cell2mat(val); catch; end
        end
    end

    methods(Access=private)
        function obj = inputRectify(obj)
            for idx = 1: 1: numel(obj)
                % endpoints to timetype
                topTraits = endpointTraits(obj(idx).range{2});
                try if topTraits.isInvalid, obj(idx).range{2} = obj(idx).range{1}; obj(idx) = obj(idx).endpoints2Timetype(); end
                catch, obj(idx) = obj(idx).bottomAddToTopFromUnit; end
                % snap endpoints
                if ~isempty(obj(idx).unit), try obj(idx) = obj(idx).snapEndpointsToUnitOfTime(); catch; end; end
                % if still not converted to datetime / duration
                if isa(obj(idx).range{1}, 'char') || isa(obj(idx).range{1}, 'string'), try obj(idx) = obj(idx).valuefunc(@datetime); catch; end; end
                if isa(obj(idx).range{1}, 'numeric') || isa(obj(idx).range{2}, 'numeric'), try obj(idx) = obj(idx).valuefunc(DurationFormat2FuncUtility(obj(idx).unit)); catch; end; end
                % Unit rectify
                if isa(obj(idx).range{1}, 'duration') && isa(obj(idx).range{2}, 'duration')
                    format1 = obj(idx).range{1}.Format; format2 = obj(idx).range{2}.Format;
                    if isequal(format1, format2)
                        switch format1
                            case {'s', 'd'}, obj(idx).unit = symunit(format1);
                            case 'm', obj(idx).unit = symunit('minute');
                            case 'y', obj(id).unit = symunit('year');
                        end
                    end
                end
                % check is nar
                try if isnar(obj), obj.nar = true; else, obj.nar = false; end; catch; end
            end
        end

        function obj = endpoints2Timetype(obj)
            bottomTraits = endpointTraits(obj.range{1});
            topTraits  = endpointTraits(obj.range{2});
            if bottomTraits.isText
                obj.range{1} = text2Timetype_helper(obj.range{1}, obj.range{2}, obj.unit);
                obj.range{1} = handleTimeZone(obj.range{1}, obj.range{2}, topTraits);
            end
            if topTraits.isText
                obj.range{2} = text2Timetype_helper(obj.range{2}, obj.range{1}, obj.unit);
                obj.range{2} = handleTimeZone(obj.range{2}, obj.range{1}, bottomTraits);
            end
        end

        function obj = snapEndpointsToUnitOfTime(obj)
            try % DATESHIFT only works if both FIRST and LAST are datetime.
                obj.range{1} = dateshift(obj.range{1}, 'start', UnitConvertUtility(obj.unit));
                if obj.range{2} ~= dateshift(obj.range{2}, 'end', UnitConvertUtility(obj.unit), 'previous') || obj.range{2} == obj.range{1}
                    obj.range{2}  = dateshift(obj.range{2}, 'start', UnitConvertUtility(obj.unit), 'next');
                end
            catch ME
                if isa(obj.range{2},'duration') || isa(obj.range{1},'duration') % Duration endpoint(s) not compatible with UNITOFTIME semantics
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    rethrow(ME)
                end
            end
        end
                
        function obj = snapTopBackToUnitOfTime(obj)
            try % DATESHIFT only works if both FIRST and LAST are datetime.
                obj.range{1} = dateshift(obj.range{1}, 'start', UnitConvertUtility(obj.unit));
                obj.range{2}  = dateshift(obj.range{2},  'start', UnitConvertUtility(obj.unit), 'previous');
            catch ME
                if isa(obj.range{2},'duration') || isa(obj.range{1},'duration') % Duration endpoint(s) not compatible with UNITOFTIME semantics
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    rethrow(ME)
                end
            end
        end

        function obj = bottomAddToTopFromUnit(obj, addNum)
            if nargin == 1, addNum = 1; end
            bottomTraits = endpointTraits(obj.range{1});
            topTraits = endpointTraits(obj.range{2});
            if topTraits.isInvalid, try if ~bottomTraits.isDatetime || ~bottomTraits.isDuration, obj.range{2} = obj.range{1} + addNum; end; catch; end; end
        end
    end

    methods(Hidden)
        %% display
        function disp(obj)
            import matlab.internal.display.lineSpacingCharacter
            tab = sprintf('  ');
            sz = size(obj); tp = strcat(strrep(string(int2str(sz'))," ",""),[arrayfun(@(x)"x",1:length(sz)-1)';""]); sz2cr = strcat(tp{:}); sizeChar = [sz2cr ' <a href = "matlab:help arange">arange</a> array'];
            switch numel(obj)
                case 1
                    strLeft = obj.lb.li; strRight = obj.rb.ri;
                    datetimeformat = settings().matlab.datetime.DefaultFormat.ActiveValue;
                    if ~isempty(obj.range{1})
                        if isa(obj.range{1},'datetime'), dispMsg = [strLeft ' ' dt2charHelper(obj.range{1}, datetimeformat) ', ' dt2charHelper(obj.range{2}, datetimeformat) strRight];
                        else, dispMsg = [strLeft dt2charHelper(obj.range{1}) ', ' dt2charHelper(obj.range{2}) strRight]; end
                    else, dispMsg = [obj.type ' intervalType']; 
                    end
                    dispMsg = ['(' dt2charHelper(obj.scope) ')-scope ' dispMsg];
                    if ~isequal(obj.unit, sym('1')), dispMsg = [dispMsg ' ( unit ' char(obj.unit) ' )']; end
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
                try if isnan(input), output = 'NaN'; end; catch; end
                if isempty(output), try if isnat(input), output = 'NaT'; end; catch; end; end
                if nargin == 2, if isempty(output), try output = [char(input, datetimeformat) ' ' input.TimeZone]; catch, output = char(input, datetimeformat); end; end; end
                if isempty(output), try output = char(string(input)); catch; end; end
                if isempty(output), output = ''; end
            end
        end

        %% operation
        function tf = isnar(obj)
            tf = false(size(obj)); for idx = 1: numel(obj), tf(idx) = isnar1D(obj(idx)); end
            function tf = isnar1D(obj)
                tf = any(emptyNaRArangeList == obj); if tf, return; end
                if ~tf, try if isequal(obj.range{1}, obj.range{2}) && ~any(strcmp(strcat(obj.lb.li,obj.rb.ri), {'[]','{}'})), tf = true; end; catch; end; end
                if ~tf, try if isnan(obj.range{1}) || isnan(obj.range{2}), tf = true; end; catch; end; end
                if ~tf, try if isnat(obj.range{1}) || isnat(obj.range{2}), tf = true; end; catch; end; end
            end
        end

        function pd = abs(obj)
            sz = size(obj); sz = arrayfun(@(x){sz(x)}, 1:length(sz));
            pd(sz{:}) = arange(); for idx = 1: numel(obj), pd(idx) = abs1D(obj(idx)); end
            function pd = abs1D(obj)
                pd = obj;
                if pd.scope < 0
                    pd.range{1} = obj.range{2};
                    pd.range{2} = obj.range{1};
                    pd.lb = obj.rb;
                    pd.rb = obj.lb;
                end
            end
        end

        function pd = uminus(obj)
            sz = size(obj); sz = arrayfun(@(x){sz(x)}, 1:length(sz));
            pd(sz{:}) = arange(); for idx = 1: numel(obj), pd(idx) = uminus1D(obj(idx)); end
            function pd = uminus1D(obj)
                pd = obj;
                pd.range{1} = obj.range{2};
                pd.range{2} = obj.range{1};
                pd.lb = obj.rb;
                pd.rb = obj.lb;
            end
        end

        function obj = plus(obj1, obj2)
            obj = operateSizeHelper(obj1, obj2, @plus1D, @sz2ar);
            function obj = plus1D(obj1, obj2)
                numericFlag1 = isnumeric(obj1); numericFlag2 = isnumeric(obj2);
                if ~numericFlag1 && numericFlag2, obj = plus1D(obj1, arange(obj2));
                elseif numericFlag1 && numericFlag2, sum = obj1 + obj2; obj = arange(sum);
                elseif numericFlag1 && ~numericFlag2, obj = plus1D(arange(obj1),obj2);
                else % ~numericFlag1 && ~numericFlag2
                    if ~isa(obj1, 'arange') || ~isa(obj2, 'arange')
                        try obj = plus(arange(obj1), arange(obj2)); catch; end
                    else
                        if obj1.nar || obj2.nar, obj = arange(); return; end
                        % To be updated
                        unit1 = obj1.unit; unit2 = obj2.unit; if ~isempty(unit1) && ~isempty(unit2), if ~isequal(unit1,unit2), error('Unit does not match.'); end; end
                        abs1 = abs(obj1); abs2 = abs(obj2);
                        obj = obj1; 
                        obj.lb = abs1.lb + abs2.lb; 
                        obj.rb = abs1.rb + abs2.rb;
                        obj.range{1} = abs1.range{1} + abs2.range{1};
                        obj.range{2} = abs1.range{2} + abs2.range{2};
                    end
                end
            end
        end

        function obj = minus(obj1, obj2)
            obj = operateSizeHelper(obj1, obj2, @minus1D, @sz2ar);
            function obj = minus1D(obj1, obj2)
                numericFlag1 = isnumeric(obj1); numericFlag2 = isnumeric(obj2);
                if ~numericFlag1 && numericFlag2, obj = plus1D(obj1, arange(obj2));
                elseif numericFlag1 && numericFlag2, sum = obj1 + obj2; obj = arange(sum);
                elseif numericFlag1 && ~numericFlag2, obj = plus1D(arange(obj1),obj2);
                else % ~numericFlag1 && ~numericFlag2
                    if ~isa(obj1, 'arange') || ~isa(obj2, 'arange')
                        try obj = plus(arange(obj1), arange(obj2)); catch; end
                    else
                        if obj1.nar || obj2.nar, obj = arange(); return; end
                        % To be updated
                        unit1 = obj1.unit; unit2 = obj2.unit; if ~isempty(unit1) && ~isempty(unit2), if ~isequal(unit1,unit2), error('Unit does not match.'); end; end
                        abs1 = abs(obj1); abs2 = abs(obj2);
                        obj = obj1; 
                        obj.lb = abs1.lb + abs2.rb; 
                        obj.rb = abs1.rb + abs2.lb;
                        obj.range{1} = abs1.range{1} - abs2.range{2};
                        obj.range{2} = abs1.range{2} - abs2.range{1};
                    end
                end
            end
        end
    end

    methods(Access=public)
        %% Intersection
        function tf = intervalLessThan(obj1, obj2)
            tf = operateSizeHelper(obj1, obj2, @intervalLessThan1D, @false);
        end

        function tf = intervalLessThan1D(obj1, obj2)
            if obj1.nar || obj2.nar, tf = false;
            elseif ~unitSame(obj1,obj2), tf = false;
            else
                if isequal(obj1.range{1}, obj1.range{2}) && isequal(obj2.range{1}, obj2.range{2}), tf = (obj1.range{1} < obj2.range{1});
                elseif ~isempty(obj1) && ~isempty(obj2)
                    validList = {')[', ')(', ']('}; % max1 == max
                    max1 = max(obj1.range{1}, obj1.range{2});
                    min2 = min(obj2.range{1}, obj2.range{2});
                    tf = ( max1 < min2 ) || ( (isequal(max1, min2)) && any(strcmp([obj1.rbt.ri, obj2.lb.li], validList)));
                end
            end
        end

        function tf = intervalGreaterThan(obj1, obj2)
            tf = intervalLessThan(obj2, obj1);
        end

        function tf = unitSame(obj1, obj2)
            tf = operateSizeHelper(obj1, obj2, @(x,y)(isempty(x.unit)&&isempty(y.unit))||isequal(x.unit,y.unit), @false);
        end

        function tf = intervalMayIntersect(obj1, obj2)
            tf = ~intervalGreaterThan(obj1, obj2) & ~intervalLessThan(obj1, obj2) & ~(obj1.nar | obj2.nar);
        end

        function pd = intersect(obj1, obj2)
            pd = operateSizeHelper(obj1, obj2, @intersect1D, @sz2ar);
        end

        function pd = times(obj1, obj2)
            pd = operateSizeHelper(obj1, obj2, @times1D, @sz2ar);
            function pd = times1D(obj1, obj2)
                if isnumeric(obj1)
                    if obj1 > 0
                        pd = obj2;
                            pd.range{1} = obj1 .* obj2.range{1};
                            pd.range{2} = obj1 .* obj2.range{2};
                    elseif obj1 < 0
                        pd = obj2;
                            pd.range{1} = obj1 .* obj2.range{2};
                            pd.range{2} = obj1 .* obj2.range{1};
                            pd.lb = obj.rb; pd.rb = obj.lb;
                    else
                        pd = arange();
                    end
                    elseif isnumeric(obj2), pd = times1D(obj2, obj1);
                else, error('Not supported inputs. Expect numeric and arange.')
                end
            end
        end

        function pd = mtimes(obj1, obj2) % stack in a new dimension / one-dimensionalize
            if ~isa(obj1, 'arange'), obj1 = arange(obj1); end
            if ~isa(obj2, 'arange'), obj2 = arange(obj2); end
            sz1 = size(obj1); sz2 = size(obj2);
            if all(sz1 == sz2)
                if sz1(:,end) == 1, EndPoint = length(sz1) - 1;
                else, EndPoint = length(sz1);
                end
                sz = [arrayfun(@(x){sz1(x)},1:EndPoint),{2}];
                pd(sz{:}) = arange();
                correctPartStem = arrayfun(@(x){1:sz1(x)},1:EndPoint);
                correctPart1 = [correctPartStem, {1}];
                pd(correctPart1{:}) = obj1;
                correctPart2 = [correctPartStem, {2}];
                pd(correctPart2{:}) = obj2;
            else
                error('Size not match. Expect same size.')
            end
        end

        function pd = mpower(obj, int)% stack in a new dimension
            try
                int = double(int64(int));
            catch
                error('Syntax Error. Expect power of integral.');
            end
            sz = size(obj);
            if sz(:,end) == 1, EndPoint = length(sz) - 1;
            else, EndPoint = length(sz);
            end
            newSZ = [arrayfun(@(x){sz(x)},1:EndPoint),int];
            pd(newSZ{:}) = arange();
            correctPartStem = arrayfun(@(x){1:sz(x)},1:EndPoint);
            for idx = 1: int
                correctPart = [correctPartStem,{idx}];
                pd(correctPart{:}) = obj;
            end
        end

        function tf = eq(obj1, obj2, intersectFlag) % Whether May Intersect
            if nargin == 2, intersectFlag = true; end
            tf = operateSizeHelper(obj1, obj2, @(x,y)eq1D(x,y,intersectFlag), @false);
            function tf = eq1D(obj1, obj2, intersectFlag), if ~intersectFlag, tf = isequal(obj1, obj2); else, tf = intervalMayIntersect(obj1, obj2); end; end
        end

        function tf = ne(obj1, obj2, intersectFlag)
            if nargin == 2, intersectFlag = true; end
            tf = ~eq(obj1, obj2, intersectFlag);
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
                else, flag = 0;
                end
            end
        end

        %% is in arange / is not in arange / is ambiguously in arange
        function tf = ni(obj, mat)
            tf = operateSizeHelper(obj, mat, @ni1D, @false);
            function tf = ni1D(obj, mat)
                if obj.nar, tf = false;
                elseif obj.range{1} <= obj.range{2}
                    switch strcat(obj.lb.li, obj.rb.ri)
                        case {'[)', '[}'}, tf = obj.range{1} <= mat && mat < obj.range{2};
                        case {'()', '{)', '(}', '{}'}, tf = obj.range{1} < mat && mat < obj.range{2};
                        case '[]', tf = obj.range{1} <= mat && mat <= obj.range{2};
                        case {'(]', '{]'}, tf = obj.range{1} < mat && mat <= obj.range{2};
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
                elseif obj.range{1} <= obj.range{2}
                    switch strcat(obj.lb.li, obj.rb.ri)
                        case {'[)', '{)'}, tf = mat < obj.range{2} || obj.range{1} <= mat;
                        case '()', tf = mat <= obj.range{1} || obj.range{2} <= mat;
                        case {'[]', '{]', '[}', '{}'}, tf = mat < obj.range{1} || obj.range{2} < mat;
                        case {'(]', '(}'}, tf = mat <= obj.range{1} || obj.range{2} < mat;
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
                elseif obj.range{1} <= obj.range{2}
                    tf = false; if any(strcmp({obj.lb.li, obj.rb.li}, '{')) && (mat == obj.range{1} || mat == obj.range{2}), tf = true; end
                else
                    tp = abs(obj);
                    tf = isambiguousinarange1D(tp, mat);
                end
            end
        end
        
        %% Conversion to other classes
        function obj = valuefunc(obj, func, varargin)
            for idx = 1: numel(obj)
                obj(idx).range{1} = func(obj(idx).range{1}, varargin{:});
                obj(idx).range{2} = func(obj(idx).range{2}, varargin{:});
            end
        end
        function tr = arange2timerange(obj)
            if numel(obj) == 1
                if isequal(obj.unit, sym('1')), try tr = timerange(obj.range{1}, obj.range{2}, obj.type); catch, error('Ambiguous interval type.'); end
                elseif ~isempty(obj.range{1}) && ~isempty(obj.range{2}) && any(validatestring(UnitConvertUtility(obj.unit), {'years', 'quarters', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds'}))
                        if isa(obj.range{1}, 'datetime')
                            tp = obj.snapTopBackToUnitOfTime(); 
                            tr = timerange(tp.range{1}, tp.range{2}, UnitConvertUtility(tp.unit)); 
                            if any(strcmp(strcat(obj.lb.li, obj.rb.ri),{'[]','()','(]'})), warning('IntervalType change to openright.'); end
                        end
                        if isempty(tr)
                            try
                                tp = obj.valuefunc(DurationFormat2FuncUtility(obj.unit));
                                if ~isa(tp.range{1}, 'duration'), error('Try value converting to duration failed.');
                                else, try tr = timerange(tp.range{1}, tp.range{2}, tp.type); catch, error('Ambiguous interval type.'); end; end
                            catch ME, error(ME.message);
                            end
                        end
                elseif ~isempty(obj.range{1}) && ~isempty(obj.range{2}) && isa(obj.range{1}, 'duation')
                    try tr = timerange(obj.range{1}, obj.range{2}, obj.type); catch, error('Ambiguous interval type.'); end
                else
                    error('Convert to timerange failed.');
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

function chr = UnitConvertUtility(sym)
    chr = char(sym);
    chr = strrep(chr, 'symunit(''year_Julian'')', 'years');
    chr = strrep(chr, 'symunit(''month_30'')', 'months');
    chr = strrep(chr, 'symunit(''week'')', 'weeks');
    chr = strrep(chr, 'symunit(''d'')', 'days');
    chr = strrep(chr, 'symunit(''min'')', 'minutes');
    chr = strrep(chr, 'symunit(''s'')', 'seconds');
end

function NewUnit = UnitRectifyUtility(Unit)
    if isa(Unit, 'sym'), NewUnit = Unit; return; end
    if isa(Unit, 'string'), Unit = char(Unit); end
    try 
        if any(validatestring(Unit, {'years', 'year', 'quarters', 'quarter', 'months', 'month', 'weeks', 'week', 'days', 'day', 'hours', 'hour', 'minutes', 'minute', 'seconds', 'second'}))
            if strcmp(Unit(end), 's'), Unit = Unit(1:end-1); end
            NewUnit = str2symunit(Unit);
        end
    catch
        try
        NewUnit = str2symunit(Unit);
        catch
            try NewUnit = str2sym(Unit); catch; end
        end
    end
end

function func = DurationFormat2FuncUtility(in)
    switch UnitConvertUtility(in)
        case 'seconds', func = @seconds;
        case 'minutes', func = @minutes;
        case 'hours', func = @hours;
        case 'days', func = @days;
    end
end

function tp = emptyNaRArangeList()
    tp([9 1]) = arange; ls = {'[)' '()' '(]' '[]' '{)' '{]' '(}' '[}'};
    for indx = 2: 9
        this = ls{indx-1}; 
        tp(indx).lb = BoundaryType(this(1));
        tp(indx).rb = BoundaryType(this(2));
    end
end

function ar = sz2ar(sz)
    sz = arrayfun(@(x){sz(x)},1:length(sz));
    ar(sz{:}) = arange();
end
