function preproc_generate_BG_img_parallel
handles=gui.gui_gethand;
if get(handles.bg_subtract,'Value')==1
	bg_img_A = gui.gui_retr('bg_img_A');
	bg_img_B = gui.gui_retr('bg_img_B');
	sequencer=gui.gui_retr('sequencer');%Timeresolved or pairwise 0=timeres.; 1=pairwise
	if sequencer ~= 2 % bg subtraction only makes sense with time-resolved and pairwise sequencing style, not with reference style.
		if isempty(bg_img_A) || isempty(bg_img_B)
			answer = questdlg('Mean intensity background image needs to be calculated. Press ok to start.', 'Background subtraction', 'OK','Cancel','OK');
			if strcmp(answer , 'OK')
				%disp('BG not present, calculating now')
				%% Calculate BG for all images....
				% read first image to determine properties
				filepath = gui.gui_retr('filepath');
				if gui.gui_retr('video_selection_done') == 0
					[~,~,ext] = fileparts(filepath{1});
					if strcmp(ext,'.b16')
						image1=f_readB16(filepath{1});
						image2=f_readB16(filepath{2});
						imagesource='b16_image';
					else
						image1=imread(filepath{1});
						image2=imread(filepath{2});
						imagesource='normal_pixel_image';
					end
				else
					video_reader_object = gui.gui_retr('video_reader_object');
					video_frame_selection=gui.gui_retr('video_frame_selection');
					image1 = read(video_reader_object,video_frame_selection(1));
					image2 = read(video_reader_object,video_frame_selection(2));
					imagesource='from_video';
				end
				classimage=class(image1); %memorize the original image format (double, uint8 etc)

				if size(image1,3)>1
					image1=rgb2gray(image1); %rgb2gray conserves the variable class (single, double, uint8, uint16)
					image2=rgb2gray(image2);
					colorimg=1;
				else
					colorimg=0;
				end
				counter=1;

				%convert all image types to double, ranging from 0...1
				if strcmp(classimage,'double')==1 %double stays double
					%do nothing
				elseif strcmp(classimage,'single')==1 %e.g. 32bit tif, ranges from 0...1
					image1=double(image1);
					image2=double(image2);
				elseif strcmp(classimage,'uint16')==1 %e.g. 16bit tif, ranges from 0...65535
					image1=double(image1)/65535;
					image2=double(image2)/65535;
				elseif strcmp(classimage,'uint8')==1 %0...255
					image1=double(image1)/255;
					image2=double(image2)/255;
				end
				if sequencer==0 %time-resolved
					start_bg=2;
					skip_bg=1;
				else
					start_bg=3;
					skip_bg=2;
				end
				%perform image addition
				%if timeresolved: generate only one background image from all
				%images
				%if not: generate two background images. One from even frames,
				%one from odd frames
				gui.gui_toolsavailable(0,'Busy, please wait...')
				updatecntr=0;

				%das innere zu einer function machen und außen parfor...?
				%als erstes: normaler for loop erstellt feste Liste mit Dateinamen.
				%aus denen holt sich parfor loop die infos
				%loop unten kann so bleiben wie er ist, lädt aber nicht bilder, sondern schreibt dateinamen in liste
				cntr=1;
				imagelist_A=cell(0);
				imagelist_B=cell(0);
				for i=start_bg:skip_bg:size(filepath,1)

					imagelist_A{cntr}=filepath{i};
					if sequencer==1 %not time-resolved
						imagelist_B{cntr}=filepath{i+1};
					else
						imagelist_B=imagelist_A; %totally strange workaround for Matlab R2022b.... if sequencer == 0 then this variable will never be used. But if it is empty, then an error occurs...
					end

					cntr=cntr+1;

				end

				hbar = pivprogress(numel(imagelist_A),handles.preview_preprocess);
				parfor	i=1:numel(imagelist_A)

					image_to_add1=[];
					image_to_add2=[];
					counter=counter+1; %counts the amount of images --> do that elsewhere
					if strcmp('b16_image',imagesource)
						image_to_add1 = f_readB16(imagelist_A{i}); %will be double
						if sequencer==1 %not time-resolved
							image_to_add2 = f_readB16(imagelist_B{i});
						end
					elseif strcmp('normal_pixel_image',imagesource)
						image_to_add1 = imread(imagelist_A{i});
						if sequencer==1 %not time-resolved
							image_to_add2 = imread(imagelist_B{i}); %will be double or uint8
						end
					elseif strcmp('from_video',imagesource)
						disp('parallel bg calculation wird mit videoframes nicht gehen....')
					end
					%% convert images to a grayscale double
					%images arrive in their original format here
					%convert everything to grayscale and double [0...1]
					if colorimg==1
						image_to_add1 = rgb2gray(image_to_add1); %will conserve image class
						if sequencer==1 %not time-resolved
							image_to_add2 = rgb2gray(image_to_add2);
						end
					end

					if strcmp(classimage,'single')==1
						image_to_add1=double(image_to_add1);
						if sequencer==1 %not time-resolved
							image_to_add2=double(image_to_add2);
						end
					end
					if strcmp(classimage,'uint8')==1
						image_to_add1=double(image_to_add1)/255;
						if sequencer==1 %not time-resolved
							image_to_add2=double(image_to_add2)/255;
						end
					end
					if strcmp(classimage,'uint16')==1
						image_to_add1=double(image_to_add1)/65535;
						if sequencer==1 %not time-resolved
							image_to_add2=double(image_to_add2)/65535;
						end
					end

					%now everything is double [0...1]

					%% sum images
					image1=image1 +image_to_add1;
					if sequencer==1 %not time-resolved
						image2=image2+image_to_add2;
					end
					hbar.iterate(1); %#ok<*PFBNS>
				end %of for loop and image summing
				close(hbar);

				set (handles.preview_preprocess, 'string', 'Apply and preview current frame');
				%divide the sum by the amount of summed images
				image1_bg=image1/counter;
				if sequencer==1 %not time-resolved
					image2_bg=image2/counter;
				end

				%Convert back to original image class, if not double anyway
				if strcmp(classimage,'uint8')==1 %#ok<*STISA>
					image1_bg=uint8(image1_bg*255);
					if sequencer==1 %not time-resolved
						image2_bg=uint8(image2_bg*255);
					end
				end
				if strcmp(classimage,'single')==1
					image1_bg=single(image1_bg);
					if sequencer==1 %not time-resolved
						image2_bg=single(image2_bg);
					end
				end
				if strcmp(classimage,'uint16')==1
					image1_bg=uint16(image1_bg*65535);
					if sequencer==1 %not time-resolved
						image2_bg=uint16(image2_bg*65535);
					end
				end

				%make results accessible to the rest of the GUI:
				gui.gui_put('bg_img_A',image1_bg);
				if sequencer==1 %not time-resolved
					gui.gui_put('bg_img_B',image2_bg);
				else
					gui.gui_put('bg_img_B',image1_bg); %timeresolved --> same bg image for a and b
				end
				set(handles.preview_preprocess, 'String', 'Apply and preview current frame');drawnow;
				gui.gui_update_progress(0)
				gui.gui_toolsavailable(1)
			else % user has checkbox enabled, but doesn't want to calculate the background...
				set(handles.bg_subtract,'Value',0);
			end
		else
			%disp('BG exists')
		end

	else
		set(handles.bg_subtract,'Value',0);
		warndlg(['Background removal is only available with the following sequencing styles:' sprintf('\n') '* Time resolved: [A+B], [B+C], [C+D], ...' sprintf('\n') '* Pairwise: [A+B], [C+D], [E+F], ...'])
		uiwait
	end
end

