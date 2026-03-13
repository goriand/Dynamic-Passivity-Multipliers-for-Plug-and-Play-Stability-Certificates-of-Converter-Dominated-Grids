%%
% This Differential model includes:
% Transmission line Model(pi)



% This machine is per unit
% Balanced assumptions are made.

%%
function [Y_Branch] = generate_RL_TL_TF(parameters,from_bus,to_bus)


%% Parameters
% [omega_s,R,X,tap] 
       w0=2*pi*50;
       
       omega_s=parameters(1);  

       R=parameters(2);
       X=parameters(3);
       t=parameters(4);
       
% Consider tap       
if t==0 %if ratio is zero, consider ratio as 1
    t=1;
end
    R_to_bus=R*t;
    X_to_bus=X*t;
    R_from_bus=R*t^2;
    X_from_bus=X*t^2;
    
   
    % L_to_bus=X_to_bus;
    % 
    % L_from_bus=X_from_bus;

    r_x_ratio=R_from_bus/X_from_bus;
%% Variable Names
Inputs=["Vd_","Vq_"]; % The input is voltage

line_num_str_array_inputs=string(from_bus*ones(1,length(Inputs)));% voltage at from bus
Input1=strcat(Inputs,line_num_str_array_inputs);
line_num_str_array_inputs=string(to_bus*ones(1,length(Inputs)));% voltage at from bus
Input2=strcat(Inputs,line_num_str_array_inputs);

Inputs=[Input1,Input2];


States=["Id_line_","Iq_line_"];
States=[strcat(States,string(from_bus*ones(1,length(States))),"_",string(to_bus*ones(1,length(States))))];


Outputs=["Id_line_","Iq_line_"];
Outputs=[strcat(Outputs,string(from_bus*ones(1,length(Outputs))),"_",string(to_bus*ones(1,length(Outputs)))),...%%inject
    strcat(Outputs,string(to_bus*ones(1,length(Outputs))),"_",string(from_bus*ones(1,length(Outputs))))];%%leave

%% RL line tf model

s=tf('s');

Branch=1/X_from_bus*[r_x_ratio+s*1/w0,-1;1, r_x_ratio+s*1/w0]^-1;
Y_Branch=[Branch,-Branch;-Branch,Branch];


Y_Branch.InputName=Inputs;
Y_Branch.OutputName=Outputs;

% inputs: "Vd_","Vq_"
% states: 'Id_line_','Iq_line_'
% outputs: 'Id_line_','Iq_line_','Id_line_','Iq_line_' (inject and leave)

end


