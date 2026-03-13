%%
% This Differential model includes:
% Bus Model

% This machine is per unit
% Balanced assumptions are made.

%%
function [Bus] = generate_shunt_C_SSM(parameters,bus_num,SM_location,GFL_location,GFM_location,load_location,line_leave_location,line_inject_location)

%% Parameters
% [omega_s,R,X,tap] 
       w0=2*pi*50;
       
       omega_s=parameters(1);  
       Bc=parameters(2);
       
       Cf=Bc/w0;%Chnage into Cf
%% Variable Names

Outputs=["Vd_","Vq_"]; % The output is voltage

bus_num_str_array_inputs=string(bus_num*ones(1,length(Outputs)));% voltage at from bus
Outputs=strcat(Outputs,bus_num_str_array_inputs);

States=Outputs;
% %% Check what is connected to the bus
% % Step 1: Input data
% MVABase=network.baseMVA;
% Busdata=network.bus;
% Linedata=network.branch;
% 
% [row,~]=size(Busdata);
% Nb=row; %Bus number
% [row,~]=size(Linedata);
% Nline=row; %line number
% 
% Bload=[];P_load0=[];Q_load0=[];Nload=0;
% 
% 
% for i=1:Nb %Check where is load
%     if(Busdata(i,3)~=0||Busdata(i,4)~=0)
%         Nload=Nload+1;
%         Bload=[Bload;Busdata(i,1)];
%         P_load0=[P_load0;Busdata(i,3)/MVABase];
%         Q_load0=[Q_load0;Busdata(i,4)/MVABase];
% 
%     end
%  
% end
% Macdata=network.gendy;
% %Generator parameter
% [row,~]=size(Macdata);
% Ng=row; %Number of generator 
% Bg=Macdata(:,1); %Generator bus

% Step2 Check

%     num_SM=find(num_bus==(Bg(:,1)));% Check SG
%     
%     num_load=find(num_bus==Bload(:,1));%Check Load
%     
%     num_line1=find(num_bus==Linedata(:,1));%Check Line from bus
%     num_line2=find(num_bus==Linedata(:,2));%Check Line to bus

% Create Inputs
Inputs_SM=["Id_SM_","Iq_SM_"]; 
Inputs_SM_1=[];
[N_SM,~]=size(SM_location);
for i=1:N_SM

SM_num_str_array_inputs=string(SM_location(i)*ones(1,length(Inputs_SM)));
Inputs_SM_0=strcat(Inputs_SM,SM_num_str_array_inputs);
Inputs_SM_1=[Inputs_SM_1,Inputs_SM_0];
end
Inputs_SM=Inputs_SM_1;
%
Inputs_GFL=["Id_GFL_","Iq_GFL_"]; 
Inputs_GFL_1=[];
[N_GFL,~]=size(GFL_location);
for i=1:N_GFL

SM_num_str_array_inputs=string(GFL_location(i)*ones(1,length(Inputs_GFL)));
Inputs_GFL_0=strcat(Inputs_GFL,SM_num_str_array_inputs);
Inputs_GFL_1=[Inputs_GFL_1,Inputs_GFL_0];
end
Inputs_GFL=Inputs_GFL_1;
%
Inputs_GFM=["Id_GFM_","Iq_GFM_"]; 
Inputs_GFM_1=[];
[N_GFM,~]=size(GFM_location);
for i=1:N_GFM

GFM_num_str_array_inputs=string(GFM_location(i)*ones(1,length(Inputs_GFM)));
Inputs_GFM_0=strcat(Inputs_GFM,GFM_num_str_array_inputs);
Inputs_GFM_1=[Inputs_GFM_1,Inputs_GFM_0];
end
Inputs_GFM=Inputs_GFM_1;
%
Inputs_load=["Id_load_","Iq_load_"]; 
Inputs_load_1=[];
[N_load,~]=size(load_location);
for i=1:N_load

load_num_str_array_inputs=string(load_location(i)*ones(1,length(Inputs_load)));
Inputs_load_0=strcat(Inputs_load,load_num_str_array_inputs);
Inputs_load_1=[Inputs_load_1,Inputs_load_0];
end
Inputs_load=Inputs_load_1;

%
Inputs_line_leave=["Id_line_","Iq_line_"]; 
Inputs_line1_1=[];
[N_line_leave,~]=size(line_leave_location);
for i=1:N_line_leave


Inputs_line1_0=strcat(Inputs_line_leave,string(line_leave_location(i,1)*ones(1,length(Inputs_line_leave))),...
    "_",string(line_leave_location(i,2)*ones(1,length(Inputs_line_leave))));
Inputs_line1_1=[Inputs_line1_1,Inputs_line1_0];
end
Inputs_line_leave=Inputs_line1_1;

%
Inputs_line_inject=["Id_line_","Iq_line_"];
Inputs_line2_1=[];
[N_line_inject,~]=size(line_inject_location);
for i=1:N_line_inject
Inputs_line2_0=strcat(Inputs_line_inject,string(line_inject_location(i,2)*ones(1,length(Inputs_line_inject))),...
    "_", string(line_inject_location(i,1)*ones(1,length(Inputs_line_inject))));%% For line inject, the name is reserved and ...
                                                                                % the current diretion is determined in line building model

Inputs_line2_1=[Inputs_line2_1,Inputs_line2_0];
end
Inputs_line_inject=Inputs_line2_1;

Inputs=[Inputs_SM,Inputs_GFL,Inputs_GFM,Inputs_load,Inputs_line_leave,Inputs_line_inject];

%% Pi Line model 
A=zeros(1,1);
B=zeros(1,2*(N_SM+N_GFL+N_GFM+N_load+N_line_leave+N_line_inject));
C=zeros(2,1);
D=zeros(2,2*(N_SM+N_GFL+N_GFM+N_load+N_line_leave+N_line_inject));

%/Inject is negative and leaving is positive
% Output 1: Id_sum 
for i=1:N_SM
D(1,2*i-1)=-1;
end

for i=1:N_GFL
D(1,2*N_SM+2*i-1)=-1;
end

for i=1:N_GFM
D(1,2*N_SM+2*N_GFL+2*i-1)=-1;
end

for i=1:N_load
D(1,2*N_SM+2*N_GFL+2*N_GFM+2*i-1)=1;
end

for i=1:N_line_leave
D(1,2*N_SM+2*N_GFL+2*N_GFM+2*N_load+2*i-1)=1;
end

for i=1:N_line_inject
D(1,2*N_SM+2*N_GFL+2*N_GFM+2*N_load+2*N_line_leave+2*i-1)=1;%% Since the name is reserved, so it is positive 1 here
end


% Output 2: Iq_sum
for i=1:N_SM
D(2,2*i)=-1;
end
for i=1:N_GFL
D(2,2*N_SM+2*i)=-1;
end
for i=1:N_GFM
D(2,2*N_SM+2*N_GFL+2*i)=-1;
end

for i=1:N_load
D(2,2*N_SM+2*N_GFL+2*N_GFM+2*i)=1;
end

for i=1:N_line_leave
D(2,2*N_SM+2*N_GFL+2*N_GFM+2*N_load+2*i)=1;
end

for i=1:N_line_inject
D(2,2*N_SM+2*N_GFL+2*N_GFM+2*N_load+2*N_line_leave+2*i)=1;
end

D=-D;
Current_sum=ss(A,B,C,D,'InputName',Inputs,'OutputName',["Id_sum","Iq_sum"]);
% inputs:  'Id_SM_','Iq_SM_','Id_GFL_','Iq_GFL_','Id_GFM_','Iq_GFM_','Id_load_','Iq_load_''Id_line_','Iq_line_'
% outputs: 'Id_sum','Iq_sum'


% Calvlt

A=zeros(2,2);
B=zeros(2,2);
C=[1,0;0,1];
D=zeros(2,2);

%A martix
%For Vd_
A(1,2)=w0;%Vq_

% for Vq_
A(2,1)=-w0;%Vd_


%B martix

B(1,1)=1/Cf;%Id_sum

B(2,2)=1/Cf;%Iq_sum
Current=ss(A,B,C,D,'InputName',["Id_sum","Iq_sum"],'OutputName',Outputs,'StateName',States);
% inputs: 'Id_sum','Iq_sum'
% outputs: "Vd_","Vq_"
% states: "Vd_","Vq_"

Bus=connect(Current_sum,Current,...
    Inputs,Outputs);

% inputs: 'Id_SM_','Iq_SM_','Id_GFL_','Iq_GFL_','Id_GFM_','Iq_GFM_','Id_load_','Iq_load_''Id_line_','Iq_line_'
% outputs: "Vd_","Vq_"
% states: "Vd_","Vq_"
end


