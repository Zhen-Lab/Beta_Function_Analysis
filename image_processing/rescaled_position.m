%load metadata of generated by NIS elements and LabVIEW. The metadata file is generated from Fiji. I
%have had a hard time to get the metadata correctly from matlab.

figure; subplot(2,1,1); plot(istart:iend,smoothts(signal{1}','e',1));
subplot(2,1,2); plot(istart:iend,smoothts(signal{2}','e',1));

button = questdlg('Load nd2 metadata?','','Yes (xls)','No','Yes (xls)');

switch button
    
    case 'Yes (xls)'
        [filename,pathname]  = uigetfile({'*.xls'});
        file_name_nd2 = [pathname filename];
        
        if exist('date_nd2', 'var')
            answer = inputdlg({'start recording date (mm/dd/yyyy HH:MM:SS AM/PM)'}, 'Cancel to clear previous', 1, ...
            {date_recording});
        else
            answer = inputdlg({'start recording date (mm/dd/yyyy HH:MM:SS AM/PM)'}, '', 1);
        end
        
        if isempty(answer)
        
            answer = inputdlg({'start recording date (mm/dd/yyyy HH:MM:SS AM/PM)'}, '', 1);
        
        end
        
        
        date_recording=answer{1};
        date_nd2=datevec(date_recording,'mm/dd/yyyy HH:MM:SS PM');
        t=read_nd2_metadata(file_name_nd2);
        
        
        
        
    case 'No'
        
        if ~exist('t','var')
            disp('no nd2 metadata is loaded. Cannot determine head position');
            position_on_plate=[];
            return;
        end
        
end

%Load the stage data

button = questdlg('Load stage metadata?','','Yes (txt)','No','Yes (txt)');

switch button
    
    case 'Yes (txt)'
        [filename,pathname]  = uigetfile({'*.txt'});
        file_name_stage = [pathname filename];
        [date_stage,metadata_stage]=read_stage_metadata(file_name_stage);
        
    case 'No'
        
        if ~exist('metadata_stage','var')
            disp('no stage metadata is loaded. Cannot determine head position');
            position_on_plate=[];
            return;
        end
end




        



f=[3600 60 1];
%t_stage is the time (in the unit of seconds) recorded by LabVIEW
t_stage=date_stage(4:6)*f'+metadata_stage(:,1);
%t_nd2 is the time (in the unit of seconds) recorded by NIS elements
t_nd2 = date_nd2(4:6)*f'+t;

normalized_ratio=(ratio-min(ratio))/min(ratio);

if ~exist('neuron_position_on_plate','var')


neuron_position_on_plate = convert_position( neuron_position_data,t_nd2,t_stage,metadata_stage,istart,iend);

end

numframes=iend-istart+1;
    

neuron_position_on_plate_smooth=zeros(numframes,2);



neuron_position_on_plate_smooth(:,1)=smooth(neuron_position_on_plate(:,1),10);
neuron_position_on_plate_smooth(:,2)=smooth(neuron_position_on_plate(:,2),10);

neuron_velocity_on_plate=diff(neuron_position_on_plate_smooth,1)*fps;
neuron_velocity_on_plate(:,1)=smooth(neuron_velocity_on_plate(:,1),40);
neuron_velocity_on_plate(:,2)=smooth(neuron_velocity_on_plate(:,2),40);



figure;


subplot(3,1,2); plot((istart+(2:numframes)-1)/fps,smooth(neuron_velocity_on_plate(:,1),1));
hold on; plot(get(gca,'Xlim'),[0 0],'color',[0.5 0.5 0.5]);
xlabel('Time (s)'); ylabel('neuron x velocity (\mum /s)');
subplot(3,1,3); plot((istart+(2:numframes)-1)/fps,smooth(neuron_velocity_on_plate(:,2),1));
hold on; plot(get(gca,'Xlim'),[0 0],'color',[0.5 0.5 0.5]);
xlabel('Time (s)'); ylabel('neuron y velocity (\mum / s)');


%subplot(3,1,1); plot((istart+(3:numframes)-1),smooth((ratio(3:end)-min(ratio(3:end)))/min(ratio(3:end)),10),'r');  hold on;
subplot(3,1,1); plot((istart:iend)/fps,smoothts(normalized_ratio','e',30),'r');  hold on;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ignore this part

button = questdlg('identify reversal events?','','Yes','No','Yes');


switch button
    
    case 'Yes'
        
        if exist('start_f','var')
            k=length(start_f)+1;
        else
            k=1;
        end
        
        while 1
            
            start_frame=input('Enter starting frame of reversal: ','s');
            end_frame = input('Enter ending frame of reversal: ','s');
            
            if ~isempty(start_frame)
                
                start_f(k) = str2num(start_frame);
                end_f(k) = str2num(end_frame);
                plot([start_f(k) start_f(k)]/fps,get(gca,'Ylim'));
                plot([end_f(k) end_f(k)]/fps,get(gca,'Ylim'));
                k=k+1;
                
            
            else
                
                break;
            end
            
            
                
               
                
        end
        
        
        

       
    case 'No'
        
        if ~exist('start_f','var')
            
            disp('no reversal events have been formally identified');
            
        else
            
            for k=1:length(start_f)
                plot([start_f(k) start_f(k)]/fps,get(gca,'Ylim'));
                plot([end_f(k) end_f(k)]/fps,get(gca,'Ylim'));
            end
        end
                
                
            
        
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


xlabel('Time (s)'); ylabel('\delta R/R');



plot_position_and_signal(normalized_ratio,neuron_position_on_plate);
xlabel('neuron position x coordinate (\mum)'); ylabel('neuron position y coordinate (\mum)');


figure;
subplot(3,1,1); plot((istart+(1:numframes)-1)/fps,normalized_ratio,'r');
xlabel('Time (s)'); ylabel('\delta R/R');

subplot(3,1,2); plot((istart+(1:numframes)-1)/fps,smooth(neuron_position_on_plate(:,1),1));
xlabel('Time (s)'); ylabel('neuron position x coordinate (\mum)');

subplot(3,1,3); plot((istart+(1:numframes)-1)/fps,smooth(neuron_position_on_plate(:,2),1));
xlabel('Time (s)'); ylabel('neuron position y coordinate (\mum)');

figure;

if exist('GC3','var')
    subplot(2,1,1); plot((istart+(1:numframes)-1)/fps,smooth(GC3,30),'g');
end


if exist('RFP','var')
    subplot(2,1,2); plot((istart+(1:numframes)-1)/fps,smooth(RFP,30),'r');
end





















