% clear all
% close all

function [Init,results,param,location]= Initilization(gfm_conn_buses)

% Coupling Impedance parameters
rc = 0.01; % pu
xc = 0.015; % pu

NGFM_add=size(gfm_conn_buses,1);

dyn_buses=[100]'; % Dynamic network model
GFM_locations=[35:35+NGFM_add-1]';
GFL_locations=[];
Gen_locations=[];
net=case39;






line_add=repmat(net.branch(1,:),NGFM_add,1);
line_add(:,1:5)=zeros(NGFM_add,5);
line_add(:,1)=GFM_locations;
line_add(:,2)=gfm_conn_buses;
line_add(:,3)=rc*ones(NGFM_add,1);
line_add(:,4)=xc*ones(NGFM_add,1);

net.branch=[net.branch;line_add];


bus_add=repmat(net.bus(1,:),NGFM_add,1);
bus_add(:,1)=GFM_locations;
bus_add(:,2)=2*ones(NGFM_add,1);
net.bus=[net.bus;bus_add];



gen_add=repmat(net.gen(1,:),NGFM_add,1);
gen_add(:,1)=GFM_locations;
gen_add(:,2)=600*ones(NGFM_add,1);
gen_add(:,3)=200*ones(NGFM_add,1);
gen_add(:,4)=2000*ones(NGFM_add,1);
gen_add(:,5)=-2000*ones(NGFM_add,1);
gen_add(:,6)=ones(NGFM_add,1);
net.gen=[net.gen;gen_add];


gencost_add=repmat(net.gencost(1,:),NGFM_add,1);
net.gencost=[net.gencost;gencost_add];

mpopt = mpoption('verbose', 0, 'model', 'AC');
mpopt = mpoption(mpopt, 'out.all', 0);



results = runpf(net, mpopt);

gfm_conn_buses=[6;32; gfm_conn_buses];

if ~(results.success) 
    error('Power flow did not converge. Please check the system data or solver settings.');
elseif NGFM_add~=8
error('Number of GFM is not 10');

end



slac_bus=find(results.bus(:,2)==3); %Find the slack bus and set it as gen
results.bus(slac_bus,2)=2;

%% Initilization 
Busdata=results.bus;
[row,~]=size(Busdata);
num_buses=row; %Bus number
Ty=Busdata(1:row,1:2); %Type of Bus
Vm=Busdata(:,8);
Va=Busdata(:,9);
Va=deg2rad(Va);

MVAbase=results.baseMVA;

Gen=results.gen;




%% dermine thetaref

thetaref=0;


%% Inner Bus voltage
vD_bus=zeros(num_buses,1);
vQ_bus=zeros(num_buses,1);
for i=1:num_buses
k=find(Busdata(i,1)==Ty(:,1));
vD_bus(i)=Vm(k)*cos(Va(k)-thetaref);
vQ_bus(i)=Vm(k)*sin(Va(k)-thetaref);

end

%% Load current &impedance

num_loads=0;load_location=[];P_load=[];Q_load=[];

for i=1:num_buses
    if(Busdata(i,3)~=0||Busdata(i,4)~=0)      
        num_loads=num_loads+1;
        load_location=[load_location;Busdata(i,1)];
        P_load=[P_load;Busdata(i,3)/MVAbase];
        Q_load=[Q_load;Busdata(i,4)/MVAbase];
    end
end

G_load=[];B_load=[];
R_load=[];L_load=[];
iD_load=[];iQ_load=[];
load_location_Sta=[];load_location_Dyn=[];
for i=1:num_loads
    if ismember(load_location(i,1),dyn_buses)
        k=find(load_location(i,1)==Ty(:,1));
        V=Vm(k)*exp(1i*Va(k));
        Iload=(P_load(i)-1i*Q_load(i))/conj(V);
        Zload=V/Iload;
        R_load=[R_load;real(Zload)];L_load=[L_load;imag(Zload)];
        angleI=angle(Iload);
        magI=abs(Iload);
        iD_load=[iD_load;magI*cos(angleI-thetaref)];
        iQ_load=[iQ_load;magI*sin(angleI-thetaref)];
        load_location_Dyn=[load_location_Dyn;load_location(i,1)];
    else
        k=find(load_location(i,1)==Ty(:,1));
        G_load=[G_load;P_load(i)/(Vm(k)^2)];B_load=[B_load;-Q_load(i)/(Vm(k)^2)];
        load_location_Sta=[load_location_Sta;load_location(i,1)];
    end
end
%% Build up Xc list
Bc=zeros(num_buses,1);
[num_lines,~]=size(results.branch);
for i=1:num_lines
    k=find((results.branch(i,1)==Busdata(:,1)));
    Bc(k)=Bc(k)+results.branch(i,5)/2;
    
    k=find((results.branch(i,2)==Busdata(:,1)));
    Bc(k)=Bc(k)+results.branch(i,5)/2;
end
for i=1:num_buses
    Bc(i)=Bc(i)+Busdata(i,6)/MVAbase;
end




% load data4.mat
% 
% Bc(30:39)=Bc(30:39)+Cf;
% 
% Bc(find(0==Bc))=0.1;%% Incase there is bus without capcitor
% Bc=Bc+1e-10;
%% Initilize GFL
% GFL_locations=[4];

num_GFL=size(GFL_locations,1);
delta0_GFL=zeros(num_GFL,1);
IoD0_GFL=zeros(num_GFL,1);
IoQ0_GFL=zeros(num_GFL,1);
Iod0_GFL=zeros(num_GFL,1);
Ioq0_GFL=zeros(num_GFL,1);
Vod0_GFL=zeros(num_GFL,1);
Voq0_GFL=zeros(num_GFL,1);
VbD0_GFL=zeros(num_GFL,1);
VbQ0_GFL=zeros(num_GFL,1);

VoD0_GFL=zeros(num_GFL,1);
VoQ0_GFL=zeros(num_GFL,1);
for i=1:num_GFL
    
    k=find(Gen(:,1)==GFL_locations(i));
    delta0_GFL(i)=Va(GFL_locations(i))-thetaref;
    V=Vm(GFL_locations(i))*exp(1i*Va(GFL_locations(i)));
    Pg=Gen(k,2)/MVAbase;
    Qg=Gen(k,3)/MVAbase;
    I=(Pg-1i*Qg)/conj(V);
    angleI=angle(I);
    magI=abs(I);
    IoD0_GFL(i)=magI*cos(angleI);
    IoQ0_GFL(i)=magI*sin(angleI);
    Iod0_GFL(i)=IoD0_GFL(i)*cos(delta0_GFL(i))+IoQ0_GFL(i)*sin(delta0_GFL(i));
    Ioq0_GFL(i)=-IoD0_GFL(i)*sin(delta0_GFL(i))+IoQ0_GFL(i)*cos(delta0_GFL(i));

    VoD0=vD_bus(GFL_locations(i));
    VoQ0=vQ_bus(GFL_locations(i));

    Vod0_GFL(i)=VoD0*cos(delta0_GFL(i))+VoQ0*sin(delta0_GFL(i));
    Voq0_GFL(i)=-VoD0*sin(delta0_GFL(i))+VoQ0*cos(delta0_GFL(i));


    [row, col] = find(results.branch == GFL_locations(i), 1);

    no_bus_gfl = results.branch(row, 3 - col);% Find the bus that connect to the converter

    VbD0_GFL(i)=vD_bus(no_bus_gfl);
    VbQ0_GFL(i)=vQ_bus(no_bus_gfl);
    VoD0_GFL(i)=vD_bus(GFL_locations(i));
    VoQ0_GFL(i)=vQ_bus(GFL_locations(i));

end

%% Initilize GFM
% GFM_locations=[1];
num_GFM=size(GFM_locations,1);
delta0_GFM=zeros(num_GFM,1);
IoD0_GFM=zeros(num_GFM,1);
IoQ0_GFM=zeros(num_GFM,1);
Iod0_GFM=zeros(num_GFM,1);
Ioq0_GFM=zeros(num_GFM,1);
Vod0_GFM=zeros(num_GFM,1);
Voq0_GFM=zeros(num_GFM,1);
VbD0_GFM=zeros(num_GFL,1);
VbQ0_GFM=zeros(num_GFL,1);
VoD0_GFM=zeros(num_GFL,1);
VoQ0_GFM=zeros(num_GFL,1);
for i=1:num_GFM
    
    k=find(Gen(:,1)==GFM_locations(i));
    delta0_GFM(i)=Va(GFM_locations(i))-thetaref;
    V=Vm(GFM_locations(i))*exp(1i*Va(GFM_locations(i)));
    Pg=Gen(k,2)/MVAbase;
    Qg=Gen(k,3)/MVAbase;
    I=(Pg-1i*Qg)/conj(V);
    angleI=angle(I);
    magI=abs(I);
    IoD0_GFM(i)=magI*cos(angleI);
    IoQ0_GFM(i)=magI*sin(angleI);
    Iod0_GFM(i)=IoD0_GFM(i)*cos(delta0_GFM(i))+IoQ0_GFM(i)*sin(delta0_GFM(i));
    Ioq0_GFM(i)=-IoD0_GFM(i)*sin(delta0_GFM(i))+IoQ0_GFM(i)*cos(delta0_GFM(i));

    VoD0=vD_bus(GFM_locations(i));
    VoQ0=vQ_bus(GFM_locations(i));

    Vod0_GFM(i)=VoD0*cos(delta0_GFM(i))+VoQ0*sin(delta0_GFM(i));
    Voq0_GFM(i)=-VoD0*sin(delta0_GFM(i))+VoQ0*cos(delta0_GFM(i));


    [row, col] = find(results.branch == GFM_locations(i), 1);

    no_bus_gfm = results.branch(row, 3 - col);% Find the bus that connect to the converter

    VbD0_GFM(i)=vD_bus(no_bus_gfm);
    VbQ0_GFM(i)=vQ_bus(no_bus_gfm);
    VoD0_GFM(i)=vD_bus(GFM_locations(i));
    VoQ0_GFM(i)=vQ_bus(GFM_locations(i));

end
%%
loc_GFM = arrayfun(@(x) find(results.bus(:,1) == x, 1, 'first'), GFM_locations, 'UniformOutput', true);
loc_GFL = arrayfun(@(x) find(results.bus(:,1) == x, 1, 'first'), GFL_locations, 'UniformOutput', true);

param = ini_ibr_param(results, num_GFM, num_GFL, GFM_locations, GFL_locations);

Bc([loc_GFM;loc_GFL])=Bc([loc_GFM;loc_GFL])+[param.Bf_GFM;param.Bf_GFL];

% load data.mat
% Bc(30:39)=Bc(30:39)+Cf;
Bc(find(0==Bc))=0.1;%% Incase there is bus without capcitor
% Bc=Bc+1e-10;
param.Bc = Bc;
%% Initial value
% Inti=[delta0_GFL;Vod0_GFL;Voq0_GFL;IoD0_GFL;IoQ0_GFL;Iod0_GFL;Ioq0_GFL;VbD0_GFL;VbQ0_GFL;...
     % delta0_GFM;Vod0_GFM;Voq0_GFM;IoD0_GFM;IoQ0_GFM;Iod0_GFM;Ioq0_GFM;VbD0_GFM;VbQ0_GFM];


rowNames.vsc={'delta0','Vod0','Voq0','IoD0','IoQ0','Iod0','Ioq0','VbD0','VbQ0','VoD0','VoQ0'}; 
% Place GFL_data and GFM_data each on a single line, using semicolons between signals:
GFL_data = {delta0_GFL; Vod0_GFL; Voq0_GFL; IoD0_GFL; IoQ0_GFL; Iod0_GFL; Ioq0_GFL; VbD0_GFL; VbQ0_GFL; VoD0_GFL; VoQ0_GFL}; 
GFM_data = {delta0_GFM; Vod0_GFM; Voq0_GFM; IoD0_GFM; IoQ0_GFM; Iod0_GFM; Ioq0_GFM; VbD0_GFM; VbQ0_GFM; VoD0_GFM; VoQ0_GFM};

% Build the table
Init.vsc=table(GFL_data,GFM_data,'VariableNames',{'GFL','GFM'},'RowNames',rowNames.vsc);

%%-------- II. Load sub-table --------------------------------------------
rowNames.load = {'P','Q','iD','iQ', 'G', 'B'};

load_data = {P_load; Q_load; iD_load; iQ_load; G_load; B_load};

Init.load = table(load_data , ...
                  'VariableNames',{'value'}, ...
                  'RowNames',     rowNames.load);

%%-------- III. Bus sub-table --------------------------------------------
rowNames.bus = {'vD','vQ'};

bus_data = {vD_bus; vQ_bus};

Init.bus  = table(bus_data , ...
                  'VariableNames',{'value'}, ...
                  'RowNames',     rowNames.bus);


%%
location = struct('GFM', [], 'GFL', [], 'Gen', [], 'Load', []);
location.GFM=GFM_locations;
location.GFL=GFL_locations;
location.Gen=Gen_locations;
location.Load=load_location;


%%


end