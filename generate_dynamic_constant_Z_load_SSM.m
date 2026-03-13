%%
% This Differential model includes:
% Load Model

%Load addittamce is calculated using constant power value and bus voltage


% This machine is per unit
% Balanced assumptions are made.

%%
function [Load] = generate_dynamic_constant_Z_load_SSM(parameters,initial_value,load_num)


%% Parameters
% [omega_s,R,X,tap] 
       w0=2*pi*60;
       
       omega_s=parameters(1); 
       P_load=parameters(2); 
       Q_load=parameters(3); 
%% Initial value
    R_load=initial_value(1);
    L_load=initial_value(2)/w0;
    Vd=initial_value(3);
    Vq=initial_value(4);
    Id_load=initial_value(5);
    Iq_load=initial_value(6);
%% Variable Names

Inputs=["Vd_","Vq_"]; %Input is current
loadbus_num_str_array_outputs=string(load_num*ones(1,length(Inputs)));
Inputs=strcat(Inputs,loadbus_num_str_array_outputs);

States=["Id_load_","Iq_load_"]; % The output is load current

load_num_str_array_inputs=string(load_num*ones(1,length(States)));% voltage at from bus
States=strcat(States,load_num_str_array_inputs);

Outputs=States;
%% Load_temp build
% Count in the load into the network martix

    Aload=zeros(2,2);
    Bload=zeros(2,4);
    Cload=[1,0;0,1];
    Dload=zeros(2,4);
    %A matrix
    
    Aload(1,1)=-R_load/L_load;Aload(1,2)=w0;
    Aload(2,1)=-w0;Aload(2,2)=-R_load/L_load;
    
    
    
    %B matrix
    Bload(1,1)=1/L_load; % Vdq for Id_load
    Bload(2,2)=1/L_load; % Vdq for Iq_load
    
    Bload(1,3)=-1/L_load*Id_load; Bload(1,4)=-Vd/(L_load^2)+R_load*Id_load/(L_load^2);% R,L for Id_load
    Bload(2,3)=-1/L_load*Iq_load; Bload(2,4)=-Vq/(L_load^2)+R_load*Iq_load/(L_load^2);
    
    
    
Load=ss(Aload,Bload,Cload,Dload,'InputName',[Inputs],'OutputName',Outputs,...
                 'StateName', States);    
% Inputs: "Vd_","Vq_","Rload_","Lload_" 
% Outputs: "Id_load_", "Iq_load_"
% Outputs: "Id_load_", "Iq_load_"
% %% Load_temp build
% % Count in the load into the network martix
% 
%     Aimpdeance=[0];
%     Bimpdeance=[0,0];
%     Cimpdeance=[0;0];
%     Dimpdeance=zeros(2,2);
% 
% Dimpdeance(1,1)=Vd*2*P_load/(P_load^2+Q_load^2);%Vd for Rload
% Dimpdeance(1,2)=Vq*2*P_load/(P_load^2+Q_load^2);%Vq
% 
% Dimpdeance(2,1)=Vd*2*Q_load/(P_load^2+Q_load^2)/w0;%Vd for Lload
% Dimpdeance(2,2)=Vq*2*Q_load/(P_load^2+Q_load^2)/w0;%Vq
% 
% 
% Load_impedance=ss(Aimpdeance,Bimpdeance,Cimpdeance,Dimpdeance,'InputName',Inputs,'OutputName',[strcat("Rload",num2str(load_num)),strcat("Lload",num2str(load_num))]);
% 
% % Inputs: "Vd_","Vq_"
% % Outputs: "Rload_","Lload_" 
% 
% 
% Load=connect(Load_current,Load_impedance,...
%     Inputs,Outputs);

% Inputs: "Vd_","Vq_"
% Outputs: "Id_load_", "Iq_load_"
% States: "Vd_","Vq_"
end


