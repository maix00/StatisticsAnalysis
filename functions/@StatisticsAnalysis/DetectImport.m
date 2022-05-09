function obj = DetectImport(obj)
    % DetectImport detects import options.
    %
    %   obj = DetectImport(obj)
    %   obj = obj.DetectImport

    %   WANG Yi-yang 28-Apr-2022

    if ~isempty(obj.originalDetectedImportOptions)
        obj.DetectedImportOptions = obj.originalDetectedImportOptions;
    else
        if ~isempty(obj.TablePath)
            obj.originalDetectedImportOptions = detectImportOptions(obj.TablePath);
            obj.DetectedImportOptions = obj.originalDetectedImportOptions;
        end
    end
end