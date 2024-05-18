clc
clear variables
close all

% 4 class classification
folders = {'BLUETOOTH', 'ZIGBEE', 'WLANbg', 'WLANnac'};

% WLANac settings classification
%folders = {'WLANnacBPSK', 'WLANnacQPSK', 'WLANnacQAM16', 'WLANnacQAM256'};

% 7 class classification
%folders = {'BLUETOOTH', 'ZIGBEE', 'WLANbg', 'WLANnac', 'BluetoothWLANnac', 'BluetoothWLANbg', 'ZigBeeWLANbg'};

% 8 class classification
%folders = {'BLUETOOTH', 'ZIGBEE', 'WLANbg', 'WLANnac', 'BluetoothWLANnac', 'BluetoothWLANbg', 'ZigBeeWLANbg', 'BluetoothWLANnacZigBee'};

sizes_dim = [];
truncated_data = struct();  % comment this to add new data to the output instead of overwriting

for f = 1:length(folders)
    files = dir(fullfile(folders{f}, '*.mat')); % Getting the list of all .mat files

    for i = 1:length(files)
        %% Loading data
        disp(files(i).name); %just displaying the names
        filename = fullfile(folders{f}, files(i).name);
        raw_data = load(filename);
        %impairments = raw_data.waveStruct.impairments;
        %% Creating the 3D matrices 
        
        % Ensure the sample size is the same as the desired packet length in generation scripts!
        samples = 256; 
        split_data = [real(raw_data.waveStruct.waveform), imag(raw_data.waveStruct.waveform)];
        [r, c] = size(split_data);
        reshaped_data = permute(reshape(split_data',[c,samples,r/samples]),[2,1,3]);
    
    
        %% Putting the data into dictionaries
        key = files(i).name;  
        key = key(1:end-4);                 % extracting ".mat"               
        scatterplot(reshaped_data(:,:,1))
        fieldName = strrep(key, '_', ' ');  % Replace underscore with minus for plotting
        title(' ')
        %title(strcat('Constellation Diagram of',{' '}, fieldName))
        key = strrep(key, '-', '_');  % Replace minus with underscore
        structured_data.(key) = reshaped_data; % Convert to a valid field name

        const_saving_path = fullfile(folders{f},'Constellation Diagrams v1');
        if ~exist(const_saving_path, 'dir')
            mkdir(const_saving_path);
        end
        %savefig(fullfile(const_saving_path, [fieldName, '.png']));    % saving the constelation diagrams
        print(fullfile(const_saving_path, [fieldName, '.png']), '-dpng');
        print(fullfile(const_saving_path, [fieldName, '.svg']), '-dsvg');
        print(fullfile(const_saving_path, [fieldName, '.eps']), '-depsc');
    
    end


    %% Truncating the data so all signals have the same sample size

    fn = fieldnames(structured_data);
    dimensions = [];

    for k = 1:numel(fn)
        A = size(structured_data.(fn{k}));
        dimensions = [dimensions, A(3)];
    end
    %% Making sure both folders have same amount of data
    smallest_dim = min(dimensions);
    sizes_dim = [sizes_dim smallest_dim];
    smallest_dim = min(sizes_dim);

    %% Possibility to add new data to dataset
    for j = 1:numel(fn)
        % Check if the field already exists in truncated_data
        if isfield(truncated_data, fn{j})

            new_data = structured_data.(fn{j})(:,:,1:smallest_dim);
            existing_data = truncated_data.(fn{j})(:,:,1:smallest_dim);
            
            % Append new_data to existing_data
            truncated_data.(fn{j}) = cat(3, existing_data, new_data);
        else
            % If the field doesn't exist in truncated_data, simply add it
            % Truncate to smallest_dim before adding
            truncated_data.(fn{j}) = structured_data.(fn{j})(:,:,1:smallest_dim);
        end

    % scatterplot(truncated_data.(fn{j})(:,:,1))
    % fieldName = strrep(key, '_', ' ');  % Replace underscore with space
    % title(strcat('Constellation Diagram of',{' '}, fieldName))

    end
    
    % Clear structured_data to prepare for the next folder's data
    % This is crucial to avoid carrying over data from the previous folder
    clear structured_data;
    structured_data = struct();
end

