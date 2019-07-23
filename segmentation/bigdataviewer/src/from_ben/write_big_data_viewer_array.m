function result = write_big_data_viewer_array(path, I, options)
% Save dataset as an .h5 along with an .xml using the BigDataViewer format of Fiji
%
% The format description: http://fiji.sc/BigDataViewer#About_the_BigDataViewer_data_format
%
% Parameters:
% filename: name of the file: xml or h5
% options:  [@em optional], a structure with extra parameters
%   .ChunkSize - [@em optional], a matrix that defines chunking layout
%   .Deflate - [@em optional], a number that defines gzip compression level (0-9).
%   .SubSampling - [@em optional], a matrix that defines scaling factor for
%          the image pyramid (for example, [1,1,1; 2,2,2; 4,4,4] makes 3 levels)
%   .ResamplingMethod - [@em optional], a string that defines resampling method
%   .t - time point, when time point > 1, the dataset will be added to the exising
%   .lutColor - [@em optional], a matrix with definition of color channels [1:colorChannel, R G B], (0-1)
%   .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
%   .ImageDescription - [@em optional], a string with description of the dataset
%
% Return values:
% result: @b 0 - fail, @b 1 - success

%| 
% @b Examples:
% @code result = saveBigDataViewerFormat('mydataset.h5', I, options);  // save dataset @endcode

% Copyright (C) 31.01.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

result = 0;
if nargin < 3; options = struct(); end;

[p,d,~] = fileparts(path);
h5_filename = fullfile(p,d,[d '.h5']);
xml_filename = fullfile(p,d,[d '.xml']);

options.Datatype = class(I);     % Possible: double,uint64,uint32,uint16,uint8,single,int64,int32,int16,int8

% check options
if ~isfield(options, 'ChunkSize'); options.ChunkSize = 64*[1;1;1]; end;
if ~isfield(options, 'Deflate'); options.Deflate = 0; end;
if ~isfield(options, 'SubSampling'); options.SubSampling = [1;1;1]; end;
if ~isfield(options, 'ResamplingMethod'); options.ResamplingMethod = 'bicubic'; end;
if ~isfield(options, 't'); options.t = 1; end;
if ~isfield(options, 'showWaitbar'); options.showWaitbar = false; end;

height = size(I,1);
width = size(I,2);
depth = size(I,3);
colors = size(I,4);
time = size(I,5);

% check data class
availableClassesList = {'double','uint64','uint32','uint16','uint8','single','int64','int32','int16','int8'};
if ~ismember(options.Datatype, availableClassesList)
    errordlg(sprintf('!!! Error !!!\n\nWrong data class (%s)!\nAvailable classes:\ndouble,uint64,uint32,uint16,uint8,single,int64,int32,int16,int8', options.Datatype), 'Wrong class');
    return;
end


% convert to int16 (the only class accepted by BDV)
if isa(I, 'int16') == 0
    if isa(I, 'uint8')
        I = uint16(I);
    end
    
    I = int16(I);
    options.Datatype = 'int16';
end

noLevels = size(options.SubSampling,2);
noDims = size(options.SubSampling,1);

if size(options.ChunkSize, 2) ~= noLevels   % when chunk size is defined for one level, use it for all levels
    options.ChunkSize = repmat(options.ChunkSize,[1, noLevels]);
end

if options.t(1) == 1
    if exist(h5_filename, 'file')==2; delete(h5_filename); end;
    
    
    for colId = 1:colors
        % generate s00, s01... datasets with resolutions and subdivisions
        datasetName = sprintf('/s%02i/resolutions', colId-1);
        h5create(h5_filename, datasetName, [noDims, noLevels], 'Datatype', 'double','ChunkSize', [noDims, 1]);
        h5write(h5_filename, datasetName, options.SubSampling);
        %h5create( Filename, datasetName, [Inf, Inf], 'Datatype', 'double','ChunkSize', [noDims, 1]);
        %h5write(h5Filename, datasetName, options.subSampling, [1 1], [noDims 1]);

        datasetName = sprintf('/s%02i/subdivisions', colId-1);
        h5create(h5_filename, datasetName, [noDims, noLevels], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
        h5write(h5_filename, datasetName, int32(options.ChunkSize));
        %h5create(h5Filename, datasetName, [Inf, Inf], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
        %h5write(h5Filename, datasetName, int32(options.ChunkSize), [1 1], [noDims 1]);
        
        if isfield(options, 'lutColors')
            datasetName = sprintf('/s%02i/color', colId-1);
            h5create(h5_filename, datasetName, [noDims, 1], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
            h5write(h5_filename, datasetName, int32(options.lutColors(colId,:))');
        end
    end
    
    % storing image desciption field
    if isfield(options, 'ImageDescription')
        file_id = H5F.open(h5_filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
        space_id = H5S.create('H5S_SCALAR');
        stype = H5T.copy('H5T_C_S1');
        sz = numel(options.ImageDescription);
        H5T.set_size(stype,sz);
        dataset_id = H5D.create(file_id,'/ImageDescription', stype,space_id,'H5P_DEFAULT');
        H5D.write(dataset_id,stype,'H5S_ALL','H5S_ALL','H5P_DEFAULT', options.ImageDescription);
        H5D.close(dataset_id)
        H5S.close(space_id)
        H5F.close(file_id);
    end
end

index = 1;
% main data loop
for timeId = 1:size(I, 5)
    timeId2 = options.t(1) + timeId - 1;
    for colId = 1:colors
        for levelId = 1:noLevels
            newH = round(height/options.SubSampling(1,levelId));
            newW = round(width/options.SubSampling(2,levelId));
            newZ = round(depth/options.SubSampling(3,levelId));
            
            % % --------- resize dataset
            if newW ~= width || newH ~= height || newZ ~= depth  
                if options.showWaitbar;    waitbar(0.2, wb); end;
                resizeOpt.height = newH;
                resizeOpt.width = newW;
                resizeOpt.depth = newZ;
                resizeOpt.method = options.ResamplingMethod;
                resizeOpt.algorithm = 'imresize';
                imgOut = squeeze(mibResize3d(I(:, :, :, colId, timeId), [], resizeOpt));
            else
                imgOut = squeeze(I(:, :, :, colId, timeId));
            end
            
            datasetName = sprintf('/t%05i/s%02i/%d/cells', timeId2-1, colId-1, levelId-1);
            
            % make sure that ChunkSize smaller than size of the dataset
            ChunkSize = zeros(size(options.ChunkSize(:,levelId)'));
            for i=1:noDims
                ChunkSize(i) = min([options.ChunkSize(i,levelId) size(imgOut, i)]);
            end
            if options.showWaitbar;    waitbar(0.6, wb); end;
            h5create(h5_filename, datasetName, [newH, newW, newZ], ...
                'Datatype', options.Datatype, 'ChunkSize', ChunkSize, 'Deflate', options.Deflate);
            h5write(h5_filename, datasetName, imgOut);
            %h5create(h5Filename, datasetName, [Inf, Inf, Inf], ...
            %    'Datatype', options.Datatype, 'ChunkSize', ChunkSize, 'Deflate', options.Deflate);
            %h5write(h5Filename, datasetName, imgOut, [1 1 1], [newH, newW, newZ]);
            
            index = index + 1;
            if options.showWaitbar;    waitbar(1, wb); end;
         end
    end
end
if options.showWaitbar;    delete(wb); end;


%% Save XML header

result = 0;

options.height = height;
options.width = width;
options.colors = colors;
options.depth = depth;
options.time = time;
options.pixSize.x = 1;
options.pixSize.y = 1;
options.pixSize.z = 1;
options.pixSize.units = '�m';
options.lutColors = [0, 1, 0; 1, 0, 1];

if ~isfield(options, 'Format'); options.Format = 'bdv.hdf5'; end;
if ~isfield(options, 'DatasetName'); 
    options.DatasetName = '\MIB_Export'; 
else
    if options.DatasetName(1) ~= '/'
        options.DatasetName = ['/' options.DatasetName];
    end
end;


% saving xml file
% A structure containing:
% s.XMLname.Attributes.attrib1 = "Some value";
% s.XMLname.Element.Text = "Some text";
% s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
% s.XMLname.DifferentElement{1}.Text = "Some more text";
% s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
% s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
% s.XMLname.DifferentElement{2}.Text = "Even more text";
%
% Will produce:
% <XMLname attrib1="Some value">
%   <Element>Some text</Element>
%   <DifferentElement attrib2="2">Some more text</Element>
%   <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
% </XMLname>

%delete([baseName '.xml']);

s = struct();
s.SpimData.AttributesText.version = '0.2';
s.SpimData.BasePath.Text = '.';
s.SpimData.BasePath.AttributesText.type = 'relative';

s.SpimData.SequenceDescription.ImageLoader.AttributesText.format = options.Format;
s.SpimData.SequenceDescription.ImageLoader.hdf5.Text = [baseName '.h5'];
s.SpimData.SequenceDescription.ImageLoader.hdf5.AttributesText.type = 'relative';
s.SpimData.SequenceDescription.ImageLoader.Datasetname.Text= options.DatasetName;

% add extra field with image description
if isfield(options, 'ImageDescription')
    s.SpimData.SequenceDescription.ViewSetups.ImageDescription.Text = options.ImageDescription;
end
% generate list of materials and their colors
if isfield(options, 'ModelMaterialNames')
    for matId = 1:numel(options.ModelMaterialNames)
        s.SpimData.SequenceDescription.ViewSetups.Materials.(sprintf('Material%03i',matId)).Name.Text = options.ModelMaterialNames{matId};
        s.SpimData.SequenceDescription.ViewSetups.Materials.(sprintf('Material%03i',matId)).Color.Text = num2str(options.lutColors(matId,:));
    end
end

s.SpimData.SequenceDescription.ViewSetups.Attributes.AttributesText.name = 'channel';
    
% color channel section
for colId = 1:options.colors
    s.SpimData.SequenceDescription.ViewSetups.Attributes.Channel{colId}.id.Text = num2str(colId);
    s.SpimData.SequenceDescription.ViewSetups.Attributes.Channel{colId}.name.Text = num2str(colId);

    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.id.Text = num2str(colId - 1);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.name.Text = sprintf('channel %d', colId);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.size.Text = sprintf('%d %d %d', options.height, options.width, options.depth);
    if isfield(options, 'pixSize')
        s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.voxelSize.unit.Text = options.pixSize.units;
        s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.voxelSize.size.Text = sprintf('%f %f %f', options.pixSize.y, options.pixSize.x, options.pixSize.z);
    end
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.attributes.channel.Text = num2str(colId);
    
    % add extra field with information about color channel
    if isfield(options, 'lutColors')
        s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.color.Text = num2str(options.lutColors(colId,:));
    end
end

% time points setup
s.SpimData.SequenceDescription.Timepoints.AttributesText.type = 'range';
s.SpimData.SequenceDescription.Timepoints.first.Text = '0';
s.SpimData.SequenceDescription.Timepoints.last.Text = num2str(options.time-1);

% registration section
index = options.time*options.colors;    % index of the registration to store
for t=(options.time-1):-1:0
    for colId = (options.colors-1):-1:0
        s.SpimData.ViewRegistrations.ViewRegistration{index}.AttributesText.timepoint = num2str(t);
        s.SpimData.ViewRegistrations.ViewRegistration{index}.AttributesText.setup = num2str(colId);
        s.SpimData.ViewRegistrations.ViewRegistration{index}.ViewTransform.AttributesText.type = 'affine';
        if isfield(options, 'pixSize')
            s.SpimData.ViewRegistrations.ViewRegistration{index}.ViewTransform.affine.Text = ...
                sprintf('%f 0.0 0.0 0.0 0.0 %f 0.0 0.0 0.0 0.0 %f 0.0', options.pixSize.y, options.pixSize.x, options.pixSize.z);
        end
        index = index - 1;
    end
end
struct2xml(s, xml_filename);
result = 1;

end

