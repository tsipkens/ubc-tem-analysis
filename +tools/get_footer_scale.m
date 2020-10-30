
% GET_FOOTER_SCALE Crops the footer from the image and determines the scale.
%=========================================================================%

function [Imgs,pixsize] = get_footer_scale(Imgs)

for jj=1:length(Imgs)
    
    %-- Step 1-3: Crop footer away ---------------------------------------%
    % when the program reaches a row of only white pixels, removes
    % everything below it (specific to ubc photos). It will do nothing if
    % there is no footer or the footer is not pure white.
    white = 255; % how white is the background of footer?
    footer_found = 0; % flag whether footer was found
    
    for ii = 1:size(Imgs(jj).raw,1)
        if sum(Imgs(jj).raw(ii,:)) > ...
                (0.85 * size(Imgs(jj).raw,2) * white) % 85% white row
            FooterEdge = ii;
            footer_found = 1;
            Imgs(jj).cropped = Imgs(jj).raw(1:FooterEdge-1, :);
            footer  = Imgs(jj).raw(FooterEdge:end, :);
            
            footer_found = 1;
            break;
        end
    end
    
    if footer_found == 0
        Imgs(jj).cropped = Imgs(jj).raw;
        warning(['No footer found, cropped image is raw image. ' ...
            'Assign pixsize manually']);
        return;
    end
    
    
    %== Detecting magnification and/or pixel size ========================%
    Imgs(jj).ocr = ocr(footer);
    bool_nm = 1;
    
    %-- Look for pixel size ----------------------------------------------%
    pixsize_end = strfind(Imgs(jj).ocr.Text,' nm/pix')-1;
    if isempty(pixsize_end) % if not found, try nmlpix
        pixsize_end = strfind(Imgs(jj).ocr.Text,' nmlpix')-1;
        
        if isempty(pixsize_end)
            pixsize_end = strfind(Imgs(jj).ocr.Text,' pm/pix')-1; % micrometer
            
            if isempty(pixsize_end)
                pixsize_end = strfind(Imgs(jj).ocr.Text,' pmlpix')-1;
            end
            bool_nm = 0;
        end
    end

    pixsize_start = strfind(Imgs(jj).ocr.Text,'Cal')+5;
    Imgs(jj).pixsize = str2double(...
        Imgs(jj).ocr.Text(pixsize_start:pixsize_end));
    if bool_nm==0; Imgs(jj).pixsize = Imgs(jj).pixsize*1e3; end
    

end

pixsize = [Imgs(1).pixsize];

end



