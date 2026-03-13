%%
% This Differential model includes:
% Transmission line Model(pi)



% This machine is per unit
% Balanced assumptions are made.

%%
function [Y_C] = generate_shunt_C_TF(parameters,cap_bus)


%% Parameters
% [omega_s,R,X,tap] 
       w0=2*pi*50;
       
       omega_s=parameters(1);  
       Bc=parameters(2);
       
       Cf=Bc/w0;%Chnage into Cf
       

%% Variable Names
Inputs=["Vd_","Vq_"]; % The input is voltage

line_num_str_array_inputs=string(cap_bus*ones(1,length(Inputs)));% voltage at from bus
Input1=strcat(Inputs,line_num_str_array_inputs);


Inputs=[Input1];


States=["Id_cap_","Iq_cap_"];
States1=[strcat(States,string(cap_bus*ones(1,length(States))))];

States=[States1];

Outputs=States;

%% RL line tf model

s=tf('s');

Shunt_C=[s*Cf,-w0*Cf;w0*Cf, s*Cf];
Y_C=[Shunt_C];



Y_C.InputName=Inputs;
Y_C.OutputName=Outputs;

% inputs: "Vd_","Vq_"
% states: 'Id_line_','Iq_line_'
% outputs: 'Id_line_','Iq_line_','Id_line_','Iq_line_' (inject and leave)

end


