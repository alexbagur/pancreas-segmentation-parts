function partssegpath = segpartskmeans(segpath)
%SEGPARTSKMEANS Pancreas head, body, tail segmentation using the approach
%in Fontana et al, 2016 (https://doi.org/10.1120/jacmp.v17i5.6236) based on k-means
%   
%   Example:
%       SEGPARTSKMEANS('./example_data/pancreas_seg.nii.gz')
%   
% Alex Bagur, 2022
[wholeseg, XYZmm] = spm_read_vols(spm_vol(segpath));
wholesegcoords = XYZmm(:,wholeseg>0);

% Run kmeans with 3 clusters (head, body, tail parts)
rng(0)
idx = kmeans(wholesegcoords', 3);
partsseg = wholeseg;
partsseg(wholeseg==1)=idx;

% In case head, body, tail cluster indices do not correspond to labels
% 1, 2, 3, respectively, reassign labels
% Use Centroid for robustness instead of 1 voxel
Centroids = regionprops3(partsseg).Centroid;
% Down-most part is Head (lowest Z)
[~,currentheadlabel]=min(Centroids(:,3));
partsseg(partsseg==currentheadlabel)=4;
% Right-most part is Tail (highest Y)
[~,currenttaillabel]=max(Centroids(:,2));
partsseg(partsseg==currenttaillabel)=6;
% Rest is Body
uvals = unique(partsseg);
currentbodylabel = uvals(uvals~=0 & uvals~=4 & uvals~=6);
partsseg(partsseg==currentbodylabel)=5;
% Reassign
partsseg(partsseg==4)=1;
partsseg(partsseg==5)=2;
partsseg(partsseg==6)=3;

% Write output
partssegpath = strrep(segpath,'.nii','_parts_kmeans.nii');
partssegvol = spm_vol(segpath); partssegvol.fname = partssegpath;
partssegvol.dt(1) = 64; % change data type to double
partssegvol.descrip = 'Parts segmentation using kmeans method';
spm_write_vol(partssegvol, partsseg);
end

