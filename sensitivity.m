close all
clear struct
cmap = [0 0 1; 0 1 0.8];
NUM_X_POINTS = 100;

FONT_SIZE = 10;
WIDTH = 3.5;
HEIGHT = 3.5;
LINE_WIDTH = 1.5;
BLACK = [0 0 0];

%% Guaiacol hydrogenation base parameter structure
struct.feedPrice = 0.01;
struct.standardPotential = -1.5;
struct.transferCoefficient = 0.1;
struct.wasteElectrons = 6;
struct.productFE = 0.125;
struct.herFE = 0.75;
struct.currentDensity = -100;
struct.exchangeCurrentDensity = -0.1;
struct.reactantMW = 124.14;
struct.prodMW = 94.11;
struct.productionRate = 0.2;        % ~ 1000 kg/day

phenol = EconomicCase(struct);
phenol.plotBreakdown()

%% Current density and HER at fixed selectivity
fig = figure('Name','Sensitivity on Current Density');
axes(fig)

for fe = 0:0.1:0.9
    prodFE = 0.5*(1-fe);
    phenol.vary('HER FE',fe)
    phenol.vary('Prod FE',prodFE)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

%Format plot nicely
ylim([0 10])
for i = 1:length(fig.Children(end).Children)
    line = fig.Children(end).Children(i);
    line.LineWidth = LINE_WIDTH;
    line.Color = interp1([0;1],cmap,i/length(fig.Children(end).Children));
end
ylabel('Cost [$ kg^{-1}]')
xlabel('Current Density [A m^{-2}]')
fig.Units = 'inches';
fig.Position(3) = WIDTH;
fig.Position(4) = HEIGHT;
fig.Children(end).FontSize = FONT_SIZE;
fig.Children(end).XLabel.FontSize = FONT_SIZE;
fig.Children(end).YLabel.FontSize = FONT_SIZE;
fig.Children(end).XColor = BLACK; fig.Children(end).YColor = BLACK;
fig.Children(end).Box = 'on';
saveas(fig,'../ECH TE Paper/figures/currentDensitySensitivtiy.svg','svg')
%% Faradaic Efficiency at fixed current density
fig = figure('Name','Sensitivity on Faradaic Efficiency');
axes(fig)

for fe = 0:0.1:0.9
    phenol.vary('HER FE',fe)
    phenol.runSensitivity('Product FE',linspace(0,1-fe,100),fig)
end

%Format plot nicely
ylim([0 10])
for i = 1:length(fig.Children(end).Children)
    line = fig.Children(end).Children(i);
    line.LineWidth = LINE_WIDTH;
    line.Color = interp1([0;1],cmap,i/length(fig.Children(end).Children));
end
ylabel('Cost [$ kg^{-1}]')
xlabel('Faradaic Efficiency [-]')
fig.Units = 'inches';
fig.Position(3) = WIDTH;
fig.Position(4) = HEIGHT;
fig.Children(end).FontSize = FONT_SIZE;
fig.Children(end).XLabel.FontSize = FONT_SIZE;
fig.Children(end).YLabel.FontSize = FONT_SIZE;
fig.Children(end).XColor = BLACK; fig.Children(end).YColor = BLACK;
fig.Children(end).Box = 'on';
saveas(fig,'../ECH TE Paper/figures/faradaicEfficiencySensitivity.svg','svg')
%% Current density and Faradaic Efficiency at fixed HER
fig = figure('Name','Sensitivity on Product Faradaic Efficiency');
axes(fig)

phenol.vary('HER FE',0.1)
for fe = 0:0.1:0.9
    phenol.vary('Product FE',fe)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

%Format plot nicely
ylim([0 10])
for i = 1:length(fig.Children(end).Children)
    line = fig.Children(end).Children(i);
    line.LineWidth = LINE_WIDTH;
    line.Color = interp1([0;1],cmap,i/length(fig.Children(end).Children));
end
ylabel('Cost [$ kg^{-1}]')
xlabel('Current Density [A m^{-2}]')
fig.Units = 'inches';
fig.Position(3) = WIDTH;
fig.Position(4) = HEIGHT;
fig.Children(end).FontSize = FONT_SIZE;
fig.Children(end).XLabel.FontSize = FONT_SIZE;
fig.Children(end).YLabel.FontSize = FONT_SIZE;
fig.Children(end).XColor = BLACK; fig.Children(end).YColor = BLACK;
fig.Children(end).Box = 'on';
saveas(fig,'../ECH TE Paper/figures/currentDensityFESensitivity.svg','svg')