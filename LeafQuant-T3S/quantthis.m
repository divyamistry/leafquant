function [min_val, pos10, pos25, pos50, pos75, pos90, max_val, mean_val, area_selected, percent] = quantthis(J, h, showProcessedRegions, exposureVal)

% draw an ellipse to indicate where the selection was made
rectangle('Position',h.getPosition(),'Curvature',[1,1],'EdgeColor','y', 'LineWidth',2);

% crop the selection into a new image for quantification
crop_xy_coord = min(h.getVertices);
crop_wl = max(h.getVertices);
crop_wl = crop_wl - crop_xy_coord;
croprect = [crop_xy_coord crop_wl];
I = imcrop(J,croprect);

% create selection mask to make sure only only the ellipse is quantified
I_mask = imcrop(createMask(h),croprect);

% find if there is any "black" (i.e. non-leaf, or background) in this crop
background_area_from_crop = 0;
for a=1:crop_wl(2)
    for b=1:crop_wl(1)
        if ((I_mask(a,b) == 1) && logical(prod(I(a,b,:) <= 1))) % sometimes
                                                 % this results in having
                                                 % extra area pixels at the
                                                 % end that linger. It's
                                                 % the border pixels of the
                                                 % selection that get lost
                                                 % due to number rounding
                                                 % done by matlab while
                                                 % getting h.getVertices
                                                 % and createMask(h).
            background_area_from_crop = background_area_from_crop + 1;
        end
    end
end

% apply mask to the cropped RGB image.
I = bsxfun(@times, I, cast(I_mask, class(I)));

%% 

% exposureVal = 1.5;
% we'll keep adding to finalImage as we process the leaves. We'll start
% with a blank image. //This may be unnecessary in the long run because for
% T3S we're not adding a bunch of leaf segments. We're only dealing with
% one at a time. Probably enough to just set I_Diff as the "finalImage"
% finalImage = I(:,:,1)-I(:,:,1);
processedImage = I;

% giving names to image RGB layers so that they can be referenced easily
R=1;
G=2;
B=3;

% get the discolaration in gray scale
I_R = processedImage(:,:,R);
I_B = processedImage(:,:,B);
I_G = processedImage(:,:,G);
I_gmrpgmb = (I_G-I_R) + (I_G-I_B);
I_Diff = I_G - (exposureVal * I_gmrpgmb); % this is the image with only 
                                          % infected areas in gray shade, 
                                          % everything else is black.

% finalImage = finalImage + I_Diff; % add the grayscale leaf in result image
% figure, imshow(finalImage);
% Previous two lines: because I got rid of "finalImage" in the beginning
% of this code section, I'm getting rid of this. Showing I_Diff is enough
% to show what the resulting gray scale image is.
if (showProcessedRegions==true)
    figure('Name','Processed region'), imshow(I_Diff);
end
%% 
color_bins = 256; %number of bins to put the 256 shades of gray into. 256/color_bins=size of each bin

[cts, x] = imhist(I_Diff,color_bins);

xp = zeros(1,256);
% xp(1)=0;
for a=2:256
    xp(a) = xp(a-1) + cts(a);
end
xp = xp(1:find(cts,1,'last'));

%% 
% now find positions P_q of the quantiles q using P_q = N*q
p_q10 = xp(end)*0.1;
p_q25 = xp(end)*0.25;
p_q50 = xp(end)*0.5;
p_q75 = xp(end)*0.75;
p_q90 = xp(end)*0.9;

% go through the cummulative array to find position of the quantile
pos10=1;
for a=1:size(xp,2)
    if (p_q10 == xp(a))
        pos10 = a;
    elseif (p_q10 < xp(a))
        pos10 = a-1;
        break;
    end
end

pos25=1;
for a=1:size(xp,2)
    if (p_q25 == xp(a))
        pos25 = a;
    elseif (p_q25 < xp(a))
        pos25 = a-1;
        break;
    end
end

pos50=1;
for a=1:size(xp,2)
    if (p_q50 == xp(a))
        pos50 = a;
    elseif (p_q50 < xp(a))
        pos50 = a-1;
        break;
    end
end

pos75=1;
for a=1:size(xp,2)
    if (p_q75 == xp(a))
        pos75 = a;
    elseif (p_q75 < xp(a))
        pos75 = a-1;
        break;
    end
end

pos90=1;
for a=1:size(xp,2)
    if (p_q90 == xp(a))
        pos90 = a;
    elseif (p_q90 < xp(a))
        pos90 = a-1;
        break;
    end
end

% sum_discoloration = sum(cts.*x);
mean_discoloration = sum(cts.*x)/sum(cts(2:end));
area_discoloration = sum(I_mask(:)) - background_area_from_crop; %
                                     % sum up all the 1's in the mask. sum
                                     % up all the 1's from final processed
                                     % image. subtract former from the
                                     % latter. this should get the actual 
                                     % area for
                                     % which the leaf is to be quantified.
                                     % 
percent_discoloration = 100 * (sum(cts(2:end))/area_discoloration);

%% 
min_val = find(xp,1,'first');
max_val = find(xp,1,'last');
mean_val= mean_discoloration;
area_selected= uint32(area_discoloration);
percent = percent_discoloration;
end