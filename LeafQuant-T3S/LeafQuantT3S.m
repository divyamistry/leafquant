%% LeafQuantT3S v0.1

function LeafQuantT3S(exprId, repId, numOfRegions, showProcessedRegions, exposureVal)
% clear workspace to clean up previous variables saved in the memory.
% clear;

%turn off warning for image shown at smaller zoom than 100%
warning('off','Images:initSize:adjustingMag');

if(~islogical(showProcessedRegions))
    disp('showProcessedRegions MUST be a logical (i.e. true or false) value.');
    return;
end

% get the image file
[imageFileName, imagePathName, ~] = uigetfile({'*.jpg;*.jpeg;*.png;*.tiff;*.tif','Image Files (JPEG, PNG, TIFF)';'*.*','All Files'},'Choose the image file','.');
imageFullName = strcat(imagePathName,imageFileName);
disp(strcat('Started working with: ',imageFullName));

%% 
% file with the command and the rectangle that was used to leafquant the image
launchCmd = sprintf('LeafQuant launched using: %s(''%s'',''%s'',%d,%d,%.2f)',mfilename,exprId,repId,numOfRegions, showProcessedRegions, exposureVal);
cmdOutFileName = strcat(imageFullName,'.txt');
cmdOutFileId = fopen(cmdOutFileName,'w+');
fprintf(cmdOutFileId,'%s\n',launchCmd);

% name of the leafquant output file with the table of color quantification analysis
csvOutFileName = strcat(imageFullName,'.csv');

if (imageFileName==0)
    return;
end
J = imread(imageFullName);

%% 
% very loose check to see if given image has 3 layers (as in RGB image)
Jlayers = size(J,3);
if(Jlayers ~= 3)
    disp('given image MUST be an RGB image.');
    return;
end

%%
% show the image and get ready for user input
imshow(J);
h = imellipse;

%%
% expecting this experiment name to be defined
% exprName = 'Xoc & Xcr-PRA1';

% display the header for each of the columns being printed
str = sprintf('%10s %5s | %5s %4dq %4dq %4dq %4dq %4dq %5s %5s | %5s %5s','exprId','repId', 'min',10,25,50,75,90,'max','mean','area','%non-green');
disp(str);

% header for the file output.
header = 'expr_id,rep_id,min,10q,25q,50q,75q,90q,max,mean,selected_area,percent_nongreen';
csvOutFileId = fopen(csvOutFileName,'w+');
fprintf(csvOutFileId,'%s\n',header);

% for every section that needs to be quantified, run this command
% once the ellipse has been correctly placed.
for i=1:numOfRegions
    wait(h);
    [min_val, pos10, pos25, pos50, pos75, pos90, max_val, mean_val, area_selected, percent] = quantthis(J,h, showProcessedRegions, exposureVal);
    
    % display result on console
    str = sprintf('%10s %5s | %5d %5d %5d %5d %5d %5d %5d %.2f | %5d %.2f',...
                   exprId, repId, min_val,pos10,pos25,pos50,pos75,pos90,max_val,...
                   mean_val, area_selected, percent);
    disp(str);
    
    % put results in the csv file
    fprintf(csvOutFileId,'%s,%s,%d,%d,%d,%d,%d,%d,%d,%f,%d,%f\n',...
            exprId,repId,min_val,pos10,pos25,pos50,pos75,pos90,max_val,...
            mean_val, area_selected, percent);
end
h.delete;

% close the output files
fclose(csvOutFileId);
fclose(cmdOutFileId);
%%
% return the warning for image zoom to "on"
warning('on','Images:initSize:adjustingMag');







