function [T, Missing] = tableMissingValuesHelper(T, varargin)
    
    if ~isempty(varargin)
        Options = OptionsSizeHelper(varargin, 2, true);
        TMV = TableMissingValues(T, Options);
    else
        TMV = TableMissingValues(T);
    end
    T = TMV.Table;
    Missing = TMV.Missing;
end