function [] = crop()
    % This function is for cropping the spectral phaosr camera target image
    % into four channels and manually use them to find the control points of
    % one chosen reference channel with other three moving channels during
    % image registration.
    
    %% open target image which should have .tif or .tiff extension
    [file,path] = uigetfile({'*.tif';'*.tiff'});
    target_img = imread(strcat(path,file));
    %% crop image 
    imshow(uint8(255*mat2gray(target_img)));
    % start cropping
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
    %% display cropped images,export 4 channels and save control points

    figure(2);
    subplot(2,2,1);
    imshow(uint8(255*mat2gray(target_img(position{1}(2):position{1}(2)+position{1}(4),position{1}(1):position{1}(1)+position{1}(3)))));
    imwrite(target_img(position{1}(2):position{1}(2)+position{1}(4),position{1}(1):position{1}(1)+position{1}(3)),strcat(path,'ASIN.tif'));
    title('ASIN');

    subplot(2,2,3);
    imshow(uint8(255*mat2gray(target_img(position{2}(2):position{2}(2)+position{2}(4),position{2}(1):position{2}(1)+position{2}(3)))));
    imwrite(target_img(position{2}(2):position{2}(2)+position{2}(4),position{2}(1):position{2}(1)+position{2}(3)),strcat(path,'ACOS.tif'));
    title('ACOS');

    subplot(2,2,2);
    imshow(uint8(255*mat2gray(target_img(position{3}(2):position{3}(2)+position{3}(4),position{3}(1):position{3}(1)+position{3}(3)))));
    imwrite(target_img(position{3}(2):position{3}(2)+position{3}(4),position{3}(1):position{3}(1)+position{3}(3)),strcat(path,'SIN.tif'));
    title('SIN');

    subplot(2,2,4);
    imshow(uint8(255*mat2gray(target_img(position{4}(2):position{4}(2)+position{4}(4),position{4}(1):position{4}(1)+position{4}(3)))));
    imwrite(target_img(position{4}(2):position{4}(2)+position{4}(4),position{4}(1):position{4}(1)+position{4}(3)),strcat(path,'COS.tif'));
    title('COS');

    save(strcat(path,'ROIs.mat'),'position');

end

