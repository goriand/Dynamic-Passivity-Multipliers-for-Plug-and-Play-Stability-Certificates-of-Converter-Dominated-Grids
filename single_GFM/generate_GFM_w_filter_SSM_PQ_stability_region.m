%--------------------------------------------------------------------------
% MATLAB Code for VSC Model with Controllers and Network Interfacing
%
% Description:
% This code models a Voltage Source Converter (VSC) working in grid-forming mode
% in a power system, 
% including the power, voltage, and current controllers, as well as the 
% network and filter dynamics. It integrates these subsystems into a 
% unified state-space model to analyze the system's behavior in response 
% to various inputs such as power and voltage references. The code also 
% provides a method to validate the VSC model by comparing its system 
% matrices with a predefined grid system model.
%
% Key Features:
% - Models individual subsystems: power controller, voltage controller, 
%   current controller, LC filter, and network dynamics.
% - Combines these subsystems into a unified VSC model.
% - Computes the transfer function of the VSC system for frequency-domain 
%   analysis.
% - Compares the VSC system matrices with a test grid system to ensure 
%   accuracy within a defined tolerance.
%
% Author: Youhong Chen
% Affiliation: Imperial College London
% Date: 18-01-2025

clear all

machine_location = 1;
load data3.mat


Pg=100;
Sload=10+10j;
Zc=0.01+0.015j;

%% Parameters
% mp: 0.94
% nq: 0.034210526315789476
% Lf: 9.349030470914129e-05
% Cf: 0.000722
% rf: 0.006925207756232688
% Lc: 2.4238227146814406e-05
% rLc: 0.002077562326869806
% Kpv: 0.7220000000000001
% Kiv: 5631.6
% Kpc: 0.7271468144044321
% Kic: 1108.0332409972298
% F: 0.75
% wc_lp: 31.41

w0=2*pi*50;
Kpv = Kpd_GFM(1); % Voltage proportional control gain
Kiv = 0.0; % Voltage integral control gain

% Kpv = 0.722; % Voltage proportional control gain
% Kiv = 5631.6; % Voltage integral control gain

% Kpv = 10*Kpv; % Voltage proportional control gain

% Kpv = 400*2*pi*0.000722;
% Kiv = 0.001;

mp = Dp(1); % P-f droop
nq = Dq(1); % Q-v droop
wc = 1./Tm; % Cut-off frequency

% mp = 0.94; % P-f droop
% nq = 0.034210526315789476; % Q-v droop
% wc = 31.41; % Cut-off frequency


Kic = 1./Tc; % Current integral control gain

% Kic = 9203.163284835617; % Current integral control gain

% Kic = 1600*2*pi;

wn = w0; % Nominal frequency



Bf=Cf(1);
Cf=Bf;

w0 = w0; % Nominal angular frequency
F = 1;

% Cf = 0.000722; % Filter capacitance
% % Cf = Cf*w0;
% F = 0.75;

%% Initial States

[Inti,results]=Initilization2(Pg,Sload,Zc);

delta0 = Inti(1); % Initial angle (rad)
Vod0 = Inti(2); % Initial d-axis voltage
Voq0 = Inti(3); % Initial q-axis voltage
IoD0 = Inti(4); % Initial d-axis current
IoQ0 = Inti(5); % Initial q-axis current
Iod0 = Inti(6); % Transformed d-axis current
Ioq0 =Inti(7); % Transformed q-axis current
VbD0 =Inti(8); 
VbQ0 =Inti(9); 

% delta0 = 0; % Initial angle (rad)
% Vod0 = 1; % Initial d-axis voltage
% Voq0 = 0; % Initial q-axis voltage
% IoD0 = 0; % Initial d-axis current
% IoQ0 = 0; % Initial q-axis current
% Iod0 = 0; % Transformed d-axis current
% Ioq0 = 0; % Transformed q-axis current
% VbD0 = 1;
% VbQ0 = 0;


W0 = w0; % Initial angular frequency

rc=results.branch(1,3);
Lc=results.branch(1,4)/w0;
rnet=results.branch(2,3);
Lnet = results.branch(2,4)/w0;

Cn=results.branch(2,5)/2/w0;
%% Variable Names

Inputs = ["ioD_vsc_", "ioQ_vsc_", "ild_ref_vsc_", "ilq_ref_vsc_", ...
          "vid_ref_vsc_", "viq_ref_vsc_", "vod_ref_vsc_", "voq_ref_vsc_", ...
          "vid_vsc_", "viq_vsc_", "vbd_vsc", "vdq_vsc"]; 
machine_num_str_array_outputs = string(machine_location * ones(1, length(Inputs)));
Inputs = strcat(Inputs, machine_num_str_array_outputs);

Outputs = ["voD_vsc_", "voQ_vsc_", "w_vsc_","vbD_vsc_", "vbQ_vsc_"];
machine_num_str_array_outputs = string(machine_location * ones(1, length(Outputs)));
Outputs = strcat(Outputs, machine_num_str_array_outputs);

States = ["delta_vsc_", "P_vsc_", "Q_vsc_", "phid_vsc_", "phiq_vsc_", ...
          "gammad_vsc_", "gammaq_vsc_", "ild_vsc_", "ilq_vsc_", ...
          "vod_vsc_", "voq_vsc_", "iod_vsc_", "ioq_vsc_"];
machine_num_str_array_states = string(machine_location * ones(1, length(States)));
States = strcat(States, machine_num_str_array_states);

%% Power Controller

% Initialize state-space matrices
A = zeros(3,3);
B = zeros(3,9);

% Define state-space equations for power controller
A(1,2) = -mp; % d delta_vsc/d P_vsc
B(1,1) = -1;  % d delta_vsc/d w_com
B(1,8) = mp;  % d delta_vsc/d dP_ref_vsc

A(2,2) = -wc; % d P_vsc/d P_vsc
B(2,4) = wc * Iod0; % d P_vsc / d vod_vsc
B(2,5) = wc * Ioq0; % d P_vsc / d voq_vsc
B(2,6) = wc * Vod0; % d P_vsc / d iod_vsc
B(2,7) = wc * Voq0; % d P_vsc / d ioq_vsc

A(3,3) = -wc; % d Q_vsc/d Q_vsc
B(3,4) = -wc * Ioq0; % d Q_vsc / d vod_vsc
B(3,5) = wc * Iod0; % d Q_vsc / d voq_vsc
B(3,6) = -wc * Voq0; % d Q_vsc / d iod_vsc (corrected sign)
B(3,7) = -wc * Vod0; % d Q_vsc / d ioq_vsc



% Output and feedthrough matrices
C = zeros(6,3);
C(1,1) = 1; % d delta/d delta
C(2,2) = 1; % d P/d P
C(3,3) = 1; % d Q/d Q
C(4,2) = -mp; % dw_vsc/dP_vsc
C(5,3) = -nq;  % d vod_ref_vsc/dQ_vsc

D = zeros(6,9);
D(4,8) = mp; % dw_vsc/dP_ref_vsc
D(5,9) = nq; % dw_vsc/dP_ref_vsc

% Create power controller state-space system
Power_c = ss(A, B, C, D, ...
    'InputName', ["w_com", States(8:13), "P_ref", "Q_ref"], ...
    'OutputName', [States(1:3), Outputs(3), Inputs(7:8)], ...
    'StateName', [States(1:3)]);
% Inputs: w_com, Ildq, Vodq, Iodq, P_ref, Q_ref
% Outputs: Delta, P, Q, W, Vodq_ref
% States: Delta, P, Q

%% Voltage Controller

% Initialize state-space matrices
A = zeros(2,2);
B = zeros(2,9);

% Define input-output relationships for voltage controller
% State 1: phid_vsc
B(1,1) = Kiv;    % d phid_vsc/d vod_ref_vsc
B(1,5) = -Kiv;   % d phid_vsc/d vod_vsc

% State 2: phiq_vsc
B(2,2) = Kiv;    % d phiq_vsc/d voq_ref_vsc
B(2,6) = -Kiv;   % d phiq_vsc/d voq_vsc

% Define output and feedthrough matrices
C = zeros(2,2);
D = zeros(2,9);

% Output 1: ild_ref_vsc
C(1,1) = 1;         % d ild_ref_vsc/d phid_vsc
D(1,1) = Kpv;       % d ild_ref_vsc/d vod_ref_vsc
D(1,5) = -Kpv;      % d ild_ref_vsc/d vod_vsc
D(1,6) = -wn * Cf;  % d ild_ref_vsc/d voq_vsc
D(1,7) = F;         % d ild_ref_vsc/d iod_vsc
D(1,9) = -Voq0 * Cf; % d ild_ref_vsc/d w_vsc

% Output 2: ilq_ref_vsc
C(2,2) = 1;         % d ilq_ref_vsc/d phiq_vsc
D(2,2) = Kpv;       % d ilq_ref_vsc/d voq_ref_vsc
D(2,5) = wn * Cf;   % d ilq_ref_vsc/d vod_vsc
D(2,6) = -Kpv;      % d ilq_ref_vsc/d voq_vsc
D(2,8) = F;         % d ilq_ref_vsc/d ioq_vsc
D(2,9) = Vod0 * Cf; % d ilq_ref_vsc/d w_vsc

% Create voltage controller state-space system
Voltage_c = ss(A, B, C, D, ...
    'InputName', [Inputs(7:8), States(8:13), Outputs(3)], ...
    'OutputName', [Inputs(3:4)], ...
    'StateName', [States(4:5)]);
% Inputs: Vodq_ref, Ildq, Vodq, Iodq, W
% Outputs: Ildq_ref
% States: Phidq

%% Current Controller

% Initialize state-space matrices for integral controller
% With zero-pole cancellation, rf/Lf dynamics are cancelled out
A = zeros(2,2);
B = zeros(2,2);

% State 1: gammad_vsc (integral state)
A(1,1) = -Kic; % d gammad_vsc/d gammad_vsc
B(1,1) = Kic;  % d gammad_vsc/d ild_ref_vsc

% State 2: gammaq_vsc (integral state)
A(2,2) = -Kic; % d gammaq_vsc/d gammaq_vsc
B(2,2) = Kic;  % d gammaq_vsc/d ilq_ref_vsc

% Define output and feedthrough matrices
C = eye(2,2);
D = zeros(2,2);

% Create current controller state-space system
Current_c = ss(A, B, C, D, ...
    'InputName', [Inputs(3:4)], ...
    'OutputName', [States(8:9)], ...
    'StateName', [States(6:7)]);
% Inputs: Ildq_ref
% Outputs: Ildq (with zero-pole cancellation, these represent ideal currents)
% States: Gammadq (integral states)

%% C Filter

% Initialize state-space matrices
A = zeros(2,2);
B = zeros(2,7);

% State 1: vod_vsc
A(1,2) = W0;         % d vod_vsc/d voq_vsc
B(1,1) = -1/Cf;      % d vod_vsc/d iod_vsc
B(1,3) = 1/Cf;       % d vod_vsc/d ild_vsc
B(1,7) = Voq0;       % d vod_vsc/d w_vsc

% State 2: voq_vsc
A(2,1) = -W0;        % d voq_vsc/d vod_vsc
B(2,2) = -1/Cf;      % d voq_vsc/d ioq_vsc
B(2,4) = 1/Cf;       % d voq_vsc/d ilq_vsc
B(2,7) = -Vod0;      % d voq_vsc/d w_vsc

% Define output and feedthrough matrices
C = eye(2,2);
D = zeros(2,7);

% Create C filter state-space system
Filter = ss(A, B, C, D, ...
    'InputName', [States(12:13), States(8:9), Inputs(11:12), Outputs(3)], ...
    'OutputName', [States(10:11)], ...
    'StateName', [States(10:11)]);
% Inputs: Iodq, Ildq, Vbdq, W
% Outputs: Vodq
% States: Vodq


%% Rotating Frame dq-DQ

% Initialize state-space matrices
A = 0;
B = zeros(1,3);
C = zeros(2,1);
D = zeros(2,3);

% Output 1: voD_vsc
D(1,1) = cos(delta0); D(1,2) = -sin(delta0); % d ioD_vsc/d iodq_vsc
D(1,3) = -Vod0 * sin(delta0) - Voq0 * cos(delta0); % d ioD_vsc/d delta

% Output 2: voQ_vsc
D(2,1) = sin(delta0); D(2,2) = cos(delta0); % d ioQ_vsc/d iodq_vsc
D(2,3) = Vod0 * cos(delta0) - Voq0 * sin(delta0); % d ioQ_vsc/d delta

% Create dq-DQ transformation state-space system
dq_DQ = ss(A, B, C, D, ...
    'InputName', [States(10:11), States(1)], ...
    'OutputName', [Outputs(1:2)], ...
    'StateName', []);
% Inputs: Vodq, Delta
% Outputs: VoDQ

%% Rotating Frame DQ-dq

% Initialize state-space matrices
A = 0;
B = zeros(1,3);
C = zeros(2,1);
D = zeros(2,3);

% Output 1: iod_vsc
D(1,1) = cos(delta0); D(1,2) = sin(delta0); % d iod_vsc/d ioDQ
D(1,3) = -IoD0 * sin(delta0) + IoQ0 * cos(delta0); % d iod_vsc/d delta

% Output 2: ioq_vsc
D(2,1) = -sin(delta0); D(2,2) = cos(delta0); % d ioq_vsc/d ioDQ
D(2,3) = -IoD0 * cos(delta0) - IoQ0 * sin(delta0); % d ioq_vsc/d delta

% Create DQ-dq transformation state-space system
DQ_dq = ss(A, B, C, D, ...
    'InputName', [Inputs(1:2), States(1)], ...
    'OutputName', [States(12:13)], ...
    'StateName', []);
% Inputs: IoDQ
% Outputs: Iodq


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


% State 1: vbD_vsc
A(1,2)=W0;  %d vbD_vsc/ d vbQ_vsc

B(1,1)=1/Cn; %d vbD_vsc/ d ioD_vsc
B(1,3)=-1/Cn; %d vbD_vsc/ d ilD_net
B(1,5)=VbQ0;% d vbD_vsc/d w_vsc

% State 2: vbQ_vsc
A(2,1)=-W0;  %d vbQ_vsc/ d vod_vsc

B(2,2)=1/Cn; %d vbQ_vsc/ d ioQ_vsc
B(2,4)=-1/Cn; %d vbQ_vsc/ d ilQ_net
B(2,5)=-VbD0;% d vbQ_vsc/d w_vsc







C=eye(2,2);
D=zeros(2,5);










Busbar=ss(A,B,C,D,'InputName',[Inputs(1:2),"ilD_net","ilQ_net",Outputs(3)],'OutputName',[Outputs(4:5)],...
    'StateName',[Outputs(4:5)]);
% inputs: IoDQ,IlDQ_net,W
% outputs: VbDQ,
% states: VbDQ,




%% Combine All Controllers and Filters into a Single System

% Connect all subsystems to create a unified VSC model
VSC_w_controls = connect(Power_c, Voltage_c, Current_c, Filter, dq_DQ, DQ_dq,Filter_L,Line,Busbar, ...
    ["P_ref","Q_ref"], [States(2:3)]);
% % inputs: P_ref, Q_ref
% % outputs: P,Q
% States: Delta (angle), P (active power), Q (voltage magnitude), Phidq (voltage states), 
%         Vodq (output voltages), IoDQ (coupling current)

eig_cl=eig(VSC_w_controls);




GFM_w_controls_impedance = connect(Power_c, Voltage_c, Current_c, Filter, dq_DQ, DQ_dq,Filter_L,...
    [Outputs(4:5)], [Inputs(1:2)]);
% Inputs: VbDQ
% Outputs: IoDQ 
% States: Delta (angle), P (active power), V (voltage magnitude), Phidq (voltage states), 
%         Vodq (output voltages)
% 

eig_GFM = eig(GFM_w_controls_impedance);

% return;

%% Analyze Hermitian part of impedance transfer function
% Define frequency range for analysis
w_min = 0.1;     % Minimum frequency [rad/s]
w_max = w0*5;    % Maximum frequency [rad/s]
n_points = 1000; % Number of frequency points

% Create logarithmically spaced frequency vector
w_vec = logspace(log10(w_min), log10(w_max), n_points);

% Preallocate arrays for eigenvalues
eig_hermitian = zeros(2, n_points); % 2x2 system has 2 eigenvalues
eig_flipped = zeros(2, n_points); % 2x2 system has 2 eigenvalues

%% Efficient Passivity Analysis Function
% Define J matrix for weighted passivity
J = [0 -1; 1 0];

% Compute eigenvalues of Hermitian part at each frequency
for i = 1:n_points
    w = w_vec(i);
    
    % Evaluate transfer function at frequency w
    G_jw = freqresp(GFM_w_controls_impedance, w);
    G_jw = -squeeze(G_jw); % Remove singleton dimensions
    
    % Compute Hermitian part: 0.5*(G(jω) + G(jω)^H)
    H_jw = 0.5 * (G_jw + G_jw');
    
    % Calculate eigenvalues of the Hermitian part
    eig_hermitian(:, i) = eig(H_jw);

    eig_flipped(:, i) = eig(0.5 * (J * G_jw + (J * G_jw)'));
end

% Plot eigenvalues of Hermitian part vs frequency
figure;
semilogx(w_vec, real(eig_hermitian(1,:)), 'b-', 'LineWidth', 1.5);
hold on;
semilogx(w_vec, real(eig_hermitian(2,:)), 'r-', 'LineWidth', 1.5);
grid on;

semilogx(w_vec, real(eig_flipped(1,:)), 'b--', 'LineWidth', 1.5);
semilogx(w_vec, real(eig_flipped(2,:)), 'r--', 'LineWidth', 1.5);


xlabel('Frequency (rad/s)');
ylabel('Eigenvalues of Hermitian part');
title('Eigenvalues of Hermitian part of GFM impedance vs. frequency');
legend('\lambda_1', '\lambda_2', '\lambda_1 (flipped)', '\lambda_2 (flipped)');




% Tuned filter for stability certificate (mp 1%, nq 1%)
A_filter = 1.0e+02 * [-0.168501662776551,   0.596606291186166;
    -0.206143008912238,  -1.104580617971971];

B_filter = [6.992915567691922,  -7.622972921438289;
            11.364427882644076,  -2.118256128392985];

C_filter = [13.379271610693163,  -7.844060929307741;
   4.397353141972610,  11.674871131112019];


A_filter = 1.0e+02 * [-0.122128952221932   0.038474879852206                   0                   0                   0
   0.049837466689726  -0.235485988148767  -0.082227187832474                   0                   0
                   0   0.041880232097688  -0.104372976763683   0.103613020627630                   0
                   0                   0   0.034334730018129  -0.726250514216908   0.151714562408861
                   0                   0                   0   0.129116622922354  -1.557381417591347];
            
B_filter = [0.900512037284536  -3.531423447028800
  -0.725822395845697 -13.463161948824901
   2.887796952743384   1.304838739533805
  16.728854693093400  -1.028564302714347
  16.334204889727047   3.282681941576035];

C_filter = [5.732560451596713  -2.292945093244381  -5.542197083693287  20.225063695011393 -22.793050183608599
 -11.787697216015886   6.226744166898103  20.295280495311257   6.974368500794156   0.818613959332916];

% % Tuned filter for stability certificate (mp 2%, nq 5%)
% A_filter2 = 1.0e+02 *[-4.553856101610749   3.784855520881041
%             -1.416739510477288   1.084109548399305];

% B_filter2 = [3.057908707671544 -12.035689060235136
%             16.434046409251092  -5.497574806611152];

% C_filter2 = [13.282438544519520  -6.362014883971025
%             -6.933078835414110  13.608256092086114];

% % Tuned filter for stability certificate (mp 0.1%, nq 0.1%)
% A_filter3 = [-5.2641    2.7622
%     2.8205 -111.0244];
% B_filter3 = [1.2871   -2.8357
%    12.5329   -2.7358];
% C_filter3 = [2.1583   -1.9240
%     1.1680    8.8490];

% % Tuned filter for stability certificate (mp 0.5%, nq 0.5%)
% A_filter4 = [-6.1236    2.2605
%     1.4580 -100.2427];

% B_filter4 = [14.1740   -1.3335
%     2.7981   -3.5606];

% C_filter4 = [1.1288    0.2807
%     3.0500    5.7773];

% % Tuned filter for stability certificate (mp 2%, nq 3%)
% A_filter5 = 1.0e+02 * [-0.201003399814060   0.030278549777792
%   -0.278176188370222  -2.739051814753501];
% B_filter5 = [20.537345944971047  -2.818577358860542
%   12.659618691513931   3.613065437519621];
% C_filter5 = [5.111209716204845 -13.872555638212829
%    8.802392753963195   1.992100242724160];

D_filter = eye(2);

% Create flexible filter set for stability analysis
filterSet = struct();
filterSet(1).name = 'Filter_mp1_nq1';
filterSet(1).description = 'Tuned filter (mp 1%, nq 1%)';
filterSet(1).sys = ss(A_filter, B_filter, C_filter, D_filter);

% filterSet(2).name = 'Filter_mp2_nq5';
% filterSet(2).description = 'Tuned filter (mp 2%, nq 5%)';
% filterSet(2).sys = ss(A_filter2, B_filter2, C_filter2, D_filter);

% filterSet(3).name = 'Filter_mp0.1_nq0.1';
% filterSet(3).description = 'Tuned filter (mp 0.1%, nq 0.1%)';
% filterSet(3).sys = ss(A_filter3, B_filter3, C_filter3, D_filter);

% filterSet(4).name = 'Filter_mp0.5_nq0.5';
% filterSet(4).description = 'Tuned filter (mp 0.5%, nq 0.5%)';
% filterSet(4).sys = ss(A_filter4, B_filter4, C_filter4, D_filter);


% filterSet(5).name = 'Filter_mp2_nq3';
% filterSet(5).description = 'Tuned filter (mp 2%, nq 3%)';
% filterSet(5).sys = ss(A_filter5, B_filter5, C_filter5, D_filter);

% % You can add more filters here by extending the filterSet array
% filterSet(3).name = 'Filter_custom';
% filterSet(3).description = 'Custom filter';
% filterSet(3).sys = ss(A_custom, B_custom, C_custom, D_filter);

% Display available filters
fprintf('\nConfigured Filter Set:\n');
for k = 1:length(filterSet)
    fprintf('  %d. %s: %s\n', k, filterSet(k).name, filterSet(k).description);
end

% Backward compatibility - keep original filter as default
Gf_tuned = filterSet(1).sys;



% Efficient feasibility checking function with generalized conditions
function isFeasible = checkFeasibility(sys, J, w_vec)
    % Check feasibility: for every ω, at least one condition must be satisfied:
    % 1. Her{G(jω)} ≥ 0 OR
    % 2. Her{exp(-1j*theta)*J*G(jω)} ≥ 0 for some theta in [0, π/2]
    % Returns: logical flag
    
    % Define sample angles in [0, π/2]
    num_angles = 1; % Number of angles to sample (can be adjusted)
    theta_vec = linspace(0, 0, num_angles);
    
    isFeasible = true;
    tol_passivity = -1e-6; % Small tolerance for numerical issues
    
    for w = w_vec
        % Evaluate transfer function at frequency w
        G_jw = freqresp(sys, w);
        G_jw = -squeeze(G_jw); % Remove singleton dimensions
        
        % Standard passivity: Her{G(jω)} = 0.5*(G + G')
        Her_G = 0.5 * (G_jw + G_jw');
        eig_std = real(eig(Her_G));
        minEig_std = min(eig_std);
        
        % If standard passivity is satisfied, continue to next frequency
        if minEig_std >= tol_passivity
            continue;
        end
        
        % Check all generalized passivity conditions with rotated J matrices
        feasible_at_freq = false;
        
        % Check rotated J matrices including the original (theta = 0)
        for theta = theta_vec
            % Create rotated J matrix: exp(-1j*theta) * J
            rot_J = exp(-1j*theta) * J;
            
            % Calculate Hermitian part of rotated J * G
            rot_JG = rot_J * G_jw;
            Her_rot_JG = 0.5 * (rot_JG + rot_JG');
            
            % Check eigenvalues
            eig_rot = real(eig(Her_rot_JG));
            minEig_rot = min(eig_rot);
            
            if minEig_rot >= tol_passivity
                feasible_at_freq = true;
                break; % At least one condition is satisfied
            end
        end
        
        % If no condition is satisfied at this frequency, system is not feasible
        if ~feasible_at_freq
            isFeasible = false;
            break;
        end
    end
end

% Define frequency range for passivity analysis (optimize for efficiency)
w_passivity = logspace(-1, log10(5*w0), 200); % Fewer points for efficiency in parallel loop

% Check feasiblity of the original system without filter
feasibilityFlag_orig = checkFeasibility(GFM_w_controls_impedance, J, w_vec);
fprintf('\nFeasibility of original system without filter: %s\n', string(feasibilityFlag_orig));


%% ------------------------------------------------------------------------
%% Stability Region over Droop Gains (m_p vs n_q)
% This section scans the (mp, nq) space to identify stable combinations.

% Grid resolution (user adjustable)
Nmp = 71; % number of points along mp axis
Nnq = 71; % number of points along nq axis

mp_vec = linspace(0, 5*Dp(1), Nmp);
nq_vec = linspace(0, 5*Dq(1), Nnq);

% Initialize results arrays for multiple filters
nFilters = length(filterSet);
nu_values = zeros(Nmp, Nnq, nFilters);     % Passivity index for each filter
pluginSafeFlag = false(Nmp, Nnq, nFilters); % Plugin-safe region for each filter

% Feasibility analysis (filter-independent): Her{G(jω)} ≥ 0 OR Her{JG(jω)} ≥ 0
feasibilityFlag = false(Nmp, Nnq);   % Feasibility: either standard or weighted passivity

stabilityFlag = false(Nmp, Nnq);
margin = nan(Nmp, Nnq); % max real part of eigenvalues (negative => stable)

tol = 1e-6; % small tolerance for numerical noise (treat real_part < tol as stable)

% Preallocate cell for a few dominant eigenvalues (optional diagnostics)
dominantEig = cell(Nmp, Nnq); % each entry: vector of eigenvalues with largest real parts

fprintf('\nScanning stability region over mp and nq (grid %d x %d = %d points) ...\n', Nmp, Nnq, Nmp*Nnq);
tic;
% Initialize parallel pool with detailed diagnostics
fprintf('Checking parallel computing capabilities...\n');
fprintf('MATLAB Version: %s\n', version);

% Initialize parallel pool variable
p = [];

% Check if Parallel Computing Toolbox is installed and available
toolboxes = ver;
pct_installed = any(contains({toolboxes.Name}, 'Parallel Computing Toolbox'));
if pct_installed
    fprintf('✓ Parallel Computing Toolbox is installed\n');
else
    fprintf('✗ Parallel Computing Toolbox is NOT installed\n');
end

% Check if Parallel Computing Toolbox license is available
if license('test','Distrib_Computing_Toolbox') && pct_installed
    fprintf('✓ Parallel Computing Toolbox license available\n');
    
    % Check if the toolbox functions are accessible
    if exist('gcp','file')
        fprintf('✓ gcp function is available\n');
        
        % Check current parallel pool status
        try
            p = gcp('nocreate');
            if isempty(p)
                fprintf('No parallel pool currently running. Attempting to start...\n');
                
                % Try to start parallel pool
                try
                    % Get default cluster and check if available
                    defaultCluster = parcluster();
                    fprintf('Default cluster: %s\n', defaultCluster.Type);
                    fprintf('Available workers: %d\n', defaultCluster.NumWorkers);
                    
                    % Start parallel pool
                    p = parpool(defaultCluster);
                    fprintf('✓ Parallel pool started successfully with %d workers\n', p.NumWorkers);
                catch ME
                    fprintf('✗ Failed to start parallel pool:\n');
                    fprintf('  Error: %s\n', ME.message);
                    fprintf('Continuing with serial execution...\n');
                    p = [];
                end
            else
                fprintf('✓ Parallel pool already running with %d workers\n', p.NumWorkers);
            end
        catch gcp_err
            fprintf('✗ Error accessing gcp function: %s\n', gcp_err.message);
            fprintf('Full error details: %s\n', gcp_err.getReport());
            p = [];
        end
    else
        fprintf('✗ gcp function is not available - toolbox may not be properly installed\n');
    end
else
    fprintf('✗ Parallel Computing Toolbox not available or no license\n');
    fprintf('Continuing with serial execution...\n');
end


% Use parfor if parallel pool is available, otherwise use regular for loop
% To force serial execution, change the next line to: USE_PARALLEL = false;
USE_PARALLEL = true;

% Safely check for parallel pool
try
    if license('test','Distrib_Computing_Toolbox')
        poolObj = gcp('nocreate');
    else
        poolObj = [];
    end
catch
    poolObj = [];
end

% Check if we can use parallel processing
USE_PARFOR = USE_PARALLEL && ~isempty(poolObj);

if USE_PARFOR
    fprintf('Running parallel analysis with %d workers...\n', poolObj.NumWorkers);
    
    % Test parallel processing with a simple loop
    fprintf('Testing parallel processing... ');
    tic;
    parfor k = 1:poolObj.NumWorkers
        pause(0.1); % Small delay to test parallel execution
    end
    test_time = toc;
    fprintf('Test completed in %.2f seconds\n', test_time);
    
    fprintf('MANUAL STEP: To enable parallel processing, change "for ii = 1:Nmp" to "parfor ii = 1:Nmp" in the main loop below\n');
else
    fprintf('Running serial analysis...\n');
end

% Main computation loop - change "for" to "parfor" manually if needed
parfor ii = 1:Nmp
    mp_i = mp_vec(ii); % local droop for this iteration
    for jj = 1:Nnq
        nq_j = nq_vec(jj);

        % ---------------- Power Controller (rebuild with updated mp_i,nq_j) ----------------
        Apc = zeros(3,3); Bpc = zeros(3,9);
        % State 1 dynamics (delta)
        Apc(1,2) = -mp_i;      % d delta_vsc/d P_vsc
        Bpc(1,1) = -1;         % d delta_vsc/d w_com
        Bpc(1,8) = mp_i;       % d delta_vsc/d dP_ref_vsc
        % State 2 dynamics (P)
        Apc(2,2) = -wc;        % d P_vsc/d P_vsc
        Bpc(2,4) = wc * Iod0;  % d P_vsc / d vod_vsc
        Bpc(2,5) = wc * Ioq0;  % d P_vsc / d voq_vsc
        Bpc(2,6) = wc * Vod0;  % d P_vsc / d iod_vsc
        Bpc(2,7) = wc * Voq0;  % d P_vsc / d ioq_vsc
        % State 3 dynamics (Q)
        Apc(3,3) = -wc;        % d Q_vsc/d Q_vsc
        Bpc(3,4) = -wc * Ioq0; % d Q_vsc / d vod_vsc
        Bpc(3,5) = wc * Iod0;  % d Q_vsc / d voq_vsc
        Bpc(3,6) = wc * Voq0;  % d Q_vsc / d iod_vsc
        Bpc(3,7) = -wc * Vod0; % d Q_vsc / d ioq_vsc

        Cpc = zeros(6,3); Dpc = zeros(6,9);
        Cpc(1,1) = 1; % delta
        Cpc(2,2) = 1; % P
        Cpc(3,3) = 1; % Q
        Cpc(4,2) = -mp_i; % w output sensitivity to P
        Cpc(5,3) = -nq_j; % vod_ref sensitivity to Q
        Dpc(4,8) = mp_i;  % w_ref path
        Dpc(5,9) = nq_j;  % vod_ref path

        Power_c_loop = ss(Apc, Bpc, Cpc, Dpc, ...
            'InputName', ["w_com", States(8:13), "P_ref", "Q_ref"], ...
            'OutputName', [States(1:3), Outputs(3), Inputs(7:8)], ...
            'StateName', [States(1:3)]);

        % ---------------- Connect GFM system (without Line and Busbar) ----------------
        try
            GFM_tmp = connect(Power_c_loop, Voltage_c, Current_c, Filter, dq_DQ, DQ_dq, Filter_L,...
                [Outputs(4:5)], [Inputs(1:2)]);
            ev = eig(GFM_tmp.A); % state matrix eigenvalues
            rmax = max(real(ev));
            margin(ii,jj) = rmax;
            stabilityFlag(ii,jj) = (rmax < tol);
            [~, idxSort] = sort(real(ev),'descend');
            dominantEig{ii,jj} = ev(idxSort(1:min(4,end)));
        catch ME
            margin(ii,jj) = NaN;
            stabilityFlag(ii,jj) = false;
            dominantEig{ii,jj} = ME.identifier;
        end
        % Calculate feasibility and stability indices for the current configuration
        if stabilityFlag(ii,jj)
            try
                % Feasibility analysis: Her{G(jω)} ≥ 0 OR Her{JG(jω)} ≥ 0 for all ω
                isFeas = checkFeasibility(GFM_tmp, J, w_passivity);
                feasibilityFlag(ii,jj) = isFeas;
                
                % Test stability with each filter in the filter set
                % Store results in temporary variables to avoid PARFOR 3D indexing issues
                nu_temp = nan(1, nFilters);
                plugin_temp = false(1, nFilters);
                
                for kFilter = 1:nFilters
                    try
                        % Apply the k-th filter to the GFM model and calculate passivity index
                        neg_filtered_GFM = -filterSet(kFilter).sys * GFM_tmp;
                        nu_temp(kFilter) = getPassiveIndex(neg_filtered_GFM, "input");
                        plugin_temp(kFilter) = nu_temp(kFilter) > -1e-6;
                    catch
                        nu_temp(kFilter) = NaN;
                        plugin_temp(kFilter) = false;
                    end
                end
                
                % Assign to output arrays (PARFOR compatible)
                for kFilter = 1:nFilters
                    nu_values(ii,jj,kFilter) = nu_temp(kFilter);
                    pluginSafeFlag(ii,jj,kFilter) = plugin_temp(kFilter);
                end
                
            catch
                % If feasibility analysis fails, set all values to default
                feasibilityFlag(ii,jj) = false;
                feasibilityMargin(ii,jj) = NaN;
                for kFilter = 1:nFilters
                    nu_values(ii,jj,kFilter) = NaN;
                    pluginSafeFlag(ii,jj,kFilter) = false;
                end
            end
        else
            % System is unstable - set all flags to false
            feasibilityFlag(ii,jj) = false;
            feasibilityMargin(ii,jj) = NaN;
            for kFilter = 1:nFilters
                nu_values(ii,jj,kFilter) = NaN;
                pluginSafeFlag(ii,jj,kFilter) = false;
            end
        end

    end
end

% Report completion based on execution mode
if USE_PARFOR
    fprintf('  Parallel loop complete.\n');
else
    fprintf('  Serial loop complete.\n');
end
elapsed_scan = toc;
fprintf('Stability scan finished in %.2f s.\n', elapsed_scan);

% ---------------- Plot Unified Feasibility and Plugin-Safe Regions ----------------

% Create single comprehensive visualization with transparent overlays
figure('Name','Unified Feasibility and Plugin-Safe Analysis','Position',[100 100 1000 700]);

% Prepare coordinate grids
mp_plot = 100*0.01*mp_vec/Dp(1);  % Convert to percentage of droop gain
nq_plot = 100*nq_vec;
[MP_grid, NQ_grid] = meshgrid(mp_plot, nq_plot);

% Base layer: Stability regions (solid background)
% Red for unstable, light gray for stable
baseMap = double(stabilityFlag');
baseColors = [0.9 0.3 0.3; 0.85 0.85 0.85]; % Red for unstable, light gray for stable

% Plot base stability map
h_base = imagesc(mp_plot, nq_plot, baseMap);
set(gca,'YDir','normal');
colormap(baseColors);
hold on;



% Define colors for different filters
filterColors = [
    0.0 0.4 0.8;  % Blue
    0.8 0.4 0.0;  % Orange  
    0.6 0.2 0.8;  % Purple
    0.8 0.6 0.0;  % Gold
    0.2 0.8 0.6;  % Teal
];

% Overlay 2: Combined Plugin-safe regions (merge all filters)
% Create combined plugin-safe map: true where ANY filter works
anyFilterPluginSafe = any(pluginSafeFlag, 3); % Logical OR across all filters
combinedPluginMap = double(stabilityFlag' & anyFilterPluginSafe');
fprintf('Combined plugin-safe map (any filter works): %d non-zero points\n', sum(combinedPluginMap(:) > 0));

% Plot combined plugin-safe regions
if any(combinedPluginMap(:))
    % Use blue color for combined plugin-safe regions
    pluginColor = [0.0 0.4 0.8]; % Blue
    
    try
        % Create filled contours with transparency
        [~, h_fill] = contourf(MP_grid, NQ_grid, combinedPluginMap, [0.5 1], 'LineStyle', 'none');
        
        % Set transparency and color for plugin-safe regions
        if ~isempty(h_fill.FacePrims)
            set(h_fill.FacePrims, 'FaceAlpha', 0.4); % 40% transparency
            h_fill.FaceColor = pluginColor;
        else
            % Fallback: scatter plot
            idx = find(combinedPluginMap > 0.5);
            if ~isempty(idx)
                [row, col] = ind2sub(size(combinedPluginMap), idx);
                mp_plugin = mp_plot(col);
                nq_plugin = nq_plot(row);
                scatter(mp_plugin, nq_plugin, 80, pluginColor, 'filled', 'MarkerFaceAlpha', 0.5);
            end
        end
        
        % Add boundary contour for visibility
        contour(MP_grid, NQ_grid, combinedPluginMap, [0.5 0.5], ...
            'LineWidth', 2, 'Color', pluginColor);
    catch ME
        fprintf('Error plotting combined plugin-safe regions: %s\n', ME.message);
        % Simple fallback: scatter plot
        idx = find(combinedPluginMap > 0.5);
        if ~isempty(idx)
            [row, col] = ind2sub(size(combinedPluginMap), idx);
            mp_plugin = mp_plot(col);
            nq_plugin = nq_plot(row);
            scatter(mp_plugin, nq_plugin, 70, pluginColor, 'filled', 'MarkerFaceAlpha', 0.5);
        end
    end
else
    fprintf('No combined plugin-safe regions to plot\n');
end



% Overlay 1: Feasibility region (transparent green patches)
feasMap = double(stabilityFlag' & feasibilityFlag');
fprintf('Feasible map: %d non-zero points\n', sum(feasMap(:) > 0));

if any(feasMap(:))
    try
        % Create filled contour for feasible regions
        [~, h_feas] = contourf(MP_grid, NQ_grid, feasMap, [0.5 1], 'LineStyle', 'none');
        
        % Set transparency and color
        if ~isempty(h_feas.FacePrims)
            set(h_feas.FacePrims, 'FaceAlpha', 0.5); % 50% transparency
            h_feas.FaceColor = [0.2 0.8 0.3]; % Green color
        else
            % Fallback: use patch objects for feasible regions
            idx = find(feasMap > 0.5);
            if ~isempty(idx)
                [row, col] = ind2sub(size(feasMap), idx);
                mp_feas = mp_plot(col);
                nq_feas = nq_plot(row);
                scatter(mp_feas, nq_feas, 100, [0.2 0.8 0.3], 'filled', 'MarkerFaceAlpha', 0.5);
            end
        end
        
        % Add boundary contour for visibility
        contour(MP_grid, NQ_grid, feasMap, [0.5 0.5], ...
            'LineWidth', 1.5, 'Color', [0.0 0.6 0.2]);
    catch ME
        fprintf('Error plotting feasible regions: %s\n', ME.message);
        % Simple fallback: scatter plot
        idx = find(feasMap > 0.5);
        if ~isempty(idx)
            [row, col] = ind2sub(size(feasMap), idx);
            mp_feas = mp_plot(col);
            nq_feas = nq_plot(row);
            scatter(mp_feas, nq_feas, 80, [0.2 0.8 0.3], 'filled', 'MarkerFaceAlpha', 0.6);
        end
    end
else
    fprintf('No feasible regions to plot\n');
end

% Formatting
xlabel('m_p, %', 'FontSize', 12);
ylabel('n_q, %', 'FontSize', 12);
title('Unified Stability, Feasibility & Plugin-Safe Regions', 'FontSize', 14);
grid on;
axis tight;

% Custom legend for combined regions
legend_entries = {'Unstable', 'Stable', 'Certified with piecewise m(\omega)', 'Certified with the 5^{th} order filter m(s)'};
legend_handles = [];

% Base stability legend entries
legend_handles(1) = patch(NaN, NaN, [0.9 0.3 0.3], 'FaceAlpha', 1); % Unstable - red
legend_handles(2) = patch(NaN, NaN, [0.85 0.85 0.85], 'FaceAlpha', 1); % Stable - gray
legend_handles(3) = patch(NaN, NaN, [0.2 0.8 0.3], 'FaceAlpha', 0.4); % Feasible - green
legend_handles(4) = patch(NaN, NaN, [0.0 0.4 0.8], 'FaceAlpha', 0.4, ...
    'EdgeColor', [0.0 0.4 0.8], 'LineWidth', 2); % Combined plugin-safe - blue

legend(legend_handles, legend_entries, 'Location', 'eastoutside', 'FontSize', 10);


% ---------------- Save Results ----------------
resultsStab.mp_vec = mp_vec;
resultsStab.nq_vec = nq_vec;
resultsStab.stabilityFlag = stabilityFlag;
resultsStab.feasibilityFlag = feasibilityFlag;
resultsStab.feasibilityMargin = feasibilityMargin;

% Multi-filter results
resultsStab.filterSet = filterSet; % Store filter definitions
resultsStab.nu_values = nu_values; % Passivity indices for all filters (3D array)
resultsStab.pluginSafeFlag = pluginSafeFlag; % Plugin-safe flags for all filters (3D array)

% Stability analysis results
resultsStab.margin = margin; % maximum real part (negative => stable)
resultsStab.dominantEig = dominantEig;
resultsStab.tolerance = tol;
resultsStab.J_matrix = J; % Store the J matrix used for weighted passivity
resultsStab.w_passivity = w_passivity; % Frequency range used for passivity analysis
resultsStab.elapsed_seconds = elapsed_scan;

save('stability_region_mp_nq.mat','resultsStab');
fprintf('Comprehensive stability and passivity region data saved to stability_region_mp_nq.mat\n');

% Print comprehensive summary statistics
fprintf('\n=== COMPREHENSIVE ANALYSIS SUMMARY ===\n');
fprintf('Grid Resolution: %d × %d = %d points\n', Nmp, Nnq, Nmp*Nnq);
fprintf('Computation Time: %.2f seconds\n', elapsed_scan);

fprintf('\nStability Analysis:\n');
fprintf('  Stable points: %d/%d (%.1f%%)\n', sum(stabilityFlag(:)), numel(stabilityFlag), 100*mean(stabilityFlag(:)));

fprintf('\nFeasibility Analysis (filter-independent):\n');
stable_count = sum(stabilityFlag(:));
feasible_count = sum(feasibilityFlag(:));
fprintf('  Feasible points: %d/%d (%.1f%% of stable)\n', feasible_count, stable_count, 100*feasible_count/stable_count);
fprintf('  Mean safety margin: %.4f\n', nanmean(feasibilityMargin(feasibilityFlag)));
fprintf('  Min safety margin: %.4f\n', nanmin(feasibilityMargin(feasibilityFlag)));

fprintf('\nPlugin-Safe Analysis (filter-dependent):\n');
for kFilter = 1:nFilters
    pluginSafeFlag_flat = pluginSafeFlag(:,:,kFilter);
    plugin_count = sum(stabilityFlag(:) & pluginSafeFlag_flat(:));
    fprintf('  %s: %d/%d (%.1f%% of stable)\n', filterSet(kFilter).name, plugin_count, stable_count, 100*plugin_count/stable_count);
end

% Combined filter analysis
allFiltersWork = all(pluginSafeFlag, 3);
anyFilterWorks = any(pluginSafeFlag, 3);
allFiltersCount = sum(stabilityFlag(:) & allFiltersWork(:));
anyFilterCount = sum(stabilityFlag(:) & anyFilterWorks(:));

fprintf('\nCombined Filter Performance:\n');
fprintf('  At least one filter works: %d/%d (%.1f%% of stable)\n', anyFilterCount, stable_count, 100*anyFilterCount/stable_count);
fprintf('  All filters work: %d/%d (%.1f%% of stable)\n', allFiltersCount, stable_count, 100*allFiltersCount/stable_count);
fprintf('  Filter agreement ratio: %.1f%%\n', 100*allFiltersCount/max(anyFilterCount,1));




