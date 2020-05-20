%Scripts for generating data shown in Orella et al.

close
clear all

%Define some constants to use throughout the script
NUM_X_POINTS = 100;
FONT_SIZE = 10;
WIDTH = 3.5;
HEIGHT = 3.5;
LINE_WIDTH = 1.0;
BLACK = [0 0 0];
RED = [206.04 59.16 59.16]/255;

%Some nice colors to use
hslColors = [   0       127.5       0;
                7.65    145.35      7.65;
                17.85   160.65      17.85;
                30.6    173.4       30.6;
                45.9    183.6       45.9;
                63.75   191.25      63.75;
                94.35   186.15      94.35;
                122.4   183.6       122.4;
                147.9   183.6       147.9;
                170.85  186.15      170.85] / 255;

hsvColors = [   120/360 1           0.5 ; 
                120/360 0.1         0.68];
            
colors.FA = [237 28 36] / 255;
colors.MEOH = [0 105 181] / 255;
colors.ETOH = [242 101 34] / 255;
colors.PROH = [127 63 152] / 255;

styles.FA = '-';
styles.MEOH = '--';
styles.ETOH = ':';
styles.PROH = '-.';
%% CO2 to CO base parameter structure
struct.feedPrice = 0.0165;                  % [=] $/kg from CEH market report 2010
struct.standardPotential = -1.333;          % [=] V from thermo
struct.transferCoefficient = 0.1;           % [=] - estimated from work with Steve
struct.productFE = 0.95;                    % [=] - Masel/Jiao
struct.herFE = 0.05;                        % [=] - no other products made
struct.currentDensity = -1000;              % [=] A/m^2 ~ from Masel
struct.exchangeCurrentDensity = -0.1;       % [=] A/m^2 these can vary massively
struct.reactantMW = 44;                     % [=] g/mol chemistry
struct.prodMW = 28;                         % [=] g/mol chemistry
struct.productionRate = 0.4;                % [=] mol/s ~ 1000 kg/day
struct.saltPrice = 0;                       % [=] $/kg gas phase system
struct.solventPrice = 0;                    % [=] $/kg gas phase system
struct.catalystPrice = 552;                 % [=] $/kg gold
struct.molality = Inf;                      % [=] mol / kg solvent - no solvent
struct.molarity = 1/22.4 * 1000;            % [=] mol / L - ideal gas
struct.electrolyteRatio = 0;                % [=] - no salt here
struct.diffusionCoeff = 2.2e-9;             % [=] m^2/s approx for CO2
struct.blThickness = 3e-6;                  % [=] m approx
struct.conversion = 0.20;                   % [=] - estimated from experiments from McLain/Steve
struct.lifetime = 40;                       % [=] years incredibly optimistic
struct.catalystLoading = 10;                % [=] mg/cm^2 typical loadings
struct.kp = 0.003;                          % [=] $/kg mixture rough estimate for Sherwood
struct.wasteMW = 44;                        % [=] g/mol no waste, just use CO2
struct.costOfCapital = 0.0;


conversion = 0.05:1e-4:0.99;
%% MeOH case
meohstruct = struct;
meohstruct.prodMW = 32;
meohstruct.standardPotential = 0.02;
meohstruct.productFE = 0.5;
meohstruct.herFE = 0.5;
meohstruct.productionRate = 0.25;
meohstruct.numberElectrons = 6;
meohstruct.kp = 0.4;
meohstruct.conversion = conversion;
co2econ = EconomicCase(meohstruct);

hold on
limiting_conversion = 1 + struct.blThickness * struct.currentDensity / ...
    6 / 96485 / struct.diffusionCoeff / struct.molarity;
p1 = plot(meohstruct.conversion(conversion < limiting_conversion), ...
     co2econ.cost(conversion < limiting_conversion)/max(co2econ.cost), ...
     'LineStyle', styles.MEOH, 'Color', colors.MEOH, 'DisplayName', 'MeOH', 'LineWidth', 1);
plot([limiting_conversion, limiting_conversion], [min(co2econ.cost(conversion < limiting_conversion))/ max(co2econ.cost), 1], ...
     'LineStyle', styles.MEOH, 'Color', colors.MEOH, 'LineWidth', 1)
%% FA case
fastruct = struct;
fastruct.prodMW = 46;
fastruct.standardPotential = -1.48;
fastruct.productionRate = 0.25;
fastruct.kp = 0.4;
fastruct.conversion = conversion;
co2econ = EconomicCase(fastruct);
limiting_conversion = 1 + struct.blThickness * struct.currentDensity / ...
    2 / 96485 / struct.diffusionCoeff / struct.molarity;
p2 = plot(conversion(conversion < limiting_conversion), ...
     co2econ.cost(conversion < limiting_conversion)/max(co2econ.cost), ...
     'LineStyle', styles.FA, 'Color', colors.FA, 'DisplayName', 'FA', 'LineWidth', 1);
plot([limiting_conversion, limiting_conversion], [min(co2econ.cost(conversion < limiting_conversion))/ max(co2econ.cost), 1], ...
     'LineStyle', styles.FA, 'Color', colors.FA, 'LineWidth', 1)
%% Ethanol case
etstruct = struct;
etstruct.prodMW = 46;
etstruct.catalystPrice = 8000;
etstruct.productFE = 0.3;
etstruct.herFE = 0.7;
etstruct.standardPotential = -1.15;
etstruct.productionRate = 0.25;
etstruct.numberElectrons = 12;
etstruct.kp = 0.4;
etstruct.conversion = conversion;
co2econ = EconomicCase(etstruct);
limiting_conversion = 1 + struct.blThickness * struct.currentDensity / ...
    12 / 96485 / struct.diffusionCoeff / struct.molarity;
p3 = plot(conversion(conversion < limiting_conversion), ...
     co2econ.cost(conversion < limiting_conversion)/max(co2econ.cost), ...
     'LineStyle', styles.ETOH, 'Color', colors.ETOH, 'DisplayName', 'EtOH', 'LineWidth', 1);
plot([limiting_conversion, limiting_conversion], [min(co2econ.cost(conversion < limiting_conversion))/ max(co2econ.cost), 1], ...
     'LineStyle', styles.ETOH, 'Color', colors.ETOH, 'LineWidth', 1)
 
ylim([0, 1])
xlabel('Conversion (-)')
ylabel('Normalized Cost (-)')
legend([p1, p2, p3],'box','off','Location','north')
ax = gca;
ax.YTickLabel = [];
ax.FontSize = 9;
ax.Box = 'on';

fig = gcf;
fig.Units = 'inches';
fig.Position(3:4) = [3.3, 3.3];