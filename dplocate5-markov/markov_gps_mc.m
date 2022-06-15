function markov_gps_mc(read_dir, out_dir, extension, matlab_dir, date_from, subject, study)
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

%%
for ipc=1:5   % 1=all 2=work 3=social 4=night 5=sleep 
    %% Initialization & Parameters    
    epochs1={'All';'Day';'Evening';'Night';'LateNight'};
    epc_lbl{1,1}={'12AM',' 1AM',' 2AM',' 3PM',' 4AM',' 5AM',' 6AM',' 7AM',' 8AM',' 9AM','10AM','11AM','12PM',' 1PM',' 2PM',' 3PM',' 4PM',' 5PM',' 6PM',' 7PM',' 8PM',' 9PM','10PM','11PM','12AM'};
    epc_lbl{2,1}={' 9AM','10AM','11AM','12PM',' 1PM',' 2PM',' 3PM',' 4PM',' 5PM'};
    epc_lbl{3,1}={' 6PM',' 7PM',' 8PM',' 9PM','10PM'};
    epc_lbl{4,1}={'10PM','11PM','12AM',' 1AM',' 2AM'};
    epc_lbl{5,1}={' 2AM',' 3PM',' 4AM',' 5AM',' 6AM'};
    epochm={[0 24];[9 17];[18 22];[22 2];[2 6]};
    epochm1={[0 24];[7 15];[2 6];[22 2];[18 22]};
    
    hrlm=epochm{ipc,1};  % Focus epoch for markov
    
    epc1=epochs1{ipc,1};
    ts_mark=15;  % Sampling time 
    tran_lim=5;  % transition probability limit; smaller than this limit is removed from graph
    nfeww=[2 2 2 2 2];    % less than this number repeated POIs are deleted 
    nfew=nfeww(ipc);
    dfar=25;    % farther than this distance POIs are deleted
    
    trg=1.5;    % 1.5 for 1,2  - 10 for 3 

    %% Colors
    wnt=winter(30);
    spr=spring(30);
    sumr=summer(30);
    autm=autumn(20);
    copr=copper(17);
    colll=[autm(1:12,:);wnt(1:15,:);sumr(1:12,:);spr(1:10,:);copr;sumr(15:26,:);spr(18:25,:);wnt(21:30,:);autm(16:20,:)];
    colr=[colll;colll;colll;colll;colll;colll];
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
        cmd = strcat(matlab_dir,'markov_gps_mc_decrypter.py --input "',file_path,'" --output "', temp_unlocked, '"');
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
    end
    
    % find the difference between starting date and the marked date
    mn=datenum(cdates_year,cdates_month,cdates_day);
    hp2=length(ltkc);
    % find the difference between starting date and the marked date

    t0=datenum(cdates_year,cdates_month,cdates_day)-datenum(2015,1,31);
    %% Plot the colorful detailed daily pattern
    figure(50)
    set(gcf,'position',get(0,'screensize'))
    clrr3=colr(1:hp2,:);
    clrr3=[[.75 .75 .75];clrr3; [.9 .9 .9];[1 1 1]];
    colormap(gca,clrr3)
    tpd=length(pdy3(1,:));
    ipd=1:tpd;
    hh2=imagesc(pdy3(:,ipd));
    ax = ancestor(hh2, 'axes');
    xrule = ax.XAxis;
    h2=colorbar;
    set(gca, 'FontWeight','b')

    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24)
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',0:1:tpd,'XTickLabelRotation',90)
    xrule.FontSize = 8;
    grid on
    xlabel('Days','FontSize',12,'FontWeight','bold')
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold')
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
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
    lblf2{hp2+2,1}=' '; lblf2{hp2+3,1}=' ';
    set(h2,'YTick',.5:0.98:hp2+2,'YTickLabel',lblf2)

    %% Plot the colorful detailed daily pattern
    figure(10)
    set(gcf,'position',get(0,'screensize'))
    clrr3=colr(1:hp2,:);
    clrr3=[[.75 .75 .75];clrr3; [.9 .9 .9];[1 1 1]];
    colormap(gca,clrr3)
    hh2=imagesc(pdy3(:,ipd));
    ax = ancestor(hh2, 'axes');
    xrule = ax.XAxis;
    h2=colorbar;
    set(gca, 'FontWeight','b')
    tpd=length(pdy3(1,:));
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24)
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',0:1:tpd,'XTickLabelRotation',90)
    xrule.FontSize = 8;
    grid on
    xlabel('Days','FontSize',12,'FontWeight','bold')
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold')
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
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
    lblf2{hp2+2,1}=' '; lblf2{hp2+3,1}=' ';
    set(h2,'YTick',.5:0.98:hp2+2,'YTickLabel',lblf2)
    %% Remove far POIs (>dfar)
    wid=mod([mod(t0,7)+[0:tpd-1]],7);
    iwid=find(wid==10 );
    pdy33=pdy3;
    ifar=find(ddfk<dfar,1,'last');
    pdy33(:,iwid)=ifar+1;
    pdy33(pdy33>ifar)=ifar+1;
    
    tpd=length(pdy33(1,:));
    %% Plot the colorful detailed daily pattern
    figure(1000+ipc)
    set(gcf,'position',get(0,'screensize'))
    clrr33=colr(1:ifar,:);
    clrr33=[[.75 .75 .75];clrr33;[1 1 1]];
    colormap(gca,clrr33)
    hhh2=imagesc(pdy33(:,ipd));
    ax = ancestor(hhh2, 'axes');
    xrule = ax.XAxis;
    hd2=colorbar;
    set(gca, 'FontWeight','b')
    tpd=length(pdy33(1,:));
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24)
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',0:1:tpd,'XTickLabelRotation',90)
    xrule.FontSize = 8;
    grid on
    xlabel('Days','FontSize',12,'FontWeight','bold')
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold')
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
    lblf2{1,1}=' ';
    for fh=1:ifar
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
    lblf2{ifar+2,1}=' '; 
    set(hd2,'YTick',.5:0.97:ifar+1,'YTickLabel',lblf2)
    %% Find rare structures
    if ipc==1   % Only for all
        pal=1;    
        figure(30+ipc)
        set(gcf,'position',get(0,'screensize'))    
        pdy3ff=pdy33;
        pdy3ff(pdy3ff~=pal)=0;
        rpdy=corrcoef(pdy3ff);
        trpdy=triu(rpdy,1);
        pdy3fs=nansum(trpdy)./([1 1:length(rpdy(1,:))-1]);
        pdy3fsm=tsmovavg(pdy3fs,'s',4,2);
        plot(pdy3fsm,'Color',clrr33(pal,:),'LineWidth',2)
        hold on
        mnh=nanmean(pdy3fsm)/trg;
        plot([1,length(pdy3fsm)],[mnh,mnh],'LineWidth',1)            
        set(gca,'XTick',0:1:tpd,'XTickLabel',0:1:tpd,'XTickLabelRotation',90)
        xrule.FontSize = 8;
        grid on
        pdy3fd=[0 diff(pdy3fsm)];
        hold on
        plot(trg*mnh*sign(pdy3fd),'b','LineWidth',1)
        sg=pdy3fsm-mnh;
        sgd=pdy3fd;
        isg1=find(sg>=0,1,'first');
        isg2=find(sgd(1:isg1)<=0,1,'last');
        plot(isg2,0,'*','MarkerSize',10)
        isg3=find(sg>=0,1,'last');
        isg4=find(sgd(1:isg3)>0,1,'last');
        hold on
        plot(isg4,0,'*','MarkerSize',10)
        xlabel('Relative days','FontSize',12,'FontWeight','bold')
        ylabel('Correlation factor','FontSize',12,'FontWeight','bold')

    end
    %% Remove rare structures 
    pdy33b=pdy33;
    pdy33b(:,1:isg2)=ifar+1;
    pdy33b(:,isg4:end)=ifar+1;
    %% Plot the colorful detailed daily pattern
    figure(2000+ipc)
    set(gcf,'position',get(0,'screensize'))
    clrr33=colr(1:ifar,:);
    clrr33=[[.75 .75 .75];clrr33;[1 1 1]];
    colormap(gca,clrr33)
    pdy33bf=flip(pdy33b(:,ipd),1);
    hhh3=imagesc(pdy33bf);
    ax = ancestor(hhh3, 'axes');
    xrule = ax.XAxis;
    hs2=colorbar;
    set(gca, 'FontWeight','b')
    tpd=length(pdy33b(1,:));
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24)
    set(gca,'XTick',.5:1:tpd+.5,'XTickLabel',0:1:tpd,'XTickLabelRotation',90)
    xrule.FontSize = 8;
    grid on
    xlabel('Days','FontSize',12,'FontWeight','bold')
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold')
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
    lblf2{1,1}=' ';
    for fh=1:ifar
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
    lblf2{ifar+2,1}=' ';
    set(hs2,'YTick',.5:0.97:ifar+2,'YTickLabel',lblf2)
    set(hs2,'ylim',[1 ifar])
%     if ipc==1
%         savefig(gcf,strcat(pwd,'/paperfigs/',num2str(study),'_',num2str(sb-2),'_no_far_rare.fig'))
%     end
    %% Replace missing POIs with closest POIs to calculate the difference and find few repeatings 
    pdy34b=pdy33b;
    tpdep=length(pdy34b(1,:));
    if ipc==4
        pdy34b(hrlm(2)*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-hrlm(2))*60,tpdep);
    else
        pdy34b(0*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-0)*60,tpdep);
        pdy34b(hrlm(2)*60+1:24*60,:)=(ifar+1)*ones((24-hrlm(2))*60,tpdep);
    end
    pdy34b(pdy34b==ifar+1)=NaN;
    pdy34b=[pdy34b;zeros(1,tpd)];
    pdy34v=reshape(pdy34b,[1441*tpd,1]);
    pdy34t=[1:1441*tpd]';
    nipd=isnan(pdy34v);
    pdy35v=interp1(pdy34t(~nipd),pdy34v(~nipd),pdy34t,'nearest','extrap');
    pdy35=reshape(pdy35v,[1441,tpd]);
    %% Find POIs with few repeating 
    ipdyd=[find(diff(pdy35v));1441*tpd];
    pdy35d=pdy35v(ipdyd);
    aun = unique(pdy35d);
    pdyout = [aun,histc(pdy35d(:),aun)];
    [pdys,inds]=sort(pdyout(:,2),'descend');
    ifewp=setdiff([1:ifar]',pdyout(:,1));
    ifew=[aun(inds(pdys<nfew));ifewp];
    iall=sort(aun(inds(pdys>=nfew)));
    if isempty(iall)
        iall=1;
        ifew=ifew(2:end);
    end
    %% Remove few POIs 
    pdy3f=pdy33b;
    tpdep=length(pdy3f(1,:));
    if ipc==4
        pdy3f(hrlm(2)*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-hrlm(2))*60,tpdep);
    else
        pdy3f(0*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-0)*60,tpdep);
        pdy3f(hrlm(2)*60+1:24*60,:)=(ifar+1)*ones((24-hrlm(2))*60,tpdep);
    end
    pdy3f(ismember(pdy3f,ifew))=ifar+1;
    tpd=length(pdy33(1,:));

    %% Replace missing POIs with closest POIs 
    pdy34f=pdy3f;
    pdy34f(pdy34f==ifar+1)=NaN;
    pdy34fe=pdy34f;
    tpdr=length(pdy34fe(1,:));
    pdy34fe(pdy34fe>0)=1;
    pdy34fer=reshape(pdy34fe,[1440*tpdr,1]);
    pdy34fen=reshape(pdy34fer,[60,24*tpdr]);
    iclmn=find(sum(pdy34fen,'omitnan')<1);
    iclmp=find(sum(pdy34fen,'omitnan')>=1);
    pdy34fr=reshape(pdy34f,[1440*tpdr,1]);
    pdy34fn=reshape(pdy34fr,[60,24*tpdr]);
    for clmns=1:length(iclmn)
        pdy34fn(:,iclmn(clmns))=(ifar+1)*ones(60,1);
    end
    tpdd=length(pdy34fn(1,:));
    pdy34vf=reshape(pdy34fn,[60*tpdd,1]);
    pdy34tt=[1:60*tpdd]';
    nipdf=isnan(pdy34vf);
    pdy35vf=interp1(pdy34tt(~nipdf),pdy34vf(~nipdf),pdy34tt,'nearest','extrap');
    pdy35f=reshape(pdy35vf,[1440,tpdd/24]);

    %% choose the markov analysis epoch 
    pdy35fp=pdy35f;
    tpddd=length(pdy35fp(1,:));
    if ipc==4
        pdy35fp(hrlm(2)*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-hrlm(2))*60,tpddd);
    else
        pdy35fp(0*60+1:hrlm(1)*60,:)=(ifar+1)*ones((hrlm(1)-0)*60,tpddd);
        pdy35fp(hrlm(2)*60+1:24*60,:)=(ifar+1)*ones((24-hrlm(2))*60,tpddd);
    end
    aun1 = unique(pdy35fp);
    aun2=aun1(1:end-1);
    if ipc==1
        clrr1=ones(ifar,3);
        clrr1(aun2,:)=[[.75 .75 .75];colr(1:length(aun2)-1,:)];
    end
    %% Plot
    f1=figure(70+ipc);
    set(gcf,'position',get(0,'screensize'))
    clrr34p=clrr1(1:ifar,:);
    colormap(gca,[clrr34p(aun2,:);[1 1 1]])
    pdy35fpm=pdy35fp;
    for cr=1:length(aun2)
        pdy35fpm(pdy35fpm==aun2(cr))=cr;
    end
    pdy35fpmn=[pdy35fpm;[pdy35fpm(:,2:end) (cr+1)*ones(1440,1)]];
    pdy35fpm(pdy35fpm==ifar+1)=cr+1;
    pdy35fpmn(pdy35fpmn==ifar+1)=NaN;
    if ipc==1
        ipdydy=find(nansum(pdy35fpmn(540:1800,:),1));  % 540:1800
    end

    hh35fp1=imagesc(flip(pdy35fpm(:,ipd),1));
    ax = ancestor(hh35fp1, 'axes');
    xrule = ax.XAxis;
    h25fp=colorbar;
    set(gca, 'FontWeight','b')
    set(gca,'YTick',0.5:60:1440.5,'YTickLabel',0:1:24)
    set(gca,'XTick',.5:1:tpddd+.5,'XTickLabel',0:1:tpddd,'XTickLabelRotation',90)
    %xlim([347.5, 402.5])
    xrule.FontSize = 8;
    grid on
    xlabel('Days','FontSize',12,'FontWeight','bold')
    ylabel('Day time (hours)','FontSize',12,'FontWeight','bold')
    ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
    lblf25p{1,1}=' ';
    nfw=0;
    for fh=1:ifar
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
        if ismember(fh,aun2)
            nfw=nfw+1;
            lblf25p{nfw+1,1}=strcat(sprintf(fmt,fh),'-',sprintf(fmt2,ddfk(fh)),' km');
        end
    end
    lblf25p{nfw+2,1}=' ';
    set(h25fp,'YTick',.5:.97:length(aun2)+1,'YTickLabel',lblf25p)
    try
        set(h25fp,'ylim',[1 length(aun2)])
    catch ME
    end
%     if ipc==1
%         savefig(strcat(pwd,'/paperfigs/',num2str(study),'_',num2str(sb-2),'_filledmissing.fig'))
%     end
    %% Output folder
    outp=strcat(out_dir,stdy,'/',sb1,'/phone/processed/mtl_plt');
    if exist(outp,'dir')~=7
        mkdir(outp) 
    end

    %% choose the markov analysis epoch 
    if ipc==1    %  all
        ff2=figure(700);
        set(gcf,'position',get(0,'screensize'))
        set(gcf,'color','white')
        colormap(gca,[clrr34p(aun2,:);[1 1 1]])
        pdydy=ipd(ipdydy);
        pdysh=1:length(pdydy);
        hh35fp0=imagesc(flip(pdy35fpm(:,pdydy(pdysh))));
        ax = ancestor(hh35fp0, 'axes');
        xrule = ax.XAxis;
        h25fpp=colorbar;
        yrule = ax.YAxis;
        set(gca, 'FontWeight','b')
        if (epochm{ipc,1}(1,1)<epochm{ipc,1}(1,2))
            ylim([epochm{ipc,1}(1,1)*60+.5 epochm{ipc,1}(1,2)*60+.5])
            set(gca,'YTick',(epochm{ipc,1}(1,1)*60+0.5):60:(epochm{ipc,1}(1,2)*60+0.5),'YTickLabel',epc_lbl{ipc,1}(1:1:end)) 
        else
            ylim([epochm{ipc,1}(1,1)*60+.5 epochm{ipc,1}(1,2)*60+24*60+.5])
            set(gca,'YTick',(epochm{ipc,1}(1,1)*60+0.5):60:(epochm{ipc,1}(1,2)*60+0.5+24*60),'YTickLabel',epc_lbl{ipc,1})
        end

        set(gca,'XTick',0.5:1:length(pdydy)+.5,'XTickLabel',0:1:length(pdydy),'XTickLabelRotation',90)
        xlim([.5, length(pdydy)-.5])
        %xlim([347.5, 405.5])

        xrule.FontSize = 12;
        yrule.FontSize = 17;
        grid on
                    
        ylabel(epc1,'FontSize',17,'FontWeight','bold')
        xlabel('Days','FontSize',17,'FontWeight','bold')
        set(gcf,'position',get(0,'screensize'))
        ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
        lblf25p{1,1}=' ';
        nfw=0;
        for fh=1:ifar
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
            if ismember(fh,aun2)
                nfw=nfw+1;
                lblf25p{nfw+1,1}=strcat(sprintf(fmt,fh),'-',sprintf(fmt2,ddfk(fh)),' km');
            end
        end
        lblf25p{nfw+2,1}=' ';
        set(h25fpp,'YTick',.5:.99:length(aun2)+1,'YTickLabel',lblf25p)
        try
            set(h25fpp,'ylim',[1 length(aun2)])
        catch ME
        end
        %%        
        savefig(strcat(outp,'/',stdy,'-',sb1,'-markovMap.fig'))
        img = getframe(gcf);
        imwrite(img.cdata, strcat(outp,'/',stdy,'-',sb1,'-markovMap.png'));
        disp('Save Markov Map ...')        
    end 
    %% choose the markov analysis epoch 
    if ipc~=1    % Not all
        ff1=figure(70);
        set(gcf,'position',get(0,'screensize'))
        set(gcf,'color','white')
%               subplot(3,3,iipc)
        if ipc==2
            subplot(46,1,28:43)
        elseif ipc==3
            subplot(46,1,19:26)
        elseif ipc==4
            subplot(46,1,10:17)
        elseif ipc==5
            subplot(46,1,1:8)
        end
        colormap(gca,[clrr34p(aun2,:);[1 1 1]])
        if ipc==4
            pdy35fpmd=[pdy35fpm(:,1:end);[pdy35fpm(:,2:end) (cr+1)*ones(1440,1)]];
            hh35fp=imagesc(flip(pdy35fpmd(:,pdydy(pdysh))));
        elseif ipc==5
            pdy35fpmd=[pdy35fpm(:,2:end) (cr+1)*ones(1440,1)];
            hh35fp=imagesc(flip(pdy35fpmd(:,pdydy(pdysh))));
        else
            hh35fp=imagesc(flip(pdy35fpm(:,pdydy(pdysh))));
        end
        ax = ancestor(hh35fp, 'axes');
        h25pp=colorbar;
        xrule = ax.XAxis;
        yrule = ax.YAxis;
        set(gca, 'FontWeight','b')
        if (epochm1{ipc,1}(1,1)<epochm1{ipc,1}(1,2))
            ylim([epochm1{ipc,1}(1,1)*60+.5 epochm1{ipc,1}(1,2)*60+.5])
            set(gca,'YTick',(epochm1{ipc,1}(1,1)*60+0.5):60:(epochm1{ipc,1}(1,2)*60+0.5),'YTickLabel',epc_lbl{ipc,1}(1:1:end)) 
        else
            ylim([epochm1{ipc,1}(1,1)*60+.5 epochm1{ipc,1}(1,2)*60+24*60+.5])
            set(gca,'YTick',(epochm1{ipc,1}(1,1)*60+0.5):60:(epochm1{ipc,1}(1,2)*60+0.5+24*60),'YTickLabel',epc_lbl{ipc,1})
        end
        
        if ipc==5                    
            set(gca,'XTick',0.5:1:length(pdydy)-.5,'XTickLabel','','XTickLabelRotation',0)
            xlim([.5, length(pdydy)-.5])
        else                    
            set(gca,'XTick',0.5:1:length(pdydy)-.5,'XTickLabel','','XTickLabelRotation',0)
            xlim([.5, length(pdydy)-.5])
        end

        xrule.FontSize = 18;
        yrule.FontSize = 18;
        grid on
        ddfk=deg2km(distance(ltkc,lnkc,ltkc(1),lnkc(1)));
        lblf25pf{1,1}=' ';
        nfw=0;
        for fh=1:ifar
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
            if ismember(fh,aun2)
                nfw=nfw+1;
                lblf25pf{nfw+1,1}=strcat(sprintf(fmt,fh),'-',sprintf(fmt2,ddfk(fh)),' km');
            end
        end
        lblf25pf{nfw+2,1}=' ';
        set(h25pp,'YTick',.5:.97:length(aun2)+1,'YTickLabel',lblf25pf)
        try
            set(h25pp,'ylim',[1 length(aun2)])
        catch ME
        end
                      
        ylabel(epc1,'FontSize',17,'FontWeight','bold')

        if ipc==2
            xlabel('Days','FontSize',17,'FontWeight','bold')
            set(gcf,'position',get(0,'screensize'))                      
        end
        if ipc==5
            %%        
            savefig(strcat(outp,'/',stdy,'-',sb1,'-markovTimeBands.fig'))
            img = getframe(gcf);
            imwrite(img.cdata, strcat(outp,'/',stdy,'-',sb1,'-markovTimeBands.png'));
        end
        %saveas(gcf, strcat(pwd,'/',epc,'/',num2str(study),'_',num2str(sb),'_pat','.png'));
    end
    %% Start of the Markov
    pdy35vfp=reshape(pdy35fp,[1440*length(pdy35fp(1,:)),1]);
    pdy35df=pdy35vfp(1:ts_mark:end,1);
    pdy35ddf=[pdy35df(1:end-1) pdy35df(2:end)];
    iout=find((pdy35ddf(:,1)==ifar+1)|(pdy35ddf(:,2)==ifar+1));
    pdy35ddf(iout,:)=[];
    %% Find transition matrix
    if ipc==1
        tab_pdy=table(pdy35ddf(:,1),pdy35ddf(:,2),'VariableNames',{'s_t','next_s_t'});
    end
    tst_id=(fix(length(pdy35ddf(:,1))*1/3)+1):round(length(pdy35ddf(:,1))*2/3);
    pdy35ddf_test=pdy35ddf(tst_id,:);
    pdy35ddf_train=pdy35ddf;% ([1:tst_id(1)-1 (tst_id(2)+1):end],:);
    pt1=pdy35ddf_train(:,1); 
    pt2=pdy35ddf_train(:,2);
    pts1=pdy35ddf_test(:,1);
    pts2=pdy35ddf_test(:,2);
    mark=[];
    tran_w=[];
    for stt1=1:ifar
        ipt1=find(pt1==stt1);
        nmg=length(ipt1);
        tran_w(stt1,1)=nmg;
        for stt2=1:ifar
            ptt2=pt2(ipt1);
            mark(stt1,stt2)=100*length(find(ptt2==stt2))/nmg;
        end
    end
    tran_mx=mark;
    tran_mxp=ceil(tran_mx(aun2,aun2));
    tran_wp=tran_w(aun2);
    if ipc>4
        tran_mxp(tran_mxp<1)=0;
    else
        tran_mxp(tran_mxp<tran_lim)=0;
    end
    tran_ord=[];
    tran_mxd=tran_mxp;
    for jj=1:length(tran_mxp(1,:))
        tran_mxd(jj,jj)=0;
        for ii=jj+1:length(tran_mxp(:,1))
            tran_ord(jj,ii)=tran_mxp(ii,jj)+tran_mxp(jj,ii);        
        end
    end
    for ps=1:length(aun2)
        vars{1,ps}=strcat('',num2str(aun2(ps)));
    end
    %%
    pts2_es=[];
    for pit=1:length(pts1)
        irw=find(aun2==pts1(pit));
        tr_rw=round(1000*tran_mxp(irw,:));
        selm=[];
        selmr=[];
        for icl=1:length(tr_rw)
            if tr_rw(icl)>0
                selm=[selm; aun2(icl)*ones(tr_rw(icl),1)];            
            end
            selmr=[selmr;aun2(icl)*ones(fix(1000/length(tr_rw)),1)];
        end
        pts2_es(pit,1)=datasample(selm,1);
        pts2_esr(pit,1)=datasample(selmr,1);
    end

    %% Graph
    if ipc==2
        tran_mxpp=tran_mxp;
    end
    g=digraph(tran_mxp,vars);
    %ord=graphtopoorder(g);
    f222=figure(80+ipc);
    set(gcf,'position',get(0,'screensize'))
    if length(tran_wp)==1
        Lwd=30;
    else
        Lwd1 = ceil(tran_wp);
        Lwd=30*(Lwd1+1)/(max(Lwd1));
    end
    gend=g.Edges.EndNodes;
    gnd=g.Nodes.Name;
    Lwdth=2*ones(size(g.Edges.Weight));
    for nd=1:length(gnd)
        Lwdth((strcmp(gend(:,1),gnd{nd,1})&strcmp(gend(:,2),gnd{nd,1})))=Lwd(nd);
    end
    if ipc>4
       gp=plot(g,'Layout','circle','EdgeColor','b','EdgeAlpha',1,'EdgeLabel','','LineWidth',Lwdth);
       ydst=0.025;
       xdst=.00;
    else
        gp=plot(g,'Layout','force','EdgeColor','b','EdgeAlpha',1,'EdgeLabel','','LineWidth',Lwdth);
        ydst=0.067;
        xdst=0;
    end
    gp.Marker = 's';
    colr1=clrr34p(aun2,:);
    if ipc>3
        fnt=48;
        gp.MarkerSize = 38/2;
    else
        fnt=48;
        gp.MarkerSize = 28/2;
    end
    gp.NodeColor = colr1;%[0.9100 0.4100 0.1700];
    nl = gp.NodeLabel;
    gp.NodeLabel = '';
    xd = get(gp, 'XData');
    yd = get(gp, 'YData');
    %%        
    savefig(strcat(outp,'/',stdy,'-',sb1,'-markovDiag_',epc1,'.fig'))
    img = getframe(gcf);
    imwrite(img.cdata, strcat(outp,'/',stdy,'-',sb1,'-markovDiag_',epc1,'.png'));  
    disp('Save Markov Diag ...')
    pause(5)

    %% Delete
    clearvars -except date_from sb1 stdy encp read_dir matlab_dir out_dir study sbs ipc isg2 isg4 pdydy clrr1 tran_mxpp tab_pdy idz sbz pdysh ipd
end


display('COMPLETE');
exit(0);
