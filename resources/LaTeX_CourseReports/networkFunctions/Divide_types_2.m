function [country_types, properties] = Divide_types_2(data, rowNames, N)
    idxx = kmeans(data, N);
    country_types = cell(length(unique(abs(idxx))),1);
    noise_points = cell.empty;
    for ii = 1: size(idxx,1)
        type = idxx(ii,1);
        if type == -1
            noise_points = [noise_points, rowNames(ii)];
        else
            country_types{type,1} = [country_types{type,1}, rowNames(ii)];
        end
    end
    properties = cell(size(data,1),2);
    for ii = 1:size(data,1)
        properties{ii,1} = rowNames(ii);
        properties{ii,2} = data(ii,:);
    end
end

