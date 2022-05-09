function [rinexfilename] = getrinexfiles(date,station)
warning off;
% Last Update: 2021-04-17
% Created by: Erman ÞENTÜRK
% Address: Kocaeli University, Department of Surveying Engineering
% E-mail: erman.senturk@kocaeli.edu.tr
% %**************************************************************************
% % getrinexdata('2022-01-22', 'LAUT00FJI')
% %**************************************************************************
d = datevec(date);
v = datenum(d);
dayofyear = num2str(v - datenum(d(1),1,0), '%03i');
%local directory
directory = fullfile(pwd, 'data');
rinexdirectory = fullfile(directory, 'rinex');
rinexfiledirectory = [rinexdirectory '\' num2str(d(1)) '\' dayofyear]; mkdir(rinexfiledirectory);
%ftp directory
rinexlocationsites = 'https://cddis.nasa.gov/archive/gnss/data/daily/';

filename{1} = [lower(station(1:4)),dayofyear,'0.',num2str(mod(d(1),100),'%02d'),'o.gz'];
rinexfile{1} = [rinexlocationsites num2str(d(1)) '/' dayofyear '/' num2str(mod(d(1),100),'%02d') 'o/' filename{1}];

filename{2} = [lower(station(1:4)),dayofyear,'0.',num2str(mod(d(1),100),'%02d'),'d.Z'];
rinexfile{2} = [rinexlocationsites num2str(d(1)) '/' dayofyear '/' num2str(mod(d(1),100),'%02d') 'd/' filename{2}];

filename{3} = [station,'_R_',[num2str(d(1)),dayofyear],'0000_01D_30S_MO.crx.gz'];
rinexfile{3} = [rinexlocationsites num2str(d(1)) '/' dayofyear '/' num2str(mod(d(1),100),'%02d') 'd/' filename{3}];

wget_exe = ['"' fullfile(fullfile(pwd, 'apps'), 'wget.exe') '"'];
gzip_exe = ['"' fullfile(fullfile(pwd, 'apps'), 'gzip.exe') '"'];
crx2rnx_exe = ['"' fullfile(fullfile(pwd, 'apps'), 'CRX2RNX.exe') '"'];

if exist(fullfile(rinexfiledirectory, filename{1}), 'file') ~= 2 && exist(fullfile(rinexfiledirectory, filename{1}(1:end-3)), 'file') ~= 2 && ...
   exist(fullfile(rinexfiledirectory, filename{2}), 'file') ~= 2 && exist(fullfile(rinexfiledirectory, filename{2}(1:end-2)), 'file') ~= 2 && ...
   exist(fullfile(rinexfiledirectory, filename{3}), 'file') ~= 2 && exist(fullfile(rinexfiledirectory, filename{3}(1:end-3)), 'file') ~= 2
    for i = 1 : 3
        wgetrinex{i} = [ wget_exe  ' -O ' rinexfiledirectory '\' filename{i} ' --auth-no-challenge --user=alifuat_bas --password=21042018Ali ' rinexfile{i}];
        %downloading file
        disp('Downloading daily RINEX files ...');
        system(wgetrinex{i});
        s = dir(fullfile(rinexfiledirectory, filename{i}));
        if exist(fullfile(rinexfiledirectory, filename{i}), 'file') == 2 && s.bytes > 1000
            %unzip
            system([gzip_exe ' -df ' fullfile(rinexfiledirectory, filename{i})]);
            if i == 1
                rinexfilename = fullfile(rinexfiledirectory,filename{i}(1:end-3));
            elseif i == 2
                system([crx2rnx_exe,' ',fullfile(rinexfiledirectory, filename{i}(1:end-2))]);
                rinexfilename = fullfile(rinexfiledirectory,filename{i}(1:end-2));
                break
            elseif i == 3
                system([crx2rnx_exe,' ',fullfile(rinexfiledirectory, filename{i}(1:end-3))]);
                rinexfilename = fullfile(rinexfiledirectory,filename{i}(1:end-3));
                break
            end
        else
            delete(fullfile(rinexfiledirectory, filename{i}))
        end
    end
else
    if exist(fullfile(rinexfiledirectory, filename{1}(1:end-3)), 'file') == 2
        rinexfilename = fullfile(rinexfiledirectory,filename{1}(1:end-3));
    elseif exist(fullfile(rinexfiledirectory, filename{2}(1:end-2)), 'file') == 2
        rinexfilename = fullfile(rinexfiledirectory,filename{2}(1:end-2));
    else
        rinexfilename = fullfile(rinexfiledirectory,filename{3}(1:end-3));
    end
end
end