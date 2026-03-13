%%
% This Differential model includes:
% Transmission line Model(pi)



% This machine is per unit
% Balanced assumptions are made.

%%
function [Branch] = generate_RL_TL_SSM(parameters,from_bus,to_bus)


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
    
   
    L_to_bus=X_to_bus/w0;
    
    L_from_bus=X_from_bus/w0;
    
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
%% Pi Line model 
A=zeros(2,2);
B=zeros(2,4);
C=[eye(2); -eye(2)];
D=zeros(4,4);

%A matrix

A(1,1)=-R_from_bus/L_from_bus;A(1,2)=w0;%Id_line_
A(2,1)=-w0;A(2,2)=-R_from_bus/L_from_bus;%Iq_line_

%B matrix
% State 1: Id_line_
B(1,1)=1/L_from_bus;%Vd,_frombus
B(1,3)=-1/L_to_bus;%Vd,_tobus

% State 2: Iq_line_
B(2,2)=1/L_from_bus;%Vq_frombus
B(2,4)=-1/L_to_bus;%Vq_tobus


Branch=ss(A,B,C,D,'InputName',Inputs,'OutputName',Outputs,'StateName',States);
% inputs: "Vd_","Vq_"
% states: 'Id_line_','Iq_line_'
% outputs: 'Id_line_','Iq_line_','Id_line_','Iq_line_' (inject and leave)

end


