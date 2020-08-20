
% SEG_OTSU_RB_ORIG  Performs Otsu thresholding + a rolling ball transformation (as per Dastanpur et al.).
% Authors:  Ramin Dastanpour, Steven N. Rogak, 2016-02
%           Developed at the University of British Columbia
% Modified: Timothy Sipkens
% 
% Note: The method remains true to the original code by Dastanpour et al., 
%       and differs from the other implementation included with this code
%       which does not immediately remove boundary aggregates, adds
%       background subtraction, and adds a denoising step. 
%=========================================================================%

function [img_binary] = seg_otsu_rb_orig(...
    imgs, pixsizes, minparticlesize, coeffs) 

%-- Parse inputs ---------------------------------------------------------%
if isstruct(imgs)
    Imgs_str = imgs;
    imgs = {Imgs_str.cropped};
    pixsize = [Imgs_str.pixsize];
elseif ~iscell(imgs)
    imgs = {imgs};
end

n = length(imgs); % number of images to consider

if ~exist('pixsizes','var'); pixsizes = []; end
if isempty(pixsizes); pixsizes = ones(size(img)); end
if length(pixsizes)==1; pixsizes = pixsizes .* ones(size(imgs)); end % extend if scalar

if ~exist('minparticlesize','var'); minparticlesize = []; end
if ~exist('coeffs','var'); coeffs = []; end
%-------------------------------------------------------------------------%

% Loop over images, calling seg function below on each iteration.
img_binary{n} = []; % pre-allocate cells
img_kmeans{n} = [];
feature_set{n} = [];

disp('Performing Otsu thresholding (as per Dastanpour):');
if n>1; tools.textbar(0); end
for ii=1:n
    img = imgs{ii}; pixsize = pixsizes(ii); % values for this iteration
    
%== CORE FUNCTION ========================================================%
    %== Step 1: Apply intensity threshold (Otsu) =========================%
    level = graythresh(img); % applies Otsu thresholding
    bw = imbinarize(img, level);
    
    bw = ~imclearborder(~bw); % clear aggregates on border
        % required due to occasional background gradients included in results
    
    
    %== Step 2: Rolling Ball Transformation ==============================%
    img_binary{ii} = agg.rolling_ball(bw,pixsize,minparticlesize,coeffs);
    img_binary{ii} = ~img_binary{ii};
%=========================================================================%
    
    if n>1; tools.textbar(ii / n); end
end

% If a single image, cell arrays are unnecessary.
% Extract and just output images. 
if n==1
    img_binary = img_binary{1};
    img_kmeans = img_kmeans{1};
    feature_set = feature_set{1};
end


end
