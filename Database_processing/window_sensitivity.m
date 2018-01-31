function seq_nums = window_sensitivity(win)

global Simple_alarm

minsupp = 0.1;
minconf = 0.2;
Sequence_database = multiTemporal_newstruct(Simple_alarm,win,minsupp,minconf);

ps = 0;

for i = 1:size(Sequence_database,2)-1
    ps = ps+size(Sequence_database{1,i}.p,1);
end
seq_nums = ps;