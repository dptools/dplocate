function preprocess_gps_mc(file_path, output_dir, ref_date,matlab_dir)
display('START');
encp=1;
if encp==1
    % Get passcode
    pss = getenv('BEIWE_STUDY_PASSCODE');
    if (isempty(pss) == 1)
        disp('Please set the BEIWE_STUDY_PASSCODE environment variable.');
        disp('Cannot unlock files without the passphrase.Exiting.');
        exit(1);
    end
end

% Check if the output path exists
if ~ endsWith(output_dir, '/')
    output_dir = strcat(output_dir, '/');
end
if ~ endsWith(matlab_dir, '/')
    matlab_dir = strcat(matlab_dir, '/');
end

if exist(output_dir,'dir')~=7
    disp(strcat('Output directory ', output_dir, ' does not exist. Exiting.'));
    exit(1);
end

% parse consent date
cdates=strsplit(ref_date, '-');
cdates=cellfun(@str2num,cdates(1:end));
cdates_year=cdates(1);
cdates_month=cdates(2);
cdates_day=cdates(3);

%% Initialization
thr=0.75; % threshold between epochs (in mins)
mxdur=5;   % Maximum duration of an epoch (in mins)
nmp=30;
hp=nmp;
cwns=200000; cwnp=cwns+1000000; cwnl=2000;
mwnl=2000; mwns=2;
dia=300;
disp('Sanity check complete.');
%% Decrypt
if (exist(file_path, 'file') == 2)
    %% safely ingest file
    disp('Loading the input file');
    if encp==1
        temp_unlocked='/tmp/tempo.mat';
        cmd = sprintf('python %spreprocess_gps_decrypter.py --input "%s" --output "%s"', matlab_dir, file_path, temp_unlocked);
        system(cmd);
        pause(0.01);
        load(temp_unlocked);
        pause(0.01);
        cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
        system(cmd2);
    else
        load (file_path)
    end

    %% Find Time Zone Offset
    disp('Finding the timezone offset');
    t2=t1 / 1000 / 3600 / 24 + datenum('1970-01-01');
    [y,m,d,h,mn,s]=datevec(t2);
    tt = datetime(y,m,d,'TimeZone','America/New_York');
    [tt2,tt3]=tzoffset(tt);
    tt4=datenum(tt2);
    tt5=t2+tt4;       % In day  
    tt6=tt5*3600*24;  % In second
    tt7=tt5*24*60;    % In minute
    tt8=tt5*24;       % In hour

    %% Sort the Time
    disp('Sorting the time');
    crd=[tt5 tt6 tt7 tt8 lat1 lon1];
    crds=sortrows(crd,1);
    lat1s=crds(:,5); lon1s=crds(:,6); 
    tt5s=crds(:,1); tt6s=crds(:,2); tt7s=crds(:,3); tt8s=crds(:,4);

    %% Separate Epochs
    disp('Separating epochs');
    tt5_day=tt5s; 
    tt5_rl=tt5_day-datenum(cdates_year,cdates_month,cdates_day)+1;
    tt5_rl6=tt5_day-datenum(cdates_year,cdates_month,cdates_day,6,0,0)+1;
    t0=datenum(cdates_year,cdates_month,cdates_day)-datenum(2015,1,31);

    %% Find Epochs
    disp('Finding epochs');
    format long
    tt5_rld=diff(tt5_rl*24*60);  % difference between epochs
    itt51=find(tt5_rld>thr);    % find epochs with more than 3/4 mins apart 
    itt51_sp=[(itt51);length(tt5_rl)];  % end of all epochs
    itt51_st=[1;(itt51+1)];             % beginning of all epochs
    tt5_rlu=24*60*(tt5_rl(itt51_sp)-tt5_rl(itt51_st)); % length of all epochs in minutes
    itt52=find(tt5_rlu>mxdur);                      % find epochs more than 5 minutes long
    length(itt52)
    %% Split the large epochs to make them all <5mins
    disp('Splitting the epochs');
    itt5ns=itt51;
    
    if ~isempty(itt52)
        for lg=1:length(itt52)
            lngth=fix(24*60*(tt5_rl(itt51_sp(itt52(lg)))-tt5_rl(itt51_st(itt52(lg))))/mxdur);
            splg=ceil((itt51_sp(itt52(lg))-itt51_st(itt52(lg)))/(lngth+15));
            for lg1=1:lngth
                itt5ns=[itt5ns;itt51_st(itt52(lg))+lg1*splg];
            end
        end
    end
    itt55=sort(itt5ns);
    itt551_sp=[(itt55);length(tt5_rl)];  % end of all epochs
    itt551_st=[1;(itt55+1)];             % beginning of all epochs
    tt55_rlu=24*60*(tt5_rl(itt551_sp)-tt5_rl(itt551_st)); % length of all epochs in minutes
    itt552=find(tt55_rlu>mxdur);                      % find epochs more than 5 minutes long

    %% Again split the large epochs to make them all <5mins if they are not already
    itt5ns=itt55;
    if ~isempty(itt552)
        for lg=1:length(itt552)
            splg=fix((itt551_sp(itt552(lg))-itt551_st(itt552(lg)))/2);
            for lg2=1:1
                itt5ns=[itt5ns;itt551_st(itt552(lg))+lg2*splg];
            end
        end
    end
    itt5=sort(itt5ns);

    %% Calculating 1st epoch's parameters: time
    disp('Calculating the first epoch parameters');
    tt5_10mn(1,1)=mean(tt5_rl([1:itt5(1)]));    % mean time (s)
    tt5_10(1,1)=mean(tt5_rl([1,itt5(1)]));      % Midpoint time (s)
    tt5_10n(1,1)=numel(tt5_rl(1:itt5(1)));      % Number of points
    tt5_10d(1,1)=floor(tt5_10(1,1));            % day relative        
    tt5_10t(1,1)=datetime(datevec((tt5_10(1,1)-floor(tt5_10(1,1)))),'Format','HH:mm:ss');               %time of day   
    tt5_10tmn(1,1)=datetime(datevec((tt5_10mn(1,1)-floor(tt5_10mn(1,1)))),'Format','HH:mm:ss');         % mean time (hh:mm:ss)           
    tt5_10s(1,1)=datetime(datevec((tt5_rl(1)-floor(tt5_rl(1)))),'Format','HH:mm:ss');                   % start time (hh:mm:ss)    
    tt5_10p(1,1)=datetime(datevec((tt5_rl(itt5(1))-floor(tt5_rl(itt5(1))))),'Format','HH:mm:ss');       % end time (hh:mm:ss)
    tt5_10u(1,1)=24*3600*(tt5_rl(itt5(1))-tt5_rl(1));                   % duration (s)
    tt5_10w(1,1)=mod(tt5_10d(1,1)+t0-1,7)+1;                            % weekday 
    tt5_106(1,1)=24*3600*1000*mean(tt5_rl6([1,itt5(1)]));               % reftime

    %% Calculating 1st epoch's parameters: locations and distances
    lat1se=lat1s(1:itt5(1));  lon1se=lon1s(1:itt5(1));     % Latitude and longitudes
    length(lat1se)
    latdet{1,1}=lat1se;  londet{1,1}=lon1se;               % Save all raw data         
    lat1s10(1,1)=mean(lat1se);                      % interim epoch center's latitude 
    lon1s10(1,1)=mean(lon1se);                      % interim epoch center's longitude
    chck1=1
    dfm=1000*deg2km(distance(lat1se,lon1se,lat1s10(1,1),lon1s10(1,1)));    % Find distance of all data points from center    
    chck2=2
    rds_mx(1,1)=max(dfm);               % Maximum distance
    rds_mean(1,1)=mean(dfm);            % Mean distance
    rds_med(1,1)=median(dfm);           % Median distance

    % Avoid zero std
    if std(dfm)<0.01
        rds_std(1,1)=0.01;
    else
        rds_std(1,1)=std(dfm);              % standard deviation of distance
    end

    % Calculate whole path
    disp('Calculating the path');
    tpath(1,1)=0;
    dst=0;
    ep=0;
    if length(lat1se)>1
        for epc=2:length(lat1se)
            ep=ep+1;
            dst(ep,1)=1000*deg2km(distance(lat1se(epc-1),lon1se(epc-1),lat1se(epc),lon1se(epc))); % distances
            tpath(1,1)=tpath(1,1)+dst(ep,1);                    % total path
        end
    end
    dst_mean(1,1)=mean(dst);                    % Mean distance of the collected points from each other
    dst_std(1,1)=std(dst);                      % Standard deviation of distance of points
    num_3std(1,1)=numel((find(dst<(dst_mean(1,1)-3*dst_std(1,1)))))+numel(find(dst>(dst_mean(1,1)+3*dst_std(1,1)))); % number of points with larger than 3sd from mean
    num_5std(1,1)=numel((find(dst<(dst_mean(1,1)-5*dst_std(1,1)))))+numel(find(dst>(dst_mean(1,1)+5*dst_std(1,1)))); % number of points with larger than 5sd from mean
    dfb(1,1)=0;
    tfb(1,1)=0;
    rds_3sd(1,1)=numel(find(dfm>3*rds_std(1,1)));       % number of points out of 3sd distance from center
    rds_5sd(1,1)=numel(find(dfm>5*rds_std(1,1)));       % number of points out of 5sd distance from center
    lat1s11(1,1)=mean(lat1se(dfm<=3*rds_std(1,1)));     % Keep points closer than 3sd (filtered center)
    lon1s11(1,1)=mean(lon1se(dfm<=3*rds_std(1,1)));     % Keep points closer than 5sd (filtered center)
    latdet1{1,1}=lat1se(dfm<=3*rds_std(1,1));  londet1{1,1}=lon1se(dfm<=3*rds_std(1,1));    % save points closer than 3std

    %% Calculating other epoch's parameters
    disp('Working on the rest of the epochs');
    ntg=1;
    for g=2:length(itt5)
        ntg=ntg+1;
        %% Time
        tt5_10mn(ntg,1)=mean(tt5_rl((itt5(g-1)+1):itt5(g)));
        tt5_10(ntg,1)=mean(tt5_rl([(itt5(g-1)+1),itt5(g)]));
        lat1s10(ntg,1)=mean(lat1s((itt5(g-1)+1):itt5(g)));
        lon1s10(ntg,1)=mean(lon1s((itt5(g-1)+1):itt5(g)));
        tt5_10n(ntg,1)=numel(tt5_rl((itt5(g-1)+1):itt5(g)));
        tt5_10d(ntg,1)=floor(tt5_10(ntg,1));
        tt5_10t(ntg,1)=datetime(datevec((tt5_10(ntg,1)-floor(tt5_10(ntg,1)))),'Format','HH:mm:ss'); 
        tt5_10tmn(ntg,1)=datetime(datevec((tt5_10mn(ntg,1)-floor(tt5_10mn(ntg,1)))),'Format','HH:mm:ss');
        tt5_10s(ntg,1)=datetime(datevec((tt5_rl((itt5(g-1)+1))-floor(tt5_rl((itt5(g-1)+1))))),'Format','HH:mm:ss');
        tt5_10p(ntg,1)=datetime(datevec((tt5_rl(itt5(g))-floor(tt5_rl(itt5(g))))),'Format','HH:mm:ss');
        tt5_10u(ntg,1)=24*3600*(tt5_rl(itt5(g))-tt5_rl((itt5(g-1)+1)));
        tt5_10w(ntg,1)=mod(tt5_10d(ntg,1)+t0-1,7)+1;
        tt5_106(ntg,1)=24*3600*1000*mean(tt5_rl6([(itt5(g-1)+1),itt5(g)]));
        %% Distance and Locations
        lat1se=lat1s((itt5(g-1)+1):itt5(g));  lon1se=lon1s((itt5(g-1)+1):itt5(g));
        latdet{ntg,1}=lat1se;  londet{ntg,1}=lon1se;
        lat1s10(ntg,1)=mean(lat1se);
        lon1s10(ntg,1)=mean(lon1se);
        % Distance
        dfb(ntg,1)=1000*deg2km(distance(lat1s10(ntg,1),lon1s10(ntg,1),lat1s10(ntg-1,1),lon1s10(ntg-1,1)));
        tfb(ntg,1)=(tt5_10(ntg,1)-tt5_10(ntg-1,1))*24*3600;
        dfm=1000*deg2km(distance(lat1se,lon1se,lat1s10(ntg,1),lon1s10(ntg,1)));
        rds_mx(ntg,1)=max(dfm);
        rds_mean(ntg,1)=mean(dfm);
        rds_med(ntg,1)=median(dfm);
        if std(dfm)<0.01
           rds_std(ntg,1)=0.01;
        else
           rds_std(ntg,1)=std(dfm);
        end
        % path distances
        tpath(ntg,1)=0;
        dst=0;
        ep=0;
        if length(lat1se)>1
            for epc=2:length(lat1se)
                ep=ep+1;
                dst(ep,1)=1000*deg2km(distance(lat1se(epc-1),lon1se(epc-1),lat1se(epc),lon1se(epc)));
                tpath(ntg,1)=tpath(ntg,1)+dst(ep,1);
            end
        end
        dst_mean(ntg,1)=mean(dst);
        dst_std(ntg,1)=std(dst);
        num_3std(ntg,1)=numel((find(dst<(dst_mean(ntg,1)-3*dst_std(ntg,1)))))+numel(find(dst>(dst_mean(ntg,1)+3*dst_std(ntg,1))));
        num_5std(ntg,1)=numel((find(dst<(dst_mean(ntg,1)-5*dst_std(ntg,1)))))+numel(find(dst>(dst_mean(ntg,1)+5*dst_std(ntg,1))));
        % filtered data
        rds_3sd(ntg,1)=numel(find(dfm>3*rds_std(ntg,1)));
        rds_5sd(ntg,1)=numel(find(dfm>5*rds_std(ntg,1)));
        lat1s11(ntg,1)=mean(lat1se(dfm<=3*rds_std(ntg,1)));
        lon1s11(ntg,1)=mean(lon1se(dfm<=3*rds_std(ntg,1)));
        latdet1{ntg,1}=lat1se(dfm<=3*rds_std(ntg,1));  londet1{ntg,1}=lon1se(dfm<=3*rds_std(ntg,1));
    end
    sfb=dfb./tfb;           % calculate speed after epoch
    dfa=circshift(dfb,-1);
    tfa=circshift(tfb,-1);
    sfa=dfa./tfa;           % calculate speed before epoch
    sf0=tpath./tt5_10u;     % calculate speed during epoch

    %% Build table
    disp('Building dash table');
    dash=table(tt5_106,tt5_10d,tt5_10t,tt5_10w,tt5_10s,tt5_10p,tt5_10tmn,tt5_10u,tt5_10n,lat1s10,lon1s10,tpath,dst_mean,dst_std,num_3std,num_5std,lat1s11,lon1s11,rds_mx,rds_mean,rds_med,rds_std,rds_3sd,rds_5sd,sf0,tfb,dfb,sfb,tfa,dfa,sfa,'VariableNames',...
        {'reftime','day','timeofday','weekday','starttime','endtime','mean_time','dur_time','num_loc','mean_loc_lat','mean_loc_lon','tot_path_len','mean_dist','sd_dist','num_3sd','num_5sd','mean_loc_lat_filt','mean_loc_lon_filt','radius_mx','radius_mean','radius_med','radius_std','nrad_3sd','nrad_5sd','speed_0','time_dif_b','dist_b','speed_b','time_dif_a','dist_a','speed_a'});

    %% dash revised version 
    disp('Saving dash');
    if encp==1
        temp_unlocked_output='/tmp/dash.mat';
        save(temp_unlocked_output,'dash','latdet','londet','latdet1','londet1');
        pause(0.01);

        disp('Locking up dash');
        locked_filename='gps_dash2/dash.mat.lock';
        locked_file_path=strcat(output_dir, locked_filename);
        cmd = sprintf('python %spreprocess_gps_encrypter.py --input "%s" --output "%s"', matlab_dir, temp_unlocked_output, locked_file_path);
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', temp_unlocked_output);
        system(cmd2);
    else
        filename='gps_dash2/dash.mat';
        file_path_out=strcat(output_dir, filename);
        save(file_path_out,'dash','latdet','londet','latdet1','londet1');
    end
else
    disp(strcat(file_path, ' does not exist. exiting.'));
    exit(1);
end

display('COMPLETE');
exit(0);
