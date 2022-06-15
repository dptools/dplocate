function process_gps_mc(study,subject,ref_date,min_day,max_day, file_path, output_dir, matlab_dir)
display('START');
encp=1;

if encp==1
    %% Get passcode
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

% Check if the input file exists
if (exist(file_path, 'file') ~= 2)
    disp(strcat(file_path, ' does not exist. exiting.'));
    exit(1);
end
min_d=max(1,str2double(min_day));
max_d=str2double(max_day);
for idys=1:10
    disp(strcat('batch-',num2str(idys)))
    min_day=(idys-1)*max_d+min_d;
    max_day=(idys*max_d);
    %% Initialization
    sb=subject;
    hp=150;      % Pool of PoIs
    dia11=50;   % Classification diameter
    hp2=80;     % Chosen circles
    sepp=0.85;  % Separatoion factor of the circles
    nwl=1:50;   
    diac=120;   % Larger classification diameter
    dia12=120;  % Largest classification diameter
    dtm=12/24/60; % Color expansion 12min
    epch_tr=10;    % Epoch trigger
    dailyext=strcat('_nr',num2str(idys)); % extention to save daily data
    clust=1;      % 1=fast 2=old
    hst=5;

    %% Colors
    wnt=winter(30);
    spr=spring(30);
    sumr=summer(30);
    autm=autumn(20);
    copr=copper(17);
    colll=[autm(1:12,:);wnt(1:15,:);sumr(1:12,:);spr(1:10,:);copr;sumr(15:26,:);spr(18:25,:);wnt(21:30,:);autm(16:20,:)];
    colr=[colll;colll;colll;colll;colll;colll];

    %% Process the consent date
    cdates=strsplit(ref_date, '-');
    cdates=cellfun(@str2num,cdates(1:end));
    cdates_year=cdates(1);
    cdates_month=cdates(2);
    cdates_day=cdates(3);

    % find the difference between starting date and the marked date
    t0=datenum(cdates_year,cdates_month,cdates_day)-datenum(2015,1,31);

    %% Load and decrypt the dpdash table
    disp('Loading the input file');
    if encp==1
        temp_unlocked='/tmp/tempo.mat';
        cmd = sprintf('python %sprocess_gps_mc_decrypter.py --input "%s" --output "%s"', matlab_dir, file_path, temp_unlocked);
        system(cmd);
        pause(0.1);
        load(temp_unlocked);
        pause(0.01);
        cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
        system(cmd2);
    else
        load(file_path)
    end

    %% dash-based data detection > epch_tr
    iddays=find(dash.day<max_day & dash.day>=min_day);
    if isempty(iddays)
        break
    end
    disp('Filtering data');
    id30=find(dash.num_loc>epch_tr & dash.day<max_day & dash.day>=min_day);
    dash31=table(dash.reftime(id30),dash.day(id30),dash.timeofday(id30),dash.weekday(id30),dash.starttime(id30),dash.endtime(id30),dash.dur_time(id30),dash.num_loc(id30),dash.radius_mx(id30),dash.radius_mean(id30),dash.tot_path_len(id30),dash.speed_0(id30),dash.time_dif_b(id30),dash.dist_b(id30),dash.speed_b(id30),dash.time_dif_a(id30),dash.dist_a(id30),dash.speed_a(id30),dash.mean_dist(id30),dash.sd_dist(id30),dash.radius_med(id30),dash.radius_std(id30),dash.nrad_3sd(id30),dash.nrad_5sd(id30),dash.num_3sd(id30),dash.num_5sd(id30),dash.mean_loc_lat_filt(id30),dash.mean_loc_lon_filt(id30),'VariableNames',...
    {'reftime','day','timeofday','weekday','starttime','endtime','dur_time','num_loc','radius_mx','radius_mean','tot_path_len','speed_0','time_dif_b','dist_b','speed_b','time_dif_a','dist_a','speed_a','mean_dist','sd_dist','radius_med','radius_std','nrad_3sd','nrad_5sd','num_3sd','num_5sd','mean_loc_lat','mean_loc_lon'});

    %% extract data
    tt5=dash31.reftime/1000+datenum(cdates_year,cdates_month,cdates_day,6,0,0);
    lat1s=dash31.mean_loc_lat;
    lon1s=dash31.mean_loc_lon;

    %% Find the most visited locations during all days
    disp('Finding the most frequently visited locations');
    ltkd=[]; lnkd=[]; nkd=[]; ikd=[];
    ltkdc=[]; lnkdc=[]; nkdc=[];
    dd0 = cell(length(lat1s),6);
    for k1=1:length(lat1s)   % for all epochs
        %% Find the distance of all points from the chosen epoch  
        dd00=1000*deg2km(distance(lat1s,lon1s,lat1s(k1),lon1s(k1)));
        [dd0s,idx1s]=sort(dd00);     % sort
        %% find points that are in dia1 distance
        dd0{k1,1}=idx1s(dd0s<dia11);
        dd0{k1,2}=dd0s(dd0s<dia11);
        dd0{k1,3}=lat1s(k1);
        dd0{k1,4}=lon1s(k1);
        dd0{k1,5}=k1;
        dd0{k1,6}=sum(exp(((dd0{k1,2}-dia11).^2)/((dia11/2)^2)));  % Calculate the score based on          distance
    end

    %% Find the most popular PoIs
    disp('Finding the most popular PoIs');
    if clust==1    % Always choose clust=1
        roh=cell2mat(dd0(:,6));  % score vector
        [~,Ip1] = sort(roh,'descend');  % score sort
    else
        [~,Ip1] = sort(cellfun(@length,dd0(:,1)),'descend');
    end

    Ip=Ip1;
    ds0 = dd0(Ip,:);
    hp=min(hp,length(ds0));
    for k2=1:hp  %  choose 100
        ltkd=[ltkd ds0{1,3}];   % First Lat
        lnkd=[lnkd ds0{1,4}];   % First Lon
        ikd=[ikd ds0{1,5}];     % First k1
        iopd{k2,1}=ds0{1,1};    % First id
        Ipd=Ip(~ismember(Ip,ds0{1,1}));   % Delete first row
        ds0 = dd0(Ipd,:);       % Update matrix
        Ip  = Ipd;
        if isempty(ds0)
            break
        end
    end
    ilt=find(~isnan(ltkd));
    ltkd=ltkd(ilt);
    lnkd=lnkd(ilt);
    iopd=iopd(ilt);
    hp=min(hp,length(ltkd));

    %% Pruning the PoIs based on distance and overlap
    disp('Pruning the PoIs');
    for k3=1:hp
        for k4=1:hp
            ptb1(k3,k4)=1000*deg2km(distance(ltkd(k3),lnkd(k3),ltkd(k4),lnkd(k4)));   % Distance
            ptb2(k3,k4)=length(iopd{k3,1}(~ismember(iopd{k3,1},iopd{k4,1})))/length(iopd{k3,1}); %             No overlap percenatge
            ptb3(k3,k4)=length(iopd{k3,1}(~ismember(iopd{k3,1},iopd{k4,1})));   % No Overlap 
        end
    end

    [fr,fc,fv]=find((ptb2<sepp)&(ptb2>0));  % apply sepparation factor
    fd=[];
    for ff=1:length(fr)
        if fr(ff)>fc(ff)
            fd=[fd; fr(ff)];
        end
    end

    irf=setdiff(1:hp,fd);
    ltkdc1=ltkd(irf);      lnkdc1=lnkd(irf);
    hp2=min(hp2,length(ltkdc1));
    ltkc=ltkdc1(1:hp2);   lnkc=lnkdc1(1:hp2);
    ddfk1=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
    [dfs,idfs]=sort(ddfk1,'ascend');
    ltkc=ltkc(idfs); lnkc=lnkc(idfs);
    ptb11=ptb1(irf,:);
    ptb12=ptb11(:,irf);
    ptb13=ptb12(idfs,idfs);  % reduced distance matrix
    ptb13n=sort(ptb13);
    if length(ptb13n)==1
        dia1=diac;
    else
        ptb13r=ptb13n(2,:);
        dia1=[];

        for po=1:hp2
            if ptb13r(po)>2*diac
                dia1(po)=dia12;
            elseif (ptb13r(po)<=2*diac && ptb13r(po)>2*dia11)
                dia1(po)=ptb13r(po)/2;
            elseif ptb13r(po)<=2*dia11
                dia1(po)=dia11;
            end
        end
    end

    %% Combine the close circles
    disp('Combining the close circles');
    [ip1,ip2]=find(ptb13<diac & ptb13>0);   ipg=[ip1 ip2];    % Find close circles
    ip1q=unique(ip1);       % Unique  
    pq=[];
    for iip=1:length(ip1q)
        pq{iip,1}=ip1q(iip);
        iip1=find(ip1==ip1q(iip));
        rpq1=ip2(iip1);
        pq{iip,1}=[pq{iip,1};rpq1];
        pq{iip,2}=ip1q(iip);
        mlng=[];
        for inp=1:length(iip1)
            mlng=[mlng; ptb13(ip1(iip1(inp)),ip2(iip1(inp)))];
        end
        pq{iip,6}=mean(mlng)/length(pq{iip,1});
        pq{iip,7}=mean(mlng)/(length(pq{iip,1})^(.5));
    end

    pq1=pq; pqq1=[];  ipqq1=0;
    while ~isempty(pq1)
        ipqq1=ipqq1+1;
        [~,imq1] = min(cell2mat(pq1(:,7)));
        pqq1{ipqq1,1}=intersect(pq1{imq1,1},cell2mat(pq1(:,2)));
        [pmq2,imq2]=setdiff(cell2mat(pq1(:,2)),pq1{imq1,1});    
        pq1=pq1(imq2,:);
    end

    %% Coarse clusters
    disp('Coarse clusters');
    ltkcc=ltkc;  lnkcc=lnkc; ikc=1:length(ltkcc);
    ltmc=[];  lnmc=[];  dia2=[];
    for ir=1:length(pqq1)
        ltq=ltkcc(pqq1{ir,1}); lnq=lnkcc(pqq1{ir,1});
        ltmc(ir,1)=mean(ltq);   lnmc(ir,1)=mean(lnq);
        dc00=1000*deg2km(distance(ltq,lnq,ltmc(ir),lnmc(ir)));
        dia2(ir,1)=max(dc00)+dia11;
        ikc=setdiff(ikc,pqq1{ir,1});
    end

    ltmc=[ltmc;ltkcc(ikc)'];  lnmc=[lnmc;lnkcc(ikc)'];  dia2=[dia2;1*dia11*ones(length(ikc),1)];
    pqq2=pqq1;
    for rpqq=1:length(ikc)
        pqq2{length(pqq1)+rpqq,1}=ikc(rpqq);
    end

    pqq2u=[];
    for im=1:length(pqq2)
        pqq2u=[pqq2u;min(pqq2{im,1})];
    end

    ddfm1=deg2km(distance(ltmc,lnmc,ltmc(pqq2u==1),lnmc(pqq2u==1)));
    [mfs,imfs]=sort(ddfm1,'ascend');
    ltmc=ltmc(imfs);
    lnmc=lnmc(imfs); 
    dia2=dia2(imfs); pqq2=pqq2(imfs);  pqq2u=pqq2u(imfs);

    %% Assign epochs to POIs and confidence level
    disp('Assigning epochs to PoIs');
    poi1=[]; conf1=[]; poi3=[]; conf3=[];
    for th=1:height(dash31(:,1))
        lath=dash31.mean_loc_lat(th);
        lonh=dash31.mean_loc_lon(th);
        nm=dash31.num_loc(th);
        rd_mx=dash31.radius_mx(th);
        rd_mn=dash31.radius_mean(th);
        rd_md=dash31.radius_med(th);
        rd_sd=dash31.radius_std(th);
        nm3=dash31.nrad_3sd(th);
        nm5=dash31.nrad_5sd(th);
        dh1=1000*deg2km(distance(lath,lonh,ltkc,lnkc));
        dh2=1000*deg2km(distance(lath,lonh,ltmc,lnmc));

        [mdh1,idh1]=sort(dh1);
        dia1s_len = min(length(dia1), length(idh1));
        dia1_copy = dia1(1:dia1s_len);
        idh1_copy = idh1(1:dia1s_len);
        dia1s=dia1_copy(idh1_copy);

        %dia1s=diac*ones(1,length(idh1));

        [mdh2,idh2]=sort(dh2);
        dia2s_len = min(length(dia2), length(idh2));
        dia2_copy = dia2(1:dia2s_len);
        idh2_copy = idh2(1:dia2s_len);
        dia2s=dia2_copy(idh2_copy);

        if dia2s_len<4
            if mdh1(1)<dia1s(1)
                poi1(th,1)=idh1(1);
                if (dia1s(1)-mdh1(1))>=rd_mx
                    conf1(th,1)=100;
                elseif (dia1s(1)-mdh1(1))>=(rd_md)
                    conf1(th,1)=95;
                elseif (dia1s(1)-mdh1(1))>=(rd_mn)
                    conf1(th,1)=90;    
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-rd_sd)
                    conf1(th,1)=60;
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-2*rd_sd)
                    conf1(th,1)=30;
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-3*rd_sd)
                    conf1(th,1)=10;
                else
                    conf1(th,1)=0;
                end
                cond1(th,1)=dia1s(1)-mdh1(1);
            else
                poi1(th,1)=0;
                conf1(th,1)=100;
                cond1(th,1)=0;
            end

            if mdh2(1)<dia2s(1)
                poi3(th,1)=idh2(1);
                if (dia2s(1)-mdh2(1))>=rd_mx
                    conf3(th,1)=100;
                elseif (dia2s(1)-mdh2(1))>=(rd_md)
                    conf3(th,1)=95;
                elseif (dia2s(1)-mdh2(1))>=(rd_mn)
                    conf3(th,1)=90;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-rd_sd)
                    conf3(th,1)=60;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-2*rd_sd)
                    conf3(th,1)=30;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-3*rd_sd)
                    conf3(th,1)=10;
                else
                    conf3(th,1)=0;
                end
                cond3(th,1)=dia2s(1)-mdh2(1);
            else
                poi3(th,1)=0;
                conf3(th,1)=0;
                cond3(th,1)=0;
            end

        else
            if mdh1(1)<dia1s(1)
                poi1(th,1)=idh1(1);
                if (dia1s(1)-mdh1(1))>=rd_mx
                    conf1(th,1)=100;
                elseif (dia1s(1)-mdh1(1))>=(rd_md)
                    conf1(th,1)=95;
                elseif (dia1s(1)-mdh1(1))>=(rd_mn)
                    conf1(th,1)=90;    
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-rd_sd)
                    conf1(th,1)=60;
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-2*rd_sd)
                    conf1(th,1)=30;
                elseif (dia1s(1)-mdh1(1)+hst)>=(rd_md-3*rd_sd)
                    conf1(th,1)=10;
                else
                    conf1(th,1)=0;
                end
                cond1(th,1)=dia1s(1)-mdh1(1);
            elseif mdh1(2)<dia1s(2)
                poi1(th,1)=idh1(2);
                if (dia1s(2)-mdh1(2))>=rd_mx
                    conf1(th,1)=100;
                elseif (dia1s(2)-mdh1(2))>=(rd_md)
                    conf1(th,1)=95;
                elseif (dia1s(2)-mdh1(2))>=(rd_mn)
                    conf1(th,1)=90;    
                elseif (dia1s(2)-mdh1(2)+hst)>=(rd_md-rd_sd)
                    conf1(th,1)=60;
                elseif (dia1s(2)-mdh1(2)+hst)>=(rd_md-2*rd_sd)
                    conf1(th,1)=30;
                elseif (dia1s(2)-mdh1(2)+hst)>=(rd_md-3*rd_sd)
                    conf1(th,1)=10;
                else
                    conf1(th,1)=0;
                end
                cond1(th,1)=dia1s(2)-mdh1(2);
            elseif mdh1(3)<dia1s(3)
                poi1(th,1)=idh1(3);
                if (dia1s(3)-mdh1(3))>=rd_mx
                    conf1(th,1)=100;
                elseif (dia1s(3)-mdh1(3))>=(rd_md)
                    conf1(th,1)=95;
                elseif (dia1s(3)-mdh1(3))>=(rd_mn)
                    conf1(th,1)=90;    
                elseif (dia1s(3)-mdh1(3)+hst)>=(rd_md-rd_sd)
                    conf1(th,1)=60;
                elseif (dia1s(3)-mdh1(3)+hst)>=(rd_md-2*rd_sd)
                    conf1(th,1)=30;
                elseif (dia1s(3)-mdh1(3)+hst)>=(rd_md-3*rd_sd)
                    conf1(th,1)=10;
                else
                    conf1(th,1)=0;
                end
                cond1(th,1)=dia1s(3)-mdh1(3);
            elseif mdh1(4)<dia1s(4)
                poi1(th,1)=idh1(4);
                if (dia1s(4)-mdh1(4))>=rd_mx
                    conf1(th,1)=100;
                elseif (dia1s(4)-mdh1(4))>=(rd_md)
                    conf1(th,1)=95;
                elseif (dia1s(4)-mdh1(4))>=(rd_mn)
                    conf1(th,1)=90;    
                elseif (dia1s(4)-mdh1(4)+hst)>=(rd_md-rd_sd)
                    conf1(th,1)=60;
                elseif (dia1s(4)-mdh1(4)+hst)>=(rd_md-2*rd_sd)
                    conf1(th,1)=30;
                elseif (dia1s(4)-mdh1(4)+hst)>=(rd_md-3*rd_sd)
                    conf1(th,1)=10;
                else
                    conf1(th,1)=0;
                end
                cond1(th,1)=dia1s(4)-mdh1(4);
            else
                poi1(th,1)=0;
                conf1(th,1)=100;
                cond1(th,1)=0;
            end

            if mdh2(1)<dia2s(1)
                poi3(th,1)=idh2(1);
                if (dia2s(1)-mdh2(1))>=rd_mx
                    conf3(th,1)=100;
                elseif (dia2s(1)-mdh2(1))>=(rd_md)
                    conf3(th,1)=95;
                elseif (dia2s(1)-mdh2(1))>=(rd_mn)
                    conf3(th,1)=90;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-rd_sd)
                    conf3(th,1)=60;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-2*rd_sd)
                    conf3(th,1)=30;
                elseif (dia2s(1)-mdh2(1)+hst)>=(rd_md-3*rd_sd)
                    conf3(th,1)=10;
                else
                    conf3(th,1)=0;
                end
                cond3(th,1)=dia2s(1)-mdh2(1);
            elseif mdh2(2)<dia2s(2)
                poi3(th,1)=idh2(2);
                if (dia2s(2)-mdh2(2))>=rd_mx
                    conf3(th,1)=100;
                elseif (dia2s(2)-mdh2(2))>=(rd_md)
                    conf3(th,1)=95;
                elseif (dia2s(2)-mdh2(2))>=(rd_mn)
                    conf3(th,1)=90;
                elseif (dia2s(2)-mdh2(2)+hst)>=(rd_md-rd_sd)
                    conf3(th,1)=60;
                elseif (dia2s(2)-mdh2(2)+hst)>=(rd_md-2*rd_sd)
                    conf3(th,1)=30;
                elseif (dia2s(2)-mdh2(2)+hst)>=(rd_md-3*rd_sd)
                    conf3(th,1)=10;
                else
                    conf3(th,1)=0;
                end
                cond3(th,1)=dia2s(2)-mdh2(2);
            elseif mdh2(3)<dia2s(3)
                poi3(th,1)=idh2(3);
                if (dia2s(3)-mdh2(3))>=rd_mx
                    conf3(th,1)=100;
                elseif (dia2s(3)-mdh2(3))>=(rd_md)
                    conf3(th,1)=95;
                elseif (dia2s(3)-mdh2(3))>=(rd_mn)
                    conf3(th,1)=90;
                elseif (dia2s(3)-mdh2(3)+hst)>=(rd_md-rd_sd)
                    conf3(th,1)=60;
                elseif (dia2s(3)-mdh2(3)+hst)>=(rd_md-2*rd_sd)
                    conf3(th,1)=30;
                elseif (dia2s(3)-mdh2(3)+hst)>=(rd_md-3*rd_sd)
                    conf3(th,1)=10;
                else
                    conf3(th,1)=0;
                end
                cond3(th,1)=dia2s(3)-mdh2(3);
            else
                poi3(th,1)=0;
                conf3(th,1)=0;
                cond3(th,1)=0;
            end
        end
    end

    %% Analysis for detailed clustering
    tst=dash31.starttime;   tdst=datevec(tst);
    tst2=dash31.day+(datenum(2017,9,11,tdst(:,4),tdst(:,5),0)-datenum(2017,9,11,0,0,0));
    tsp=dash31.endtime;     tdsp=datevec(tsp);
    tsp2=dash31.day+(datenum(2017,9,11,tdsp(:,4),tdsp(:,5),0)-datenum(2017,9,11,0,0,0));
    tday=dash31.timeofday;  tdays=datevec(tday);
    tdays2=dash31.day+(datenum(2017,9,11,tdays(:,4),tdays(:,5),tdays(:,6))-datenum(2017,9,11,0,0,0));
    tpd=(ceil(max(tsp2)));
    tq=1/1440:(1/1440):tpd;
    piq1=nan(size(tq));   piq3=nan(size(tq));

    for its=1:length(tst2)
        piq1((tq>=(tst2(its)-dtm)) & (tq<=(tsp2(its)+dtm)) )=poi1(its);
        piq3((tq>=(tst2(its)-dtm)) & (tq<=(tsp2(its)+dtm)) )=poi3(its);
    end

    %% Add weekdays to the days
    wk1=[0:1:tpd];
    wkd=mod(wk1+t0,7);
    wks(wkd==0)='S';
    wks(wkd==1)='S';
    wks(wkd==2)='M';
    wks(wkd==3)='T';
    wks(wkd==4)='W';
    wks(wkd==5)='T';
    wks(wkd==6)='F';
    for ds=1:length(wk1)
        wk1s{1,ds}=strcat(wks(ds),'-',sprintf('%03d',wk1(1,ds)));
    end
    
    %% Plot the colorful detailed daily pattern
    figure(2);
    set(gcf,'position',get(0,'screensize'));
    pdy3=reshape(piq1,[1440,max(tq)]);
    piqm1=piq1(~isnan(piq1)); % Delete nans
    piqm=piqm1(piqm1>0);    % Delete zeros
    iia1=unique(piqm); % Find frequency of appearance
    hp3=length(iia1);
    pdy3(pdy3==0)=hp3+1;
    pdy3(isnan(pdy3))=hp3+2;
    clrr3=colr(1:hp3,:);
    clrr3=[clrr3; [.9 .9 .9];[1 1 1]];
    colormap(gca,clrr3);
    hh2=imagesc(pdy3);
    ax = ancestor(hh2, 'axes');
    xrule = ax.XAxis;
    h2=colorbar;

    set(gca, 'FontWeight','b');
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24);
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',wk1s,'XTickLabelRotation',90);
    xrule.FontSize = 8;
    grid on;
    title(strcat('study=',study,'/sb=',sb,'/clust=',num2str(clust),'/epch=',num2str(epch_tr),          '/detailed'),'Rotation',0, 'FontSize',14, 'FontWeight','b');
    xlabel('Relative days','FontSize',12,'FontWeight','bold');
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold');
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
    lblf2{1,1}=' ';

    for fh=1:length(iia1)
        if fh>=10
            fmt='%02d';
        elseif fh<10
            fmt='%02d';
        end

        if ddfk(fh)>=1000
            fmt2='%4.0f';
        elseif ddfk(fh)>=100
            fmt2='%3.1f';
        elseif ddfk(fh)>=10
            fmt2='%2.1f';
        elseif ddfk(fh)>=1
            fmt2='%1.2f';
        elseif ddfk(fh)<1
            fmt2='%0.2f';
        end
        lblf2{fh+1,1}=strcat(sprintf(fmt,fh),'-',sprintf(fmt2,ddfk(fh)),' km');
    end

    lblf2{hp3+2,1}=' '; lblf2{hp3+3,1}=' ';
    set(h2,'YTick',.5:0.98:hp3+2,'YTickLabel',lblf2);
    img = getframe(gcf);

    disp('Saving daily img file');
    if encp==1
        img_path = strcat(output_dir,study,'_',sb,'_daily',dailyext,'.png');
        locked_img_path = strcat(output_dir,study,'_',sb,'_daily',dailyext, '.png.lock');
        imwrite(img.cdata, img_path);
        pause(6);
        cmd = sprintf('python %sprocess_gps_mc_encrypter.py --input "%s" --output "%s"', matlab_dir, img_path, locked_img_path);
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', img_path);
        system(cmd2);
    else
        img_path = strcat(output_dir,study,'_',sb,'_daily',dailyext,'.png');
        imwrite(img.cdata, img_path);
    end
    %% Save in protected folder
    disp('Saving mat file');
    if encp==1
        tmp_mat_output='/tmp/daily.mat';
        save(tmp_mat_output,'pdy3','ddfk','ltkc','lnkc');
        pause(.01);
        disp('Locking up mat file');
        locked_filename=strcat('daily',dailyext,'.mat.lock');
        locked_file_path=strcat(output_dir,'gps_dash2/',locked_filename);
        cmd = sprintf('python %sprocess_gps_mc_encrypter.py --input "%s" --output "%s"', matlab_dir,          tmp_mat_output, locked_file_path);
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', tmp_mat_output);
        system(cmd2);
    else
        unlocked_filename=strcat('daily',dailyext,'.mat');
        unlocked_file_path=strcat(output_dir,'gps_dash2/',unlocked_filename);
        save(unlocked_file_path,'pdy3','ddfk','ltkc','lnkc');
    end
end

display('COMPLETE');
exit(0); 
