
% SEG_SLIDER Performs background correction and manual thresholding on a user-defined portion of the image using an updated UI.
%  
%  [IMGS_BINARY] = agg.seg_slider2(IMGS) applies the slider method to the
%  images speified in IMGS, an Imgs data structure. IMGS_BINARY is a binary
%  mask resulting from the procedure.
%  
%  [IMGS_BINARY] = agg.seg_slider2({IMGS}) applies the slider method to the
%  images speified in IMGS, a cell of cropped images.
%  
%  [IMG_BINARY] = agg.seg_slider2(IMG) applies the slider method to the
%  single, copped image given by IMG.
%  
%  [IMG_BINARY] = agg.seg_slider2(...,IMGS_BINARY) adds the options for a
%  pre-classified binary image, which allows for modification of an
%  existing binary mask. 
% 
%  AUTHOR: Timothy Sipkens, 2021-01-31
%  BASED ON: Code by Ramin Dastanpour


function [imgs_binary] = seg_slider2(imgs, imgs_binary)

%== Parse input ==========================================================%
% Use common inputs parser, noting that pixel size is not
% used as an input to this function.
[imgs, ~, n] = agg.parse_inputs(imgs, []);

% Initial cellular array of image binaries, if image 
% binary is not provided. Empty if not provided.
if ~exist('imgs_binary','var'); imgs_binary = []; end
if isempty(imgs_binary); imgs_binary{n} = []; end
if ~iscell(imgs_binary); imgs_binary = {imgs_binary}; end

% Check to make sure there is an equal number of binary 
% and imags inputs, if supplied. If not supplied, imgs_binary{n} = [];
% ensures appropriate length.
if length(imgs_binary) ~= n
    error('Size mismatch between imgs and imgs_binary');
end
%=========================================================================%


slider_app = agg.ui_slider2(imgs);
waitfor(slider_app, 'f_return');

imgs_binary = slider_app.imgs_binary;

slider_app.delete;
clear slider_app;

end
