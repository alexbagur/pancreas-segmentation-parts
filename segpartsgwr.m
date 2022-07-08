function partssegpath = segpartsgwr( segpath )
%SEGPARTSGWR Parts segmentation using registration to a template generated
%using groupwise registration (GWR).
% 
%   Example: 
%       SEGPARTSGWR('./example_data/pancreas_seg.nii.gz')
%   
% Alex Bagur, 2022
thisscriptdir = fileparts(mfilename('fullpath'));
partstemplatepath = [thisscriptdir '/templates/Template_4_parts_seg.nii.gz'];

% Work with .nii
if endsWith(segpath,'.nii.gz')
    segpath = gunzip(segpath);
    segpath = segpath{1};
end
if endsWith(partstemplatepath,'.nii.gz')
    partstemplatepath = gunzip(partstemplatepath);
    partstemplatepath = partstemplatepath{1};
end

[folder,name,ext]=fileparts(segpath);

% Output files
outputDir = [folder filesep name '-gwr_output'];
mkdir(outputDir)

%% Calculate deformation map from subject to template
% Creates file y_*_Template.nii
ypath = [outputDir filesep 'y_' name '_Template' ext];
if ~isfile(ypath)
job.images = {{segpath}};
gunzip([thisscriptdir '/templates/Template_0.nii.gz'])
gunzip([thisscriptdir '/templates/Template_1.nii.gz'])
gunzip([thisscriptdir '/templates/Template_2.nii.gz'])
gunzip([thisscriptdir '/templates/Template_3.nii.gz'])
gunzip([thisscriptdir '/templates/Template_4.nii.gz'])
job.templates = { [thisscriptdir '/templates/Template_0.nii'], ...
                  [thisscriptdir '/templates/Template_1.nii'], ...
                  [thisscriptdir '/templates/Template_2.nii'], ...
                  [thisscriptdir '/templates/Template_3.nii'], ...
                  [thisscriptdir '/templates/Template_4.nii'], ...
                  };
spm_shoot_warp(job);
movefile([folder filesep 'j_' name '_Template' ext], [outputDir filesep 'j_' name '_Template' ext])
movefile([folder filesep 'v_' name '_Template' ext], [outputDir filesep 'v_' name '_Template' ext])
movefile([folder filesep 'y_' name '_Template' ext], ypath)
end

%% Warp template with parts labels to subject space
%% 1. Calculate inverse of deformation maps 
% Creates files y_iy_*.nii
iyname = ['iy_' name '_Template' ext];
iypath = [outputDir '/y_' iyname];
comp_y_iy_name = ['comp_y_' iyname];
comp_y_iy_path = [outputDir '/y_' comp_y_iy_name];

% Run Utils>Composition>Inverse
clear job
job.comp{1}.inv.comp{1}.def = {ypath};
job.comp{1}.inv.space = {segpath};
job.out{1}.savedef.ofname = iyname;
job.out{1}.savedef.savedir.saveusr = {outputDir};
spm_deformations(job);

% Check that composing deformation map with its inverse gives Identity
% Creates files comp_y_iy_*.nii
clear job
job.comp{1}.def = {ypath};
job.comp{2}.def = {iypath};
job.out{1}.savedef.ofname = comp_y_iy_name;
job.out{1}.savedef.savedir.saveusr = {outputDir};
spm_deformations(job);

%% 2. Apply inverse deformation to template (with parts segmentation)
% Apply inverse deformation map to template image with parts segmentation
[~,tname,ext]=fileparts(partstemplatepath);
ipartstemplatepath = [outputDir '/i' tname ext];

% Run Pullback method
clear job
job.comp{1}.def = {iypath};
job.out{1}.pull.fnames = {partstemplatepath};
job.out{1}.pull.savedir.saveusr = {outputDir};
job.out{1}.pull.interp = -1; % -1: Categorical, 0: NN
job.out{1}.pull.mask = 0;
job.out{1}.pull.fwhm = [0 0 0];
job.out{1}.pull.prefix = 'i';
spm_deformations(job);

%% Subject parts segmentation in template space
% Nearest-neighbor approach
[~,partssegpath] = segpartsnn(segpath, ipartstemplatepath);

% Remove intermediate files
delete([thisscriptdir '/templates/Template_0.nii'])
delete([thisscriptdir '/templates/Template_1.nii'])
delete([thisscriptdir '/templates/Template_2.nii'])
delete([thisscriptdir '/templates/Template_3.nii'])
delete([thisscriptdir '/templates/Template_4.nii'])
delete([thisscriptdir '/templates/Template_4_parts_seg.nii'])
rmdir(outputDir,'s') 

close all

end

function [partsseg, partssegpath] = segpartsnn( segpath, partstemplatepath )
%SEGPARTSNN Takes binary segmentation in segpath registered to template
%with parts segmentation and segments in template space
% 
% Does label propagation 
% 
arguments
    segpath
    partstemplatepath
end
partstemplate = spm_read_vols(spm_vol(partstemplatepath));
svol = spm_read_vols(spm_vol(segpath));

% Nearest-neighbour
% For each query point (subject point), find closest point in template and
% its part label
[I1,I2,I3] = ind2sub(size(svol), find(svol > 0.5));
[Q1,Q2,Q3] = ind2sub(size(partstemplate), find(partstemplate > 0));

ttvol = partstemplate(partstemplate>0);
Idx = knnsearch([Q1,Q2,Q3], [I1,I2,I3]); ttvol(Idx);
partsseg = double(svol > 0.5);
partsseg(partsseg>0) = ttvol(Idx);

% Write output
partssegpath = strrep(segpath,'.nii','_parts_gwr.nii');
partssegvol = spm_vol(segpath); partssegvol.fname = partssegpath;
partssegvol.dt(1) = 64; % change data type to double
partssegvol.descrip = 'Parts segmentation using groupwise registration method';
spm_write_vol(partssegvol, partsseg);
end
