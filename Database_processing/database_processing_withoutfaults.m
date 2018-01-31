clear all
close all
clc
load Simple_alarm_withoutfaults

window = 20;
minsupp = 0.1;
minconf = 0.2;
Sequence_database = multiTemporal_newstruct(Simple_alarm,window,minsupp,minconf);
save Sequence_database_withoutfaults Sequence_database
%% Counting the confidence of transition: confr 
n = size(Sequence_database,2)-1;
for k = 2:n
    for i = k:(-1):2
        Sequence_database{k}.confr(:,i-1) = Sequence_database{k}.sup(:,i)./Sequence_database{k}.sup(:,i-1);
    end
end

%% Counting the improvement
% for k = 2:n
%     for i = k:(-1):2
%         for j = 1:size(Sequence_database{k}.p,1)
%             index = find(Sequence_database{1}.p == Sequence_database{k}.p(j,2*i-1));
%             F{k}.imp(j,i-1) = F{k}.confr(j,i-1)/F{1}.sup(index);
%         end
%     end
% end
%% Filtering for confr threshold

for i = 2:size(Sequence_database,2)-1
    index = find(Sequence_database{i}.confr(:,end)>0.8);
    Sequence_database_confr{i}.p = Sequence_database{i}.p(index ,:);
    Sequence_database_confr{i}.ES = Sequence_database{i}.ES(1,index);
    Sequence_database_confr{i}.sup = Sequence_database{i}.sup(index,:);
    Sequence_database_confr{i}.conf = Sequence_database{i}.conf(index,:);
    Sequence_database_confr{i}.source = Sequence_database{i}.source(index,:);
    Sequence_database_confr{i}.TID = Sequence_database{i}.TID(1,index);
    Sequence_database_confr{i}.confr = Sequence_database{i}.confr(index,:);
%     Sequence_database_confr{i}.imp = Sequence_database{i}.imp(index,:);
end

%% Collecting unique alarms
alarm = [];
for i = 2:size(Sequence_database_confr,2)
    for k = 1:size(Sequence_database_confr{i}.p,1)
        alarm = [alarm; [Sequence_database_confr{i}.p(k,1:2:end)]'];
    end
end
set_event = unique(alarm);

%% Collecting the rules applicable for the suppression of the given alarm
 k = 1;
 rule_size = [];
for i = 1:size(set_event,1)
    rules = [];
   
    for j = 2:size(Sequence_database_confr,2)
        index = find(Sequence_database_confr{j}.p(:,end) == set_event(i));
        rules = [rules; ones(size(index,1),1)*j index];
    end
    rule_size = [rule_size; rules(:,1)];
    if ~isempty(rules)
        Alarm_rules{k}.alarm = set_event(i);
        Alarm_rules{k}.rules = rules;
        k = k+1;
    end
end


%% Bar graph for rule count per alarm
rs = max(rule_size);
k = 1;
alarm = [];
for i = 1:size(Alarm_rules,2)
    Bar_graph_alarm(k,:) = histc(Alarm_rules{i}.rules(:,1),[2:rs]);
    k = k+1;
    alarm = [alarm Alarm_rules{i}.alarm];
end
figure(1)
bar(Bar_graph_alarm,'stacked')
set(gca,'XTickLabel',{alarm})
% l = cell(1,2);
% l{1}='k = 1'; l{2}='k = 2'; l{3}='k = 3'; l{4}='k = 4'; l{5}='k = 5';
l = [];
for i = 1:size(Bar_graph_alarm,2)
    l = [l; 'length = ' num2str(i+1)];
end
legend(gca,l);
colormap(gray(rs-1))
xlabel('Alarm tag')
ylabel('Number of sequences')
xlim([0 11])
saveas(gcf,'Suppressablealarms.png')

%% Bar graph for event count

for i = 1:size(Alarm_rules,2)
    event_ID = [];
    for j = 1:size(Alarm_rules{i}.rules,1)
        event_ID = [event_ID; Sequence_database_confr{Alarm_rules{i}.rules(j,1)}.TID{Alarm_rules{i}.rules(j,2)}(:,end)];
    end
    Alarm_rules{i}.allalarms = find(Simple_alarm(:,1) == Alarm_rules{i}.alarm);
    Alarm_rules{i}.suppressed = unique(event_ID);
    Alarm_rules{i}.nonsuppressed = setdiff(Alarm_rules{i}.allalarms,Alarm_rules{i}.suppressed);
    Bar_graph_event(i,:) = [size(Alarm_rules{i}.suppressed,1) size(Alarm_rules{i}.nonsuppressed,1)];
end
sum_alarm = sum(Bar_graph_event,2);
supp_percents = Bar_graph_event(:,1)./sum_alarm*100;

figure(2)
bar(Bar_graph_event,'stacked')
set(gca,'XTickLabel',{alarm})
l = cell(1,2);
l{1}='Suppressed'; l{2}='Non suppressed';
% legend(gca,l,'Location','northeast');
legend(gca,l);
colormap('gray')
xlabel('Alarm tag')
ylabel('Number of alarms')
xlim([0 11])
for i = 1:length(supp_percents)
    text(i-0.5,sum_alarm(i)+15,[num2str(supp_percents(i),'%2.2f') '%'])
end

saveas(gcf,'Suppressedratio_2.png')
supp_percent = sum(Bar_graph_event(:,1))/sum(sum(Bar_graph_event))*100;

%% Heatmap of alarm pari frequency
load Sequence_database_withoutfaults

tags = Sequence_database{2}.p(:,[1 3]);
sup = Sequence_database{2}.sup(:,end);

for i = 1:2
    tags(rem(tags(:,i),10)== 5,i) =  tags(rem(tags(:,i),10)== 5,i)-3;
end

xtag = unique(tags(:,1));
ytag = unique(tags(:,2));
heatmat = zeros(size(xtag,1),size(ytag,1));
for i = 1:size(xtag,1)
    for j = 1:size(ytag,1)
        indexsup = find(and(tags(:,1)==xtag(i),tags(:,2)==ytag(j)));
        if ~isempty(indexsup)
            heatmat(i,j) = heatmat(i,j)+sum(sup(indexsup));
        end
    end
end

c = gray;
c = flip(c);
clf
heatmap(heatmat,ytag,xtag,[], 'TickAngle', 45,'ShowAllTicks', true,'Colormap', 'gray',...
        'Colorbar', true,'ColorLevels', 10);
colormap(c)
xlabel('1^{st} alarm')
ylabel('2^{nd} alarm')