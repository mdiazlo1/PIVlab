function [x,y,u,v,u_filt,v_filt] = PIVlab_commandline(images,settings)
% Example script how to use PIVlab from the commandline
% Just run this script to see what it does.
% You can adjust the settings in "s" and "p", specify a mask and a region of interest


nr_of_cores = 1; % integer, 1 means single core, greater than 1 means parallel
if nr_of_cores > 1
    try
        local_cluster=parcluster('local'); % single node
        corenum =  local_cluster.NumWorkers ; % fix : get the number of cores available
    catch
        warning('on');
        warning('parallel local cluster can not be created, assigning number of cores to 1');
        nr_of_cores = 1;
    end
end

amount = size(images,3);
%% Standard PIV Settings
s = cell(15,2); % To make it more readable, let's create a "settings table"
%Parameter                          %Setting			%Options
s{1,1}= 'Int. area 1';              s{1,2}=settings.W1;			% window size of first pass
s{2,1}= 'Step size 1';              s{2,2}=settings.StepSize;			% step of first pass
s{3,1}= 'Subpix. finder';           s{3,2}=1;			% 1 = 3point Gauss, 2 = 2D Gauss
s{4,1}= 'Mask';                     s{4,2}=[];			% If needed, supply a binary image mask with the same size as the PIV images
s{5,1}= 'ROI';                      s{5,2}=settings.ROI;			% Region of interest: [x,y,width,height] in pixels, may be left empty to process the whole image
s{6,1}= 'Nr. of passes';            s{6,2}=settings.NumPass;			% 1-4 nr. of passes
s{7,1}= 'Int. area 2';              s{7,2}=settings.W2;			% second pass window size
s{8,1}= 'Int. area 3';              s{8,2}=settings.W3;			% third pass window size
s{9,1}= 'Int. area 4';              s{9,2}=settings.W4;			% fourth pass window size
s{10,1}='Window deformation';       s{10,2}='*linear';	% '*spline' is more accurate, but slower
s{11,1}='Repeated Correlation';     s{11,2}=0;			% 0 or 1 : Repeat the correlation four times and multiply the correlation matrices.
s{12,1}='Disable Autocorrelation';  s{12,2}=0;			% 0 or 1 : Disable Autocorrelation in the first pass.
s{13,1}='Correlation style';        s{13,2}=0;			% 0 or 1 : Use circular correlation (0) or linear correlation (1).
s{14,1}='Repeat last pass';			s{14,2}=0;			% 0 or 1 : Repeat the last pass of a multipass analyis
s{15,1}='Last pass quality slope';  s{15,2}=0.025;		% Repetitions of last pass will stop when the average difference to the previous pass is less than this number.


%% Standard image preprocessing settings (not used)
p = cell(10,1);
%Parameter                       %Setting           %Options
p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
p{2,1}= 'CLAHE';                 p{2,2}=0;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
p{3,1}= 'CLAHE size';            p{3,2}=50;         % CLAHE window size
p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
p{6,1}= 'Clipping';              p{6,2}=0;          % 1 = enable clipping, 0 = disable
p{7,1}= 'Wiener';                p{7,2}=0;          % 1 = enable Wiener2 adaptive denoise filter, 0 = disable
p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size
p{9,1}= 'Minimum intensity';     p{9,2}=0.0;        % Minimum intensity of input image (0 = no change)
p{10,1}='Maximum intensity';     p{10,2}=1.0;       % Maximum intensity on input image (1 = no change)

%% other settings
pairwise = settings.Type; % 0 for [A+B], [B+C], [C+D]... sequencing style, and 1 for [A+B], [C+D], [E+F]... sequencing style

%% PIV analysis loop
if pairwise == 1
    if mod(amount,2) == 1 %Uneven number of images?
        disp('Image folder should contain an even number of images.')
        %remove last image from list
        amount=amount-1;
    end

    disp(['Found ' num2str(amount) ' images (' num2str(amount/2) ' image pairs).'])
    x=cell(amount/2,1);
    y=x;
    u=x;
    v=x;
else
    disp(['Found ' num2str(amount) ' images'])
    x=cell(amount-1,1);
    y=x;
    u=x;
    v=x;
end

typevector=x; %typevector will be 1 for regular vectors, 0 for masked areas
correlation_map=x; % correlation coefficient

%% Main PIV analysis loop:
% parallel
ImgPairNum = amount/2;

% if nr_of_cores > 1
% 	if misc.pivparpool('size')<nr_of_cores
% 		misc.pivparpool('open',nr_of_cores);
% 	end
%
% 	parfor i=1:amount  % index must increment by 1
% 		[x{i}, y{i}, u{i}, v{i}, typevector{i},correlation_map{i}] = ...
% 			piv.piv_analysis(images(:,:,i),images(:,:,i+1),i,s,nr_of_cores,false);
% 	end % sequential loop
for i=1:2:amount % index must increment by 1

    [x{i}, y{i}, u{i}, v{i}, typevector{i},correlation_map{i}] = ...
        piv.piv_analysis(images(:,:,i), images(:,:,i+1),i,s,nr_of_cores,true);

    disp([int2str((i)/amount*100) ' %']);

end
x = x(~cellfun('isempty',x)); y = y(~cellfun('isempty',y));
u = u(~cellfun('isempty',u)); v = v(~cellfun('isempty',v));
typevector = typevector(~cellfun('isempty',typevector));
correlation_map = correlation_map(~cellfun('isempty',correlation_map));
% The most important results are x,y,u,v. These can now be validated

%% PIV postprocessing loop
% Standard image post processing settings

r = cell(6,1);
%Parameter     %Setting                                     %Options
r{1,1}= 'Calibration factor, 1 for uncalibrated data';      r{1,2}=settings.UCal;                   % Calibration factor for u
r{2,1}= 'Calibration factor, 1 for uncalibrated data';      r{2,2}=settings.VCal;                   % Calibration factor for v
r{3,1}= 'Valid velocities [u_min; u_max; v_min; v_max]';    r{3,2}=settings.ValVel;  % Maximum allowed velocities, for uncalibrated data: maximum displacement in pixels
r{4,1}= 'Stdev check?';                                     r{4,2}=0;                   % 1 = enable global standard deviation test
r{5,1}= 'Stdev threshold';                                  r{5,2}=7;                   % Threshold for the stdev test
r{6,1}= 'Local median check?';                              r{6,2}=0;                   % 1 = enable local median test
r{7,1}= 'Local median threshold';                           r{7,2}=3;                   % Threshold for the local median test

u_filt=cell(size(u));
v_filt=cell(size(v));
typevector_filt=typevector;

if nr_of_cores >1 % parallel loop

    if misc.pivparpool('size')<nr_of_cores
        misc.pivparpool('open',nr_of_cores);
    end

    parfor PIVresult=1:size(x,1)

        [u_filt{PIVresult,1}, v_filt{PIVresult,1},typevector_filt{PIVresult,1}]= ...
            post_proc_wrapper(u{PIVresult,1},v{PIVresult,1},typevector{PIVresult,1},r,true);

    end

else % sequential loop

    for PIVresult=1:size(x,1)

        [u_filt{PIVresult,1}, v_filt{PIVresult,1},typevector_filt{PIVresult,1}]= ...
            post_proc_wrapper(u{PIVresult,1},v{PIVresult,1},typevector{PIVresult,1},r,true);

    end

end

%% clean up parallel pool, and cluster (if required, will save RAM)
%{
if nr_of_cores >1 % parallel
	poolobj = gcp('nocreate'); % GET the current parallel pool
	if ~isempty(poolobj ); delete(poolobj );end
	clear local_cluster;
end
%}
%%
% Save the data to a Matlab file
% save(fullfile(SaveDirectory, 'frames_result_.mat'));

%%
clearvars -except p s r x y u v typevector directory filenames u_filt v_filt typevector_filt correlation_map
disp('DONE.')

end
function [u_filt, v_filt,typevector_filt] = post_proc_wrapper(u,v,typevector,post_proc_setting,paint_nan)
% wrapper function for postproc.PIVlab_postproc

% INPUT
% u, v: u and v components of vector fields
% typevector: type vector
% post_proc_setting: post processing setting
% paint_nan: bool, whether to interpolate missing data

% OUTPUT
% u_filt, v_filt: post-processed u and v components of vector fields
% typevector_filt: post-processed type vector


[u_filt,v_filt] = postproc.PIVlab_postproc(u,v, ...
    post_proc_setting{1,2},...
    post_proc_setting{2,2},...
    post_proc_setting{3,2},...
    post_proc_setting{4,2},...
    post_proc_setting{5,2},...
    post_proc_setting{6,2},...
    post_proc_setting{7,2});

typevector_filt = typevector; % initiate
typevector_filt(isnan(u_filt))=2;
typevector_filt(isnan(v_filt))=2;
typevector_filt(typevector==0)=0; %restores typevector for mask

if paint_nan
    u_filt=misc.inpaint_nans(u_filt,4);
    v_filt=misc.inpaint_nans(v_filt,4);
end


end
