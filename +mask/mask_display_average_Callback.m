function mask_display_average_Callback (~,~,~)
handles=gui.gui_gethand;
bg_img_A = gui.gui_retr('bg_img_A');
bg_img_B = gui.gui_retr('bg_img_B');
if get(handles.bg_subtract,'Value')==0
	set(handles.bg_subtract,'Value',1);
	bg_was_on=0;
else
	bg_was_on=1;
end
if isempty(bg_img_A) || isempty(bg_img_B)
	if gui.gui_retr('video_selection_done') == 0 && gui.gui_retr('parallel')==1 % this is not nice, duplicated functions, one for parallel and one for video....
		preproc.preproc_generate_BG_img_parallel
	else
		preproc.preproc_generate_BG_img
	end
	bg_img_A = gui.gui_retr('bg_img_A');
	bg_img_B = gui.gui_retr('bg_img_B');
end
pivlab_axis=gui.gui_retr('pivlab_axis');
bg_img_AB=double((bg_img_A+bg_img_B)/2);
bg_img_AB=bg_img_AB/max(bg_img_AB(:));
bg_img_AB = repmat(bg_img_AB,1,1,3);
image(bg_img_AB, 'parent',pivlab_axis, 'cdatamapping', 'scaled');
colormap('gray');
axis image;
set(gca,'ytick',[])
set(gca,'xtick',[])

if bg_was_on==0
	set(handles.bg_subtract,'Value',0)
	gui.gui_put('bg_img_A',[]);
	gui.gui_put('bg_img_B',[]);
end