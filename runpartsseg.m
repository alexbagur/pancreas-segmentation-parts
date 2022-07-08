function partssegpath = runpartsseg( segpath, method )
%RUNPARTSSEG Runs most up-to-date parts segmentation
% segpath needs to be isotropic resolution for the SPM12 methods to work
% 
%   RUNPARTSSEG( segpath ) runs parts segmentation via registration to a
%   group template (https://doi.org/10.1002/jmri.28098)
%   
%   RUNPARTSSEG( segpath, method ) specifies which method for parts
%   segmentation to run. Available are 'gwr' [default] and 'kmeans'.
%   
% Alex Bagur, 2022
arguments
    segpath
    method = 'gwr'
end

% File exists
if ~isfile(segpath)
    error('File does not exist')
end

% Work with .nii
if ~endsWith(segpath,'.nii.gz')
    error('Needs .nii.gz format to work')
end

% ISOTROPIC data check
if numel(unique(niftiinfo(segpath).PixelDimensions))>1
    error('Non-isotropic data found. Current method only works with isotropic data. Check PixelDimensions.')
end

% Work with .nii
segpathnii = gunzip(segpath);
segpathnii = segpathnii{1};

switch method
    case 'gwr'
        % Preprocessing: Align to ref image and crop to template size
        alignToCentroid(segpathnii);
        % Run groupwise registration-based parts-seg
        partssegpathnii = segpartsgwr(segpathnii);
        % Realign again to subject by padding + translation
        alignToCentroidInverse(partssegpathnii, strrep(segpathnii,'.nii','.nii.gz'));
    case 'kmeans'
        % Fontana et al 2016 method
        partssegpathnii = segpartskmeans(segpathnii);
    otherwise
        error(['Unsupported method ' method '.'])
end

%% Housekeeping
partssegpath = gzip(partssegpathnii); % gzip partsseg and delete nii
delete(partssegpathnii)
delete(segpathnii) % delete intermediate files

end
