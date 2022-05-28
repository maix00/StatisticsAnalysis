function elbow_2(data, rowNames, N)
    
error = zeros(1, N);
for k = 1: N
    M = 20;
    list = zeros(1, M);
    for idx = 1: M
        list(1, idx) = Error(data, rowNames, k);
    end
    error(1,k) = mean(list);
end
plot(error)

    function error = Error(data, rowNames, k)
        error = 0;
        prop = zeros(1, size(data,2));
        [country_types, properties] = Divide_types_2(data, rowNames, k);
        for ii = 1:size(country_types,1)
            if size(country_types{ii,1},2) == 0
                continue
            end
            num = 1;
            try
                prod(country_types{ii,1});
            catch
                num = size(country_types{ii,1},2);
            end
            for country = country_types{ii,1}
                for jj = 1:size(properties,1)
                    if strcmp(country,properties{jj,1})
                        prop = prop + properties{jj,2};
                    end
                end
            end
            prop = prop/num;
            err = 0;
            for country = country_types{ii,1}
                for jj = 1:size(properties,1)
                    if strcmp(country,properties{jj,1})
                        err = err + norm(properties{jj,2}-prop);
                    end
                end
            end
            error = error + err;
        end
    end
end