function param = ini_ibr_param(results, num_GFM, num_GFL, GFM_locations, GFL_locations)
%INI_IBR_PARAM  Initialise IBR parameters and return as a struct.
% Scalars (Tm, Tc, Tp) remain numeric; per-unit parameters are vectors.

% ------------------- constants -------------------
fd  = 50;     % Hz
fc  = 500;    % Hz
w0  = 2*pi*50;
fm  = 20;     % Hz
fp  = 100;    % Hz

Tc = 1/(2*pi*fc);
Tm = 1/(2*pi*fm);
Tp = 1/(2*pi*fp);

% ------------------- GFM parameters (locals) -------------------
Bf_GFM  = zeros(num_GFM,1);
Kpd_GFM = zeros(num_GFM,1);
Kid_GFM = zeros(num_GFM,1);
Kiq_GFM = zeros(num_GFM,1);
Dp      = zeros(num_GFM,1);
Dq      = zeros(num_GFM,1);

for i = 1:num_GFM
    k = find(GFM_locations(i) == results.gen(:,1), 1, 'first');
    P_GFM = results.gen(k,2) ./ results.baseMVA;   % pu

    Bf_GFM(i)  = 0.2 * P_GFM / 0.9;
    Kpd_GFM(i) = (Bf_GFM(i)/w0) * (2*pi*fd);

    Kid_GFM(i) = 0;
    Kiq_GFM(i) = 0;

    Dp(i) = 0.01 * w0 / P_GFM;
    Dq(i) = 0.01 / (P_GFM * tan(acos(0.9)));
end

% ------------------- GFL parameters (locals) -------------------
Bf_GFL = zeros(num_GFL,1);
Kp_PLL = zeros(num_GFL,1);
Ki_PLL = zeros(num_GFL,1);
Kp_P   = zeros(num_GFL,1);
Ki_P   = zeros(num_GFL,1);
Kp_V   = zeros(num_GFL,1);
Ki_V   = zeros(num_GFL,1);

fpll = 20;    % PLL bandwidth [Hz]
zeta = 0.9;   % damping
fp_p = 20;    % P-loop crossover [Hz]
xg   = 0.5;   % virtual line reactance
fv   = 20;    % V-loop crossover [Hz]

wbw = 2*pi*fpll;
wn  = wbw .* sqrt( 2 ./ ( sqrt((4*zeta.^2+2).^2 + 4) + 4*zeta.^2 + 2 ) );

for i = 1:num_GFL
    k = find(GFL_locations(i) == results.gen(:,1), 1, 'first');
    P_GFL = results.gen(k,2) ./ results.baseMVA;   % pu

    Bf_GFL(i) = 0.02 * P_GFL / 0.9;

    % PLL gains (type-2)
    Kp_PLL(i) = -2 .* zeta .* wn;
    Ki_PLL(i) = -wn.^2;

    % P (active power) loop
    Kp_P(i) = fp_p ./ fc;
    Ki_P(i) = 2*pi .* fp_p;

    % V (voltage) loop
    Kp_V(i) = -fv ./ (fc .* xg);
    Ki_V(i) = -(2*pi*fv) ./ xg;  % uses fv by design
end

% ------------------- construct the output struct -------------------
param = struct( ...
    'Tm', Tm, ...
    'Tc', Tc, ...
    'Tp', Tp, ...
    'Bf_GFM',  Bf_GFM, ...
    'Kpd_GFM', Kpd_GFM, ...
    'Kid_GFM', Kid_GFM, ...
    'Kiq_GFM', Kiq_GFM, ...
    'Dp',      Dp, ...
    'Dq',      Dq, ...
    'Bf_GFL',  Bf_GFL, ...
    'Kp_PLL',  Kp_PLL, ...
    'Ki_PLL',  Ki_PLL, ...
    'Kp_P',    Kp_P, ...
    'Ki_P',    Ki_P, ...
    'Kp_V',    Kp_V, ...
    'Ki_V',    Ki_V ...
);

end
