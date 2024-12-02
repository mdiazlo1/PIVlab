function FetchFilterMatrices()
%Jassal, G., & Schmidt, B. E. (2024, August 12). wOFV Filter Matrices. https://doi.org/10.17605/OSF.IO/Y48MK
gui.update_progress(0)
uiwait(warndlg('Wavelet filter matrices do not exist. They are downloaded and stored for later use now.','No filter matrices found','modal'));
gui.toolsavailable(1)
gui.toolsavailable(0,'Downloading filter matrices...');drawnow
FileName = fullfile(userpath, 'Filter Matrices.zip');
F = parfeval(backgroundPool,@download_stuff,0,FileName);
pause(1)
fig = uifigure;
fig.Visible='off';
fig.Position = [680   687   444   191];
movegui(fig,'center');
fig.Resize='off';
fig.WindowStyle = 'modal';
fig.Visible='on';
d = uiprogressdlg(fig,'Title','Please Wait','Message','Downloading filter matrices','Cancelable','on');
progress=0;
while strcmpi (F.State, 'running')
	s = dir(FileName);
	if ~isempty(s)
		filesize = s.bytes;
		progress= (filesize/256840824);
		d.Value=progress;
		d.Message = ['Downloading filter matrices (' num2str(round(filesize/1024/1024)) ' / ' num2str(round(256840824/1024/1024)) ' MB done).'];
	end
	if d.CancelRequested
		cancel(F)
		break
	end
	pause(0.25)
end
close(d)
close(fig)

gui.toolsavailable(1)
gui.toolsavailable(0,'Unzipping filter matrices...');drawnow
disp('Filter Matrices downloaded, unzipping...')
[filepath,~,~]=  fileparts(which('PIVlab_GUI.m'));
unzip(FileName,fullfile(filepath,'+wOFV','Filter matrices'))
disp('Filter Matrices stored.')
delete(FileName)
gui.toolsavailable(1)
gui.toolsavailable(0,'Busy, please wait...');drawnow

function download_stuff (FileName)
FileUrl = 'https://files.osf.io/v1/resources/y48mk/providers/osfstorage/?zip=';
options = weboptions('Timeout',10);
websave(FileName,FileUrl,options);