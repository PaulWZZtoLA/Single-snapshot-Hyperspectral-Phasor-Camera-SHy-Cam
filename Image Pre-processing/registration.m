function [] = registration(ref_ch,T)
% This function is for cropping the spectral phaosr camera images
% into four channels and manually use them to find the control points of
% one chosen reference channel with other three moving channels during
% image registration.
% 
% Input:
%   1.ref_ch: the channel number that is used as taget/reference channel
%      during registration, channel number is defined as the following:
%                     sensor 
%                       13
%                       24  
%      For our SPC prototype, 1->ASIN, 2->ACOS, 3->SIN, 4->COS
%   2.T: the number of time points

    %% load control ROIs
    [file,path] = uigetfile('*.mat','Load ROIs');
    if isequal(file,0)
         disp('User selected Cancel')
    else
         load(fullfile(path,file));
    end
    
    %% load control points
    switch ref_ch
        % reference channel is ASIN
        case 1
        ACOS_table = readmatrix(fullfile(path,'ACOS_landmarks.csv')); acos_fixpoint = ACOS_table(:,5:6);acos_movpoint = ACOS_table(:,3:4);
        SIN_table = readmatrix(fullfile(path,'SIN_landmarks.csv')); sin_fixpoint = SIN_table(:,5:6);sin_movpoint = SIN_table(:,3:4);
        COS_table = readmatrix(fullfile(path,'COS_landmarks.csv')); cos_fixpoint = COS_table(:,5:6);cos_movpoint = COS_table(:,3:4);

        tform_acos = fitgeotrans(acos_movpoint,acos_fixpoint,'lwm',size(acos_fixpoint,1));
        tform_sin = fitgeotrans(sin_movpoint,sin_fixpoint,'lwm',size(sin_fixpoint,1));
        tform_cos = fitgeotrans(cos_movpoint,cos_fixpoint,'lwm',size(cos_fixpoint,1));


        % reference channel is ACOS
        case 2
        SIN_table = readmatrix(fullfile(path,'SIN_landmarks.csv')); sin_fixpoint = SIN_table(:,5:6);sin_movpoint = SIN_table(:,3:4);
        COS_table = readmatrix(fullfile(path,'COS_landmarks.csv')); cos_fixpoint = COS_table(:,5:6);cos_movpoint = COS_table(:,3:4);
        ASIN_table = readmatrix(fullfile(path,'ASIN_landmarks.csv')); asin_fixpoint = ASIN_table(:,5:6);asin_movpoint = ASIN_table(:,3:4);    

        tform_sin = fitgeotrans(sin_movpoint,sin_fixpoint,'lwm',size(sin_fixpoint,1));
        tform_cos = fitgeotrans(cos_movpoint,cos_fixpoint,'lwm',size(cos_fixpoint,1));
        tform_asin = fitgeotrans(asin_movpoint,asin_fixpoint,'lwm',size(asin_fixpoint,1));

        % reference channel is SIN
        case 3
        ACOS_table = readmatrix(fullfile(path,'ACOS_landmarks.csv')); acos_fixpoint = ACOS_table(:,5:6);acos_movpoint = ACOS_table(:,3:4);
        COS_table = readmatrix(fullfile(path,'COS_landmarks.csv')); cos_fixpoint = COS_table(:,5:6);cos_movpoint = COS_table(:,3:4);
        ASIN_table = readmatrix(fullfile(path,'ASIN_landmarks.csv')); asin_fixpoint = ASIN_table(:,5:6);asin_movpoint = ASIN_table(:,3:4);

        tform_acos = fitgeotrans(acos_movpoint,acos_fixpoint,'lwm',size(acos_fixpoint,1));
        tform_cos = fitgeotrans(cos_movpoint,cos_fixpoint,'lwm',size(cos_fixpoint,1));
        tform_asin = fitgeotrans(asin_movpoint,asin_fixpoint,'lwm',size(asin_fixpoint,1));

        % reference channel is COS
        case 4
        ACOS_table = readmatrix(fullfile(path,'ACOS_landmarks.csv')); acos_fixpoint = ACOS_table(:,5:6);acos_movpoint = ACOS_table(:,3:4);
        SIN_table = readmatrix(fullfile(path,'SIN_landmarks.csv')); sin_fixpoint = SIN_table(:,5:6);sin_movpoint = SIN_table(:,3:4);
        ASIN_table = readmatrix(fullfile(path,'ASIN_landmarks.csv')); asin_fixpoint = ASIN_table(:,5:6);asin_movpoint = ASIN_table(:,3:4);

        tform_acos = fitgeotrans(acos_movpoint,acos_fixpoint,'lwm',size(acos_fixpoint,1));
        tform_sin = fitgeotrans(sin_movpoint,sin_fixpoint,'lwm',size(sin_fixpoint,1));
        tform_asin = fitgeotrans(asin_movpoint,asin_fixpoint,'lwm',size(asin_fixpoint,1));
    end
    %% load dark frame for dark-current correction
     [file,path] = uigetfile('*.tif','Load dark frame');
     if isequal(file,0)
         disp('User selected Cancel')
     else
        dark_tif = bfopen(fullfile(path,file));
     end
    % get the image size
    [H,W] = size(dark_tif{1,1}{1});
    % calculate the average dark frame
    dark_img = zeros(H,W);
    % calculate average dark frame 
    for n = 1:size(dark_tif{1,1},1)
        dark_img = dark_img + double(dark_tif{1,1}{n,1});
    end
    dark_img = uint16(dark_img/size(dark_tif{1,1},1));
    % get the size of registered image
    [h,w] = size(dark_img(position{ref_ch}(2):position{ref_ch}(2)+position{ref_ch}(4),position{ref_ch}(1):position{ref_ch}(1)+position{ref_ch}(3)));
    %% load images to be registered, only one ome.tif file needs to be selected, others will be loaded automatically 
    [file,path] = uigetfile('*.ome.tif','Load images to be registered');
     if isequal(file,0)
         disp('User selected Cancel')
     else
        img = bfopen(fullfile(path,file));
     end
    % get the number of tiles to be registered 
    N = size(img,1);
    % get the number of z stacks
    Z = size(img{1,1},1)/T;
    %% start registration, registered images will be save to a subfolder
    % called 'registered' under MATLAB current folder
    mkdir('registered');   
    % preallocation for one registered tile, image saving order (X,Y,Z,C,T)
    img_registered = zeros(h,w,Z,4,T,'uint16');
    
     for i = 1:N
        % create  metadata 
        metadata = createMinimalOMEXMLMetadata(img_registered);
        % set the actual pixel size
        pix_size = 0.297; %um
        pixelSize = ome.units.quantity.Length(java.lang.Double(pix_size), ome.units.UNITS.MICROMETER);
        % set the pixel size in object plane
        metadata.setPixelsPhysicalSizeX(pixelSize, 0);
        metadata.setPixelsPhysicalSizeY(pixelSize, 0);
        % set the z step
        z_step = 1;%um
        pixelSizeZ = ome.units.quantity.Length(java.lang.Double(z_step), ome.units.UNITS.MICROMETER);
        metadata.setPixelsPhysicalSizeZ(pixelSizeZ, 0);
        RefObj = imref2d(size(img{1,1}{1,1}(position{ref_ch}(2):position{ref_ch}(2)+position{ref_ch}(4),position{ref_ch}(1):position{ref_ch}(1)+position{ref_ch}(3))));


        % go through all time points
        for t = 1:T
           % go through all z stacks
           for z = 1:Z
               % display current registered image
                disp(strcat('n=',num2str(i),'t=',num2str(t),'z=',num2str(z)));
                % go through all channels
                for ch = 1:4
                    if ch ~= ref_ch
                         channel_registering = img{i,1}{z+(t-1)*Z,1}(position{ch}(2):position{ch}(2)+position{ch}(4),position{ch}(1):position{ch}(1)+position{ch}(3))- dark_img(position{ch}(2):position{ch}(2)+position{ch}(4),position{ch}(1):position{ch}(1)+position{ch}(3));

                         switch ch
                            case 1
                            channel_registered  =  imwarp(channel_registering,tform_asin,'OutputView', RefObj);
                            case 2
                            channel_registered  =  imwarp(channel_registering,tform_acos,'OutputView', RefObj);
                            case 3
                            channel_registered  =  imwarp(channel_registering,tform_sin,'OutputView', RefObj);
                            case 4
                            channel_registered  =  imwarp(channel_registering,tform_cos,'OutputView', RefObj);
                         end
                             img_registered(:,:,z,ch,t) = channel_registered;
                    else
                       img_registered(:,:,z,ch,t) = img{i,1}{z+(t-1)*Z,1}(position{ch}(2):position{ch}(2)+position{ch}(4),position{ch}(1):position{ch}(1)+position{ch}(3)) - dark_img(position{ch}(2):position{ch}(2)+position{ch}(4),position{ch}(1):position{ch}(1)+position{ch}(3));
                    end
                end
          end
        end
            % remove 'not a number' elements
            img_registered(isnan(img_registered)) = 0;
            %  save image
            img_name = extractBetween(img{i,1}{1,2},'; ',';'); img_name = strcat(img_name{1},'.ome.tif');
            bfsave(img_registered, strcat('Registered\',img_name), 'metadata', metadata);
     end  
end

