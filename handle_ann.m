function [ann_list_modified] = handle_ann(ann_list)
    ann_list_modified = zeros(1, length(ann_list));
    for i=1:length(ann_list)
        el = ann_list(i);
        if ismember(el, '(N')
            ann_list_modified(i)=0;
        elseif ismember(el, '(AFIB') || ismember(el, '(AFL')
            ann_list_modified(i)=1;
        else
            ann_list_modified(i)=-1;
        end
    end
end