%%
% This SSM model includes:
% VSC 13th Order Model
%

% The q-axis is taken to lead the d axis (whih is aligned with a-axis) by 
% 90 degrees


% This machine is per unit
% Balanced assumptions are made.

%%
function [GFM_w_controls_admittance] = generate_GFM_wPQ_admittance(Inti,parameters,No_mach,pf_results)
% if nargin<5
% machine_location=1; % If machine number is not specified, assume first
% end
% if nargin<4
%   gov_turb = 0;  % If governor/turbine is not specified then no governor/turbine 
% end
% if nargin<3
%   PSS = 0;  % If PSS is not specified then no PSS ---------- note, PSS parameters should be the last to be added in the input so that if no PSS is chosen, their absence does not mess up indexing
% end

% if (floor(machine_location)-machine_location)~=0
%     machine_location=999999;
%     error('Machine number not of integer value. \n Machine number cannot be: %f', machine_location)
% end

% load GFM_inft_bus_SCReq5_initvars.mat
% load GFM_gains.mat

[row, col] = find(pf_results().branch == No_mach);
if size(row,1)>1 % If there is more than one line/transfermorer connect to the GFM

tr_bus=row(1);tr_to_bus=col(1);
% Inputs_inner_eline=[];
for i=2:size(row,1)
    from_bus=pf_results.branch(row(i),1);
    to_bus=pf_results.branch(row(i),2);
    eline_inner_base=["id_line_","iq_line_"];
Inputs_inner_eline=[strcat(eline_inner_base,string(from_bus*ones(1,length(eline_inner_base))),"_",string(to_bus*ones(1,length(eline_inner_base))))];
thetaref=0;

    P_flow=pf_results.branch(row(i),12+col(i)*2)/pf_results.baseMVA;
    Q_flow=pf_results.branch(row(i),13+col(i)*2)/pf_results.baseMVA;
    Vm=pf_results.bus(No_mach,8);
    Va=deg2rad(pf_results.bus(No_mach,9));
    V=Vm*exp(1i*Va);
    Iline=(P_flow-1i*Q_flow)/conj(V);
    angleI=angle(Iline);
    magI=abs(Iline);
    IlineD0=magI*cos(angleI-thetaref);
    IlineQ0=magI*sin(angleI-thetaref);
end


else
    tr_bus=row;
    tr_to_bus=col(1);
    Inputs_inner_eline=[];
    IlineD0=0;
    IlineQ0=0;
end
machine_location= pf_results().branch(tr_bus, 3 - tr_to_bus);% Find the bus that connect to the converter


% machine_location=No_mach;
%% Parameters

Dp=parameters(1);
Dq=parameters(2);
Tm=parameters(3);
Kpd_GFM=parameters(4);
Kid_GFM=parameters(5);
Tc=parameters(6);
w0=parameters(7);
Bf=parameters(8);
G_load=parameters(9);
B_load=parameters(10);

nq=Dq;
mp=Dp;% P-f droop
% nq=0;% Q-V droop
wc = 1./Tm;  % cut off frequency

Kpv = Kpd_GFM;  % voltage proportional control gain
Kiv=Kid_GFM;% voltage integral control gain

Kic=1./Tc;% current integral control gain

wn=w0; % Nominal frequency

% Cf=Cb(GFM_bus,1);% LC filter capacitor
Cf=Bf/w0;


w0=w0;
F=1;

%% Initial States



% Inti=Initilization;

delta0 = Inti(1); % Initial angle (rad)
Vod0 = Inti(2); % Initial d-axis voltage
Voq0 = Inti(3); % Initial q-axis voltage
IoD0 = Inti(4); % Initial d-axis current
IoQ0 = Inti(5); % Initial q-axis current
Iod0 = Inti(6); % Transformed d-axis current
Ioq0 =Inti(7); % Transformed q-axis current
VbD0 =Inti(8); 
VbQ0 =Inti(9); 
VoD0 =Inti(10); 
VoQ0 =Inti(11); 


if G_load~=0
    IloadD0=real((VoD0+1j*VoQ0)*(G_load+1j*B_load));
    IloadQ0=imag((VoD0+1j*VoQ0)*(G_load+1j*B_load));
else
    IloadD0=0;
    IloadQ0=0;
end


W0 = w0; % Initial angular frequency


rc=pf_results().branch(tr_bus,3);
Lc=pf_results().branch(tr_bus,4)/w0;
% rnet=case3().branch(2,3);
% Lnet = case3().branch(2,4)/w0;

% rnet=0.015;
% Lnet=0.15/w0;

%% Variable Names
Inputs=["Id_GFM_","Iq_GFM_",...
    "ild_ref_gfm_","ilq_ref_gfm_","vid_ref_gfm_","viq_ref_gfm_","vod_ref_gfm_","voq_ref_gfm_",...
    "vid_gfm_","viq_gfm_","vbd_gfm_","vbq_gfm_", "Pref_gfm_","Qref_gfm_"]; 
machine_num_str_array_outputs=string(machine_location*ones(1,length(Inputs)));
Inputs=strcat(Inputs,machine_num_str_array_outputs);

Outputs=["voD_gfm_","voQ_gfm_","w_gfm_","Vd_","Vq_"];
machine_num_str_array_outputs=string(machine_location*ones(1,length(Outputs)));
Outputs=strcat(Outputs,machine_num_str_array_outputs);

States=["delta_gfm_","P_gfm_", "Q_gfm_","phid_gfm_","phiq_gfm_","gammad_gfm_","gammaq_gfm_",...
    "ild_gfm_","ilq_gfm_","vod_gfm_","voq_gfm_","iod_gfm_","ioq_gfm_"];
machine_num_str_array_states=string(machine_location*ones(1,length(States)));
States=strcat(States,machine_num_str_array_states);

if G_load~=0
    Inputs_load=["Id_load_","Iq_load_"];
    machine_num_str_array_inputs=string(No_mach*ones(1,length(Inputs_load)));
Inputs_load=strcat(Inputs_load,machine_num_str_array_inputs);
else 
    Inputs_load=[];
end
%% Power controller
A = zeros(3,3);
B=zeros(3,9);

% State 1: delat_vsc

A(1,2)=-mp;% d delta_vsc/d P_vsc
B(1,1)=-1;% d delta_vsc/d w_com
B(1,8)=mp;% d delta_vsc / d dP_ref_vsc

% State 2: P_vsc
A(2,2)=-wc;% d P_vsc/d P_vsc

B(2,4)=wc*Iod0;% d P_vsc / d vod_vsc
B(2,5)=wc*Ioq0;% d P_vsc / d voq_vsc (include load current)
B(2,6)=wc*Vod0;% d P_vsc / d iod_vsc
B(2,7)=wc*Voq0;% d P_vsc / d ioq_vsc

B(2,7)=wc*Voq0;% d P_vsc / d dP_ref_vsc

% State 3: Q_vsc
A(3,3)=-wc;% d V_vsc/d V_vsc


B(3,4) = -wc * Ioq0; % d Q_vsc / d vod_vsc
B(3,5) = wc * Iod0; % d Q_vsc / d voq_vsc
B(3,6) = wc * Voq0; % d Q_vsc / d iod_vsc
B(3,7) = -wc * Vod0; % d Q_vsc / d ioq_vsc




C=zeros(6,3);
C(1,1)=1;%d delta/d delta
C(2,2)=1;%d P/d P
C(3,3)=1;%d V/d V


C(4,2)=-mp; %dw_vsc /dP_vsc
% C(2,3)=1e-14; %d vod_ref_vsc /dV_vsc
C(5,3) = -nq;  % d vod_ref_vsc/dQ_vsc


D=zeros(6,9);

D(4,8)=mp; %d w_vsc/ dP_ref_vsc
D(5,9) = nq; % dvod_ref_vsc/dQ_ref_vsc




if isempty(Inputs_load)~=1
% B(2,4)=wc*(Iod0+Id_load0); %P_vsc/ d vod_vsc
% B(2,5)=wc*(Ioq0+Iq_load0); %P_vsc/ d voq_vsc

% B(2,10)=wc*Vod0; % P_vsc/ d id_load
% B(2,11)=wc*Voq0; % P_vsc/ d iq_load

B=[B,[0,0;wc*Vod0,wc*Voq0;0,0]];

D=[D,zeros(6,2)];
end


if isempty(Inputs_inner_eline)~=1
% B(2,4)=wc*(Iod0+Id_load0); %P_vsc/ d vod_vsc
% B(2,5)=wc*(Ioq0+Iq_load0); %P_vsc/ d voq_vsc

% B(2,10)=wc*Vod0; % P_vsc/ d id_load
% B(2,11)=wc*Voq0; % P_vsc/ d iq_load

B=[B,[0,0;wc*Vod0,wc*Voq0;0,0]];

D=[D,zeros(6,2)];
end

Power_c=ss(A,B,C,D,'InputName',["w_com",States(8:13),Inputs(13:14),Inputs_load,Inputs_inner_eline],'OutputName',[States(1:3),Outputs(3),Inputs(7:8)],...
    'StateName',[States(1:3)]);
% inputs: W_COM,Ildq,Vodq,Iodq,P_ref, Q_ref, Idq_load
% outputs: DElta,P,Q,W,Vodq_ref
% states: DElta,P,Q
%% Voltage Controller

A = zeros(2,2);
B=zeros(2,9);

% State 1: phid_vsc


B(1,1)=Kiv;% d phid_vsc/d vod_ref_vsc
B(1,5)=-Kiv;% d phid_vsc/d vod_vsc

% State 2: phiq_vsc

B(2,2)=Kiv;% d phiq_vsc/d voq_ref_vsc
B(2,6)=-Kiv;% d phid_vsc/d voq_vsc





C=zeros(2,2);
D=zeros(2,9);

% Output 1 ild_ref_vsc

C(1,1)=1; %d ild_ref_vsc /d phid_vsc

D(1,1)=Kpv; %  ild_ref_vsc /d vod_ref_vsc
D(1,5)=-Kpv; %  ild_ref_vsc /d vod_vsc
D(1,6)=-wn*Cf; %  ild_ref_vsc /d voq_vsc
D(1,7)=F; %  ild_ref_vsc /d iod_vsc
D(1,9)=-Voq0*Cf;%  ild_ref_vsc /d w_vsc

% Output 2 ilq_ref_vsc

C(2,2)=1; %d ilq_ref_vsc /d phiq_vsc

D(2,2)=Kpv; %  ilq_ref_vsc /d voq_ref_vsc
D(2,5)=wn*Cf; %  ilq_ref_vsc /d vod_vsc
D(2,6)=-Kpv; %  ilq_ref_vsc /d voq_vsc
D(2,8)=F; %  ilq_ref_vsc /d ioq_vsc
D(2,9)=Vod0*Cf;%  ilq_ref_vsc /d w_vsc

if isempty(Inputs_load)~=1
% D(1,10)=F; %ild_ref_vsc/ d id_load
% D(2,11)=F; %ilq_ref_vsc/ d iq_load


D=[D,[F,0;0,F]];
B=[B,zeros(2,2)];
end

if isempty(Inputs_inner_eline)~=1
% D(1,10)=F; %ild_ref_vsc/ d id_load
% D(2,11)=F; %ilq_ref_vsc/ d iq_load


D=[D,[F,0;0,F]];
B=[B,zeros(2,2)];
end



Voltage_c=ss(A,B,C,D,'InputName',[Inputs(7:8),States(8:13),Outputs(3),Inputs_load,Inputs_inner_eline],'OutputName',[Inputs(3:4)],...
    'StateName',[States(4:5)]);
% inputs: Vodq_ref,Ildq,Vodq,Iodq,W,Inputs_load
% outputs: Ildq_ref
% states: Phidq

%% Current Controller

A = zeros(2,2);
B=zeros(2,2);

% State 1: ild_vsc




A(1,1)=-Kic;% d ild_vsc/d ild_vsc
B(1,1)=Kic;% d ild_vsc/d ild_ref_vsc

% State 2: ilq_vsc

A(2,2)=-Kic;% d ilq_vsc/d ilq_vsc
B(2,2)=Kic;% d ilq_vsc/d ilq_ref_vsc





C=eye(2,2);


D=zeros(2,2);








Current_c=ss(A,B,C,D,'InputName',[Inputs(3:4)],'OutputName',[States(8:9)],...
    'StateName',[States(8:9)]);
% inputs: Ildq_ref
% outputs: Ildq
% states: Ildq



%% C filter

A = zeros(2,2);
B=zeros(2,5);


% State 1: vod_vsc
A(1,2)=W0;  %d vod_vsc/ d voq_vsc

B(1,1)=-1/Cf; %d vod_vsc/ d iod_vsc
B(1,3)=1/Cf; %d vod_vsc/ d ild_vsc
B(1,5)=Voq0;% d vod_vsc/d w_vsc

% State 2: voq_vsc
A(2,1)=-W0;  %d voq_vsc/ d vod_vsc

B(2,2)=-1/Cf; %d voq_vsc/ d ioq_vsc
B(2,4)=1/Cf; %d voq_vsc/ d ilq_vsc
B(2,5)=-Vod0;% d voq_vsc/d w_vsc




C=eye(2,2);
D=zeros(2,5);




if isempty(Inputs_load)~=1

% B(1,6)=-1/Cf; % d vod_vsc/d id_load
% B(2,7)=-1/Cf; % d voq_vsc/d iq_load

B=[B,[-1/Cf,0;0,-1/Cf]];

D=[D,zeros(2,2)];
end


if isempty(Inputs_inner_eline)~=1

% B(1,6)=-1/Cf; % d vod_vsc/d id_load
% B(2,7)=-1/Cf; % d voq_vsc/d iq_load

B=[B,[-1/Cf,0;0,-1/Cf]];

D=[D,zeros(2,2)];
end





Filter_C=ss(A,B,C,D,'InputName',[States(12:13),States(8:9),Outputs(3),Inputs_load,Inputs_inner_eline],'OutputName',[States(10:11)],...
    'StateName',[States(10:11)]);
% inputs: Iodq,Ildq,W,Idq_Load
% outputs: Vodq
% states: Vodq



%% Load
 if isempty(Inputs_load)~=1

    Aload=[0];
    Bload=[0,0];
    Cload=[0;0];
    Dload=zeros(2,2);
    
    Dload(1,1)=G_load; Dload(1,2)=-B_load;% Vdq for Id_load
    Dload(2,1)=B_load; Dload(2,2)=G_load;% Vdq for Iq_load
    
%     Dload(1,3)=Vd; Dload(1,4)=-Vq;% G,B for Id_load
%     Dload(2,3)=Vq; Dload(2,4)=Vd;
% 
Load=ss(Aload,Bload,Cload,Dload,'InputName',[States(10:11)],'OutputName',Inputs_load); 
% inputs: Vodq
% outputs: Idq_Load
% states: 


 else
         Load = tf(0);
    Load.InputName = {'Load_input'};
    Load.OutputName = {'Load_output'};
 end
%% Rotating Frame dq-DQ


A = 0;
B=zeros(1,3);

C=zeros(2,1);


D=zeros(2,3);


% Output 1 voD_vsc

D(1,1)=cos(delta0); D(1,2)=-sin(delta0); % d ioD_vsc/d iodq_vsc
D(1,3)=-Vod0*sin(delta0)-Voq0*cos(delta0); % d ioD_vsc/d delta

% Output 2 voQ_vsc
D(2,1)=sin(delta0); D(2,2)=cos(delta0); % d ioD_vsc/d iodq_vsc
D(2,3)=Vod0*cos(delta0)-Voq0*sin(delta0); % d ioD_vsc/d delta

dq_DQ=ss(A,B,C,D,'InputName',[States(10:11),States(1)],'OutputName',[Outputs(1:2)],...
    'StateName',[]);
% inputs: Vodq, delta
% outputs: VoDQ
% states: 

%% Rotating Frame DQ-dq


A = 0;
B=zeros(1,3);

C=zeros(2,1);


D=zeros(2,3);


% Output 1 iod_vsc

D(1,1)=cos(delta0); D(1,2)=sin(delta0); % d vbd_vsc/d VbDQ
D(1,3)=-(IoD0-IloadD0-IlineD0)*sin(delta0)+(IoQ0-IloadQ0-IlineQ0)*cos(delta0); % d vbd_vsc/d delta

% Output 2 ioq_vsc
D(2,1)=-sin(delta0); D(2,2)=cos(delta0); % d vbq_vsc/d VbDQ
D(2,3)=-(IoD0-IloadD0-IlineD0)*cos(delta0)-(IoQ0-IloadQ0-IlineQ0)*sin(delta0); % d vbq_vsc/d delta

DQ_dq=ss(A,B,C,D,'InputName',[Inputs(1:2),States(1)],'OutputName',[States(12:13)],...
    'StateName',[]);
% inputs: ioDQ, delta
% outputs: Iodq
% states: 

%% Rotating Frame DQ-dq

if isempty (Inputs_inner_eline)~=1
eline_outer_base=["Id_line_","Iq_line_"];
Inputs_outer_eline=[strcat(eline_outer_base,string(from_bus*ones(1,length(eline_outer_base))),"_",string(to_bus*ones(1,length(eline_outer_base))))];


A = 0;
B=zeros(1,3);

C=zeros(2,1);


D=zeros(2,3);


% Output 1 iod_vsc

D(1,1)=cos(delta0); D(1,2)=sin(delta0); % d vbd_vsc/d VbDQ
D(1,3)=-(IlineD0)*sin(delta0)+(IlineQ0)*cos(delta0); % d vbd_vsc/d delta

% Output 2 ioq_vsc
D(2,1)=-sin(delta0); D(2,2)=cos(delta0); % d vbq_vsc/d VbDQ
D(2,3)=-(IlineD0)*cos(delta0)-(IlineQ0)*sin(delta0); % d vbq_vsc/d delta

DQ_dq_curr_eline=ss(A,B,C,D,'InputName',[Inputs_outer_eline,States(1)],'OutputName',[Inputs_inner_eline],...
    'StateName',[]);
% inputs: ioDQ, delta
% outputs: Iodq
% states: 
else

DQ_dq_curr_eline = tf(0);
    DQ_dq_curr_eline.InputName = {'dq_input'};
    DQ_dq_curr_eline.OutputName = {'dq_output'};
    
Inputs_outer_eline=[];
end
%% Voltage Transform

if isempty(Inputs_inner_eline)~=1
Volt_output=[strcat('Vd_', string(No_mach)),strcat('Vq_', string(No_mach))];

A=zeros(1,1);
B=zeros(1,2);
C=zeros(2,1);
D=eye(2);

VT=ss(A,B,C,D,'InputName',[Outputs(1:2)],'OutputName',[Volt_output],...
    'StateName',[]);
% inputs: VoDQ
% outputs: Vdq_nomach
% states:
else
VT = tf(0);
    VT.InputName = {'VT_input'};
    VT.OutputName = {'VT_output'};
Volt_output=[];
end

%% Filter_L

A = zeros(2,2);
B=zeros(2,4);


% State 1: ilD_vsc
A(1,1)=-rc/Lc;%d ilD_vsc/ d ilD_vsc
A(1,2)=W0;  %d ilD_vsc/ d ilQ_vsc


B(1,1)=1/Lc; %d ilD_vsc/ d voD_vsc
% B(1,3)=Ioq0;% d ilD_vsc/d w_vsc
B(1,3)=-1/Lc; %d ilD_vsc/ d vbD_vsc

% State 1: ilQ_vsc
A(2,1)=-W0;%d ilQ_vsc/ d ilD_vsc
A(2,2)=-rc/Lc;  %d ilQ_vsc/ d ilQ_vsc


B(2,2)=1/Lc; %d ilQ_vsc/ d voQ_vsc
% B(2,3)=-Iod0;% d ilQ_vsc/d w_vsc
B(2,4)=-1/Lc; %d ilQ_vsc/ d vbQ_vsc



C=eye(2,2);
D=zeros(2,4);










Filter_L=ss(A,B,C,D,'InputName',[Outputs(1:2),Outputs(4:5)],'OutputName',[Inputs(1:2)],...
    'StateName',[Inputs(1:2)]);
% inputs: VoDQ,VbDQ
% outputs: IoDQ,
% states: IoDQ,


% %% Line
% 
% A = zeros(2,2);
% B=zeros(2,2);
% 
% 
% % State 1: ilD_net
% A(1,1)=-rnet/Lnet;%d ilD_net/ d ilD_net
% A(1,2)=W0;  %d ilD_net/ d ilQ_net
% 
% 
% B(1,1)=1/Lnet; %d ilD_net/ d vbD_vsc
% 
% 
% % State 1: ilQ_net
% A(2,1)=-W0;%d ilQ_net/ d ilD_net
% A(2,2)=-rnet/Lnet;  %d ilQ_net/ d ilQ_net
% 
% 
% B(2,2)=1/Lnet; %d ilQ_net/ d vbQ_vsc
% 
% 
% 
% 
% C=eye(2,2);
% D=zeros(2,2);
% 
% 
% 
% 
% 
% 
% 
% 
% Line=ss(A,B,C,D,'InputName',[Outputs(4:5)],'OutputName',["ilD_net","ilQ_net"],...
%     'StateName',["ilD_net","ilQ_net"]);
% % inputs: VbDQ,
% % outputs: IlDQ_net,
% % states: IlDQ_net,
% 
% 
% %% Busbar
% 
% A = zeros(2,2);
% B=zeros(2,5);
% CN=1e-6;
% 
% % State 1: vbD_vsc
% A(1,2)=W0;  %d vbD_vsc/ d vbQ_vsc
% 
% B(1,1)=1/CN; %d vbD_vsc/ d ioD_vsc
% B(1,3)=-1/CN; %d vbD_vsc/ d ilD_net
% B(1,5)=VbQ0;% d vbD_vsc/d w_vsc
% 
% % State 2: vbQ_vsc
% A(2,1)=-W0;  %d vbQ_vsc/ d vod_vsc
% 
% B(2,2)=1/CN; %d vbQ_vsc/ d ioQ_vsc
% B(2,4)=-1/CN; %d vbQ_vsc/ d ilQ_net
% B(2,5)=-VbD0;% d vbQ_vsc/d w_vsc
% 
% 
% 
% 
% 
% 
% 
% C=eye(2,2);
% D=zeros(2,5);
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% Busbar=ss(A,B,C,D,'InputName',[Inputs(1:2),"ilD_net","ilQ_net",Outputs(3)],'OutputName',[Outputs(4:5)],...
%     'StateName',[Outputs(4:5)]);
% % inputs: IoDQ,IlDQ_net,W
% % outputs: VbDQ,
% % states: VbDQ,

%%



% Net_impedance= connect(Line,Busbar, [Inputs(1:2)], [Outputs(4:5)]);
% Inputs: IoDQ_vsc
% Outputs: VbDQ
% States: IlDQ_net,VbDQ








%%




% VSC_w_controls=connect(Power_c,Voltage_c,Current_c,Filter_C,dq_DQ,DQ_dq,Filter_L,Line,Busbar,...
%     [Inputs(13:14)],[States(2:3)]); % 

% inputs: P_ref, V_ref
% outputs: P,V
% states: DElta,P,V,Phidq,Vodq,Iodq,Vbdq

GFM_w_controls_admittance = connect(Power_c, Voltage_c, Current_c, Filter_C, dq_DQ, DQ_dq,Filter_L,Load,DQ_dq_curr_eline,VT, ...
    [Outputs(4:5),Inputs(13:14),Inputs_outer_eline,"w_com"], [Inputs(1:2),States(2:3),Outputs(3),Volt_output]);
% Inputs: VbDQ P,V_ref, W_com
% Outputs: IoDQ P,V, W
% States: Delta (angle), P (active power), V (voltage magnitude), Phidq (voltage states), 
%         Vodq (output voltages), IoDQ (coupling current)
% 
% 
end
