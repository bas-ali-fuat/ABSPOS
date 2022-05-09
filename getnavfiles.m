function [navfilename] = getnavfiles(date)
warning off;
% Last Update: 2021-04-17
% Created by: Erman ÞENTÜRK
% Address: Kocaeli University, Department of Surveying Engineering
% E-mail: erman.senturk@kocaeli.edu.tr
% %**************************************************************************
% % getnavfiles('2022-01-22')
% %**************************************************************************
d = datevec(date);
v = datenum(d);
dayofyear = num2str(v - datenum(d(1),1,0), '%03i');
%local directory
directory = fullfile(pwd, 'data');
navdirectory = fullfile(directory, 'nav');
navfiledirectory = [navdirectory '\' num2str(d(1)) '\' dayofyear]; mkdir(navfiledirectory);
%ftp directory
navlocationsites = 'https://cddis.nasa.gov/archive/gnss/data/daily/';

filename{1} = ['brdc',dayofyear,'0.',num2str(mod(d(1),100),'%02d'),'n.gz'];
filename{2} = ['brdc',dayofyear,'0.',num2str(mod(d(1),100),'%02d'),'n.Z'];
navfile{1} = [navlocationsites num2str(d(1)) '/' dayofyear '/' num2str(mod(d(1),100),'%02d') 'n/' filename{1}];
navfile{2} = [navlocationsites num2str(d(1)) '/' dayofyear '/' num2str(mod(d(1),100),'%02d') 'n/' filename{2}];

wget_exe = ['"' fullfile(fullfile(pwd, 'apps'), 'wget.exe') '"'];
gzip_exe = ['"' fullfile(fullfile(pwd, 'apps'), 'gzip.exe') '"'];

for i = 1 : 2
    wgetnav{i} = [ wget_exe  ' -O ' navfiledirectory '\' filename{i} ' --auth-no-challenge --user=alifuat_bas --password=21042018Ali ' navfile{i}];
    %downloading file
    if exist(fullfile(navfiledirectory, filename{i}), 'file') ~= 2 && exist(fullfile(navfiledirectory, filename{1}(1:end-3)), 'file') ~= 2 && exist(fullfile(navfiledirectory, filename{2}(1:end-2)), 'file') ~= 2
       disp('Downloading daily broadcast files ...');
       system(wgetnav{i});
    end
    s = dir(fullfile(navfiledirectory, filename{i}));
    if (exist(fullfile(navfiledirectory, filename{i}), 'file') == 2) && s.bytes > 0
        %unzip
        system([gzip_exe ' -df ' fullfile(navfiledirectory, filename{i})]);
    else
        delete(fullfile(navfiledirectory, filename{i}))
    end
    if i == 1
        navfilename = fullfile(navfiledirectory, filename{i}(1:end-3));
    else
        navfilename = fullfile(navfiledirectory, filename{i}(1:end-2));
    end
end
end