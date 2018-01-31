% Extended simulator for failure analysis and general alarm management purposes
% of Vinyl Acetate (VAc) production technology simulator
% created by Rong Chen and Kedar David in 2004 [T. J. M. Rong Chen,
% Kedar Dave, “A nonlinear dynamic model of a vinyl acetate process,
% ” Ind. Eng. Chem. Res., vol. 42, no. 20, pp. 4478–4487, 2003.]

% The results are saved to the Database structure grouped by 
% failure types and number of runs: EEM: [event_start event_end event_ID]
% OSM: [state_start_time state_end_time Temp H2OComp Vap_flowrate C2H6_Comp]
% y_history: controlled variables in columns
% u_history: manipulated variables in columns
% spfn: set points in columns
% NOTE: the line for plotting is commented in order to neglect plotting
% during the generation of large databases
clear all
close all
clc

%% Initiate VAcPlant call, parameters
load('fail_time') % Lognormal time distribution of fail times

% These are all the implemented faults and the related parameters
% Fault_type = [3 6 8 11 12 14 16 17 18 19 23 24]; % Tag of variable with failure
% Fault_value = [0.3 2000 0 20000 0 5e3 1000 4 0 0.4 0 0]; % Value of variable during fail
% Two sample faults and the related parameters
Fault_type = [3 6];
Fault_value = [0.3 2000];

for fault = 1:size(Fault_type,2)
    for run_p_fault = 1:3
        OScount = 1; % # of operating states generated (>1)
        EEcount = 1; % # of errors injected
        
        OSt_min = 200; % Operating State minimal duration in minutes
        OSt_max = 200; % Operating State maximal duration in minutes
        
        %% Set Operating State Matrix
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   Structure of matrix is as follows:
        %	[state_start_time state_end_time Temp H2OComp Vap_flowrate C2H6_Comp]
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   Temperature range: 150 - 165
        %   H2O composition range: 9 - 18
        %   Vaporizer flowrate range: 2.2 - 2.64
        %   C2H6 composition is NOT range based
        %       set it to 1 to enable the modified value
        %       set it to 0 to disable it
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   Each operating state can last from OSt_min hours up to OSt_max hours long (set it
        %       in minutes!)
        %   The resulting log starts from the simulation's 10th minute
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        OSM = [10 10+OSt_min+round(rand*(OSt_max-OSt_min)) 150+rand*15 (9+rand*9)/100 2.2+rand*0.44 round(rand)];
        for i=2:OScount
            OSM = [OSM; OSM(end,2) OSM(end,2)+OSt_min+round(rand*(OSt_max-OSt_min)) 150+rand*15 (9+rand*9)/100 2.2+rand*0.44 round(rand)];
        end
        
        
        %% Set Error Event Matrix
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   The set of possible errors:
        %   (1) - HAc Feed lost
        %   (2) - O2 Feed lost
        %   (3) - Column Feed lost
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   Each error event lasts 5 minutes
        %   Errors are injected randomly between the 10 to <simulation end>-100
        %       period (in minutes)
        %   Structure: [event_start event_end event_ID]
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        EEM = [50 50+fail_time((fault-1)*200+run_p_fault) Fault_type(fault) Fault_value(fault)]
        
        
        %% Call the test_VAcPlant routine
        OSM
        EEM
        minute=OSM(end,2)
        test_VAcPlant_comment
        
        %%  Plot and save the results
        Database{fault}{run_p_fault}.EEM = EEM;
        Database{fault}{run_p_fault}.OSM = OSM;
        Database{fault}{run_p_fault}.y_history = y_history;
        Database{fault}{run_p_fault}.u_history = u_history;
        Database{fault}{run_p_fault}.spfn = setpoint;
 
%         %plot graphics
%         my_label=['   %O2  ';'  Pres  ';'  HAc-L ';'  Vap-L ';'  Vap-P ';'  Pre-T ';'  RCT-T ';'  Sep-L ';'  Sep-T ';'  Sep-V ';'  Com-T ';'  Abs-L ';'  Cir-F ';'  Cir-T ';'  Scr-F ';'  Scr-T ';'  %CO2  ';'  %C2H6 ';' FEHE-T ';'  %H2O  ';'  Col-T ';' Dect-T ';'  Org-L ';'  Aqu-L ';'  Col-L ';' Vap-In ';'%VAc E-3'];
%         MV_label=[' F-O2 ';'F-C2H4';' F-HAc';' Q-Vap';' F-Vap';'Q-Heat';'ShellT';'F-SepL';' T-Sep';'F-SepV';'Q-Comp';'F-AbsL';'F-Circ';'Q-Circ';'F-Scru';'Q-Scru';' F-CO2';' Purge';'bypass';'Reflux';'Q-Rebo';'F-Orga';'F-Aque';' F-Bot';'Q_Cond';'F-Tank'];
%         warning off
%         
%         Transient_Plot(y_history,u_history,setpoint,my_label,MV_label,storage_sampling_frequency);
    end
end
delete('database.m')
save database Database

