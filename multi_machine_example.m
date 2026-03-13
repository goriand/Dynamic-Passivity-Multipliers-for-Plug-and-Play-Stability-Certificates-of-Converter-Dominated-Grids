% clear all
% close all

% load data4.mat
w0=2*pi*50;


% gfm_conn_buses=[2 10 19 20 22 23 25 29]';
[Init,pf_results,param,location]=Initilization(gfm_conn_buses);

num_buses=size(pf_results.bus,1);
num_lines=size(pf_results.branch,1);

num_gens=size(pf_results.gen,1);
% gfl_locations=[100];
% gfm_locations=[30:39]';
% gen_locations=[100];
% load_locations=[3;4;7;8;15;16;18;20;21;23;24;25;26;27;28;29;31;39];

gfl_locations=location.GFL;
gfm_locations=location.GFM;
gen_locations=location.Gen;
load_locations=location.Load;

% load_locations=[100];
num_loads=size(load_locations,1);

num_gfls=size(gfl_locations,1);
num_gfms=size(gfm_locations,1);

gfl_conn_buses=[];
gfm_conn_buses=[];
for i=1:num_gens

    [row, col] = find(pf_results.branch == pf_results.gen(i), 1);
    conn_buses = pf_results.branch(row, 3 - col);% Find the bus that connect to the converter
    if ismember (pf_results.gen(i),gfl_locations)

        gfl_conn_buses=[gfl_conn_buses;conn_buses];

    elseif ismember (pf_results.gen(i),gfm_locations)
        gfm_conn_buses=[gfm_conn_buses;conn_buses];
    end
end
% if isempty(gfl_conn_buses)
% gfl_conn_buses=[100];
% end



delta0_GFL=Init.vsc{'delta0','GFL'}{:};
Vod0_GFL=Init.vsc{'Vod0','GFL'}{:};
Voq0_GFL=Init.vsc{'Voq0','GFL'}{:};
IoD0_GFL=Init.vsc{'IoD0','GFL'}{:};
IoQ0_GFL=Init.vsc{'IoQ0','GFL'}{:};
Iod0_GFL=Init.vsc{'Iod0','GFL'}{:};
Ioq0_GFL=Init.vsc{'Ioq0','GFL'}{:};
VbD0_GFL=Init.vsc{'VbD0','GFL'}{:};
VbQ0_GFL=Init.vsc{'VbQ0','GFL'}{:};
VoD0_GFL=Init.vsc{'VoD0','GFL'}{:};
VoQ0_GFL=Init.vsc{'VoQ0','GFL'}{:};

%%-------- 1.  VSC variables (Grid-Forming mode) -------------------------
delta0_GFM = Init.vsc{'delta0','GFM'}{:};
Vod0_GFM   = Init.vsc{'Vod0', 'GFM'}{:};
Voq0_GFM   = Init.vsc{'Voq0', 'GFM'}{:};
IoD0_GFM   = Init.vsc{'IoD0', 'GFM'}{:};
IoQ0_GFM   = Init.vsc{'IoQ0', 'GFM'}{:};
Iod0_GFM   = Init.vsc{'Iod0', 'GFM'}{:};
Ioq0_GFM   = Init.vsc{'Ioq0', 'GFM'}{:};
VbD0_GFM   = Init.vsc{'VbD0', 'GFM'}{:};
VbQ0_GFM   = Init.vsc{'VbQ0', 'GFM'}{:};
VoD0_GFM   = Init.vsc{'VoD0', 'GFM'}{:};
VoQ0_GFM   = Init.vsc{'VoQ0', 'GFM'}{:};

%%-------- 2.  Load variables -------------------------------------------
P_load  = Init.load{'P',  'value'}{:};
Q_load  = Init.load{'Q',  'value'}{:};
iD_load = Init.load{'iD', 'value'}{:};
iQ_load = Init.load{'iQ', 'value'}{:};
G_load = Init.load{'G', 'value'}{:};
B_load = Init.load{'B', 'value'}{:};
%%-------- 3.  Bus variables --------------------------------------------
vD_bus = Init.bus{'vD', 'value'}{:};
vQ_bus = Init.bus{'vQ', 'value'}{:};

omega_s=1;


load_type=[ones(num_loads,1),zeros(num_loads,1),zeros(num_loads,1)];
% load_type(13:14,:)=[zeros(2,1),ones(2,1),zeros(2,1)];

fn = fieldnames(param);    % list of field names
val = struct2cell(param);  % corresponding values

for k = 1:numel(fn)
    assignin('base', fn{k}, val{k});
end
%% Build up continuation-time model
%% Transmission Line Branches
line_el=zeros(num_gens,1);
line_total=[1:1:num_lines];
for i=1:num_gens
[row, col] = find(pf_results().branch == pf_results.gen(i));

line_el(i)=row(1);
end
line_mod=setdiff(line_total,line_el);

num_lines_mod=0;
branches=[];
tap=zeros(num_buses,1);
for n=1:1:num_lines
    from_bus=pf_results.branch(n,1);
    to_bus=pf_results.branch(n,2);
    if pf_results.branch(n,9)~=0
        tap(from_bus)=pf_results.branch(n,9);
    end
    parameters=[omega_s,pf_results.branch(n,3),pf_results.branch(n,4),pf_results.branch(n,9)]; % ws, R, X, tap ratio
    if ismember(n,line_mod)==1
        branch=generate_RL_TL_SSM(parameters,from_bus,to_bus);
    
   num_lines_mod=num_lines_mod+1;
    if num_lines_mod==1 
        branches=branch;

    elseif num_lines_mod>1
        branches=connect(branches,branch,unique([branches.InputName;branch.InputName]),...
            unique([branches.OutputName;branch.OutputName]));
    end
    end
end


%% Bus Capacitances (modelled at buses)
num_buses_mod=0;
caps=[];
for n=1:1:num_buses
    SM_num=find(n==(gen_locations));
    GFL_num=find(n==(gfl_conn_buses));
    GFM_num=find(n==(gfm_conn_buses));
    load_num=find(n==(load_locations));


    line_leave_num=find(n==(pf_results.branch(:,1)));
    line_inject_num=find(n==(pf_results.branch(:,2)));

    % for j=1:size(line_leave_num,1)
    % if ismember(line_leave_num(j), line_mod)==0
    %     line_leave_num(j)=[];
    % end
    % end
    % 
    % for j=1:size(line_inject_num,1)
    % if ismember (line_inject_num(j),line_mod)==0
    % line_inject_num(j)=[];
    % end
    % end


        parameters=[omega_s,Bc(n)];
        if pf_results.bus(n,2)==1
        cap=generate_shunt_C_SSM(parameters,pf_results.bus(n),gen_locations(SM_num),gfl_conn_buses(GFL_num),gfm_conn_buses(GFM_num),load_locations(load_num),...
                                       pf_results.branch(line_leave_num,:),pf_results.branch(line_inject_num,:)); % Will this work for branches with 0 capacitance?

        num_buses_mod=num_buses_mod+1;
        if num_buses_mod==1
            caps=cap;
        elseif num_buses_mod>1
            caps=connect(caps,cap,unique([caps.InputName;cap.InputName]),...
            unique([caps.OutputName;cap.OutputName]));
        end
        end


end
%% Load
for n=1:1:num_loads
    if pf_results.bus(load_locations(n),2)==1
        % if Q_load(n)>=0
        %     parameters=[omega_s,P_load(n),Q_load(n)];
        %     initial_states=[R_load(n),L_load(n),vD_bus(load_locations(n)),vQ_bus(load_locations(n)),iD_load(n),iQ_load(n)];
        %     load=generate_dynamic_constant_Z_load_SSM(parameters,initial_states,load_locations(n));
        % else
            parameters=[omega_s,P_load(n),Q_load(n),load_type(n,:)];
            initial_states=[G_load(n),B_load(n),vD_bus(load_locations(n)),vQ_bus(load_locations(n))];
            load=generate_dynamic_constant_Z_load_algebraic(parameters,initial_states,load_locations(n));

        % end
        if n==1
            loads=load;
        else
            loads=connect(loads,load,unique([loads.InputName;load.InputName]),...
                unique([loads.OutputName;load.OutputName]));
        end
    end
end


%% GFL
GFL_flag=0;
GFLs=[];

% SMs
% manual_setup_SMs; % This allows for comparison to determine if the connection method works.
for n=1:1:num_gfls
    L=gfl_locations(n);

 
if ismember(L,load_locations(:))
    parameters=[Tm,Kp_P(n),Ki_P(n),Kp_V(n),Ki_V(n),Tp,Kp_PLL(n),Ki_PLL(n),Tc,w0,Bc(L),...
        G_load(find(L==load_locations)),B_load(find(L==load_locations))];
else
        parameters=[Tm,Kp_P(n),Ki_P(n),Kp_V(n),Ki_V(n),Tp,Kp_PLL(n),Ki_PLL(n),Tc,w0,Bc(L),...
        0,0];
end
        init_states=[delta0_GFL(n),Vod0_GFL(n),Voq0_GFL(n),IoD0_GFL(n),IoQ0_GFL(n),Iod0_GFL(n),Ioq0_GFL(n),...
            VbD0_GFL(n),VbQ0_GFL(n),VoD0_GFL(n),VoQ0_GFL(n)];
        GFL=generate_GFL_admittance(init_states,parameters,L,pf_results);
        if GFL_flag==0
            GFLs=GFL;
            GFL_flag=1;
        else

            InputName=[GFLs.InputName;GFL.InputName];
            InputName(strcmp(InputName,"w_com"))=[];
            OutputName=[GFLs.OutputName;GFL.OutputName];
            GFLs=connect(GFLs,GFL,[InputName;"w_com"],...
                OutputName);
    %            end
        end
        if n==2
           GFL2=GFL; 
        end
 
end 

%% GFM
GFM_flag=0;
GFMs=[];

% SMs
% manual_setup_SMs; % This allows for comparison to determine if the connection method works.
for n=1:1:num_gfms
    L=gfm_locations(n);
 
 
if ismember(L,load_locations(:))
    % parameters=[Dp(n),Tm,Kpd_GFM(n),Kid_GFM(n),Tc,w0,Bc(L),...
    %     G_load(find(L==load_locations)),B_load(find(L==load_locations))];
    parameters=[Dp(n),Dq(n),Tm,Kpd_GFM(n),Kid_GFM(n),Tc,w0,Bc(L),...
        G_load(find(L==load_locations)),B_load(find(L==load_locations))];
else
        % parameters=[Dp(n),Tm,Kpd_GFM(n),Kid_GFM(n),Tc,w0,Bc(L),...
        % 0,0];
        parameters=[Dp(n),Dq(n),Tm,Kpd_GFM(n),Kid_GFM(n),Tc,w0,Bc(L),...
        0,0];
end
        init_states=[delta0_GFM(n),Vod0_GFM(n),Voq0_GFM(n),IoD0_GFM(n),IoQ0_GFM(n),Iod0_GFM(n),Ioq0_GFM(n),...
            VbD0_GFM(n),VbQ0_GFM(n),VoD0_GFM(n),VoQ0_GFM(n)];
        GFM=generate_GFM_wPQ_admittance(init_states,parameters,L,pf_results);
        if GFM_flag==0
            GFMs=GFM;
            GFM_flag=1;
        else

            InputName=[GFMs.InputName;GFM.InputName];
            InputName(strcmp(InputName,"w_com"))=[];
            OutputName=[GFMs.OutputName;GFM.OutputName];
            GFMs=connect(GFMs,GFM,[InputName;"w_com"],...
                OutputName);
    %            end
        end
        if n==2
           GFM2=GFM; 
        end
 
end 

%% Grid Frequency
Agrid=[0];
Bgrid=[0];
Cgrid=[0];
Dgrid=[1];

ref_mac=0;

if ref_mac==0 && isempty(gfm_conn_buses)==0
    ref_mac=gfm_conn_buses(1);

end



wgrid_input=sprintf("w_gfm_%i",ref_mac);
% wgrid_input=sprintf("wr_%i",1);
wgrid=ss(Agrid,Bgrid,Cgrid,Dgrid,'InputName',wgrid_input,'OutputName',["w_com"]);
% Ensure this is set to the speed of the same machine that is taken as the
% reference when calculating initial states.
%% Completed State-Space Model

Inputs=string.empty;
Outputs=string.empty;
% for i=1:1:num_gens
%     L=pf_results.gen(i,1);
% if ismember(L,gfl_locations)
%             Inputs(i)=strcat("Pref_gfl_",num2str(L));
%             Inputs(i+num_gens)=strcat("Vref_gfl_",num2str(L));
% 
%             Outputs(i)=strcat("P_gfl_",num2str(L));
%             Outputs(i+1*num_gens)=strcat("V_gfl_",num2str(L));
% 
% elseif ismember(L,gfm_locations)
%             Inputs(i)=strcat("Pref_gfm_",num2str(L));
%             Inputs(i+num_gens)=strcat("Vref_gfm_",num2str(L));
%             Outputs(i)=strcat("P_gfm_",num2str(L));
%             Outputs(i+1*num_gens)=strcat("V_gfm_",num2str(L));
% end
% end



Inputs_gfl = [ ...
    compose("Pref_gfl_%g", gfl_conn_buses) ;   % n×1
    % compose("Vref_gfl_%g", gfl_conn_buses) 
    ];  % n×1  →  2n×1
Outputs_gfl = [ ...
    compose("P_gfl_%g", gfl_conn_buses) ;   % n×1
    % compose("V_gfl_%g", gfl_conn_buses) 
    ];  % n×1  →  2n×1


Inputs_gfm = [ ...
    compose("Pref_gfm_%g", gfm_conn_buses) ;   % n×1
    % compose("Vref_gfm_%g", gfm_conn_buses) 
    ];
Outputs_gfm = [ ...
    compose("P_gfm_%g", gfm_conn_buses) ;   % n×1
    % compose("V_gfm_%g", gfm_conn_buses) 
    ];  % n×1  →  2n×1

Inputs=[Inputs_gfl;Inputs_gfm];
Outputs=[Outputs_gfl;Outputs_gfm];

%%Check any component is null
if isempty(GFLs)
    GFLs = tf(0);
    GFLs.InputName = {'GFL_input'};
    GFLs.OutputName = {'GFL_output'};
end

if isempty(GFMs)
    GFMs = tf(0);
    GFMs.InputName = {'GFM_input'};
    GFMs.OutputName = {'GFM_output'};
end

if isempty(branches)
    branches = tf(0);
    branches.InputName = {'branch_input'};
    branches.OutputName = {'branch_output'};
end

if isempty(caps)
    caps = tf(0);
    caps.InputName = {'cap_input'};
    caps.OutputName = {'cap_output'};
end

if isempty(wgrid)
    wgrid = tf(0);
    wgrid.InputName = {'wgrid_input'};
    wgrid.OutputName = {'wgrid_output'};
end

% Now connect the system
System_total = connect(branches, caps, GFMs, GFLs, loads, Inputs, Outputs);

% Outputs(strcmp(Outputs,"V_gfm_2"))=[];
% System_total2=connect(branches,caps,loads,GFMs,GFLs,wgrid,...
%         Inputs,Outputs);
mode_system=eig(System_total);

% System_total3=rem_zero_eigvals(System_total,1);
%%




