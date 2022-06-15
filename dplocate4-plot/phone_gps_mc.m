function phone_gps_mc(read_dir, out_dir, extension, matlab_dir, date_from, subject, study)
display('START');
disp(date_from)
sb1=subject;
stdy=study;
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
if ~ endsWith(out_dir, '/')
    out_dir = strcat(out_dir, '/');
end
if ~ endsWith(matlab_dir, '/')
    matlab_dir = strcat(matlab_dir, '/');
end

if exist(out_dir,'dir')~=7
    disp(strcat('Output directory ', out_dir, ' does not exist. Exiting.'));
    exit(1);
end

% Check if the path is properly formatted
if ~ endsWith(read_dir, '/')
    read_dir = strcat(read_dir, '/');
end

if ~ endsWith(out_dir, '/')
    out_dir = strcat(out_dir, '/');
end

if ~ endsWith(matlab_dir, '/')
    matlab_dir = strcat(matlab_dir, '/');
end

%% Initialization & Parameters
epc_lbl{1,1}={'10PM','11PM','12AM',' 1AM',' 2AM',' 3PM',' 4AM',' 5AM',' 6AM',' 7AM',' 8AM',' 9AM','10AM','11AM','12PM',' 1PM',' 2PM',' 3PM',' 4PM',' 5PM',' 6PM',' 7PM',' 8PM',' 9PM','10PM'};
epochm={[0 24];[9 17];[18 22];[22 2];[2 6]};
hp2=50;     %#ok<*NASGU> % Chosen circles
epch_tr=10;    % Epoch trigger
max_day=80;  % Maximum days
clust=1;      % 1=fast 2=old

%% Process the consent date
cdates=strsplit(date_from, '-');
cdates=cellfun(@str2num,cdates(1:end));
cdates_year=cdates(1);
cdates_month=cdates(2);
cdates_day=cdates(3);
%%  Read daily_all
disp('Sanity check complete.');
if encp==1
    tmpN = tempname('/tmp');
    temp_unlocked=strcat(tmpN,'.mat');
    fls=dir(strcat(read_dir,'daily_all.mat.lock'));
    file_name=fls(1,1).name;
    file_path=strcat(read_dir, file_name);
    %% Load and decrypt the input table
    disp(strcat('Loading the input file',file_path));
    cmd = strcat(matlab_dir,'phone_gps_mc_decrypter.py --input "',file_path,'" --output "', temp_unlocked, '"');
    system(cmd);
    pause(0.1);
    load(temp_unlocked);
    pause(0.01);
    cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
    system(cmd2);
    %% Read dash file 
    fls=dir(strcat(read_dir,'dash*.mat.lock'));
    file_name=fls(1,1).name;
    file_path2=strcat(read_dir, file_name);
    %% Load and decrypt the input table
    disp(strcat('Loading the input file',file_path2));
    cmd = strcat(matlab_dir,'phone_gps_mc_decrypter.py --input "',file_path2,'" --output "', temp_unlocked, '"');
    system(cmd);
    pause(0.1);
    load(temp_unlocked);
    pause(0.01);
    cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
    system(cmd2);
else
    fls=dir(strcat(read_dir,'daily_all.mat'));
    file_name=fls(1,1).name;
    file_path=strcat(read_dir, file_name);
    disp(strcat('Loading the input file',file_path));
    load(file_path)
    fls=dir(strcat(read_dir,'dash*.mat'));
    file_name=fls(1,1).name;
    file_path2=strcat(read_dir, file_name);
    disp(strcat('Loading the input file',file_path2));
    load(file_path2)
end

%% Colors                
wnt=winter(30);
spr=spring(30);
sumr=summer(30);
autm=autumn(20);
copr=copper(17);
colll=[autm(1:12,:);wnt(1:15,:);sumr(1:12,:);spr(1:10,:);copr;sumr(15:26,:);spr(18:25,:);wnt(21:30,:);autm(16:20,:)];
colr=[colll;colll;colll;colll;colll;colll];
% find the difference between starting date and the marked date
mn=datenum(cdates_year,cdates_month,cdates_day);
hp2=length(ltkc);

%% Plot the colorful detailed daily pattern
ff10=figure(10);
set(gcf,'position',get(0,'screensize'))
clrr3=colr(1:hp2,:);
clrr3=[[.75 .75 .75];clrr3; [.9 .9 .9];[1 1 1]]; %#ok<*AGROW>
colormap(gca,clrr3)
tpd=length(pdy3(1,:));
rpdy=reshape(pdy3,1440*tpd,1);                
bgn=22*60;  endt=2*60;
rpdy3=rpdy(bgn+1:end-endt);
pdy33=reshape(rpdy3,1440,tpd-1);
tpd=tpd-1;
hh2=imagesc(pdy33);
ax = ancestor(hh2, 'axes');
xrule = ax.XAxis;
h2=colorbar;
set(gca, 'FontWeight','b')    
set(gca,'YTick',0.5:60:1440.5,'YTickLabel',epc_lbl{1,1}(1:1:end)) 
set(gca,'XTick',.5:2:tpd+.5,'XTickLabel',0:2:tpd,'XTickLabelRotation',90)
xrule.FontSize = 8;
xlim([.5,tpd+.5])
grid on
title(strcat('study=',num2str(study),'/sb=',sb1,'/clust=',num2str(clust),'/epch=',num2str(epch_tr),'/detailed'),'Rotation',0, 'FontSize',14, 'FontWeight','b')
ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
tdl=timezone(lnkc,'degree')-timezone(lnkc(1),'degree');
tdls=num2str(tdl);
lblf2{1,1}=' ';
for fh=1:hp2
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
lblf2{hp2+2,1}=' '; lblf2{hp2+3,1}=' '; %#ok<*SAGROW>
set(h2,'YTick',.5:0.99:hp2+2,'YTickLabel',lblf2)
%%
outp=strcat(out_dir,stdy,'/',sb1,'/phone/processed/mtl_plt');
if exist(outp,'dir')~=7
    mkdir(outp) 
end
output_filepath_mat = strcat(outp, '/',sb1,'_gps.mat');
if (exist(output_filepath_mat, 'file') == 2)
    disp('Removing previously processed file');
    delete(output_filepath_mat);
end
savefig(strcat(outp,'/',stdy,'-',sb1,'-gps.fig'))
img = getframe(gcf);
imwrite(img.cdata, strcat(outp,'/',stdy,'-',sb1,'-gps.png'));
disp('Save daily ...')
indf_gps=pdy33;

%% DPDash Calculation
tdp=length(pdy3(1,2:end));
pdy3h=pdy3(:,2:end);
ndy=tdp;
pdy3v=reshape(pdy3h,1,1440*tdp);
clp=unique(pdy3v);
%% Find 8 most visited places
pdy3vs=zeros(size(pdy3v));
[n,bn] = hist(pdy3v,unique(pdy3v));
[~,idx] = sort(-n);
clps=bn(idx); % Sorted most visited POIs
clps(clps==max(clp))=[];      % Remove unknowns
clps(clps==max(clp)-1)=[];    % Remove missingness
mxd=min(8,max(clps));
for kn=1:mxd
    pdy3vs(pdy3v==clps(kn))=kn;
end  
pdy3vs(pdy3v==max(clp))=NaN;    % Missings
pdy3hs=reshape(pdy3vs,60,24*tdp);
%% Regular vector
pdy3hr=reshape(pdy3v,60,24*tdp);
pdy3hr(pdy3hr==max(clp))=NaN;
pdy3hr(pdy3hr==max(clp)-1)=NaN;
nhr=length(pdy3hr(1,:));
frqv=NaN(1,nhr);  dstv=NaN(1,nhr);   frqv2=NaN(1,nhr);
for hr=1:length(pdy3hr(1,:))
    dhr=pdy3hr(:,hr);
    if ~isnan(dhr)
        mxhr=nanmax(dhr);
        dstv(1,hr)=ddfk(mxhr);
        ndhr = dhr(~isnan(dhr));
        frqv(1,hr)=length(unique(ndhr));
        frqv2(1,hr)=mxhr;
    end
    dhs=pdy3hs(:,hr);
    if ~isnan(dhs)
        mxhs=nanmax(dhs);
        if mxhs==0
            frqv2(1,hr)=9;  % Others
        else
            frqv2(1,hr)=mxhs;
        end
    end
end
ind_freq=reshape(frqv,24,tdp)';
ind_freq2=reshape(frqv2,24,tdp)';
ind_dist=reshape(dstv,24,tdp)';
ind_home=[];
for dds=1:tdp
    dpy=pdy3h(:,dds);
    upy=sort(unique(dpy));
    upy=upy(upy~=max(clp));
    upy=upy(upy~=max(clp)-1);
    if ~isempty(upy)
        if ismember(upy,1)  % home is included
            dsfh=deg2km(distance(ltkc(upy(end)),lnkc(upy(end)),ltkc(1),lnkc(1)));  % Distance from home
            hdst=0;      % Home distance
            npv=length(upy);   % Number of places visited
            ndpy=dpy;
            ndpy(dpy==max(clp))=NaN;
            ndpy(dpy==max(clp)-1)=NaN;
            n1py=ndpy;  
            n1py(n1py~=1)=NaN;
            nah=nansum(n1py);
            n2py=ndpy;
            n2py(~isnan(n2py))=1;
            nall=nansum(n2py);
            prch=round(100*nah/nall);     % Percent of time at home primary
            npy=dpy;
            npy(dpy==max(clp))=NaN; 
            npy(dpy==1)=NaN;
            npy(~isnan(npy))=1;
            ntah=nansum(npy);
            prchn=round(100*(1440-ntah)/1440);     % Percent of time at home revised
            nnpy=dpy;
            nnpy(dpy==max(clp))=NaN;
            nnpy(~isnan(nnpy))=1;
            ndta=nansum(nnpy)/60;
            ind_home=[ind_home;[ndta hdst dsfh prch prchn npv]];        
        else
            %% Find the new home (the most visited place of the day)
            dpyn=dpy;
            dpyn=dpyn(dpyn~=max(clp));
            dpyn=dpyn(dpyn~=max(clp)-1);
            chm=mode(dpyn);
            dst=deg2km(distance(ltkc(upy),lnkc(upy),ltkc(chm),lnkc(chm)));  % Distance from home
            dsfh=max(dst);
            hdst=deg2km(distance(ltkc(chm),lnkc(chm),ltkc(1),lnkc(1)));      % Home distance
            npv=length(upy);   % Number of places visited
            ndpy=dpy;
            ndpy(dpy==max(clp))=NaN;
            ndpy(dpy==max(clp)-1)=NaN;
            n1py=ndpy;  
            n1py(n1py~=chm)=NaN;
            n1py(n1py==chm)=1;
            nah=nansum(n1py);
            n2py=ndpy;
            n2py(~isnan(n2py))=1;
            nall=nansum(n2py);
            prch=round(100*nah/nall);     % Percent of time at home primary
            npy=dpy;
            npy(dpy==length(clp))=NaN; 
            npy(dpy==chm)=NaN;
            npy(~isnan(npy))=1;
            ntah=nansum(npy);
            prchn=round(100*(1440-ntah)/1440);     % Percent of time at home revised
            nnpy=dpy;
            nnpy(dpy==max(clp))=NaN;
            nnpy(~isnan(nnpy))=1;
            ndta=nansum(nnpy)/60;
            ind_home=[ind_home;[ndta hdst dsfh prch prchn npv]];        
        end
    else
        ind_home=[ind_home;[NaN NaN NaN NaN NaN NaN]];
    end
end
%% DPdash format
dys=[1:1:ndy]';
mdys=dys+mn-1;
wdys=weekday(mdys+1);
jdys=(mdys-datenum('1970-01-01'))*1000*3600*24;
days=num2str(dys);
reftime=num2str(jdys);
weekday1=num2str(wdys);
timeofday=[];
for k=1:ndy
    timeofday=[timeofday;'00:00:00'];
end
tab_ddp=table(reftime,days,timeofday,weekday1);
try 
    tab_ddp.Properties.VariableNames{'days'} = 'day';
    tab_ddp.Properties.VariableNames{'weekday1'} = 'weekday';
catch ME

end
outg=strcat(out_dir,stdy,'/',sb1,'/phone/processed/gps');
if exist(outg,'dir')~=7
    mkdir(outg) 
end
activity=ind_home;
activity2=round(100*activity)/100;
activity1=string(activity2);
tab_act_hr1=array2table(activity1);
tab_act_hr1.Properties.VariableNames={'missing','homDist','radiusMobility','percentHomep','percentHome','numPlaces'};
tab_act_hr=[tab_ddp tab_act_hr1];
flp=dir(strcat(outg,'/',study,'-',sb1,'-phone_gps_homeStay_*.csv'));
if ~isempty(flp)
    for k=1:length(flp)
        filen=flp(k,1).name;
        delete(strcat(outg,'/',filen));
    end
end
writetable(tab_act_hr,strcat(outg,'/',study,'-',sb1,'-phone_gps_homeStay_daily-day1to',num2str(ndy),'.csv'),'Delimiter',',','QuoteStrings',false)
%%
score=ind_dist;
score2=round(10*score)/10;
score1=string(score2);
tab_dist_hr1 =array2table(score1);
tab_dist_hr1.Properties.VariableNames={'activityScore_hour01','activityScore_hour02', 'activityScore_hour03','activityScore_hour04','activityScore_hour05','activityScore_hour06','activityScore_hour07','activityScore_hour08','activityScore_hour09','activityScore_hour10','activityScore_hour11','activityScore_hour12','activityScore_hour13','activityScore_hour14','activityScore_hour15','activityScore_hour16','activityScore_hour17','activityScore_hour18','activityScore_hour19','activityScore_hour20','activityScore_hour21','activityScore_hour22','activityScore_hour23','activityScore_hour24'};
tab_dist_hr=[tab_ddp tab_dist_hr1];
flp=dir(strcat(outg,'/',study,'-',sb1,'-phone_gps_dist_*.csv'));
if ~isempty(flp)
    for k=1:length(flp)
        filen=flp(k,1).name;
        delete(strcat(outg,'/',filen));
    end
end
writetable(tab_dist_hr,strcat(outg,'/',study,'-',sb1,'-phone_gps_dist_hourly-day1to',num2str(ndy),'.csv'),'Delimiter',',','QuoteStrings',false)

%%
score=ind_freq;
score2=score;
score1=string(score2);
tab_freq_hr1 =array2table(score1);
tab_freq_hr1.Properties.VariableNames={'activityScore_hour01','activityScore_hour02', 'activityScore_hour03','activityScore_hour04','activityScore_hour05','activityScore_hour06','activityScore_hour07','activityScore_hour08','activityScore_hour09','activityScore_hour10','activityScore_hour11','activityScore_hour12','activityScore_hour13','activityScore_hour14','activityScore_hour15','activityScore_hour16','activityScore_hour17','activityScore_hour18','activityScore_hour19','activityScore_hour20','activityScore_hour21','activityScore_hour22','activityScore_hour23','activityScore_hour24'};
tab_freq_hr=[tab_ddp tab_freq_hr1];
flp=dir(strcat(outg,'/',study,'-',sb1,'-phone_gps_freq_*.csv'));
if ~isempty(flp)
    for k=1:length(flp)
        filen=flp(k,1).name;
        delete(strcat(outg,'/',filen));
    end
end
writetable(tab_freq_hr,strcat(outg,'/',study,'-',sb1,'-phone_gps_freq_hourly-day1to',num2str(ndy),'.csv'),'Delimiter',',','QuoteStrings',false)

%%
score=ind_freq2;
score2=score;
score1=string(score2);
tab_freq_hr1 =array2table(score1);
tab_freq_hr1.Properties.VariableNames={'activityScore_hour01','activityScore_hour02', 'activityScore_hour03','activityScore_hour04','activityScore_hour05','activityScore_hour06','activityScore_hour07','activityScore_hour08','activityScore_hour09','activityScore_hour10','activityScore_hour11','activityScore_hour12','activityScore_hour13','activityScore_hour14','activityScore_hour15','activityScore_hour16','activityScore_hour17','activityScore_hour18','activityScore_hour19','activityScore_hour20','activityScore_hour21','activityScore_hour22','activityScore_hour23','activityScore_hour24'};
tab_freq2_hr=[tab_ddp tab_freq_hr1];
flp=dir(strcat(outg,'/',study,'-',sb1,'-phone_gps_freq2_*.csv'));
if ~isempty(flp)
    for k=1:length(flp)
        filen=flp(k,1).name;
        delete(strcat(outg,'/',filen));
    end
end
writetable(tab_freq2_hr,strcat(outg,'/',study,'-',sb1,'-phone_gps_freq2_hourly-day1to',num2str(ndy),'.csv'),'Delimiter',',','QuoteStrings',false)

%%
clp1=unique(indf_gps);
tpa=tpd;
ind_tmz=zeros(size(indf_gps));
for k1=1:max(clp1)-2
    ind_tmz(indf_gps==k1)=tdl(k1);
end
ind_tmz(indf_gps==max(clp1)-1)=NaN;
ind_tmz(indf_gps==max(clp1))=NaN;
ind_vmz=reshape(ind_tmz,1,1440*length(ind_tmz(1,:)));
txq=1:1:length(ind_vmz);
txp=txq(~isnan(ind_vmz));
typ=ind_vmz(~isnan(ind_vmz));
ind_tmz1=interp1(txp,typ,txq,'previous','extrap');
txp=txq(~isnan(ind_tmz1));
typ=ind_tmz1(~isnan(ind_tmz1));
ind_tmz2=interp1(txp,typ,txq,'next','extrap');
txqm=txq-(ind_tmz2*60);
txqm(txqm<1)=1;
txqm(txqm>max(txq))=max(txq);
%% Build Replacing indecies
txa=1:1:tpa*1440;
txam=txa-(ind_tmz2(1:1:tpa*1440)*60);
txam(txam<1)=1;
txam(txam>max(txa))=max(txa);
[a11,a22,a33]=unique(txam,'last');
%%
indv_gps=reshape(indf_gps,1,1440*length(indf_gps(1,:)));
indvm2_gps=max(indv_gps)*ones(size(indv_gps));
[a1,a2,a3]=unique(txqm,'last');
indvm2_gps(a1)=indv_gps(a2);
indm2_gps=reshape(indvm2_gps,1440,length(indf_gps(1,:)));
ind_tmzz=reshape(ind_tmz2,1440,length(ind_tmz(1,:)));
ind_tmzz=ind_tmzz(:,1:tpa);
utmz=unique(ind_tmzz);
utmn=strcat(num2str(utmz),'(h)');
indf_tmz=zeros(size(ind_tmzz));
for k2=1:length(utmz)
    indf_tmz(ind_tmzz==utmz(k2))=k2;
end
display('Time zone added.')

%% Plot timezone
ff2=figure(2);
set(gcf,'position',get(0,'screensize')-[0,0,0,0])
set(gcf,'color','white')
clr5=[[0 0 0];[1 0 0 ];[1 1 0];[ 0 1 0]; [0 0 1]; [0 1 1 ]; [1 0 1];[.5 0 0 ];[0 .5 0];[0 0 .5]];
%clr5=[[1 0 0 ];[1 0 1];[ .75 .75 .75]; [0 0 1]];
clr6=[clr5(1:length(utmz),:)];
colormap(gca,clr6)
hhind=imagesc(flip(indf_tmz,1));
axi = ancestor(hhind, 'axes');
xrule = axi.XAxis;  yrule = axi.YAxis;
h25fpp=colorbar;
set(gca, 'FontWeight','b')
set(h25fpp,'YTick',1.5:.7:length(utmz)+.5,'YTickLabel',utmn,'FontSize',24)
set(gca,'YTick',0.5:60:1440.5,'YTickLabel',epc_lbl{1,1}(1:1:end))  
set(gca,'XTick',.5:4:tpa+.5,'XTickLabel',0:4:tpa,'XTickLabelRotation',90)
%title(strcat('study=',num2str(study),'/sb=',sb1,'/TimeZone'),'Rotation',0, 'FontSize',14, 'FontWeight','b')
xrule.FontSize = 24;
yrule.FontSize = 24;
xlabel('Relative Days','FontWeight','b','FontSize',24)
grid on
xlim([.5,tpa+.5])
savefig(strcat(outp,'/',stdy,'-',sb1,'-tmzn.fig'))
img = getframe(gcf);
imwrite(img.cdata, strcat(outp,'/',stdy,'-',sb1,'-tmzn.png'));
display('TimeZone Saved.');

save(strcat(outp,'/',sb1,'_gps.mat'),'indf_gps','lnkc','ltkc')
display('COMPLETE');
exit(0);
