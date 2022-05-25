function Options = OptionsSizeHelper(Options, numOneLine, Convert2Struct)
    switch class(Options)
        case 'struct' % do nothing
        case 'cell'
            if nargin == 1, numOneLine = 2; Convert2Struct = false; end
            if ~isempty(Options)
                sz = size(Options);
                if isa(Options, 'cell') && sz(1) == 1
                    if sz(2) == numOneLine
                        % do nothing
                    elseif mod(sz(2), numOneLine) == 0
                        tp = cell(sz(2)/numOneLine, numOneLine);
                        for idx = 1: sz(2)/numOneLine
                            tp(idx, :) = Options(1, numOneLine*(idx-1)+1: numOneLine*idx);
                        end
                        Options = tp;
                    else
                        error('Check Input. Length not match.');
                    end
                end
            end
            % Options Convert to struct
            if numOneLine == 2 && Convert2Struct
                Options = cell2struct(Options(:,2), Options(:,1), 1);
            end
    end
end