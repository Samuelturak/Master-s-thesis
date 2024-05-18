% Choose your own folder to save
fid = fopen('Final_dataset/Final_dataset_v2.dat', 'w');

% Check if the file was opened successfully
if fid == -1
    error('Unable to open file for writing.');
end
% Write data to the file
fieldNames = fieldnames(truncated_data);
for i = 1:numel(fieldNames)
    fprintf(fid, 'Data for %s:\n', fieldNames{i});
    dataMatrix = truncated_data.(fieldNames{i});
    fprintf(fid, '%f ', dataMatrix);  % Modify the format specifier as needed
    fprintf(fid, '\n');

end
% Close the file
fclose(fid);