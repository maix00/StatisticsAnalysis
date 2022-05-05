function [pd, btmNew, topNew, lf, rf, thisUnit] = intersect1D(obj1, obj2, ProperQuickListOutputFlag)
    % [pd, btmNew, topNew, lf, rf, thisUnit] = intersect1D(obj1, obj2, QuickListOutputFlag)
    %   Input two aranges and will output their intersects.

    %   WANG Yi-yang May 4, 2022
    
    % Initialize product
    pd = [];

    % In QuickListOutput Style, we assume all two inputs have proper 
    % boundary types.
    if nargin == 2, ProperQuickListOutputFlag = false; end

    % Since we choose not to call intervalMayIntersect (to enhance 
    % performance) we need to handle the situation where the two inputs do 
    % not intersect.
    FurtherNoticeFlag = [];

    % If any one of the input aranges is labeled as NotARange, this
    % function would imediately return NaR.
    if obj1.nar
        if ProperQuickListOutputFlag, btmNew = []; topNew = []; lf = []; rf = []; thisUnit = []; return; end
        pd = obj1;
        return;
    elseif obj2.nar
        if ProperQuickListOutputFlag, btmNew = []; topNew = []; lf = []; rf = []; thisUnit = []; return; end
        pd = obj1;
        return;
    else
        % Copy the unit first.
        thisUnit = obj1.unit;

        % Then copy the bottoms and tops and boundary type images.
        btm1 = obj1.range{1}; top1 = obj1.range{2};
        btm2 = obj2.range{1}; top2 = obj2.range{2};
        lf1 = obj1.lb.li; rf1 = obj1.rb.ri;
        lf2 = obj2.lb.li; rf2 = obj2.rb.ri;

        % Using ~obj2.notni(top1), other than obj2.ni(top1), to make
        % sure ambiguous boudary types are properly handled.
        %
        % When the top of the first input is not out of the range of 
        % the second input (is in the range of the second input, or is
        % ambiguously in the range of the second input, i.e., lies on
        % the ambiguous boudary of the second input), we can be sure
        % these two inputs would intersect (or at least, ambiguously
        % intersect), so we set the right boundary to be top of the
        % first input.
        % 
        % The right boundary type would be the right one of the first
        % input if we assume all boundary types of the inputs are
        % proper.
        if ~obj2.notni(top1), rf = rf1; topNew = top1;

            % Outside Proper Quick List Speeding, we are not sure whether the
            % right boudary is ambiguous.
            %
            % If the right boundary type of the first input was already
            % ambiguous, there is no need to change anything, as the
            % output's right boundary type was copied from it.
            if ~ProperQuickListOutputFlag && (rf ~= '}')
                % If the right boundary type of the first input was not
                % ambiguous, we need check whether the top of the first
                % input happens to be lying on the ambiguous boundary
                % of the second input. If so, we should set the
                % output's right boundary type to be ambiguous.
                if ((top1 == btm2) && (lf2 == '{')) || ((top1 == top2) && (rf2 == '}')), rf = '}'; 
                end
            end
        % When the top of the first input is definitely out of the 
        % range of the second input, YOU can not make sure these two
        % inputs would intersect (in Proper Quick List Speeding). Raise Flag
        % FurtherNoticeFlag.
        %
        % At this poiint, if one can make sure these two inputs would 
        % intersect, the output's right boundary should be the same as the
        % one of the second input.
        else, rf = rf2; topNew = top2; if ProperQuickListOutputFlag, FurtherNoticeFlag = false; end
        end

        % Now process the left boundary of the output. Likewise, switch
        % two cases, the one when the bottom of the first input is not
        % definitely outside the range of the second input, which need
        % to further handle the ambiguity, and the one when the bottom
        % of the first input is definitely outside the range of the
        % second input.
        if ~obj2.notni(btm1), lf = lf1; btmNew = btm1; 
            % Handle Ambiguity
            if ~ProperQuickListOutputFlag && (lf ~= '{')
                if ((btm1 == btm2) && (lf2 == '{')) || ((btm1 == top2) && (rf2 == '}')), rf = '}'; 
                end
            end
        else, lf = lf2; btmNew = btm2; if ProperQuickListOutputFlag, FurtherNoticeFlag = ~ FurtherNoticeFlag; end
        end

        % When FurtherNoticeFlag is true, i.e., both the bottom of the
        % top of the first input is definitely outside the range of the
        % second input, we should check whether any one further
        % surpasses the other one, so that they do not intersect, which
        % should invoke NaR.
        if FurtherNoticeFlag
            if intervalLessThan1D(obj1, obj2) || intervalLessThan1D(obj2, obj1)
                if ProperQuickListOutputFlag, btmNew = []; topNew = []; lf = []; rf = []; thisUnit = []; return; end
                pd = arange(); return
            end
        end

        % In Proper Quick List Speeding, no arange would be output.
        if ProperQuickListOutputFlag, pd = []; return; end

        % Else, construct the arange.
        pd = arange([btmNew, topNew], strcat(lf,rf), thisUnit);
    end
end