cd data/afdb
% get data from physionet
list = physionetdb('afdb');
list = list(3:25);
% for i = 1:length(list)
%     wfdb2mat(['afdb/' list{1,i}])
% end

% collect annotations
ann = {};
time_ann = {};
for l=1:length(list)
    [a,b,c,d,e,f] = rdann(['afdb/' list{1,l}], 'atr');
    ann{l} = f;
    time_ann{l} = a;
end

tot_samples = 0;

for index_list = 1:length(list)
    cd ../../
    % obtain a list where 0 = NR, 1 = AF
    ann_list = handle_ann(ann{index_list});
    % choose the max number of NR episodes to consider
    EPISODES = 3;
    if length(ann_list) > EPISODES*2
        ann_list = ann_list(1:EPISODES*2);
    end
    
    cd data/afdb
    
    %for every ECG here the preprocessed samples will be collected
    short_samples_preproc = []; 
    while length(ann_list)>1
        
        % consider only the signal from NR to the first AF!
        if ann_list(1) == 0 && ann_list(2) == 1
            
            filename = [list{1, index_list} 'm'];
            [tm, signal,FS, labels] = rdmat(filename);
            
            % keep only the first ECG
            signal = signal(:,1);
            
            % select only the normal ECG part, previous to AF
            signal = signal(time_ann{index_list}(1):time_ann{index_list}(2)-1);

            % change sample frequency from 128Hz to 120Hz
            [P, Q] = rat(120/250);
            signal = resample(signal, P, Q);

            % bandpass filter (check if the interval is correct)
            signal = bandpass(signal, [1 28], 120);

            %obtain short-term 30s ECGs (120Hz * 30s = 3600 -> length of each sample)
            short_samples = [];
            index = 1;
            sample_size = 3600;
            while (index <= length(signal))
                % every column in 'short_samples' is a 30s sample!
                if index+sample_size-1 <= length(signal)
                    short_samples = [short_samples signal(index:index+sample_size-1)];
                end
                index = index+sample_size;
            end

            ss_dim = size(short_samples);
            for i = 1:ss_dim(2)

                signal = short_samples(:, i);
                if (length(signal) < sample_size)
                    signal(numel(zeros(sample_size, 1))) = 0;
                end

                % apply discrete wavelet transform, using 'haar'
                [a, d] = haart(signal);

                % obtain a signal with length = 1*900
                signal = d{1, 2};
                assert(length(signal) == 900)

                short_samples_preproc = [short_samples_preproc signal];

            end
            
            ann_list = ann_list(3:length(ann_list));
            time_ann{index_list} = time_ann{index_list}(3:length(time_ann{index_list}));
            
        else
            % in the case we did not have NR followed by AF
            ann_list = ann_list(2:length(ann_list));
            time_ann{index_list} = time_ann{index_list}(2:length(time_ann{index_list}));
        end
    end
    
    if length(short_samples_preproc) > 0
        ssp_dim = size(short_samples_preproc);
        tot_samples = tot_samples + ssp_dim(2);

        cd ../../preproc_data/afdb
        filename = [filename '.csv'];
        writematrix(short_samples_preproc, filename);
        cd ../../data/afdb
    end
    
end

