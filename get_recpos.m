clc; clear; warning off; format long g
    station = 'ANKR00TUR';
    date = '2022-02-09';
    
    obsfile = getrinexfiles(datestr(date,'yyyy-mm-dd'),station);
    navfile = getnavfiles(datestr(date,'yyyy-mm-dd'));

    % read observation file
    [fID] = fopen(obsfile, 'r');
    if fID < 0
        error('Unable to open file named %s.\n\n', obsfile);
    end
    lines = fgets(fID);
    rinexver = str2double(lines(1:15));
    if rinexver > 2
        obsfile = strrep(obsfile,'crx','rnx');
    elseif rinexver < 3 && strcmp(obsfile(end),'d')
        obsfile(end) = 'o';
    end
    [obsmat] = rinexversion(string(obsfile));
    if rinexver > 2
        obsmat.info.typeofobs = obsmat.obs(2,:)';
    end
    rec_xyz = obsmat.info.approxpos';
    % define cols
    obs.col.WEEK = 1;
    obs.col.TOW = 2;
    obs.col.PRN = 3;
    col_offset = 3;
    for ii=1:length(obsmat.info.typeofobs)
        eval(sprintf('obs.col.%s=%s;',obsmat.info.typeofobs{ii},num2str(ii+col_offset)))
    end
    % create obs.data
    [gpswk,gpssec] = cal2gpstime(obsmat.info.epochs);
    for i = length(obsmat.info.epochs):-1:1
        obsmat.info.satno{i}(find(obsmat.info.satno{i}>32)) = []; %% SADECE GPS UYDULARI
        obsdata{i,1} = repmat(gpswk(i),length(obsmat.info.satno{i}),1);
        obsdata{i,2} = repmat(gpssec(i),length(obsmat.info.satno{i}),1);
        obsdata{i,3} = obsmat.info.satno{i};
        for j = 1 : length(obsmat.info.typeofobs)
            if sum(strcmp(obsmat.info.typeofobs{j},obsmat.obs(2,:))) > 0
                obsdata{i,col_offset+j} = obsmat.obs{1,find(strcmp(obsmat.info.typeofobs{j},obsmat.obs(2,:)))}(i,obsmat.info.satno{i})';
            else
                obsdata{i,col_offset+j} = NaN(length(obsmat.info.satno{i}),1);
            end
        end
    end
    obs.data = reshape(vertcat(obsdata{:}),length(vertcat(obsmat.info.satno{:})),length(fieldnames(obs.col))); clear obsdata;
    obs.data(any(isnan(obs.data(:,obs.col.C1)), 2), :) = [];
    obs.data(any(isnan(obs.data(:,obs.col.P2)), 2), :) = [];

    % read navigation file
    ephemeris = read_rinex_nav(string(navfile));

    epochs = unique(obs.data(:, obs.col.TOW));
    TimeSpan=epochs(1:length(epochs));

    % Broadcast Orbit
    satOrbits.XS=zeros(1,length(TimeSpan));
    satOrbits.YS=zeros(1,length(TimeSpan));
    satOrbits.ZS=zeros(1,length(TimeSpan));
    satOrbits.VXS=zeros(1,length(TimeSpan));
    satOrbits.VYS=zeros(1,length(TimeSpan));
    satOrbits.VZS=zeros(1,length(TimeSpan));
    satOrbits.clk=zeros(1,length(TimeSpan));
    satOrbits.Rel=zeros(1,length(TimeSpan));

    % GPS Satellite Measurements
    c = 2.99792458e8 ; % speed of light (m/s)
    fL1 = 1575.42e6;   % L1 frequency (Hz)
    fL2 = 1227.6e6;    % L2 frequency (Hz)
    B=fL2^2/(fL2^2-fL1^2);
    A=-B+1;
    satOrbits.C1=zeros(1,length(TimeSpan));
    satOrbits.P2=zeros(1,length(TimeSpan));
    satOrbits.P3=zeros(1,length(TimeSpan)); % Iono free pseudorange
    satOrbits.CorrP1=zeros(1,length(TimeSpan)); % Corrected Pseudorange from broadcast orbit
    satOrbits.TOW=TimeSpan';
    satOrbits.PRN=0;

    satOrbits = repmat(satOrbits,1,32); 
    for ii=1:32
        satOrbits(ii).PRN=ii;
    end

    % Initialize User Position
    userPos=zeros(length(TimeSpan),4);
    for ii = 1 : length(TimeSpan)
        this_TOW = TimeSpan(ii);
        index = find(obs.data(:,obs.col.TOW) == this_TOW);
        curr_obs.data = obs.data(index, :);
        curr_obs.col = obs.col;

        for jj=1:size(curr_obs.data,1)        
            PRN_obs.data = curr_obs.data(jj,:);
            PRN_obs.col = curr_obs.col;
            % Record Measurements
            satOrbits(PRN_obs.data(PRN_obs.col.PRN)).C1(ii)=PRN_obs.data(PRN_obs.col.C1);
            satOrbits(PRN_obs.data(PRN_obs.col.PRN)).P2(ii)=PRN_obs.data(PRN_obs.col.P2);
            % Calculate Iono Free Measurement
            P1 = satOrbits(PRN_obs.data(PRN_obs.col.PRN)).C1(ii);
            P2 = satOrbits(PRN_obs.data(PRN_obs.col.PRN)).P2(ii);
            P3=A*P1+B*P2;
            satOrbits(PRN_obs.data(PRN_obs.col.PRN)).P3(ii)=P3;
        end


            for jj=1:size(curr_obs.data,1)
                PRN_obs.data = curr_obs.data(jj,:);
                PRN_obs.col = curr_obs.col;

                % Obtain the broadcast orbits 
                PRN_obs = get_broadcast_orbits(PRN_obs,ephemeris,rec_xyz');
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).XS(ii)=PRN_obs.data(PRN_obs.col.XS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).YS(ii)=PRN_obs.data(PRN_obs.col.YS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).ZS(ii)=PRN_obs.data(PRN_obs.col.ZS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).VXS(ii)=PRN_obs.data(PRN_obs.col.VXS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).VYS(ii)=PRN_obs.data(PRN_obs.col.VYS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).VZS(ii)=PRN_obs.data(PRN_obs.col.VZS);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).clk(ii)=PRN_obs.data(PRN_obs.col.satClkCorr);
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).Rel(ii)=PRN_obs.data(PRN_obs.col.Rel);            

                % Calculate corrected pseudorange based on broadcast orbit
                satOrbits(PRN_obs.data(PRN_obs.col.PRN)).CorrP1(ii)=...
                    satOrbits(PRN_obs.data(PRN_obs.col.PRN)).P3(ii)+...
                    satOrbits(PRN_obs.data(PRN_obs.col.PRN)).clk(ii)+satOrbits(PRN_obs.data(PRN_obs.col.PRN)).Rel(ii);            
            end
% %                     

            % Calculate User Position
            [broadcast_obs,~]=createObs(this_TOW,satOrbits);
            [delta_xyz, mo, PDOP] = comp_pos(broadcast_obs,rec_xyz');
            rec_xyz = rec_xyz + delta_xyz(1:3);

        userPos(ii,1:10) = [rec_xyz; delta_xyz(4); delta_xyz(1:3); mo; size(curr_obs.data,1); PDOP]';
        [lat(ii),lon(ii),h(ii)] = ecef2geodetic(wgs84Ellipsoid('meter'),rec_xyz(1),rec_xyz(2),rec_xyz(3));
    end

    results.recpos = [userPos lat' lon' h'];    
    fprintf(['X : ',num2str(mean(userPos(:,1)),'%10.3f m '),char(177),num2str(std(userPos(:,1)),' %5.1f m\n')]);
    fprintf(['Y : ',num2str(mean(userPos(:,2)),'%10.3f m '),char(177),num2str(std(userPos(:,2)),' %5.1f m\n')]);
    fprintf(['Z : ',num2str(mean(userPos(:,3)),'%10.3f m '),char(177),num2str(std(userPos(:,3)),' %5.1f m\n')]);
