function draw_extraction_coordinates_Callback(caller, ~, ~)
gui.sliderdisp(gui.retr('pivlab_axis'));
handles=gui.gethand;
currentframe=floor(get(handles.fileselector, 'value'));
resultslist=gui.retr('resultslist');
gui.put('extract_type',[]);
if size(resultslist,2)>=currentframe && numel(resultslist{1,currentframe})>0
	gui.toolsavailable(0);
	xposition=[];
	yposition=[];
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_poly')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_poly_area')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_area')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series_area')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_rectangle_area')); %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series_displayed_smaller_radii')) %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series_area_displayed_smaller_radii')) %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series_max_circulation')) %delete pre-existing
	delete(findobj(gui.retr('pivlab_axis'),'Tag','extract_circle_series_area_max_circulation')) %delete pre-existing

	if (strcmp(caller.Tag,'draw_stuff') && strcmp(handles.draw_what.String{handles.draw_what.Value},'polyline')) || (strcmp(caller.Tag,'draw_stuff_area') && strcmp(handles.draw_what_area.String{handles.draw_what_area.Value},'polygon'))%polyline
		if strcmp(caller.Tag,'draw_stuff') %extract from polyline
			extract_type='extract_poly';
			extract_poly = images.roi.Polyline;
		elseif strcmp(caller.Tag,'draw_stuff_area')%extract from area
			extract_type='extract_poly_area';
			extract_poly = images.roi.Polygon;
		end
		extract_poly.Tag=extract_type;
		extract_poly.LabelVisible = 'on';
		extract_poly.Label = "right mouse click stops drawing";
		draw(extract_poly);
		extract_poly.LabelVisible = 'off';
		addlistener(extract_poly,'ROIMoved',@extract.poly_ROIevents);
		addlistener(extract_poly,'MovingROI',@extract.poly_ROIevents);
		addlistener(extract_poly,'DeletingROI',@extract.poly_ROIevents);
		if numel(extract_poly.Position) >=4
			xposition=extract_poly.Position(:,1);
			yposition=extract_poly.Position(:,2);
			extract_poly.LabelVisible = 'hover';
			if ~verLessThan('matlab','9.8') %I have no clue when this functionality was added... Can't find any info on this.
				extract_poly.LabelAlpha = 0.5;
				extract_poly.LabelTextColor = 'w';
			end
			if size(extract_poly.Position,1)<6
				labelstring=[];
				for i = 1:size(extract_poly.Position,1)
					labelstring=[labelstring num2str(round(extract_poly.Position(i,1))) ',' num2str(round(extract_poly.Position(i,2))) ' ; ']; %#ok<AGROW>
				end
				extract_poly.Label = labelstring;
			else
				extract_poly.LabelVisible = 'off';
			end
		end
	elseif (strcmp(caller.Tag,'draw_stuff') && strcmp(handles.draw_what.String{handles.draw_what.Value},'circle')) || (strcmp(caller.Tag,'draw_stuff_area') && strcmp(handles.draw_what_area.String{handles.draw_what_area.Value},'circle'))%circle
		if strcmp(caller.Tag,'draw_stuff') %extract from polyline
			extract_type='extract_circle';
		elseif strcmp(caller.Tag,'draw_stuff_area') %extract from area
			extract_type='extract_circle_area';
		end
		extract_poly = images.roi.Circle;
		extract_poly.LabelVisible = 'off';
		extract_poly.Tag=extract_type;
		draw(extract_poly);
		if extract_poly.Radius < 25 %check if circle is large enough or if user accidentally clicked once
			extract_poly.Radius = 25;
		end
		addlistener(extract_poly,'ROIMoved',@extract.poly_ROIevents);
		addlistener(extract_poly,'DeletingROI',@extract.poly_ROIevents);
		xposition=extract_poly.Center;
		yposition=extract_poly.Radius;
	elseif (strcmp(caller.Tag,'draw_stuff') && strcmp(handles.draw_what.String{handles.draw_what.Value},'circle series (tangent vel. only)')) || (strcmp(caller.Tag,'draw_stuff_area') && strcmp(handles.draw_what_area.String{handles.draw_what_area.Value},'circle series'))%circle series
		if strcmp(caller.Tag,'draw_stuff') %extract from polyline
			extract_type='extract_circle_series';
			set(handles.extraction_choice,'Value',11);
		elseif strcmp(caller.Tag,'draw_stuff_area') %extract from area
			extract_type='extract_circle_series_area';
		end
		extract_poly = images.roi.Circle;
		extract_poly.LabelVisible = 'off';
		extract_poly.Tag=extract_type;
		draw(extract_poly);
		if extract_poly.Radius < 25 %check if circle is large enough or if user accidentally clicked once
			extract_poly.Radius = 25;
		end
		addlistener(extract_poly,'ROIMoved',@extract.poly_ROIevents);
		addlistener(extract_poly,'DeletingROI',@extract.poly_ROIevents);
		xposition=extract_poly.Center;
		yposition=extract_poly.Radius;
		x=resultslist{1,currentframe};
		stepsize=ceil((x(1,2)-x(1,1))/1);
		radii=linspace(stepsize,extract_poly.Radius-stepsize,round(((extract_poly.Radius-stepsize)/stepsize)));
		for radius=radii
			extract_poly_series=drawcircle(gui.retr('pivlab_axis'),'Center',xposition,'Radius',radius,'Tag',[extract_type '_displayed_smaller_radii'],'Deletable',0,'FaceAlpha',0,'FaceSelectable',0,'InteractionsAllowed','none');
		end
		x_center=extract_poly.Center(1);
		y_center=extract_poly.Center(2);
		radius=extract_poly.Radius;
		text(x_center,y_center+radius,' start/end','FontSize',7, 'Rotation', 90, 'BackgroundColor',[1 1 1],'tag',[extract_type '_displayed_smaller_radii'])
		text(x_center,y_center+radius+8,'\rightarrow','FontSize',7, 'BackgroundColor',[1 1 1],'tag',[extract_type '_displayed_smaller_radii'])
		text(x_center,y_center-radius-8,'\leftarrow','FontSize',7, 'BackgroundColor',[1 1 1],'tag',[extract_type '_displayed_smaller_radii'])
		text(x_center-radius-8,y_center,'\leftarrow','FontSize',7, 'BackgroundColor',[1 1 1], 'Rotation', 90,'tag',[extract_type '_displayed_smaller_radii'])
		text(x_center+radius+8,y_center,'\rightarrow','FontSize',7, 'BackgroundColor',[1 1 1], 'Rotation', 90,'tag',[extract_type '_displayed_smaller_radii'])
	elseif strcmp(caller.Tag,'draw_stuff_area') && strcmp(handles.draw_what_area.String{handles.draw_what_area.Value},'rectangle') %rectangle
		extract_type='extract_rectangle_area';
		extract_poly = images.roi.Rectangle;
		extract_poly.LabelVisible = 'off';
		extract_poly.Tag=extract_type;
		draw(extract_poly);
		if extract_poly.Position(3) < 25 %check if rectangle is large enough or if user accidentally clicked once
			extract_poly.Position(3) = 25;
		end
		if extract_poly.Position(4) < 25 %check if rectangle is large enough or if user accidentally clicked once
			extract_poly.Position(4) = 25;
		end
		addlistener(extract_poly,'ROIMoved',@extract.poly_ROIevents);
		addlistener(extract_poly,'DeletingROI',@extract.poly_ROIevents);
		xposition=[extract_poly.Position(1) extract_poly.Position(3)]; %x and width of rectangle
		yposition=[extract_poly.Position(2) extract_poly.Position(4)]; %y and height of rectangle
	end
	gui.put('xposition',xposition)
	gui.put('yposition',yposition)
	gui.put('extract_type',extract_type);
	gui.toolsavailable(1);
end

