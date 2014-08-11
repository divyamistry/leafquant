%% LeafQuantVIGS v1

% parameters
% exprId, repId - string representing experiment and replicate of the experiment
% cropImageFirst - if true, UI will let user choose an area of the image to
%     analyse. If false, the app will process the whole image.
% showHistogram - is a boolean flag. If true, a histogram of infection level
%     will be shown per leaf.
% numOfLeaves - is an integer specifying number of leaves that are
%     expected to be found in the image or cropped region
% exposureVal - multiplier for the non-green pixel colors that would be
%     subtracted from the green channel. A value of 2 would subtract the
%     color contribution of red and blue channel from the green channel twice.
%     In general, a value of 1 should work fine

function LeafQuant_v1(exprId, repId, cropImageFirst, showHistogram, numOfLeaves, exposureVal)

%turn off warning for image shown at smaller zoom than 100%
warning('off','Images:initSize:adjustingMag');

% if showImages is not a 'true' or 'false' value, leave function
if(~islogical(showHistogram) || ~islogical(cropImageFirst)) 
    disp('showHistogram and cropImageFirst parameters MUST be logical (i.e. true or false) value.');
    return;
end

%%
% get image from user
[imageFileName, imagePathName, ~] = uigetfile({'*.jpg;*.jpeg;*.png;*.tiff','Image Files (JPEG, PNG, TIFF)';'*.*','All Files'},'Choose the image file','.');
imageFullName = strcat(imagePathName,imageFileName);
disp(strcat('Started working with: ',imageFullName));

%%
% file with the command and the rectangle that was used to leafquant the image
launchCmd = sprintf('LeafQuant launched using: %s(''%s'',''%s'',%d,%d,%d,%.2f)',mfilename,exprId,repId,cropImageFirst,showHistogram,numOfLeaves,exposureVal);
cmdOutFileName = strcat(imageFullName,'.txt');
cmdOutFileId = fopen(cmdOutFileName,'w+');
fprintf(cmdOutFileId,'%s\n',launchCmd);

% name of the leafquant output file with the table of color quantification analysis
csvOutFileName = strcat(imageFullName,'.csv');

if (imageFileName==0)
    return;
end
I = imread(imageFullName);

%%
% if given image doesn't have all three RGB layers, exit.
Ilayers = size(I,3);
if(Ilayers ~= 3)
    disp('given image MUST be an RGB image.');
    return;
end

%%
% crop the image to desired area if requested
if(cropImageFirst)
    figure('Name','Crop the image to desired rectangle');
    % crop the image
    [I, rect] = imcrop(imshow(I)); % [I, rect] = imcrop(I,[432   807  1872  1704]);
    
    % output the rectangle that was used for cropping. This can used as a
    % parameter in imcrop() to crop image of given rectangle.
    %    [I, rect] = imcrop(I,[432   807  1872  1704]);
    % above line will cut the image I from (x=432, y=807) pixel value with
    % (width=1872, height=1704) pixels.
    
    str = sprintf('[%5d %5d %5d %5d]',round(rect(1)),round(rect(2)),round(rect(3)),round(rect(4)));
    % disp(str);
    fprintf(cmdOutFileId,'%s\n',strcat('Image cropped using rectangle:',str));
    
    % highlight the cropped area on original image
    rectangle('Position',rect,'LineWidth',2,'EdgeColor','red');
    % show the cropped image
    figure('Name','Cropped Image'), imshow(I);
end

%%
level = graythresh(I);
I_BlackAndWhite = im2bw(I,level);
cc = bwconncomp(I_BlackAndWhite,8);
numOfCC = size(cc.PixelIdxList,2);
ccBoundaries = regionprops(cc,'BoundingBox');
ccAreas = regionprops(cc,'Area');
leaf_objs = zeros(1,numOfCC);
for col=1:numOfCC
    leaf_objs(col) = size(cc.PixelIdxList{col},1);
end
[~, crossRefIdx_bysize] = sort(leaf_objs,'descend');
crossRefIdx = sort(crossRefIdx_bysize(1:numOfLeaves));

% we'll keep adding to finalImage as we process the leaves. We'll start
% with a blank image.l
finalImage = I(:,:,1)-I(:,:,1);

% we'll output the textual result table to CSV file
% resultTable = cell(numOfLeaves,13); % we want 8 cols for values defined in header below
header = 'expr_id,rep_id,leaf,min,10q,25q,median,75q,90q,max,mean,total_area,percent_infected';
csvOutFileId = fopen(csvOutFileName,'w+');
fprintf(csvOutFileId,'%s\n',header);

% show table title
str = sprintf('%5s %5s %5s | %5s %4dq %4dq %4dq %4dq %4dq %5s %5s | %5s %5s','expId','repId','leaf', 'min',10,25,50,75,90,'max','mean','area','%infected');
disp(str);

% need to remember the location of labels for the leaves so that I can add
% the leaf number at the end of the processing. we'll only need the
% x-coordinate because the y value will stay constant among leaves, and
% it'll be 20% off of the bottom of the image.
xlocOfLeafNum = [0 0 0 0];
ylocOfLeafNum = ceil(size(I,1)*0.8);

% create a separate figure for the histograms if requested
if(showHistogram==true)
    figure('Name','Histogram of infection intensities per leaf');
end

% create a vector to hold all the "infection median" and "% area infection" to
% plot at the end
leafMedians = zeros(1,numOfLeaves);
leafPercentInfected = zeros(1,numOfLeaves);

for i=1:numOfLeaves
    processedImage = I;
    leaf = false(size(I_BlackAndWhite)); %create blank image
    leaf(cc.PixelIdxList{crossRefIdx(i)}) = true; %show leaf of interest
    
    for a=1:size(processedImage,1)
        for b=1:size(processedImage,2)
            if (leaf(a,b) == 0)
                processedImage(a,b,:)=0;
            end
        end
    end
    
    % giving names to image RGB layers so that they can be referenced easily
    R=1;
    G=2;
    B=3;
    
    % get the discolaration in gray scale
    I_R = processedImage(:,:,R);
    I_B = processedImage(:,:,B);
    I_G = processedImage(:,:,G);
    I_gmrpgmb = (I_G-I_R) + (I_G-I_B);
    I_Diff = I_G - (exposureVal * I_gmrpgmb); % this is the image with only infected areas in gray shade, everything else is black.
    finalImage = finalImage + I_Diff; % add the grayscale leaf in result image
    
    % get bounding box of this leaf and save location for number
    bBox = ccBoundaries(crossRefIdx(i));
    xlocOfLeafNum(i) = ceil(bBox.BoundingBox(1) + (bBox.BoundingBox(3)/2));
    
    color_bins = 256; %number of bins to put the 256 shades of gray into. 256/color_bins=size of each bin
    
    %get histogram and count of pixels in specific gray scale range
    [cts, x] = imhist(I_Diff,color_bins);
    
    %display the histogram
    if(showHistogram==true)
        subplot(1,numOfLeaves,i), imhist(I_Diff,color_bins), ylim([0 (max(cts(2:end)+mean(cts(2:end))))]);
    end
    xp = zeros(1,256);
    xp(1)=0;
    for a=2:256
        xp(a) = xp(a-1) + cts(a);
    end
    xp = xp(1:find(cts,1,'last'));
    
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
    
    mean_discoloration = sum(cts.*x)/sum(cts(2:end));
    area_discoloration = ccAreas(crossRefIdx(i)).Area;
    percent_discoloration = 100 * (sum(cts(2:end))/area_discoloration);
    
    % store the median for output plot at the end
    leafMedians(i) = pos50;
    leafPercentInfected(i) = percent_discoloration;
    
    % now display the table with quantiles
    str = sprintf('%5s %5s %5d | %5d %5d %5d %5d %5d %5d %5d %.2f | %5d %.2f',...
                   exprId,repId,i,find(xp,1,'first'),pos10,pos25,pos50,pos75,pos90,find(cts,1,'last'),...
                   mean_discoloration, area_discoloration, percent_discoloration);
    disp(str);
    
    % write the quantiles and relevant information to file
    fprintf(csvOutFileId,'%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%f,%d,%f\n',...
                         exprId,repId,i,find(xp,1,'first'),pos10,pos25,pos50,pos75,pos90,find(cts,1,'last'),...
                         mean_discoloration, area_discoloration, percent_discoloration);
end %end of per-leaf loop.

% close the file after writing
fclose(csvOutFileId);
fclose(cmdOutFileId);

% now add the text to respective locations on the result image
f = figure; imshow(finalImage);
%for i=1:numOfLeaves
%    text(xlocOfLeafNum(i), ylocOfLeafNum, int2str(i), 'Color','white','FontSize',18, 'FontWeight','bold');
%end
saveas(f,strcat(imageFullName,'_processed.png'),'png');

% now show the plot of all the medians of leaf discoloration intensities
figure('Name','Median intensities'), scatter((1:numOfLeaves),leafMedians), ylim([0 256]);
figure('Name','% infected'), scatter((1:numOfLeaves),leafPercentInfected), ylim([0 100]);

% return the warning for image zoom to "on"
warning('on','Images:initSize:adjustingMag');

