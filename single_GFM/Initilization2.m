% clear all
% close all

function [Inti,results]= Initilization2(Pg,Sload,Zc)

mpopt = mpoption('verbose', 0, 'model', 'AC');
mpopt = mpoption(mpopt, 'out.all', 0);



net=case3;
net.gen(2,2)=Pg;

net.bus(2,3)=real(Sload);
net.bus(2,4)=imag(Sload);

net.branch(1,3)=real(Zc);
net.branch(1,4)=imag(Zc);


results = runpf(net, mpopt);



%% Initilization 
Busdata=results.bus;
[row,~]=size(Busdata);
num_buses=row; %Bus number
Ty=Busdata(1:row,1:2); %Type of Bus
Vm=Busdata(:,8);
Va=Busdata(:,9);
Va=deg2rad(Va);

MVAbase=results.baseMVA;

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



%% Initilize GFL
GFL_locations=[3];
Gen=results.gen;
num_GFL=size(GFL_locations,1);
delta0=zeros(num_GFL,1);
IoD0=zeros(num_GFL,1);
IoQ0=zeros(num_GFL,1);
Iod0=zeros(num_GFL,1);
Ioq0=zeros(num_GFL,1);
Vod0=zeros(num_GFL,1);
Voq0=zeros(num_GFL,1);
for i=1:num_GFL
    
    k=find(Gen(:,1)==GFL_locations(i));
    delta0(i)=Va(GFL_locations(i))-thetaref;
    V=Vm(GFL_locations(i))*exp(1i*Va(GFL_locations(i)));
    Pg=Gen(k,2)/MVAbase;
    Qg=Gen(k,3)/MVAbase;
    I=(Pg-1i*Qg)/conj(V);
    angleI=angle(I);
    magI=abs(I);
    IoD0(i)=magI*cos(angleI);
    IoQ0(i)=magI*sin(angleI);
    Iod0(i)=IoD0(i)*cos(delta0(i))+IoQ0(i)*sin(delta0(i));
    Ioq0(i)=-IoD0(i)*sin(delta0(i))+IoQ0(i)*cos(delta0(i));

    VoD0=vD_bus(GFL_locations(i));
    VoQ0=vQ_bus(GFL_locations(i));

    Vod0(i)=VoD0*cos(delta0(i))+VoQ0*sin(delta0(i));
    Voq0(i)=-VoD0*sin(delta0(i))+VoQ0*cos(delta0(i));


    [row, col] = find(results.branch == GFL_locations(i), 1);

    k = results.branch(row, 3 - col);% Find the bus that connect to the converter

    VbD0=vD_bus(k);
    VbQ0=vQ_bus(k);

end


%% Initial value
Inti=[delta0;Vod0;Voq0;IoD0;IoQ0;Iod0;Ioq0;VbD0;VbQ0];
end