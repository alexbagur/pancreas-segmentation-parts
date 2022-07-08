function seg2data_cropped = alignToCentroid( seg2path, refsegpath )
% ALIGNTOCENTROID cropping and translation to ref image for manageable
% parts-seg.
% 
% Alex Bagur, 2022
arguments
    seg2path
    refsegpath = [fileparts(mfilename('fullpath')) '/data_ref/ref_seg.nii.gz']
end

% Work with .nii
refsegpathnii = gunzip(refsegpath);
refsegpathnii = refsegpathnii{1};

ref_seg = spm_vol(refsegpathnii);
seg2 = spm_vol(seg2path);

seg1data = double(spm_read_vols(ref_seg)>0);
seg2data = double(spm_read_vols(seg2)>0);

%
% Pad first
seg2data = padarray( seg2data, 25*ones(1,3), 0, 'pre' );
seg2data = padarray( seg2data, 25*ones(1,3), 0, 'post' );

% Translate to centroid of reference image
c1 = regionprops3(keeplargest(logical(seg1data))).Centroid;
c2 = regionprops3(keeplargest(logical(seg2data))).Centroid;
seg2data_translated = double(imtranslate(seg2data,c1-c2,'nearest'));

% Cropping
bbV = regionprops3( seg1data ).BoundingBox;
ref_img_half_size = ceil(bbV(4:6)*0.75);
cuboid_to_crop_to = [bbV(1:3)-ref_img_half_size bbV(4:6)+2*ref_img_half_size];
seg2data_cropped = imcrop3(seg2data_translated, cuboid_to_crop_to);

% QC: check you are not cropping nonzero voxels
assert(sum(seg2data(:))==(sum(seg2data_cropped(:))), ...
    'Error: you have cropped the segmentation!')

% Write to NIfTI file
seg2.dim = size(seg2data_cropped);
seg2.mat = ref_seg.mat;
spm_write_vol( seg2, seg2data_cropped );

end