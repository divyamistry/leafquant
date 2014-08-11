%% LeafQuantT3S v0.1

% clear workspace to clean up previous variables saved in the memory.
% clear;

%turn off warning for image shown at smaller zoom than 100%
warning('off','Images:initSize:adjustingMag');

% get the image file
[imageFileName, imagePathName, ~] = uigetfile({'*.jpg;*.jpeg;*.png;*.tiff;*.tif','Image Files (JPEG, PNG, TIFF)';'*.*','All Files'},'Choose the image file','/Users/divyam/Development/T3S Quant/NewFromShan/tiff photo for AvrPphB fig');

imageFullName = strcat(imagePathName,imageFileName);
%disp(strcat('Started working with: ',imageFullName));

%str = sprintf('%20s | %5s %4dq %4dq %4dq %4dq %4dq %5s %5s | %5s %5s','exprimentName', 'min',10,25,50,75,90,'max','mean','area','%infected');
%disp(str);

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
%expecting this experiment name to be defined
exprName = 'Xoc & Xcr-PRA1';

% while exist('h','var')
%     wait(h);
%     disp(quantthis(J,h,exprName));
% end

% for every section that needs to be quantified, run this command
% once the ellipse has been correctly placed.
disp(quantthis(J,h, exprName));

%%
% return the warning for image zoom to "on"
warning('on','Images:initSize:adjustingMag');







