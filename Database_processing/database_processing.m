clear all
close all
clc

global Simple_alarm
load Simple_alarm

window = 20;
minsupp = 0.1;
minconf = 0.2;
Sequence_database = multiTemporal_newstruct(Simple_alarm,window,minsupp,minconf);

%% Sensitivity analysis for window length
% win_val = [5 10 15 20 25 30];
% win_sen = [];
% for i = 1:length(win_val)
% win_sen = [win_sen window_sensitivity(win_val(i))];
% end
% win_sen = [win_val' win_sen'];
% save win_sen win_sen
% figure(3)
% plot(win_sen(:,1),win_sen(:,2))
% hold on
% plot(win_sen(:,1),win_sen(:,2),'o','MarkerEdgeColor',[0 0.45 0.74])
% xlabel('Window parameter [min]')
% ylabel('Number of sequences [pcs]')
%% Filtering for sequences containing faults at the beginning

faults = [10003 10006 10008 10011 10012 10014 10016 10018 10019 10023 10024];

for h = 1:size(faults,2)
    for i = 1:size(Sequence_database,2)-1
        index = find(and(Sequence_database{1,i}.p(:,1)==faults(h),sum(Sequence_database{1,i}.p==faults(h),2)==1));
        if ~isempty(index)
            Ff{h}{i}.p = Sequence_database{i}.p(index,:);
            Ff{h}{i}.ES = Sequence_database{i}.ES(1,index);
            Ff{h}{i}.sup = Sequence_database{i}.sup(index,:);
            Ff{h}{i}.conf = Sequence_database{i}.conf(index,:);
            Ff{h}{i}.source = Sequence_database{i}.source(index,:);
            Ff{h}{i}.TID = Sequence_database{i}.TID(1,index);
        end
    end
end

save Fault_begin_seq Ff

%% Basestat of the sequence
load Fault_begin_seq
T = Ff;

% Extracting of important stats
ext=[];
temp = [];
for k=1:size(T,2)
    ntk = size(T{k},2);
    seq_count = 0;
    for j = 2:ntk
        for i = 1:size(T{k}{j}.p,1)
            ext = [ext; [k 1 j-1 i T{k}{j}.conf(i,end) T{k}{j}.sup(i,end) T{k}{j}.p(i,3)]];
        end
        seq_count = seq_count+size(T{k}{j}.p,1);
    end
    temp = [temp; ones(seq_count,1)*seq_count];
end
ext(:,2) = temp;

% ext = Fault ID, Number of Sequences, Length of Sequence, No. of Sequence,
% confidence, support, ID of the first alarm after fault


% Effect of the fault - Statistics
bstat=[];
for i=1:max(ext(:,1))
    dum=ext(find(ext(:,1)==i),:);
    if ~isempty(dum)
        ntk=max(dum(:,2)); %number of related sequences
        ml=max(dum(:,3));  %max. length - alarm cascade ...
        [mc,imc]=max(dum(:,5)); % mc: max confidence imc: No. of seq. with max conf.
        mcs=dum(imc,6); % support of seq. with max conf.
        mcv=dum(imc,7); % Following event after failure
        mcl=dum(imc,3); % lenght of seq.
        mci=dum(imc,4); % No. of seq.
        bstat=[bstat; [i ntk ml mc mcs mcv mcl mci]];
    end
end
%bstat Fault ID, Number of Sequences, max length, max confidence,
% support of seq. with max conf., ID of the first alarm after fault, lenght
% of seq., No. of seq.
figure(1)
clf
plot(bstat(1:2,2), bstat(1:2,3),'b.','MarkerSize',10)
hold on 
plot(bstat(4:end,2), bstat(4:end,3),'b.','MarkerSize',10)
xlim([0 10.1])
ylim([0 4])
text(bstat(8,2)+0.1, bstat(8,3)+0.1,'Faults 10, 11')
text(bstat(7,2)+0.1, bstat(7,3)+0.1,'Faults 2, 6, 7')
text(bstat(5,2)+0.1, bstat(5,3)+0.1,'Fault 5')
text(bstat(1,2)+0.1, bstat(1,3)+0.1,'Fault 1')
text(bstat(4,2)+0.1, bstat(4,3)+0.1,'Fault 4')
yticks([1 2 3])
xlabel('Number of sequences')
ylabel('Max. length of sequences')

%% Time analysis of sequences
probe = [4 2 3; 2 2 1; 6 3 1; 7 3 1; 4 4 1; 3 9 1;]
for i = 1:size(probe,1)
    figure(2)
    subplot(3,2,i)
    h=probe(i,1) % Which fault
    j=probe(i,2) % sequence length - shorter than the given number by 2 (fault at the beginning, and k = 0 length is for 1 element)
    k =probe(i,3) % which sequence with this length
    dum=[min(T{h}{j}.ES{k}(:,3:end),[],2) max(T{h}{j}.ES{k}(:,3:end),[],2)]; % the time of the sequnce
    dt=diff(dum,1,2);
    hist(dt)
title(num2str(['Fault ' num2str(h) ', ' 'Length = ' num2str(j-2)]))
    xlabel('Time [min]')
    ylabel('Number of occurrence')
end

%% Similarity of faults
for h=1:size(T,2)
    alarm = [];
    alarm_f = [];
    for j = 2:size(T{h},2)
        for k = 1:size(T{h}{j}.p,1)
            alarm = [alarm; [T{h}{j}.p(k,3:2:end)]'];
            alarm_f = [alarm_f; T{h}{j}.p(k,3)];
        end
    end
    set_event{h} = unique(alarm);
    set_event_f{h} = unique(alarm_f)
end

simstat = [];
for k=1:length(T)-1
    for j=k+1:length(T)
        s=length(intersect(set_event{k},set_event{j}))/length(union(set_event{k},set_event{j})); 
       if s>0
           simstat=[simstat; [k j s]]; % melyik fault, melyik fault-tal, mennyire fednek át
       end    
    end
end
simstat

%% How determined are the first alarms of the sequence?
First_types = [];
for i = 1:length(set_event_f)
    First_types = [First_types; size(set_event_f{1,i},1)];
end
First_types
%% Confidence and support sensitivity
% consup_val = [0.1 0.2 0.4 0.6 0.8];
% 
% consup_sen = [];
% for i = 1:length(consup_val)
% [consup, seq_nums_sup, seq_nums_conf] = consup_sensitivity(consup_val(i));
% consup_sen = [consup_sen; [consup, seq_nums_sup, seq_nums_conf]]
% end 
% save consup_sen consup_sen
% load consup_sen
% figure(4)
% yyaxis left
% p1 = plot(consup_sen(:,1),consup_sen(:,2))
% hold on
% plot(consup_sen(:,1),consup_sen(:,2),'o','MarkerEdgeColor',[0 0.45 0.74])
% xlabel('Support or confidence threshold  value [-]')
% ylabel('Number of sequences for support sens. [pcs]')
% yyaxis right
% p3 = plot(consup_sen(:,1),consup_sen(:,3),'--')
% plot(consup_sen(:,1),consup_sen(:,3),'*','MarkerEdgeColor',[0.85 0.33 0.1])
% xlabel('Support or confidence threshold  value [-]')
% ylabel('Number of sequences for confidence sens. [pcs]')
% legend([p1 p3],'Support sensitivity analysis', 'Confidence sensitivity analysis')
