function aggregate_gps_mc(study,subject,ref_date,read_dir,output_dir, matlab_dir)
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

% Check if the path is properly formatted
if ~ endsWith(read_dir, '/')
    read_dir = strcat(read_dir, '/');
end
if exist(read_dir,'dir')~=7
    disp(strcat('Input directory ', read_dir, ' does not exist. Exiting.'));
    exit(1);
end

%% Initialization
sb=subject;
hp=150;     % Pool of PoIs
dia11=50;   % Classification diameter
hp2=100;     % Chosen circles
sepp=0.85;  % Separatoion factor of the circles
dtm=12/24/60; % Color expansion 12min
epch_tr=10;    % Epoch trigger
clust=1;      % 1=fast 2=old
fcs=8;        % Location that we focus on
hrlm=[0 24];  % Focus epoch for markov
ts_mark=15;  % Sampling time 
tran_lim=2;  % transition probability limit; smaller than this limit is removed from graph

thrall=0;
thrs=thrall;
thrw=thrall;
thrc=thrall;
thrg=thrall;

%% Process the consent date
cdates=strsplit(ref_date, '-');
cdates=cellfun(@str2num,cdates(1:end));
cdates_year=cdates(1);
cdates_month=cdates(2);
cdates_day=cdates(3);

% find the difference between starting date and the marked date
t0=datenum(cdates_year,cdates_month,cdates_day)-datenum(2015,1,31);

%% Colors
wnt=winter(30);
spr=spring(30);
sumr=summer(30);
autm=autumn(20);
copr=copper(17);
colll=[autm(1:12,:);wnt(1:15,:);sumr(1:12,:);spr(1:10,:);copr;sumr(15:26,:);spr(18:25,:);wnt(21:30,:);autm(16:20,:)];
colr=[colll;colll;colll;colll;colll;colll;colll;colll;colll;colll;colll;colll;colll;colll];

disp('Sanity check complete.');
fls=dir(strcat(read_dir,'daily_n*.mat.lock'))
pdyl=[];lblf2=[];
if length(fls)>1
    display('Start aggregating ...')
    for fs=1:length(fls)
        file_name=fls(fs,1).name;
        file_path=strcat(read_dir, file_name);
        %% Load and decrypt the input table
        disp(strcat('Loading the input file',file_path));
        if encp==1
            tmpN = tempname('/tmp');
            temp_unlocked=strcat(tmpN,'.mat');
            cmd = strcat(matlab_dir,'aggregate_gps_mc_decrypter.py --input "',file_path,'" --output "', temp_unlocked, '"');
            system(cmd);
            pause(0.1);
            load(temp_unlocked);
            pause(0.01);
            cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
            system(cmd2);
        else
            load(file_path);
        end
        pdyl{fs,1}=pdy3;
        pdyl{fs,2}=ddfk;
        pdyl{fs,3}=ltkc;
        pdyl{fs,4}=lnkc;
    end
    disp('Integrating the daily plots');
    %% Integrating the daily plots
    pdi=pdyl{1,1};
    ltki=pdyl{1,3};
    lnki=pdyl{1,4};
    pn=length(ltki);
    pdi(pdi==(pn+1))=10001;
    pdi(pdi==(pn+2))=10002;    
    ip=pn;
    for i=2:length(pdyl(:,1))
        pdi2=pdyl{i,1};
        ltki2=pdyl{i,3};
	lnki2=pdyl{i,4};
	pn2=length(ltki2);
        pdi22=pdi2;
        for po=1:pn2
            dd=deg2km(distance(ltki,lnki,ltki2(po),lnki2(po)));
            id=find(dd<.08,1,'first');
            if ~isempty(id)
                pdi22(pdi2==po)=id;
            else
                ip=ip+1;
                pdi22(pdi2==po)=ip;
                ltki=[ltki ltki2(po)];
                lnki=[lnki lnki2(po)];
            end
        end
        pdi22(pdi2==(pn2+1))=10001;
        pdi22(pdi2==(pn2+2))=10002;
        lp=length(pdi(1,:));
        pdi=[pdi pdi22(:,lp+1:end)];        
    end
    pdi(pdi==10001)=ip+1;
    pdi(pdi==10002)=ip+2;
    disp('Sorting the data');
    %% sort
    dd1=deg2km(distance(ltki,lnki,ltki(1),lnki(1)));
    [dds,idds]=sort(dd1,'ascend');
    ltkis=ltki(idds); lnkis=lnki(idds);
    pdis=pdi;
    for ps=1:length(idds)
        pdis(pdi==idds(ps))=ps;
    end

    disp('Plotting the daily pattern');
    %% Plot the colorful detailed daily pattern
    figure(1);
    set(gcf,'position',get(0,'screensize'));
    clrr3=colr(1:ip,:);
    clrr3=[clrr3; [.9 .9 .9];[1 1 1]];
    colormap(gca,clrr3);
    hh2=imagesc(pdis);
    ax = ancestor(hh2, 'axes');
    xrule = ax.XAxis;
    h2=colorbar;
    set(gca, 'FontWeight','b');
    tpd=length(pdis(1,:));
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24);
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',0:1:tpd,'XTickLabelRotation',90);
    xrule.FontSize = 8;

    grid on;
    title(strcat('study=',study,'/sb=',sb,'/clust=',num2str(clust),'/epch=',num2str(epch_tr),'/detailed'),'Rotation',0, 'FontSize',14, 'FontWeight','b');
    xlabel('Relative days','FontSize',12,'FontWeight','bold');
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold');
    ddfk=deg2km(distance(ltkis,lnkis,ltkis(1),lnkis(1)));
    ddfk_len=length(ddfk);

    lblf2{1,1}=' ';
    for fh=1:ip
        if fh > ddfk_len
            break;
        end

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

    lblf2{ip+2,1}=' '; lblf2{ip+3,1}=' ';
    set(h2,'YTick',.5:0.98:ip+2,'YTickLabel',lblf2);
    img = getframe(gcf);

    disp('Saving daily img file');
    img_path = strcat(output_dir,study,'_',sb,'_daily_all.png');
    imwrite(img.cdata, img_path);
    if encp==1
        locked_img_path = strcat(output_dir,study,'_',sb,'_daily_all.png.lock');       
        pause(6);
        cmd = sprintf('python %saggregate_gps_mc_encrypter.py --input "%s" --output "%s"', matlab_dir, img_path, locked_img_path);
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', img_path);
        system(cmd2);
    end

    disp('Saving data');
    %% Save in protected folder
    pdy3=pdis;
    ltkc=ltkis;
    lnkc=lnkis;
    disp('Saving mat file');
    if encp==1
        output_filepath='/tmp/daily.mat';
        save(output_filepath,'pdy3','ltkc','lnkc');
        pause(.01);
        disp('Locking up mat file');
        locked_filename='daily_all.mat.lock';
        locked_file_path=strcat(output_dir,'gps_dash2/',locked_filename);
        cmd = strcat(matlab_dir,'aggregate_gps_mc_encrypter.py --output "',locked_file_path,'" --input "', output_filepath, '"');
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', output_filepath);
        system(cmd2);
    else
        unlocked_filename='daily_all.mat.lock';
        unlocked_file_path=strcat(output_dir,'gps_dash2/',unlocked_filename);
        save(unlocked_file_path,'pdy3','ltkc','lnkc');
    end
else
    disp('Only one daily file exists.')
    file_name=fls.name;
    file_path=strcat(read_dir, file_name);
    %% Load and decrypt the input table
    disp(strcat('Loading the input file',file_path));
    if encp==1
        tmpN = tempname('/tmp');
        temp_unlocked=strcat(tmpN,'.mat');
        cmd = strcat(matlab_dir,'aggregate_gps_mc_decrypter.py --input "',file_path,'" --output "', temp_unlocked, '"');
        system(cmd);
        pause(0.1);
        load(temp_unlocked);
        pause(0.01);
        cmd2=sprintf('%s %s', 'shred -u', temp_unlocked);
        system(cmd2);
    else
        load(file_path);
    end
    
    disp('Saving mat file');
    if encp==1
        output_filepath='/tmp/daily.mat';
        save(output_filepath,'pdy3','ltkc','lnkc');
        pause(.01);   
        disp('Locking up mat file');
        locked_filename='daily_all.mat.lock';
        locked_file_path=strcat(output_dir,'gps_dash2/', locked_filename);
        cmd = strcat(matlab_dir,'aggregate_gps_mc_encrypter.py --output "',locked_file_path,'" --input "', output_filepath, '"');
        system(cmd);
        pause(.01);
        cmd2=sprintf('%s %s', 'shred -u', output_filepath);
        system(cmd2); 
    else
        unlocked_filename='daily_all.mat';
        unlocked_file_path=strcat(output_dir,'gps_dash2/', unlocked_filename);
        save(unlocked_file_path,'pdy3','ltkc','lnkc');
    end
end

display('COMPLETE');
exit(0);
