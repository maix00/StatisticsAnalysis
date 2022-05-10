function [lb, rb] = IntervalTypeName2BoundaryTypes(name)
    switch name
        case {'openright', '[)', 'closed-open'}, lb = BoundaryType('['); rb = BoundaryType('('); 
        case {'open', '()', 'open-open'}, lb = BoundaryType('('); rb = BoundaryType('('); 
        case {'closed', '[]', 'closed-closed'}, lb = BoundaryType('['); rb = BoundaryType('['); 
        case {'openleft', '(]', 'open-closed'}, lb = BoundaryType('('); rb = BoundaryType('('); 
        case {'ambiguous-open', '{)'}, lb = BoundaryType('{'); rb = BoundaryType('('); 
        case {'ambiguous-closed', '{]'}, lb = BoundaryType('{'); rb = BoundaryType('['); 
        case {'open-ambiguous', '(}'}, lb = BoundaryType('('); rb = BoundaryType('{'); 
        case {'closed-ambiguous', '[}'}, lb = BoundaryType('['); rb = BoundaryType('{'); 
        case {'ambiguous', '{}'}, lb = BoundaryType('{'); rb = BoundaryType('{'); 
        otherwise, lb = []; rb = [];
    end
end