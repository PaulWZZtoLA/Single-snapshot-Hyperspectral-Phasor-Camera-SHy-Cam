% This is a demo script for conducting image registration on a sample image
% acquired on SHy-Cam
% Revised on 2022-02-03
%% Cropping %%
% load target image for cropping & control point locating
target_img = imread('Target.tif');
% crop image
figure(1);
imshow(uint8(255*mat2gray(target_img)));
% start cropping
% for SHy-Cam presented in this work, 1->ASIN, 2->ACOS, 3->SIN, 4->COS
%      sensor
%   ------------
%   |          |  
%   | ASIN SIN |
%   |          |
%   | ACOS COS |
%   |          |
%   ------------
h = drawrectangle()
h.Label = 'ASIN';
wait(h);
position{1} = h.Position;

h = drawrectangle()
h.Label = 'ACOS';
wait(h);
position{2} = h.Position;

h = drawrectangle()
h.Label = 'SIN';
wait(h);
position{3} = h.Position;

h = drawrectangle()
h.Label = 'COS';
wait(h);
position{4} = h.Position;

% crop out 4 channels for control point locating
ASIN = target_img(position{1}(2):position{1}(2)+position{1}(4),position{1}(1):position{1}(1)+position{1}(3)); % ASIN channel, #1
ACOS = target_img(position{2}(2):position{2}(2)+position{2}(4),position{2}(1):position{2}(1)+position{2}(3)); % ACOS channel, #2
SIN  = target_img(position{3}(2):position{3}(2)+position{3}(4),position{3}(1):position{3}(1)+position{3}(3)); % SIN  channel, #3
COS  = target_img(position{4}(2):position{4}(2)+position{4}(4),position{4}(1):position{4}(1)+position{4}(3)); % COS channel,  #4

%% Control point locating %%
% In this example script, SIN channel is used as the reference (fixed)
% Please refer to the help page of 'cpselect' function
% define reference channel as SIN #3
ref_ch = 3;
% ASIN
[AS_movingpts,AS_fixedpts] = cpselect(imadjust(uint8(mat2gray(ASIN)*255),[],[],0.6),imadjust(uint8(mat2gray(SIN)*255),[],[],0.6),'Wait',true);
AS_movingpts_adjusted = cpcorr(AS_movingpts,AS_fixedpts,ASIN,SIN);
tform_asin = fitgeotrans(AS_movingpts_adjusted,AS_fixedpts,'lwm',size(AS_fixedpts,1));
Rfixed = imref2d(size(SIN));
ASIN_registered = imwarp(ASIN,tform_asin,'OutputView',Rfixed);
figure(2);subplot(1,3,1);imshowpair(ASIN_registered,SIN,'falsecolor');title('ASIN-SIN');
% ACOS
[AC_movingpts,AC_fixedpts] = cpselect(imadjust(uint8(mat2gray(ACOS)*255),[],[],0.6),imadjust(uint8(mat2gray(SIN)*255),[],[],0.6),'Wait',true);
AC_movingpts_adjusted = cpcorr(AC_movingpts,AC_fixedpts,ACOS,SIN);
tform_acos = fitgeotrans(AC_movingpts_adjusted,AC_fixedpts,'projective');
ACOS_registered = imwarp(ACOS,tform_acos,'OutputView',Rfixed);
subplot(1,3,2);imshowpair(ACOS_registered,SIN,'blend');title('ACOS-SIN');
% COS
[C_movingpts,C_fixedpts] = cpselect(imadjust(uint8(mat2gray(COS)*255),[],[],0.6),imadjust(uint8(mat2gray(SIN)*255),[],[],0.6),'Wait',true);
C_movingpts_adjusted = cpcorr(C_movingpts,C_fixedpts,COS,SIN);
tform_cos = fitgeotrans(C_movingpts_adjusted,C_fixedpts,'projective');
COS_registered = imwarp(COS,tform_cos,'OutputView',Rfixed);
subplot(1,3,3);imshowpair(COS_registered,SIN,'blend');title('COS-SIN');
%% Registration %%
% fit geometric transformation to control point pair based on local
% weighted mean method: Goshtasby, Ardeshir, "Image registration by local approximation methods," Image and Vision Computing, Vol. 6, 1988, pp. 255-261.
tform_acos = fitgeotrans(AC_movingpts,AC_fixedpts,'lwm',size(AC_fixedpts,1));
tform_cos = fitgeotrans(C_movingpts,C_fixedpts,'lwm',size(C_fixedpts,1));
tform_asin = fitgeotrans(AS_movingpts,AS_fixedpts,'lwm',size(AS_fixedpts,1));
% load sample image to be registered  
img = bfopen('Sample image.ome.tif');
% load dark frames for removing background signal
dark_tif = bfopen('Dark frame.ome.tif');
% get the original image size
[H,W] = size(dark_tif{1,1}{1});
% calculate the average dark frame
dark_img = zeros(H,W);
% calculate average dark frame 
for n = 1:size(dark_tif{1,1},1)
    dark_img = dark_img + double(dark_tif{1,1}{n,1});
end
dark_img = uint16(dark_img/size(dark_tif{1,1},1));
clear H W dark_tif 
% get the size of registered image
[h,w] = size(dark_img(position{ref_ch}(2):position{ref_ch}(2)+position{ref_ch}(4),position{ref_ch}(1):position{ref_ch}(1)+position{ref_ch}(3)));
% get the number of tiles to be registered 
N = size(img,1);
% the number of time points, in this sample image, T = 9
T = 9;
% get the number of z stacks
Z = size(img{1,1},1)/T;
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
        bfsave(img_registered, strcat('registered.ome.tif'), 'metadata', metadata);
 end  


