function parse_gps_mc(read_dir, out_dir, extension, matlab_dir)
display('START');
encp=1;

% Get passcode
if encp==1
    % Check extension
    if (strcmp(extension,'csv.lock') == 1 || strcmp(extension,'csv') == 1)
        extension = strcat('.',extension);
    end
    pss = getenv('BEIWE_STUDY_PASSCODE');
    if (strcmp(extension,'.csv.lock') == 1 && isempty(pss) == 1)
        disp('Please set the BEIWE_STUDY_PASSCODE environment variable.');
        disp('Cannot unlock files without the passphrase.Exiting.');
        exit(1);
    end
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

% Check if the path exists
if exist(read_dir,'dir')~=7
    disp(strcat('Input directory ', read_dir, ' does not exist. Exiting.'));
    exit(1);
end

if exist(out_dir,'dir')~=7
    disp(strcat('Output directory ', out_dir, ' does not exist. Exiting.'));
    exit(1);
end

% Initialization
t1=[]; u1=[]; lat1=[]; lon1=[]; alt1=[]; acc1=[];  tjdmx=0;
file_regex = strcat('*', extension);
% Check output directory
output_filepath_mat = strcat(out_dir, 'gps_dash2/file_gps.mat.lock');
if (exist(output_filepath_mat, 'file') == 2)
    disp('Previous file exists.');
    if encp==1
        tmpN = tempname('/tmp');
        temp_unlocked_m=strcat(tmpN,'.mat');
        cmd = sprintf('python %sparse_gps_decrypter.py --input "%s" --output "%s"', matlab_dir, output_filepath_mat, temp_unlocked_m);
        disp(cmd);
        system(cmd);
        load(temp_unlocked_m)
        if (exist(temp_unlocked_m)==2)
            delete(temp_unlocked_m);
        else
            disp(strcat(temp_unlocked_m, ' does not exist!'));
        end
    end
    tjmx=max(t1);
    tjdmx=1000*3600*floor(tjmx/1000/3600);
    tmdmx=datevec(tjdmx/1000/3600/24+datenum('1970-01-01'));
    [length(t1) length(lat1) length(lon1) length(alt1) length(acc1)];
    t1=t1(t1<tjdmx);
    u1=u1(t1<tjdmx);
    lat1=lat1(t1<tjdmx);
    lon1=lon1(t1<tjdmx);
    alt1=alt1(t1<tjdmx);
    acc1=acc1(t1<tjdmx);
end

% Loop through all beiwe IDs
disp('Parameters checked. Parsing GPS files.');
beiwe_ids=dir(read_dir);
for beiwe_idx=1:length(beiwe_ids)
    beiwe_id = beiwe_ids(beiwe_idx,1).name;

    if startsWith(beiwe_id, '.') == 1
        continue;
    end

    beiwe_path = strcat(read_dir,beiwe_id,'/gps/');

    beiwe_files = dir(strcat(beiwe_path, file_regex));
    %% Available Files
    d4=extractfield(beiwe_files,'name');
    d5=split(d4,'.'); d61=d5(:,:,1);
    d62=split(d61,' '); d7=d62(:,:,1);  d8=d62(:,:,2);
    d71=split(d7,'-'); dyr=d71(:,:,1); dmt=d71(:,:,2); ddy=d71(:,:,3);
    d81=split(d8,'_'); dhr=d81(:,:,1); dmn=d81(:,:,2); dsc=d81(:,:,3);

    d7=(datenum(d61,'yyyy-mm-dd HH_MM_SS')- datenum('1970-01-01'))*1000*3600*24;
    beiwe_files=beiwe_files(d7>=(tjdmx-10000));

    files_len = length(beiwe_files);

    if files_len == 0
        display('Files do not exist under this directory.');
        continue;
    end

    for f=1:files_len
        file_path = strcat(beiwe_path,beiwe_files(f,1).name);

        % Handle locked and unlocked files
        if strcmp(extension,'.csv') == 1
            temp_parsed=file_path;
        elseif strcmp(extension,'.csv.lock') == 1
            tmpN = tempname('/tmp');
            temp_unlocked=strcat(tmpN,'.csv');
            cmd = sprintf('python %sparse_gps_decrypter.py --input "%s" --output "%s"', matlab_dir, file_path, temp_unlocked);
            disp(cmd);
            system(cmd);
            if (exist(temp_unlocked)==2)
                temp_parsed=temp_unlocked;
            else
                disp('File unlock unsuccessful. Moving onto the next file');
                continue;
            end
        else
            disp('Unsupported file extension');
            continue;
        end

        % Aggregate GPS data
        [t,u,lat,lon,alt,acc] = read_gps(temp_parsed);
        t1=[t1;t]; u1=[u1;u]; lat1=[lat1;lat]; lon1=[lon1;lon];
        alt1=[alt1;alt]; acc1=[acc1;acc];
        % Delete the temp file if it exists
        if (exist(temp_unlocked)==2)
            delete(temp_unlocked);
        else
            disp(strcat(temp_unlocked, ' does not exist!'));
        end
    end
end



% Save data as mat file
disp(strcat('Saving file file_gps.mat.lock'));
if exist(strcat(out_dir,'gps_dash2'),'dir')~=7
    mkdir(strcat(out_dir,'gps_dash2'));
end
if encp==1
    tmpN = tempname('/tmp');
    input_mat_file = strcat(tmpN,'.mat');
    save(input_mat_file,'t1','u1','lat1','lon1','alt1','acc1','-v7.3');
    % Encrypt file
    disp(strcat('Encrypting file ', output_filepath_mat));
    cmd = sprintf('python %sparse_gps_encrypter.py --input "%s" --output "%s"', matlab_dir, input_mat_file, output_filepath_mat);
    system(cmd);
    delete(input_mat_file);
else
    save(output_filepath_mat,'lat1','lon1','alt1','acc1','t1','-v7.3')
end

display('COMPLETE');
exit(0);
