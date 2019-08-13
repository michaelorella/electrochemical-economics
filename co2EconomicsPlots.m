close
clear struct
cmap = [0 0 1; 0 1 0.8];
NUM_X_POINTS = 100;

FONT_SIZE = 10;
WIDTH = 3.5;
HEIGHT = 3.5;
LINE_WIDTH = 1.0;
BLACK = [0 0 0];
RED = [206.04 59.16 59.16]/255;

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

%% CO2 to CO base parameter structure
struct.feedPrice = 0.0165;
struct.standardPotential = -1.333;
struct.transferCoefficient = 0.1;
struct.productFE = 0.95;
struct.herFE = 0.05;
struct.currentDensity = -1000;
struct.exchangeCurrentDensity = -0.1;
struct.reactantMW = 44;
struct.prodMW = 28;
struct.productionRate = 0.4;        % ~ 1000 kg/day
struct.saltPrice = 0;
struct.solventPrice = 0;
struct.catalystPrice = 552;
struct.molality = Inf;
struct.molarity = 1/22.4 * 1000;
struct.electrolyteRatio = 0;
struct.diffusionCoeff = 2.2e-9;
struct.blThickness = 3e-6;
struct.conversion = 0.20;
struct.lifetime = 20;
struct.catalystLoading = 10;
struct.kp = 0.004;
struct.wasteMW = 44;

varyStruct = struct;

co2econ = EconomicCase(struct);
co2econ.plotBreakdown()
ax = gca;

co2econ.vary('Electricity Price',0.03)
co2econ.plotBreakdown(ax)

% Formic acid case
co2econ = EconomicCase(struct);
co2econ.vary('ProdMW',46)
co2econ.vary('standardPotential',-1.48)
co2econ.vary('ProductionRate',0.25)
co2econ.vary('kp',0.4)

co2econ.plotBreakdown(ax)
co2econ.vary('Electricity Price',0.03)
co2econ.plotBreakdown(ax)

% Methane case
co2econ = EconomicCase(struct);
co2econ.vary('ProdMW',16)
co2econ.vary('standardPotential',-1.06)
co2econ.vary('ProductionRate',0.72)
co2econ.vary('Number Electrons',8)
co2econ.plotBreakdown(ax)
co2econ.vary('Electricity Price',0.03)
co2econ.plotBreakdown(ax)


% Ethylene case
co2econ = EconomicCase(struct);
co2econ.vary('ProdMW',28)
co2econ.vary('standardPotential',-1.17)
co2econ.vary('ProductionRate',0.41)
co2econ.vary('Number Electrons',12)
co2econ.plotBreakdown(ax)
co2econ.vary('Electricity Price',0.03)
co2econ.plotBreakdown(ax)


% Ethanol case
co2econ = EconomicCase(struct);
co2econ.vary('ProdMW',46)
co2econ.vary('standardPotential',-1.15)
co2econ.vary('ProductionRate',0.25)
co2econ.vary('Number Electrons',12)
co2econ.vary('kp',0.4)
co2econ.plotBreakdown(ax)
co2econ.vary('Electricity Price',0.03)
co2econ.plotBreakdown(ax)

ax.FontSize = FONT_SIZE;
ylabel('Cost [$/kg]','fontsize',FONT_SIZE)

fig = gcf;
ax.XTickLabels = {'CO_2 State of the Art'};
fig.Units = 'inches';
fig.Position(3:4) = [2*WIDTH HEIGHT];
hold(ax,'on')
plot(ax,[0 4.5 4.5 6.5 6.5 8.5 8.5 10.5],[1.2 1.2 0.21 0.21 1.20 1.20 0.8 0.8],'LineWidth',LINE_WIDTH,'LineStyle','--','Color',BLACK);
saveas(gcf,'../ECH TE Paper/figures/CO2_benchmark.svg','svg')
% ax.YLim = [0 1.3];

%% 
%Let's examine what current density we would need to achieve at given
%selectivities
figure(2); clf;
ax = axes(gcf);
ax.FontSize = FONT_SIZE;
ax.Parent.Units = 'inches';
ax.Parent.PaperPosition(3:4) = [WIDTH HEIGHT];
ax.Parent.Position(3:4) = [WIDTH HEIGHT];
herFEs = 0.0:0.001:0.5;
targetCosts = linspace(0.6,1.2,7);


            

cmap = interp1(linspace(0,1,size(hslColors,1)),hslColors,linspace(0,1,length(targetCosts)));

h = waitbar(0,'Solving');
currents = NaN(length(targetCosts),length(herFEs));
for targetCost = targetCosts
    for herFE = herFEs
        varyStruct.herFE = herFE;
        varyStruct.productFE = 1 - herFE;
        co2econ = EconomicCase(varyStruct,targetCost,'Current Density');
        if co2econ.cost - targetCost < 1e-4
            currents(targetCost == targetCosts, herFE == herFEs) = co2econ.output;
        end
    end
    i = find(targetCost == targetCosts);
    h = waitbar(i/length(targetCosts),h);
end
close(h)
ax.Colormap = cmap;
plot(ax,1-herFEs,currents,'linewidth',1.0);

for i = 1:length(ax.Children)
    ax.Children(i).Color = cmap(i,:);
end

%% Feed concentration dependence
figure(3); clf;
hold all
chis = [0.05:0.01:0.1 0.2:0.2:0.8];
cmap = interp1(linspace(0,1,size(hslColors,1)),hslColors,linspace(0,1,length(chis)));
for chi = chis
    varyStruct = struct;
    percentages = linspace(1e-5,100,1e5);
    varyStruct.molarity = percentages/100*1000/22.4;
    varyStruct.conversion = chi;
    co2econ = EconomicCase(varyStruct);
    valid = co2econ.limitingCurrentDensity < varyStruct.currentDensity;
    plot(percentages(valid),co2econ.cost(valid),'color',cmap(chi == chis,:))
end
ax = gca;
ax.FontSize = FONT_SIZE;
xlabel('Concentration [% v/v]','FontSize',FONT_SIZE)
ylabel('Cost [$ kg^{-1}]','FontSize',FONT_SIZE)
ax.Box = 'on';
ax.LineWidth = 1;
ax.Parent.Units = 'inches';
ax.Parent.Position(3:4) = [WIDTH HEIGHT];
r = rectangle('Position',[0 0.86 17 1.02-0.86],'FaceColor',[0 0 0 0.15],'EdgeColor','none');
ax.YLim = [0.86 1.02];
ax.XLim = [0 100];
saveas(gcf,'../ECH TE Paper/figures/concentration_dependence.svg','svg')