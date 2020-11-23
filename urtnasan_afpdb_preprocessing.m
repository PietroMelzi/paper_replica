cd data/afpdb
% get data from physionet
list = physionetdb('afpdb');
list = list(1:2:200);
% for i = 1:length(list)
%     wfdb2mat(['afpdb/' list{1,i}])
% end

for index_list = 1:length(list)
    filename = [list{1, index_list} 'm'];
    [tm, signal,FS, labels] = rdmat(filename);

    % keep only the first ECG
    signal = signal(:,1);

    % change sample frequency from 128Hz to 120Hz
    [P, Q] = rat(120/128);
    signal = resample(signal, P, Q);

    % bandpass filter (check if the interval is correct)
    signal = bandpass(signal, [8 20], 120);

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

    short_samples_preproc = [];
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

%     cd ../../preproc_data/afpdb
%     filename = [filename '.csv'];
%     writematrix(short_samples_preproc, filename);
%     cd ../../data/afpdb
end