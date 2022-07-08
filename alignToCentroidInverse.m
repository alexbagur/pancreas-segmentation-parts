function seg2data_translated_back = alignToCentroidInverse( seg2, seg2_original )
% ALIGNTOCENTROIDINVERSE padding and translation back to subject space
% 
% Alex Bagur, 2022
arguments
    seg2
    seg2_original
end

seg2_original = spm_vol(seg2_original);
seg2 = spm_vol(seg2);

seg1data = double(spm_read_vols(seg2_original)>0);
seg2data = double(spm_read_vols(seg2));
disp('Original'); disp(sum(seg2data(:)>0))

% % % % % % % This should be equal to the original segmentation 2mm
% Padding
seg2data_padded = padarray(seg2data, size(seg1data)-size(seg2data), 0, 'pre');

% Translate to centroid of reference image
c1 = regionprops3(keeplargest(logical(seg1data))).Centroid;
c2 = regionprops3(keeplargest(seg2data_padded>0)).Centroid;
seg2data_translated_back = double(imtranslate(seg2data_padded,c1-c2,'nearest'));
disp('Translated back'); disp(sum(seg2data_translated_back(:)>0))
% % % % % % % % % % % % % % % % % % % % % % % % % 

% QC: check you are not cropping nonzero voxels
assert(sum(seg2data(:)>0)==(sum(seg2data_translated_back(:)>0)), ...
    'Error: you have cropped the segmentation!')

% Write to NIfTI file
seg2.dim = size(seg2data_translated_back);
seg2.mat = seg2_original.mat;
spm_write_vol( seg2, seg2data_translated_back );

end