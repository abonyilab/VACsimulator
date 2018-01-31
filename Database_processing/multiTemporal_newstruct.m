function Sequence_database = multiTemporal_newstruct(DT,window,minsupp,minconf)

%--------------------------------------------------------------------------
%multiTemporal(inputfilename,alpha,window,outputfilename) is the MATLAB
%implementation of the multi-temporal mining algorithm proposed by Xiaoxiao
%Kong, Qiang Wei and Guoqing Chen, which is able to mine frequent patterns
%for a temporal database.
%--------------------------------------------------------------------------
%Parameters:
%   inputfilename: the temporal database, in .xls format
%   alpha: relative support threshold, calculated by diving the support of
%       an pattern with the highest support of the degenerated patterns
%       (denoted by Emax), (0 < alpha <= 1)
%   beta: min. confidence
%   window: the lag constrain (window >= 0)
%   outputfilename: the .xls file the output is written into
%--------------------------------------------------------------------------
%
% The temporal database consists of 4 columns:
%
% - Serial number of the event during which a state occurs
% - State id
% - Start time
% - End time
%
% The temporal database is sorted by start time in an ascending order.
%

%--------------------------------------------------------------------------
% DT = actuator_database_szar;
% window = 0.5;
% minsupp = 0.2;
% minconf = 0.2;
% multiTemporal_newstruct(DT,window,minsupp,minconf)

outputfilename = 'out.xlsx';
alpha=minsupp;  %min support
% window=window;    %window
beta = minconf;  % min. conf

%% Reading the input database
DT=sortrows(DT,2);
S=unique(DT(:,1));  %Unique states in the input database
ns=size(S,1);       %Number of the unique states
Emax=max(histc(DT(:,1),S));
N=size(DT,1);
%% Degenerated pattern creation
F{1}=[];
nins=0;
for i=1:ns
    index=find(DT(:,1)==S(i));
    sup=length(index)/Emax;
    if sup>alpha
        nins=nins+1;
        F{1}.p(nins,1)=S(i) ; %IDs for the patterns
        F{1}.ES{nins}=DT(index,[2 3]);
        F{1}.sup(nins,1)=sup;
        F{1}.conf(nins,1)=1;
        F{1}.source(nins,1)=0; %what what the source
        F{1}.TID{nins}=index;
    end
end
nd=size(F{1}.p,1);

%% Generating the FREQUENT degenerated pattern (pruning the infrequent ones)
%adott elemhez meg kell nezni
k=1

while ~isempty(F{k})
    k=k+1
    F{k}=[];
    nins=0;
    
    for i=1:size(F{k-1}.p,1)    %we extend the i-th k-1 length sequence by the j-th deg.
        tspan=F{k-1}.ES{i};     %WHEN APPEARED?
        for j=1:nd              %What can we add ??
            tspanAD=F{1}.ES{j}; %WHEN appeared that we would like to add
            %keressuk, hogy az adott esemeny mar elofordult-e a szekvenciaban, ui. ezt ki kell vennunk.
            ei=find(F{k-1}.p(i,1:2:end)==F{1}.p(j)); %Az azonos esemeny sorszama(i) a szekvenciaban
            for rel=1:4; R{rel}=[]; ES_all{rel}=[]; TID_all{rel}=[]; end;
            stAD=tspanAD(:,1); etAD=tspanAD(:,2);
            for l=1:size(tspan,1), %l-th occurence of the -ith seq. ... (ezt a szekv. bovitjuk)
                st=min(tspan(l,:)); et=max(tspan(l,:));
                TID=[];
                if ~isempty(ei)
                    TID=unique(F{k-1}.TID{i}(l,ei));  %melyik tranzakciok vannak az �pp keresett l-ik esem�nysorban
                end
                [TIDr,inrem]=setdiff(F{1}.TID{j},TID); %kiveszem a mar bal oldalon es a korabban berakott esemenyekeet
                stADf=stAD(inrem); etADf=etAD(inrem);
                
                r{1}=find(and(st==stADf,et==etADf)); %E
                r{2}=find(and(stADf>et,(stADf-window)<et)); %B
                r{3}=[find(and((stADf<st), etADf>et))];%D %teles megaban foglalas, egyebkent O, "=' ezert torolve
                r{4}=[find(and(stADf>=st,and(stADf<=et,etADf>=et)))]; %O,
                %r{4}=[find((stADf>=st).*(stADf<=et).*(etADf>=et)==1)]; %O
                r{4}=setdiff(r{4},r{1});
                
                for rel=1:4;
                    if ~isempty(r{rel})
                        R{rel}=[R{rel}; r{rel}(1)];
                        ES_all{rel}=[ES_all{rel}; [tspan(l,:) stADf(r{rel}(1)) etADf(r{rel}(1))]];
                        TID_all{rel}=[TID_all{rel}; [F{k-1}.TID{i}(l,:) TIDr(r{rel}(1))]];
                    end
                end;
                
            end
            
            for rel=1:4
                
                [R{rel},ui]=unique(R{rel}); %%% Ugyanazt a tranzakciot ne tegyuk hozza tobbszor
                
                sup=length(R{rel})/Emax;
                if sup>=alpha
                    if rel~=3
                        conf=sup/F{k-1}.sup(i,end)*F{k-1}.conf(i,end);
                    else
                        conf=sup/F{1}.sup(j,end);
                    end
                    if conf>1
                        keyboard
                    end
                    
                    if conf >= beta
                        nins=nins+1;
                        F{k}.p(nins,:)=[F{k-1}.p(i,:) -rel F{1}.p(j,1)];
                        F{k}.ES{nins}=ES_all{rel}(ui,:);
                        F{k}.sup(nins,:)=[F{k-1}.sup(i,:) sup];
                        F{k}.conf(nins,:)=[F{k-1}.conf(i,:) conf] ;
                        F{k}.source(nins,:)=[F{k-1}.source(i,:) i] ;
                        F{k}.TID{nins}=TID_all{rel}(ui,:);
                    end
                end
            end
            
        end
        
    end
end




% Writing the output file - decoding the relations
z = 1;
for i = 1:size(F,2)-1
    for j = 1:size(F{1,i}.p,1)
        %         keyboard
        actpattern = F{1,i}.p(j,:);
        actpattern(2:2:size(actpattern,2)) = abs(actpattern(2:2:size(actpattern,2)));

        relations = actpattern(2:2:size(actpattern,2));  %Decoding the relations
        actpattern_str=mat2str(actpattern);
        relation_coords = find(mat2str(actpattern_str)==' ');
        relation_coords=relation_coords(1:2:size(relation_coords,2));
        relation_number=size(relation_coords,2);
        
        for k=1:relation_number
            switch relations(1,k)
                case 1
                    actpattern_str(relation_coords(1,k)) = 'E';
                case 2
                    actpattern_str(relation_coords(1,k)) = 'B';
                case 3
                    actpattern_str(relation_coords(1,k)) = 'D';
                case 4
                    actpattern_str(relation_coords(1,k)) = 'O';
            end
        end
        
        output{z,1}=actpattern_str;
        output{z,2}=F{1,i}.sup(j,end);
        output{z,3}=F{1,i}.conf(j,end);
        for k=1:size(F{1,i}.ES{1,j},1)
            output{z,3+k}=mat2str([min(F{1,i}.ES{1,j}(k,:)) max(F{1,i}.ES{1,j}(k,:))]);
        end
        z = z+1;
    end
    
    
end
% delete(outputfilename)
% xlswrite(outputfilename,output)
Sequence_database = F;
% save Sequence_database Sequence_database;
