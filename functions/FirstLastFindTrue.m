function cmpFL = FirstLastFindTrue(cmp)
    cmpFL = {};
    formerLast = 0;
    while ~isempty(find(cmp, true))
        thisFirst = find(cmp,true,'first');
        for thisLast = thisFirst: length(cmp) - formerLast
            if cmp(thisLast + 1) == 0
                break
            end
        end
        cmpFL = [cmpFL, {[formerLast + thisFirst, formerLast + thisLast]}];
        formerLast = formerLast + thisLast;
        cmp = cmp(thisLast+1:end);
    end
end