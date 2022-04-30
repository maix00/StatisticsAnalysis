classdef arange < handle
    % bottom_limit, top_limit -> arange
    properties
        bottom = [];
        top = [];
        intervaltype = 'openright';
        unit = [];
        durationflag = false;
        duration = [];
    end
    methods
        function obj = arange(bottom, varargin)
            % bottom_limit, top_limit -> arange
            % interval_type: default 'openright'
            % unit: default []
            
            ips = inputParser;
            if length(varargin) == 3
                % bottom, top, interval_type, unit
                ips.addRequired('bottom', @(x)true);
                ips.addRequired('top', @(x)true);
                ips.addRequired('interval_type', @(x)any(validatestring(x,{'openright','openleft','closed','open','closedleft','closedright'})));
                ips.addRequired('unit', @(x)true);
                ips.parse(bottom, varargin{:});
                if strcmp(class(ips.Results.bottom), class(ips.Results.top))
                    obj.bottom = ips.Results.bottom;
                    obj.top = ips.Results.top;
                else
                    error('Bottom and top does not match in class. arange/arange/[bottom, top, interval_type, unit] Calls.')
                end
                obj.intervaltype = ips.Results.interval_type;
                obj.unit = ips.Results.unit;
            elseif length(varargin) == 2
                if any(strcmp(varargin{2},{'openright','openleft','closed','open','closedleft','closedright'}))
                    % bottom, top, interval_type
                    ips.addRequired('bottom', @(x)true);
                    ips.addRequired('top', @(x)true);
                    ips.addRequired('interval_type', @(x)true);
                    ips.parse(bottom, varargin{:});
                    if strcmp(class(ips.Results.bottom), class(ips.Results.top))
                        obj.bottom = ips.Results.bottom;
                        obj.top = ips.Results.top;
                    else
                        error('Bottom and top does not match in class. arange/arange/[bottom, top, interval_type] Calls.')
                    end
                    obj.intervaltype = ips.Results.interval_type;
                elseif any(strcmp(varargin{1},{'openright','openleft','closed','open','closedleft','closedright'}))
                    % bottom, interval_type, unit
                    ips.addRequired('bottom', @(x)true);
                    ips.addRequired('interval_type', @(x)true);
                    ips.addRequired('unit', @(x)true);
                    ips.parse(bottom, varargin{:});
                    obj.bottom = ips.Results.bottom;
                    obj.intervaltype = ips.Results.interval_type;
                    obj.unit = ips.Results.unit;
                    obj = obj.bottom_unit_2_top;
                else
                    % bottom, top, unit
                    ips.addRequired('bottom', @(x)true);
                    ips.addRequired('top', @(x)true);
                    ips.addRequired('unit', @(x)true);
                    ips.parse(bottom, varargin{:});
                    if strcmp(class(ips.Results.bottom), class(ips.Results.top))
                        obj.bottom = ips.Results.bottom;
                        obj.top = ips.Results.top;
                    else
                        error('Bottom and top does not match in class. arange/arange/[bottom, top, unit] Calls.')
                    end
                    obj.unit = ips.Results.unit;
                end
            elseif length(varargin) == 1
                if any(strcmp(varargin{1},{'openright','openleft','closed','open','closedleft','closedright'}))
                    % duration, interval_type
                    ips.addRequired('duration', @(x)validateattributes(x,{'duration'},{}));
                    obj.durationflag = true;
                    ips.addRequired('interval_type', @(x)true);
                    ips.parse(bottom, varargin{:});
                    obj.duration = ips.Results.duration;
                    obj.intervaltype = ips.Results.interval_type;
                else
                    if ~strcmp(class(bottom), class(varargin{1}))
                        % bottom, unit
                        ips.addRequired('bottom', @(x)true);
                        ips.addRequired('unit', @(x)true);
                        ips.parse(bottom, varargin{:});
                        obj.bottom = ips.Results.bottom;
                        obj.unit = ips.Results.unit;
                        obj = obj.bottom_unit_2_top;
                    else
                        % bottom, top
                        ips.addRequired('bottom', @(x)true);
                        ips.addRequired('top', @(x)true);
                        ips.parse(bottom, varargin{:});
                        obj.bottom = ips.Results.bottom;
                        obj.top = ips.Results.top;
                        try
                            if length(obj.bottom) ~= length(obj.top)
                                error('Input format may be wrong. arange/arange/[bottom, top] Calls.')
                            end
                        catch
                        end
                    end
                end
            elseif isempty(varargin)
                % duration
                ips.addRequired('duration', @(x)validateattributes(x,{'duration'},{}));
                ips.parse(bottom);
                obj.durationflag = true;
                obj.duration = ips.Results.duration;
            end
            %
            switch obj.intervaltype
                case 'closedright'
                    obj.intervaltype = 'openleft';
                case 'closedleft'
                    obj.intervaltype = 'openright';
            end
            %
            if any(strcmp(class(obj.bottom), {'datetime', 'string', 'char'}))
                obj.duration = obj.arange2duration;
                obj.durationflag = 1;
            end
        end

        function obj = bottom_unit_2_top(obj)
            try
                switch obj.unit
                    case {'seconds', 'second'}
                        obj.bottom = seconds(obj.bottom);
                        obj.top = obj.bottom + seconds(1);
                    case {'minutes', 'minute'}
                        obj.bottom = minutes(obj.bottom);
                        obj.top = obj.bottom + minutes(1);
                    case {'hours', 'hour'}
                        obj.bottom = hours(obj.bottom);
                        obj.top = obj.bottom + hours(1);
                    case {'days', 'day'}
                        obj.bottom = days(obj.bottom);
                        obj.top = obj.bottom + days(1);
                    case {'years', 'year'}
                        obj.bottom = years(obj.bottom);
                        obj.top = obj.bottom + years(1);
                    otherwise
                        if ~isduration(obj.bottom)
                            obj.top = obj.bottom + 1;
                        end
                end
            catch
                % do nothing
            end
        end

        function bool = ni(obj, themat)
            % mat -> bool; whether or not in the range.
            % Input the_arange, the_mat
            
            switch obj.intervaltype
                case 'openright'
                    bool = obj.bottom <= themat & themat < obj.top;
                case 'open'
                    bool = obj.bottom < themat & themat < obj.top;
                case 'closed'
                    bool = obj.bottom <= themat & themat <= obj.top;
                case 'openleft'
                    bool = obj.bottom_limit < themat & themat <= obj.top_limit;
            end
        end

        function bool = isinarange(obj, themat)
            % the same as the method ni
            bool = obj.ni(themat);
        end
        
        function obj = value2datetime(obj, varargin)
            try
                obj.bottom = datetime(obj.bottom, varargin{:});
                if ~isempty(obj.top)
                    obj.top = datetime(obj.top, varargin{:});
                end
            catch
                error('Value convert to datetime failed. arange/arangevalue2datetime Calls.')
            end
        end

        function obj = value4datestr(obj, varargin)
            try
                obj.bottom = datestr(obj.bottom, varargin{:});
                if ~isempty(obj.top)
                    obj.top = datestr(obj.top, varargin{:});
                end
            catch
                error('Value convert to string failed. arange/arangevalue2datetime Calls.')
            end
        end

        function obj = value2str(obj, varargin)
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
                error('Value convert to string failed. arange/arangevalue2datetime Calls.')
            end
        end

        function tr = arange2timerange(obj)
            try
                % bottom, top, interval_type, unit=days
                %   bottom: duration
                %   bottom: not duration
                % bottom, top, interval_type
                %   bottom: duration
                %   bottom: not duration
                % duration, interval_type
                if isempty(obj.unit)
                    tr = timerange(obj.bottom, obj.top, obj.intervaltype);
                else
                    if any(validatestring(obj.unit, {'years', 'year', 'quarters', 'quarter', 'months', 'month', 'weeks', 'week', 'days', 'day', 'hours', 'hour', 'minutes', 'minute', 'seconds', 'second'}))
                        if ~strcmp(obj.unit(end), 's')
                            obj.unit = [obj.unit, 's'];
                        end
                        tr = timerange(obj.bottom, obj.top, obj.unit);
                    else
                        error('Value of unit not valid as of duration. arange/arange2timerange/obj.unit/validatestring Calls.')
                    end
                end
            catch
                error('Convert to timerange failed. arange/arange2timerange Calls.');
            end
        end
        
        function dt = arange2datetime(obj, varargin)
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
        end

        function dr = arange2duration(obj)
            if obj.durationflag
                dr = obj.duration;
            else
                try
                    obj = obj.value2datetime;
                catch
                end
                try
                    dr = obj.top - obj.bottom;
                    if ~isduration(dr) && any(strcmp(obj.unit,{'seconds','second','minute','minutes','hours','hour','days','day','years','year'}))
                        switch obj.unit
                            case {'seconds', 'second'}
                                dr = seconds(dr);
                            case {'minutes', 'minute'}
                                dr = minutes(dr);
                            case {'hours', 'hour'}
                                dr = hours(dr);
                            case {'days', 'day'}
                                dr = days(dr);
                            case {'years', 'year'}
                                dr = days(dr);
                        end
                    end
                catch
                    error('Convert to duration failed. Check units in seconds/minutes/hours/days.')
                end
            end
        end

        % function
    end
end