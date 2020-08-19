
% LOAD_IMGS Loads nth image specified in the image structure (or selected in UI).
%           If n is not specified, it will load all of the images. 
%           This can be problematic for large sets of images.
% Author:   Timothy Sipkens, 2019-07-04
%=========================================================================%

function [Imgs,img_raw] = load_imgs(Imgs, n)

%-- Parse inputs ---------------------------------------------------------%
% if not image information provided, use a UI to select files
if ~exist('Imgs','var'); Imgs = []; end
if isempty(Imgs); Imgs = tools.get_files; end

% if image number not specified, use the first one
if ~exist('n','var'); n = []; end
if isempty(n); n = 1:length(Imgs); end


%-- Read in image --------------------------------------------------------%
for ii=length(n):-1:1
    Imgs(ii).raw = imread([Imgs(ii).dir, Imgs(ii).fname]);
end

% output raw image
img_raw = Imgs(1).raw;

% crop out footer and get scale from text
Imgs = tools.get_footer_scale(Imgs);

end
