function BW2 = keeplargest(BW, N)
%KEEPLARGEST Keep largest component of a binary mask.
%   BW2 = KEEPLARGEST(BW) extracts the largest component of the mask BW.
%   
%   BW2 = KEEPLARGEST(BW, N) extracts the largest N components.
% 
%   bwconncomp uses 8-connectivity for 2D, 26-connectivity for 3D.
%   
% Alex Bagur, 2022
arguments
    BW
    N = 1
end
CC = bwconncomp(BW);
if CC.NumObjects<N
    warning(['There are not as many as N=' num2str(N) ' components in the mask (' ...
        num2str(CC.NumObjects) ' present). No changes done to input mask.'])
    BW2 = BW;
    return
end
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idxs] = sort(numPixels,'descend');
BW2 = false(size(BW));
for nn=1:N % take N largest components
BW2(CC.PixelIdxList{idxs(nn)}) = true;
end