%% Clear everything

clear; close all;

%% Collect neuron activity data

parts = strsplit(pwd, '\');
fname = [parts{end} '_All'];
framenum = 60;
[GCaMP, RFP, ratio, ratio_norm] ...
    = collect_neurons_data(pwd, framenum);
save(fname, 'GCaMP', 'RFP', 'ratio', 'ratio_norm');