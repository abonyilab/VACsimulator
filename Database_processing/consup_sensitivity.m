function [consup, seq_nums_sup, seq_nums_conf] = consup_sensitivity(consup)
consup
global Simple_alarm
window = 20;
minsupp = consup;
minconf = 0.2;
Sequence_database = multiTemporal_newstruct(Simple_alarm,window,minsupp,minconf);

ps = 0;

for i = 1:size(Sequence_database,2)-1
    ps = ps+size(Sequence_database{1,i}.p,1);
end
seq_nums_sup = ps;

window = 20;
minsupp = 0.2;
minconf = consup;
Sequence_database = multiTemporal_newstruct(Simple_alarm,window,minsupp,minconf);

ps = 0;

for i = 1:size(Sequence_database,2)-1
    ps = ps+size(Sequence_database{1,i}.p,1);
end
seq_nums_conf = ps;