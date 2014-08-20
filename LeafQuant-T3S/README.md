# LeafQuant-T3S

### Program requirements
LeafQuantT3S requires Mathworks MATLAB and the Image Processing Toolbox. Current version of the program has been tested on MATLAB v8.2 (R2013b) and Image Processing Toolbox v8.3 (R2013b).

### Some restrictions on the images that can be processed by LeafQuantT3S
I have not yet implemented automatic region detection in the code. Due to this, the program requires the user to select the region of infiltration. This was **necessary** because there was no way to trace the _exact_ infiltration regions _after the fact_ when images were taken. In future experiments, we may have images with exact marked regions which can be used to guide the automatic region detection. Until then we are left with this implementation. Even with this caveat, it performs remarkably well as you'll see. 

I employed MATLAB's built-in ellipse roi selection method. The infiltration regions were approximately shaped like ellipse, and therefore it seemed like a better choice than letting user draw a freehand region. As a side-effect, you'll notice that in the attached `Sample.jpg` the leaves had to be "broken" into multiple sections. All I have done is to select part of a leaf and rotated it. No color, brightness, sharpness etc. adjustments were made. The unmodified original image is also included for your perusal. This is a **CRITICAL** point to make before you analyze your images as well. LeafQuant relies on the [RGB](http://en.wikipedia.org/wiki/RGB_color_model) color scale of the image, so the user has to be careful not to modify those. We are considering alternate color models for future, including processing [RAW](http://en.wikipedia.org/wiki/Raw_image_format) images directly.

### Required parameters for the image analysis of the barley leaves
  * `exprID` is a string representing the experiment. This can be any string that helps you identify set of leaves from one experiment to other.
  * `repID` is a string represting replicate of the experiment. This can be any string that helps you distinguish compared to other replicates.
  * `numOfRegions` is the integer telling how many infiltration sections will be quantified.
  * `showProcessedImage` if set to `true` will show each of the selected regions in a separate processed grayscale image based on which quantification was done. If set to `false`, no such images are displayed.
  * `exposureVal` is a floating point number that manages quantity of non-green color to subtract from the pixels representing leaves. A value between `1.25` and `1.6` generally performs the best on our test images. This measure exists to allow corrections between photographs taken from different cameras and lighting conditions. You shouldn't have to change this if the camera, lighting conditions, image brightness, sharpness, etc. are left constant. There are examples of what this value does at the end of this user guide.

### Sample usage
There is a sample image called `Sample.jpg` included with this program. The image has 3 leaves, with three different spots of T3S infiltrations on each leaf. For the sake of this example, this image represents an experiment I call _BghT3S_, and it is my replicate _A3_. These names as no meaning for the except that they are useful for my record keeping. They'll be my `exprID` and `repID`. You can provide an empty string `''` for each if you prefer not to do use an ID.

##### Steps to get quantification results

  1. 