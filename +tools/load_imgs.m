
% LOAD_IMGS  Loads images from files.
% 
% IMGS = load_imgs() uses a file explorer to select files, loads the
% images, and attempts to detect the footer and scale of the image (using
% the detect_footer_scale subfunction). Information is output in the form
% of a data struture, with one entry per image. 
% 
% IMGS = load_imgs(FD) loads all of the images in the folder specified by
% the input string, FD. For example, the sample images can be loaded using
% IMGS = load_imgs('images'). 
% 
% IMGS = load_imgs(FD,N) loads the images specified by array N. By
% default, N spans 1 to the number of images in the given folder. For
% example, the 2nd and 3rd images can be loaded using N = [2,3]. This
% allows for partial loading of larger data sets for batch processing. 
% 
% [~,IMGS,PIXSIZE] = load_imgs(...) loads images and outputs the imported
% images after the detector footer has been remvoed as a cell array, IMGS,
% and an array of pixel sizes in nm/pixel, PIXSIZE. 
% 
% AUTHOR: Timothy Sipkens, 2019-07-04

function [Imgs, imgs, pixsize] = load_imgs(fd, n)

tools.textheader('Loading images');

%-- Parse inputs ---------------------------------------------------------%
% if not image information provided, use a UI to select files
if ~exist('fd','var'); fd = []; end
if isempty(fd); Imgs = get_fileref; end % use UI to get files

if ~isempty(fd)
    if strcmp(fd(1:4), 'http')  % if web resource
        Imgs(1).folder = '';
        Imgs(1).fname = fd;

    elseif isa(fd, 'char')  % get all images in local folder given in Imgs
        Imgs = get_fileref(fd);
    end
end


% if image number not specified, process all of the images.
if ~exist('n','var'); n = []; end
if isempty(n); n = 1:length(Imgs); end
Imgs = Imgs(n);  % option to select only some of the images before read

% This flag specified whether to attempt to remove
% scale bars overlaid on the image. 
f_replace = 1;
%-------------------------------------------------------------------------%


%-- Read in image --------------------------------------------------------%
ln = length(n); % number of images

disp('Reading files:');
tools.textbar([0, ln]);
for ii=ln:-1:1 % reverse order to pre-allocate
    Imgs(ii).raw = imread([Imgs(ii).folder, Imgs(ii).fname]);
    Imgs(ii).raw = Imgs(ii).raw(:,:,1);
    tools.textbar([ln - ii + 1, ln])
end
disp(' ');

% Crop out footer/scale bar and get scale from text.
Imgs = detect_footer_scale(Imgs, f_replace);

% format other outputs
imgs = {Imgs.cropped};
pixsize = [Imgs.pixsize];

tools.textheader();  % output footer text

end






%== GET_FILEREF ==========================================================%
%   Loads references to image files, including their name and directory.
%   Populates intitial information to Imgs structure before loading images.
function Imgs = get_fileref(fd)

if ~exist('fd','var'); fd = []; end

flag = 0; % 0: no image loaded; 1: at least one image loaded
% loop continues until at least image is selected or the program is stopped

Imgs.fname = ''; % initialize image reference structure


%-- Get file information -------------------------------------------------%
while flag == 0
    dir_start = 'images'; % initial directory to look for images
    
    % Browse or get file information.
    if isempty(fd) % if no folder, user browses for images (tif,jpg)
        [fname, folder] = uigetfile({'*.tif;*.jpg', 'TEM image (*.tif;*.jpg)'}, ...
            'Select Images', dir_start, 'MultiSelect', 'on');
    else % if folder is given, get all tif files in the folder
        t0 = [ ...  % pattern to match filenames
            dir(fullfile(fd,'*.tif')), ...  % get TIF
            dir(fullfile(fd,'*.jpg'))];  % get JPG
        fname = {t0.name};
        folder = t0(1).folder;
    end
    
    % Format file information for output
    if iscell(fname) % handle a cell array of files
        flag = 1;
        for ii=length(fname):-1:1
            Imgs(ii).fname = fname{ii};
            Imgs(ii).folder = [folder, filesep];
        end
    elseif Imgs.fname==0 % handle when no image was selected
        error('No image selected.');
    else % handle when only one image is selected
        Imgs.fname = fname;
        Imgs.folder = [folder, filesep];
        flag = 1;
    end
end
%-------------------------------------------------------------------------%


end





%== DETECT_FOOTER_SCALE ==================================================%
%   Crops the footer from the image and determines the scale.
function [Imgs, pixsizes] = detect_footer_scale(Imgs, f_replace)

disp('Looking for footers/scale:');
tools.textbar([0, length(Imgs)]);

% Outer loop allows for images with different footers/scale bars.
for jj=1:length(Imgs)
    
    
    %== OPTION 1 =========================================================%
    % Designed for UBC footer. Should work for any white footer 
    % located at the bottom of the image. 
    % Runs OCR to find "*/pix" indicators of pixel size. 
    % When the program reaches a row of only white pixels, removes
    % everything below it (specific to ubc photos). It will do nothing if
    % there is no footer or the footer is not pure white.
    white = 255; % how white is the background of footer?
    footer_found = 0; % flag whether footer was found
    
    f_nm = 1;  % flag indicating nanometers (detected below)
    
    % Search for row satisying 
    f_footrow = sum(Imgs(jj).raw, 2) > ...
    	(0.9 * size(Imgs(jj).raw,2) * white);
    ii = find(f_footrow, 1);  % first 90% white row
    
    if ~isempty(ii)  % if found footer satisyfing above
        Imgs(jj).cropped = Imgs(jj).raw(1:ii-1, :);
        footer  = Imgs(jj).raw(ii:end, :);

        footer_found = 1;  % flag that footer was found

        %-- Detecting magnification and/or pixel size ----------------%
        o1 = ocr(footer);
        Imgs(jj).ocr = o1;

        % Look for pixel size.
        pixsize_end = strfind(o1.Text,' nm/pix')-1;
        if isempty(pixsize_end) % if not found, try nmlpix
            pixsize_end = strfind(o1.Text,' nmlpix')-1;

            if isempty(pixsize_end)
                pixsize_end = strfind(o1.Text,' pm/pix')-1; % micrometer

                if isempty(pixsize_end)
                    pixsize_end = strfind(o1.Text,' pmlpix')-1;
                end
                f_nm = 0;
            end
        end

        % Interpret OCR text and compute pixel size.
        pixsize_start = strfind(o1.Text,'Cal')+5;
        Imgs(jj).pixsize = str2double(...
            o1.Text(pixsize_start:pixsize_end));

        % If given in micrometers, convert.
        if f_nm==0; Imgs(jj).pixsize = Imgs(jj).pixsize*1e3; end
    end
    
    
    %== OPTION 2 =========================================================%
    %   If above method failed, look for black text on image.
    %   OCR is used to try to detect text. If found and f_remove=1, 
    %   then then the text and scale bar are replaced with 
    %   background noise.
    %   This method is less reliable than above method and 
    %   is worth spot checking.
    if footer_found == 0
        % Binarize the image at a level 0.98*max.
        bw1 = im2bw(1 - double(Imgs(jj).raw) ./ ...
            max(max(double(Imgs(jj).raw))), 0.98);
        
        % Remove any small regions below 140 pixels.
        bw1 = bwareaopen(bw1, 140);
        
        % Run OCR to get find text corresponding to scale.
        o1 = ocr(bw1, 'CharacterSet', '0123456789nm');
        Imgs(jj).ocr = o1;
        
        % Filter for only relevant characters.
        f_chars = regexp(o1.Text, '[0123456789nm]');  % flag if characters relevant
        txt = o1.Text(f_chars);
        o1_bboxs = o1.CharacterBoundingBoxes(f_chars, :);
        
        sc_end = strfind(txt, 'nm') - 1;
        
        if ~isempty(sc_end) % if text found
            footer_found = 1; % mark that text has been found
            
            Imgs(jj).cropped = Imgs(jj).raw;  % scale bar in image, cannot crop
            
            sc_start = 1;
            sc_length = str2double(...
                txt(sc_start:sc_end));  % length of scale bar in nm
            
            rp = regionprops(bw1);
            ar = [rp.BoundingBox];
            ar = reshape(ar', [4, length(ar)/4])';
            ar = ar(:,3) ./ ar(:,4);  % arrive at aspect ratio
            [~, ar_max] = max(ar); len = rp(ar_max).BoundingBox(3);  % pixel length of scale bar
            Imgs(jj).pixsize = sc_length / len;
            
            % If given in micrometers, convert.
            if f_nm==0; Imgs(jj).pixsize = Imgs(jj).pixsize * 1e3; end

            
            
            
            % Use bounding boxes to replace the scale bar 
            % and text with background noise.
            if f_replace
                
                % Get estimate of background. Used for median and std. dev.
               img_bge = Imgs(jj).raw( ...
                    imclose(imbinarize(Imgs(jj).cropped), strel('disk', 8)));
                
                % Convert the bounding boxes for the scale bar and
                % the found characters to a mask. Dilate that mask to 
                % cover potential border. This prevents replacing dark
                % regions of the aggregate with background. 
                bw2 = bbox2mask( ...
                    cat(1, rp(ar_max).BoundingBox, ...
                    o1_bboxs), ...
                    size(Imgs(jj).cropped));
                bw2 = imdilate(bw2, strel('square', 12));
                mask2 = imdilate(bw2, strel('disk', 8)) - bw2;  % get nearby pixels
                
                % Replace dilated regions with Gaussian noise, 
                % about median of estimated background.
                Imgs(jj).cropped(bw2) = uint8(...
                    median(double(Imgs(jj).cropped(logical(mask2)))) + ...
                    std(double(Imgs(jj).cropped(logical(mask2)))) .* ...
                    randn([sum(sum(bw2)), 1]));
                Imgs(jj).cropped = reshape(Imgs(jj).cropped, size(Imgs(jj).raw));
            end
            
        end
        
    end
    
    
    % If both of the above methods fail.
    if footer_found == 0
        Imgs(jj).cropped = Imgs(jj).raw;
        Imgs(jj).pixsize = NaN;  % return NaN if nothing found
    end
    
    tools.textbar([jj, length(Imgs)]);
end

pixsizes = [Imgs.pixsize];

% If the pixel size / footer was not found for a number of images.
if any(isnan(pixsizes))
    warning(['One or more footers or scales not found.', ...
        'In these cases, cropped image is raw image. ', ...
        'Assign pixel size manually or using tools.ui_scale_bar.m.']);
    disp(' ');
end

end




%== BBOX2MASK ============================================================%
%   Convert a series of bounding boxes to an image mask.
function [mask] = bbox2mask(bboxs, img_size)

[grid2, grid1] = meshgrid(1:img_size(2), 1:img_size(1));

% Loop through bounding boxes and OR them.
mask = zeros(img_size);  % initialize mask as zeros
for ii=1:size(bboxs, 1)
    mask = or(mask, ...
        and(and(grid1 > bboxs(ii,2), grid1 < (bboxs(ii,2) + bboxs(ii,4))), ...
        and(grid2 > bboxs(ii,1), grid2 < (bboxs(ii,1) + bboxs(ii,3)))));
end

end
