function [x, y, u, v, typevec,corr_map] = piv_analysis(image1,image2,...
    PairNum,piv_setting,nr_of_cores,graph)
    % wrapper function to do PIV preprocess and PIV fft for a pair of image

    % INPUT
    %dir: directory containing images
    % filename1: the first image
    % filename2: the second image 
    % preprocess_setting: cell of dimension 10 x 2
    % piv_setting: cell of dimension 13 x 2
    % nr_of_cores: number of cores specified by user 
    % graph: bool, whether to display graphical output ( not available
    % for parallel worker)
    
    % OUTPUT
    % x, y: coordinates of vectors
    % u, v: resulted components of vector field
    % typevec: type vector
    % corr_map: corellation map

    % Original PIVlab code
    % image1=imread(fullfile(dir, filename1)); % read images
    % image2=imread(fullfile(dir, filename2));
    
    % Skip the image pre-processing step since I am doing my own processing
    % image1 = preproc.PIVlab_preproc (image1,...
    %     preprocess_setting{1,2},...
    %     preprocess_setting{2,2},...
    %     preprocess_setting{3,2},...
    %     preprocess_setting{4,2},...
    %     preprocess_setting{5,2},...
    %     preprocess_setting{6,2},...
    %     preprocess_setting{7,2},...
    %     preprocess_setting{8,2},...
    %     preprocess_setting{9,2},...
    %     preprocess_setting{10,2}); %preprocess images
    % image2 = preproc.PIVlab_preproc (image2,...
    %     preprocess_setting{1,2},...
    %     preprocess_setting{2,2},...
    %     preprocess_setting{3,2},...
    %     preprocess_setting{4,2},...
    %     preprocess_setting{5,2},...
    %     preprocess_setting{6,2},...
    %     preprocess_setting{7,2},...
    %     preprocess_setting{8,2},...
    %     preprocess_setting{9,2},...
    %     preprocess_setting{10,2});

    [x, y, u, v, typevec,corr_map,~] = piv.piv_FFTmulti(image1,image2,...
        piv_setting{1,2},...
        piv_setting{2,2},...
        piv_setting{3,2},...
        piv_setting{4,2},...
        piv_setting{5,2},...
        piv_setting{6,2},...
        piv_setting{7,2},...
        piv_setting{8,2},...
        piv_setting{9,2},...
        piv_setting{10,2},...
        piv_setting{11,2},...
        piv_setting{12,2},...
        piv_setting{13,2},0,...
				piv_setting{14,2},...
				piv_setting{15,2}); %actual PIV analysis
        
    if graph && nr_of_cores == 1 % won't run in parallel mode
        
        imagesc(double(image1)+double(image2));colormap('gray');
        hold on
        quiver(x,y,u,v,'g','AutoScaleFactor', 1.5);
        hold off;
        axis image;
        title(['Raw result ' num2str(PairNum)],'interpreter','none')
        set(gca,'xtick',[],'ytick',[])
        drawnow;
        
    end


end