%%
% This Algebraic model includes:
% Load Model

%Load addittamce is calculated using constant power value and bus voltage


% This machine is per unit
% Balanced assumptions are made.

%%
function [Load] = generate_dynamic_constant_Z_load_algebraic(parameters,initial_value,load_num)


%% Parameters
% [omega_s,R,X,tap] 
       w0=2*pi*50;
       omega_s=parameters(1); 
       P_load=parameters(2); 
       Q_load=parameters(3);
       alpha_load=parameters(4);
       beta_load=parameters(5);
       gamma_load=parameters(6);
%% Initial value
    G_load=initial_value(1);
    B_load=initial_value(2);
    Vd0=initial_value(3);
    Vq0=initial_value(4);
    V0=sqrt(Vd0^2+Vq0^2);
%% Variable Names

Inputs=["Vd_","Vq_"]; %Input is current
loadbus_num_str_array_outputs=string(load_num*ones(1,length(Inputs)));
Inputs=strcat(Inputs,loadbus_num_str_array_outputs);

Outputs=["Id_load_","Iq_load_"]; % The output is load current

load_num_str_array_inputs=string(load_num*ones(1,length(Outputs)));% voltage at from bus
Outputs=strcat(Outputs,load_num_str_array_inputs);


%% Load_temp build
% Count in the load into the network martix

    Aload=[0];
    Bload=[0,0];
    Cload=[0;0];
    Dload=zeros(2,2);
    
    % Dload(1,1)=G_load; Dload(1,2)=-B_load;% Vdq for Id_load
    % Dload(2,1)=B_load; Dload(2,2)=G_load;% Vdq for Iq_load

    Dload(1,1)=alpha_load*P_load/(V0^2)+beta_load*(Vq0^2*P_load/(V0^1.5))+gamma_load*((1-2*Vd0)*P_load/(V0^4)); % d Id_laod/ d Vd
    Dload(1,2)=alpha_load*Q_load/(V0^2)+beta_load*(Vd0^2*Q_load/(V0^1.5))+gamma_load*((Q_load-2*Vq0*P_load)/(V0^4));% d Id_load / d Vq

    Dload(2,1)=alpha_load*-Q_load/(V0^2)+beta_load*(-Vq0^2*Q_load/(V0^1.5))+gamma_load*(-(1-2*Vd0)*Q_load/(V0^4)); % d Iq_laod/ d Vd

    Dload(2,2)=alpha_load*P_load/(V0^2)+beta_load*(Vd0^2*P_load/(V0^1.5))+gamma_load*((P_load+2*Vq0*Q_load)/(V0^4));% d Iq_load / d Vq
    

    
%     Dload(1,3)=Vd; Dload(1,4)=-Vq;% G,B for Id_load
%     Dload(2,3)=Vq; Dload(2,4)=Vd;
% 
Load=ss(Aload,Bload,Cload,Dload,'InputName',[Inputs],'OutputName',Outputs);    
% Inputs: "Vd_","Vq_","Gload_","Bload_" 
% Outputs: "Id_load_", "Iq_load_"
% %% Load_temp build
% % Count in the load into the network martix
% 
%     Aimpdeance=[0];
%     Bimpdeance=[0,0];
%     Cimpdeance=[0;0];
%     Dimpdeance=zeros(2,2);
% 
% Dimpdeance(1,1)=-Vd*2*P_load/(Vd^2+Vq^2)^2;%Vd for Gload
% Dimpdeance(1,2)=-Vq*2*P_load/(Vd^2+Vq^2)^2;%Vq
% 
% Dimpdeance(2,1)=Vd*2*Q_load/(Vd^2+Vq^2)^2;%Vd for Bload
% Dimpdeance(2,2)=Vq*2*Q_load/(Vd^2+Vq^2)^2;%Vq
% 
% 
% Load_impedance=ss(Aimpdeance,Bimpdeance,Cimpdeance,Dimpdeance,'InputName',Inputs,'OutputName',[strcat("Gload",num2str(load_num)),strcat("Bload",num2str(load_num))]);
% 
% % Inputs: "Vd_","Vq_"
% % Outputs: "Gload_","Bload_" 
% 
% 
% Load=connect(Load_current,Load_impedance,...
%     Inputs,Outputs);
% 
% % Inputs: "Vd_","Vq_"
% % Outputs: "Id_load_", "Iq_load_"
% end


