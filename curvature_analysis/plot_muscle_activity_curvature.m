%% Determine curvature direction if necessary

filename = uigetfile('.mat');

if isempty(filename)
    
    fprintf('No file is chosen. \n');

else
    
    load(filename);
    close all;
    curvdataBody = curvdatafiltered;

    figure;
    subplot(141); hold on;
    plot(dorsal_data{1,1}, dorsal_data{2,1}, 'r');
    plot(ventral_data{1,1}, ventral_data{2,1}, 'b');
    plot(centerline_data_spline(:,1), centerline_data_spline(:,2), 'k');
    plot(centerline_data_spline(1,1), centerline_data_spline(1,2), 'og');
    plot(centerline_data_spline(end,1), centerline_data_spline(end,2), 'oy');
    set(gca, 'ydir', 'reverse');
    subplot(142); imagesc(curvdataBody); title('Curvature');
    subplot(143); imagesc(dorsal_smd./dorsal_smd_r); title('Dorsal activity');
    subplot(144); imagesc(ventral_smd./ventral_smd_r); title('Ventral activity');
    
    answer = questdlg('Flip curvature data?', 'Sign of curvature', ...
        'No', 'Yes', 'No');
    if isequal(answer,'Yes')
        curvdataBody = -curvdatafiltered;
        fprintf('Curvature data is flipped. \n');
        subplot(142); imagesc(curvdataBody); title('Curvature after flipping');
        data_path_name = fullfile(pwd, ['cur-corrected_' filename(1:end-4) '.mat']);
        save(data_path_name, 'curvdataBody');
        fprintf('data saved. \n');
    elseif isequal(answer,'No')
        fprintf('Curvature data remains unchanged. \n');
        data_path_name = fullfile(pwd, ['cur-corrected_' filename(1:end-4) '.mat']);
        save(data_path_name, 'curvdataBody');
        fprintf('data saved. \n');
    end
    
end

%% Select files if curvature already curated

filenamea = uigetfile('*.mat', 'Select activity file');
load(filenamea);
filenamec = uigetfile('*.mat', 'Select curvature file');
load(filenamec);
filename = filenamea;

%% Generate figures

prompt = {'Minimum of activity','Maximum of activity', ...
    'Minimum of curvature','Maximum of curvature'};
inputdlgtitle = 'Range and channel order';
dims = [1 35];
definput = {'0','2','-15', '15'};
answer = inputdlg(prompt,inputdlgtitle,dims,definput);

quest = 'GFP and RFP channel flipped?';
questdlgtitle = 'Channel order'; 
flp = questdlg(quest, questdlgtitle, 'Yes', 'No', 'No');

minia = str2double(answer{1});
maxia = str2double(answer{2});
minic = str2double(answer{3});
maxic = str2double(answer{4});
body = 35;

switch flp
    case 'Yes'
        ratio_d = dorsal_smd_r./dorsal_smd;
        ratio_v = ventral_smd_r./ventral_smd;
    case 'No'
        ratio_d = dorsal_smd./dorsal_smd_r;
        ratio_v = ventral_smd./ventral_smd_r;
end


close all;
s(1) = figure(1);
imagesc(ratio_d); 
caxis([minia maxia]); colorbar; colormap(plasma);
set(gca, 'ticklength', [0 0], 'xticklabel', [], 'yticklabel', []);
hold on;
plot(1:size(dorsal_smd,2), body*ones(size(dorsal_smd,2)), ':k');
s(2) = figure(2);
imagesc(ratio_v); 
caxis([minia maxia]); colorbar; colormap(plasma);
set(gca, 'ticklength', [0 0], 'xticklabel', [], 'yticklabel', []);
hold on;
plot(1:size(dorsal_smd,2), body*ones(size(dorsal_smd,2)), ':k');
s(3) = figure(3);
imagesc(curvdataBody); 
caxis([minic maxic]); colorbar; colormap(viridis);
set(gca, 'ticklength', [0 0], 'xticklabel', [], 'yticklabel', []);
hold on;
plot(1:size(dorsal_smd,2), body*ones(size(dorsal_smd,2)), ':k');

%% Add contour to the figures if necessary

hold on;
thr = 11; 
M = contour(curvdataBody, [thr thr]);
plot(M(1,2:end), M(2,2:end), ':k', 'linewidth', 1);

%% Save figures

answer = questdlg('Subfolder exists?', 'Subfolder', 'Yes', 'No', 'No');
switch answer
    case 'Yes'
        subfd = 1;
    case 'No'
        subfd = 0;
end

parts = strsplit(pwd, '\');
data_path_fig = fullfile(parts{1,1:end-2-subfd}, 'Alpha_Data_Plot', parts{1,end-subfd});
warning('off'); mkdir(data_path_fig); 
data_path_name_fig = fullfile(data_path_fig, [filename(1:end-4) '.mat']);
savefig(s, [data_path_name_fig(1:end-4) '_act-cur.fig']);
saveas(s(1), [data_path_name_fig(1:end-4) '_act_dorsal.tif'], 'tiffn');
saveas(s(2), [data_path_name_fig(1:end-4) '_act_ventral.tif'], 'tiffn');
saveas(s(3), [data_path_name_fig(1:end-4) '_cur.tif'], 'tiffn');
fprintf('figures saved. \n');
