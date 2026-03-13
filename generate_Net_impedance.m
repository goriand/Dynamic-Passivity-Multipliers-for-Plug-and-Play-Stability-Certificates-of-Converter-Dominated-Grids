%%
% This SSM model includes:
% VSC 13th Order Model
%

% The q-axis is taken to lead the d axis (whih is aligned with a-axis) by 
% 90 degrees


% This machine is per unit
% Balanced assumptions are made.

%%
function [Net_impedance,Line] = generate_Net_impedance()
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

load GFM_inft_bus_SCReq5_initvars.mat
load GFM_gains.mat
machine_location=1;
%% Parameters

% mp=3.1416;% P-f droop
% % nq=0;% Q-V droop
% wc = 125.6637;  % cut off frequency
% 
% Kpv = 0.1944;  % voltage proportional control gain
% Kiv=4.6751;% voltage integral control gain
% 
% % Kpc=15*60*1/3600;% current proportional control gain
% Kic=3.1416e+03;% current integral control gain
% 
% wn=314.1593; % Nominal frequency
% % rf=0.1;% LC filter resistor
% % Lf=0.01;% LC filter reactance
% Cf=7.0736e-04;% LC filter capacitor
% 
% rc=0.0199;% coupling resistor
% Lc=6.3346e-04;% coupling reactance
% 
% w0=314.1593;
% F=1;

mp=Dp;% P-f droop
% nq=0;% Q-V droop
wc = 1./Tm;  % cut off frequency

Kpv = Kpd_GFM;  % voltage proportional control gain
Kiv=Kid_GFM;% voltage integral control gain

Kic=1./Tc;% current integral control gain

wn=w0; % Nominal frequency

Cf=Cb(GFM_bus,1);% LC filter capacitor

% rc=0.015;% coupling resistor
% Lc=0.15/w0;% coupling reactance


% rc=R;% coupling resistor
% Lc=L;% coupling reactance
% rnet=R-rc+1e-10;% coupling resistor
% Lnet=L-Lc+1e-10;% coupling reactance

w0=w0;
F=1;

%% Initial States

% delta0=th(GFM_bus,1)*pi/180;
% Vod0=V_d(GFM_bus,1);
% Voq0=V_q(GFM_bus,1);
% IoD0=I_LD;
% IoQ0=I_LQ;
% Iod0=IoD0*cos(delta0)+IoQ0*sin(delta0);
% Ioq0=-IoD0*sin(delta0)+IoQ0*cos(delta0);
% W0=w0;

Inti=Initilization;

delta0 = Inti(1); % Initial angle (rad)
Vod0 = Inti(2); % Initial d-axis voltage
Voq0 = Inti(3); % Initial q-axis voltage
IoD0 = Inti(4); % Initial d-axis current
IoQ0 = Inti(5); % Initial q-axis current
Iod0 = Inti(6); % Transformed d-axis current
Ioq0 =Inti(7); % Transformed q-axis current
VbD0 =Inti(8); 
VbQ0 =Inti(9); 

W0 = w0; % Initial angular frequency


rc=case3().branch(1,3);
Lc=case3().branch(1,4)/w0;
rnet=case3().branch(2,3);
Lnet = case3().branch(2,4)/w0;


%% Variable Names
Inputs=["ioD_vsc_","ioQ_vsc_",...
    "ild_ref_vsc_","ilq_ref_vsc_","vid_ref_vsc_","viq_ref_vsc_","vod_ref_vsc_","voq_ref_vsc_",...
    "vid_vsc_","viq_vsc_","vbd_vsc_","vbq_vsc_"]; 
machine_num_str_array_outputs=string(machine_location*ones(1,length(Inputs)));
Inputs=strcat(Inputs,machine_num_str_array_outputs);

Outputs=["voD_vsc_","voQ_vsc_","w_vsc_","vbD_vsc_","vbQ_vsc_"];
machine_num_str_array_outputs=string(machine_location*ones(1,length(Outputs)));
Outputs=strcat(Outputs,machine_num_str_array_outputs);

States=["delta_vsc_","P_vsc_", "V_vsc_","phid_vsc_","phiq_vsc_","gammad_vsc_","gammaq_vsc_",...
    "ild_vsc_","ilq_vsc_","vod_vsc_","voq_vsc_","iod_vsc_","ioq_vsc_"];
machine_num_str_array_states=string(machine_location*ones(1,length(States)));
States=strcat(States,machine_num_str_array_states);




%% Line

A = zeros(2,2);
B=zeros(2,2);


% State 1: ilD_net
A(1,1)=-rnet/Lnet;%d ilD_net/ d ilD_net
A(1,2)=W0;  %d ilD_net/ d ilQ_net


B(1,1)=1/Lnet; %d ilD_net/ d vbD_vsc


% State 1: ilQ_net
A(2,1)=-W0;%d ilQ_net/ d ilD_net
A(2,2)=-rnet/Lnet;  %d ilQ_net/ d ilQ_net


B(2,2)=1/Lnet; %d ilQ_net/ d vbQ_vsc




C=eye(2,2);
D=zeros(2,2);








Line=ss(A,B,C,D,'InputName',[Outputs(4:5)],'OutputName',["ilD_net","ilQ_net"],...
    'StateName',["ilD_net","ilQ_net"]);
% inputs: VbDQ,
% outputs: IlDQ_net,
% states: IlDQ_net,


%% Busbar

A = zeros(2,2);
B=zeros(2,5);
CN=1e-9;

% State 1: vbD_vsc
A(1,2)=W0;  %d vbD_vsc/ d vbQ_vsc

B(1,1)=1/CN; %d vbD_vsc/ d ioD_vsc
B(1,3)=-1/CN; %d vbD_vsc/ d ilD_net
B(1,5)=VbQ0;% d vbD_vsc/d w_vsc

% State 2: vbQ_vsc
A(2,1)=-W0;  %d vbQ_vsc/ d vod_vsc

B(2,2)=1/CN; %d vbQ_vsc/ d ioQ_vsc
B(2,4)=-1/CN; %d vbQ_vsc/ d ilQ_net
B(2,5)=-VbD0;% d vbQ_vsc/d w_vsc







C=eye(2,2);
D=zeros(2,5);










Busbar=ss(A,B,C,D,'InputName',[Inputs(1:2),"ilD_net","ilQ_net",Outputs(3)],'OutputName',[Outputs(4:5)],...
    'StateName',[Outputs(4:5)]);
% inputs: IoDQ,IlDQ_net,W
% outputs: VbDQ,
% states: VbDQ,

%%


% Net_impedance=Line;
Net_impedance= connect(Line,Busbar, [Inputs(1:2)], [Outputs(4:5)]);
% Inputs: IoDQ_vsc
% Outputs: VbDQ
% States: IlDQ_net,VbDQ


end