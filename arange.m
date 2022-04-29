classdef arange < handle
    % bottom_limit, top_limit -> arange
    properties
        bottom_limit
        top_limit
        bottom_reach
        top_reach
    end
    methods
        function obj = arange(bottom_limit, top_limit, tag)
            % bottom_limit, top_limit -> arange

            if nargin == 2
                tag = [1 1];
            end
            obj.bottom_limit = bottom_limit;
            obj.top_limit = top_limit;
            obj.bottom_reach = logical(tag(1));
            obj.top_reach = logical(tag(2));
        end

        function thebool = ni(obj, themat)
            % mat -> bool; whether or not in the range.
            % Input the_arange, the_mat
            
            if obj.bottom_reach
                if obj.top_reach
                    thebool = obj.bottom_limit <= themat & themat <= obj.top_limit;
                else
                    thebool = obj.bottom_limit <= themat & themat < obj.top_limit;
                end
            else
                if obj.top_reach
                    thebool = obj.bottom_limit < themat & themat <= obj.top_limit;
                else
                    thebool = obj.bottom_limit < themat & themat < obj.top_limit;
                end
            end
        end

        function thebool = isinarange(obj, themat)
            % the same as the method ni
            thebool = obj.ni(themat);
        end
    end
end