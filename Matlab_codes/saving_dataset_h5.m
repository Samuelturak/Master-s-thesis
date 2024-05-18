%% Assuming you keep truncated_data saved in your WORKSPACE
% Choose your own folder to save
filename = 'Final_dataset/Final_dataset_v2.h5';
fieldNames = fieldnames(truncated_data);
for i = 1:numel(fieldNames)
    datasetName = strcat('/', fieldNames{i}); % Create a unique name for each dataset
    dataMatrix = truncated_data.(fieldNames{i});
    h5create(filename, datasetName, size(dataMatrix), 'Datatype', 'double');
    h5write(filename, datasetName, dataMatrix);
end
