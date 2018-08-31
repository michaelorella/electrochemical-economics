close all
clear struct
cmap = [0 0 1; 0 1 0.8];
NUM_X_POINTS = 100;

FONT_SIZE = 16;
WIDTH = 8;
HEIGHT = 5;
LINE_WIDTH = 2.5;
BLACK = [0 0 0];

%% Guaiacol hydrogenation base parameter structure
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
struct.conversion = 0.75;
struct.lifetime = 20;
struct.catalystLoading = 10;

phenol = EconomicCase(struct);
phenol.plotBreakdown()

%% Current density and HER at fixed selectivity
fig = figure('Name','Sensitivity on Current Density');
axes(fig)

for fe = 0:0.1:0.9
    prodFE = (1-fe);
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
saveas(fig,'../ShellMeeting/figures/currentDensitySensitivtiy.svg','svg')
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
saveas(fig,'../ShellMeeting/figures/faradaicEfficiencySensitivity.svg','svg')
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
saveas(fig,'../ShellMeeting/figures/currentDensityFESensitivity.svg','svg')