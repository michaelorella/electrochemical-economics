%Scripts for generating data shown in Orella et al.

close
clear struct

%Define some constants to use throughout the script
NUM_X_POINTS = 100;
FONT_SIZE = 10;
WIDTH = 3.5;
HEIGHT = 3.5;
LINE_WIDTH = 1.0;
BLACK = [0 0 0];
RED = [206.04 59.16 59.16]/255;

cmap = [206.04 59.16 59.16;
        0 127.5 0;
        8.95 63.25 189.95;
        117.3 0 117.3;
        168.3 83.16 0;
        135.41 135.41 17.59;
        23.87 108.73 108.73;
        91.8 91.8 91.8]/255;

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

%% Furfural to MF or furfuryl alcohol
struct.feedPrice = 0.0165;                  % [=] $/kg low value to biomass
struct.standardPotential = -1.400;          % [=] V estimate from Biddinger/Chadderdon papers
struct.transferCoefficient = 0.1;           % [=] 
struct.productFE = 0.60;                    % [=] - Masel/Jiao
struct.herFE = 0.40;                        % [=] - no other products made
struct.currentDensity = -150;               % [=] A/m^2 ~ from Masel
struct.exchangeCurrentDensity = -0.1;       % [=] A/m^2 these can vary massively
struct.reactantMW = 96;                     % [=] g/mol chemistry
struct.prodMW = 82;                         % [=] g/mol chemistry
struct.productionRate = 0.2;                % [=] mol/s ~ 1000 kg/day
struct.saltPrice = 0;                       % [=] $/kg gas phase system
struct.solventPrice = 0.001;                    % [=] $/kg gas phase system
struct.catalystPrice = 8000;                 % [=] $/kg Cu
struct.molality = 0.1;                      % [=] mol / kg solvent
struct.molarity = 100;            % [=] mol / L - ideal gas
struct.electrolyteRatio = 0.1;                % [=] 
struct.numberElectrons = 4;
struct.wasteMW = 98;                        % [=] g/mol no waste, just use CO2
struct.wasteElectrons = 2;                  % [=] - chemistry
struct.costOfCapital = 0.0;

varyStruct = struct;


% Make the base case scenario
fA = EconomicCase(struct);
fA.plotBreakdown()
ax = gca;

%% Run the waterfall analysis

f1 = figure(1); clf; ax = axes(f1);
f1.Units = 'inches';
f1.Position(3:4) = [2*WIDTH HEIGHT];
f1.Name = 'Phenol Waterfall Chart';

costs = zeros(2,4);
costs(1,1) = fA.cost;

fA.vary('Current Density',-1000)
costs(2,2) = fA.cost;
costs(1,2) = costs(1,1) - fA.cost;

fA.vary('HER FE',0.1)
fA.vary('Product FE',0.9)
costs(1,3) = costs(2,2) - fA.cost;
costs(2,3) = fA.cost;

costs(1,4) = fA.cost;

bar(ax,1:4,fliplr(costs'),'stacked')
ax.Children(1).FaceColor = 'flat';
for i = 1:length(ax.Children(1).CData(:,1))
    ax.Children(1).CData(i,:) = cmap(i,:);
end

ylabel('Cost [$ kg^{-1}]')
ax.Children(end).FaceColor = 'none';
ax.Children(end).EdgeColor = 'none';
ax.XColor = BLACK; ax.YColor = BLACK;

ax.XTickLabel = {'Base Case';
    'j = -100 mA cm^{-2}';
    '\epsilon_{HER} = 0.1, \epsilon_P = 0.9';
    'Final Case'};
ax.FontSize = FONT_SIZE;
ax.YLabel.FontSize = FONT_SIZE;

x_lim = ax.XLim;
hold(ax,'on')
plot(ax,[0 6],[1.4 1.4],'LineWidth',LINE_WIDTH,'LineStyle','--','Color',BLACK);
ax.LineWidth = LINE_WIDTH;
ax.XLim = [0.5 4.5];
ax.YScale = 'log'; ax.YLim = [0.1 10];
fix_xticklabels(ax,0.2,{'FontSize',FONT_SIZE});

