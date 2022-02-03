function [] = LU(nl,sum_to_one,T)
% This is a custom function for applying linear unmixing to SPC images 
% Input:
%      1. nl: boolean variable, 0->not apply normalization to
%      reference spectra and image, 1-> apply normalization
%      2. sum_to_one: 0->not apply sum-to-one constraint, 1-> apply
%      sum-to-one constraint
%      3. T: the number of time points
    %% load reference spectra
    %  reference spectra should be stored in a 4xN double-precision array
    %  (N:the number of signatures) and save in a .mat file named as 'ref_spectra.mat'
    [file,path] = uigetfile('*.mat','Load reference spectra');
    if isequal(file,0)
         disp('User selected Cancel')
    else
         load(fullfile(path,file));
    end
    % get the number of spectra
    CH = size(ref_spectra,2);
    % spectrum normalization
    if nl
        for i = 1:CH
           integral = 0;
           integral = ref_spectra(1,i)+ref_spectra(2,i)+ref_spectra(3,i)+ref_spectra(4,i);
           ref_spectra(:,i) = ref_spectra(:,i)/integral;
        end
    end
    %% load image
    % image should be OME.TIF format with (XYZCT) order
    [file,path] = uigetfile('*.ome.tif','Load images to be registered');
    if isequal(file,0)
         disp('User selected Cancel')
    else
        img = bfopen(fullfile(file,path));
    end
    %% Apply LU to image stack
    % get the number of z stacks
    Z = size(img{1,1},1)/4/T;
    % preallocation
    unmixed_stack = zeros(size(img{1,1}{1},1),size(img{1,1}{1},2),Z,CH,T,'uint16');
    metadata = createMinimalOMEXMLMetadata(unmixed_stack);
    % set the physical pixel size in object space
    pixel_size = 0.297; %um
    pixelSize = ome.units.quantity.Length(java.lang.Double(pixel_size), ome.units.UNITS.MICROMETER);
    metadata.setPixelsPhysicalSizeX(pixelSize, 0);
    metadata.setPixelsPhysicalSizeY(pixelSize, 0);
    % set the z step size
    z_step = 5; %um
    pixelSizeZ = ome.units.quantity.Length(java.lang.Double(z_step), ome.units.UNITS.MICROMETER);
    metadata.setPixelsPhysicalSizeZ(pixelSizeZ, 0);
    % set the constraints of linear least square solver, for detials,
    % please refer to the documentation of MATLAB 'lsqlin' function
    A = ones(1,CH);
    b = 1;
    
    if sum_to_one
        Aeq = ones(1,CH);
        beq = 1;
    else
       Aeq = [];
       beq = []; 
    end
    

    lb = zeros(CH,1);
    ub = ones(CH,1);
    options = optimoptions('lsqlin','Display','off');

    % go through all time points
    for t = 1:T
        % go through all z stacks
        for z = 1:Z
            disp(strcat('t=',num2str(t),'z=',num2str(z)));
            IMG = zeros([4,size(img{1,1}{1,1})]);
            for ch = 1:4
                 IMG(ch,:,:) = img{1,1}{4*Z*(t-1)+(z-1)*4+ch};
                 IMG_ave = reshape(double(IMG(3,:,:)) + double(IMG(4,:,:)),[1,size(IMG,2)*size(IMG,3)]);
            end

            IMG_2D = double(reshape(IMG,[4,size(IMG,2)*size(IMG,3)]));
    %         IMG_2D = IMG_2D./sum(IMG_2D,1);
            IMG_2D(isnan(IMG_2D)) = 0;

            tic;

                parfor i = 1:size(IMG,2)*size(IMG,3)
                    if sum(IMG_2D(:,i))~=0
                        unmixed(:,i) = lsqlin(ref_spectra,IMG_2D(:,i),A,b,Aeq,beq,lb,ub,[],options);
                    end
                end

            toc;

            for ch = 1:CH
                unmixed_stack(:,:,z,ch,t) = reshape(uint16(unmixed(ch,:).*IMG_ave),[size(IMG,2),size(IMG,3)]);
            end


        end
    end
    %
    bfsave(unmixed_stack, 'Unmixed Stack.ome.tif', 'metadata', metadata);
end

