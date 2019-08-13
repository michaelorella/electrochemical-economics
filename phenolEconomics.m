clc
close all
clear

% Initialize the structure that will be used as the base case for all
% calculations to follow corresponding to phenol production from guaiacol
struct.feedPrice = 0.01;
struct.standardPotential = -1.5;
struct.transferCoefficient = 0.1;
struct.wasteElectrons = 6;
struct.productFE = 0.03;
struct.herFE = 0.75;
struct.currentDensity = -500;
struct.exchangeCurrentDensity = -0.1;
struct.reactantMW = 124.14;
struct.prodMW = 94.11;
struct.productionRate = 0.2;

cmap = [206.04 59.16 59.16;
        0 127.5 0;
        8.95 63.25 189.95;
        117.3 0 117.3;
        168.3 83.16 0;
        135.41 135.41 17.59;
        23.87 108.73 108.73;
        91.8 91.8 91.8]/255;

WIDTH = 3.5;
HEIGHT = 3.5;
BLACK = [0 0 0];
BLUE = [33.05 86.66 211.75]/255;
RED = [206.04 59.16 59.16]/255;
FONT_SIZE = 10;
LINE_WIDTH = 1;

phenol = EconomicCase(struct);
phenol.plotBreakdown()

%% Current density and HER at fixed selectivity standard sensitivity
fig = figure(1); clf;
ax = axes(fig);

for fe = 0:0.1:0.5
    prodFE = 0.03/0.25*(1-fe);
    phenol.vary('HER FE',fe)
    phenol.vary('Prod FE',prodFE)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

for fe = 0:0.1:0.5
    prodFE = 0.06/0.25*(1-fe);
    phenol.vary('HER FE',fe)
    phenol.vary('Prod FE',prodFE)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

for fe = 0:0.1:0.5
    prodFE = 0.09/0.25*(1-fe);
    phenol.vary('HER FE',fe)
    phenol.vary('Prod FE',prodFE)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

for fe = 0:0.1:0.5
    prodFE = 0.12/0.25*(1-fe);
    phenol.vary('HER FE',fe)
    phenol.vary('Prod FE',prodFE)
    phenol.runSensitivity('Current Density',-logspace(0,4,100),fig)
end

hslColors_g = [ 0       127.5       0;
                7.65    145.35      7.65;
                17.85   160.65      17.85;
                30.6    173.4       30.6;
                45.9    183.6       45.9;
                63.75   191.25      63.75;
                94.35   186.15      94.35;
                122.4   183.6       122.4;
                147.9   183.6       147.9;
                170.85  186.15      170.85] / 255;
            
hslColors_r = [ 127.5   0           0;
                145.35  7.65        7.65;
                160.65  17.85       17.85;
                173.4   30.6        30.6;
                183.6   45.9        45.9;
                191.25  63.75       63.75;
                186.15  94.35       94.35;
                183.6   122.4       122.4;
                183.6   147.9       147.9;
                186.15  170.85      170.85] / 255;
            
hslColors_b = [ 0       0           127.5 ;
                7.65    7.65        145.35;
                17.85   17.85       160.65;
                30.6    30.6        173.4 ;
                45.9    45.9        183.6 ;
                63.75   63.75       191.25;
                94.35   94.35       186.15;
                122.4   122.4       183.6 ;
                147.9   147.9       183.6 ;
                170.85  170.85      186.15] / 255;
            
hslColors_v = (hslColors_b + hslColors_r) / 2;

cmap_mono_g = interp1(linspace(0,1,size(hslColors_g,1)),hslColors_g,linspace(0,1,length(ax.Children)/4));
cmap_mono_r = interp1(linspace(0,1,size(hslColors_r,1)),hslColors_r,linspace(0,1,length(ax.Children)/4));
cmap_mono_b = interp1(linspace(0,1,size(hslColors_b,1)),hslColors_b,linspace(0,1,length(ax.Children)/4));
cmap_mono_v = interp1(linspace(0,1,size(hslColors_v,1)),hslColors_v,linspace(0,1,length(ax.Children)/4));


cmap_mono = [cmap_mono_g;cmap_mono_b;cmap_mono_r;cmap_mono_v];
% cmap_mono = interp1(linspace(0,1,size(hslColors_g,1)),hslColors_g,linspace(0,1,length(ax.Children)));
% Convert units
for i = 1:length(ax.Children)
    ax.Children(i).XData = ax.Children(i).XData / 10;
    ax.Children(i).Color = cmap_mono(i,:);
end

fig.Units = 'inches';
fig.Position(3:4) = [WIDTH HEIGHT];
ylim([0 3])
ax.FontSize = FONT_SIZE;
ax.Box = 'on';
ax.XColor = BLACK; ax.YColor = BLACK;
ax.LineWidth = LINE_WIDTH;
ylabel('Cost [$ kg^{-1}]','FontSize',FONT_SIZE)
xlabel('Current Density [mA cm^{-2}]','FontSize',FONT_SIZE)
saveas(fig,'../ECH TE Paper/figures/phenol_sensitivity.svg','svg')
%% Inverted Sensitivity analyses

%First let's look at how selectivity and activity trade off
figure(1); clf;
hold all

varyStruct = struct;

herFEs = 0:0.1:0.5;
selectivities = (0.03:0.02:0.17)/0.25;
currents = NaN(length(selectivities),length(herFEs));
target = 1.2;
for selectivity = selectivities
    for herFE = herFEs
        varyStruct.herFE = herFE;
        varyStruct.productFE = selectivity*(1-herFE);
        phenol = EconomicCase(varyStruct,target,'Current Density');
        if norm(phenol.cost - target) < 1e-4
            currents(herFE == herFEs) = phenol.output / 10;
        end
    end
end
plot(1-herFEs,currents)

%% Make the waterfall plot for phenol
phenol = EconomicCase(struct);

f1 = figure(1); clf; ax = axes(f1);
f1.Units = 'inches';
f1.Position(3:4) = [2*WIDTH HEIGHT];
f1.Name = 'Phenol Waterfall Chart';

costs = zeros(2,5);
costs(1,1) = phenol.cost;

phenol.vary('Current Density',-2000)
costs(2,2) = phenol.cost;
costs(1,2) = costs(1,1) - phenol.cost;

phenol.vary('HER FE',0.2)
phenol.vary('Product FE',0.096)
costs(1,3) = costs(2,2) - phenol.cost;
costs(2,3) = phenol.cost;

phenol.vary('Product FE',0.75)
costs(1,4) = costs(2,3) - phenol.cost;
costs(2,4) = phenol.cost;
costs(1,5) = phenol.cost;

bar(ax,1:5,fliplr(costs'),'stacked')
ax.Children(1).FaceColor = 'flat';
for i = 1:length(ax.Children(1).CData(:,1))
    ax.Children(1).CData(i,:) = cmap(i,:);
end

ylabel('Cost [$ kg^{-1}]')
ax.Children(end).FaceColor = 'none';
ax.Children(end).EdgeColor = 'none';
ax.XColor = BLACK; ax.YColor = BLACK;

ax.XTickLabel = {'Base Case';
    'j = -200 mA cm^{-2}';
    '\epsilon_{HER} = 0.2, \epsilon_P = 0.096';
    '\epsilon_P = 0.75';
    'Final Case'};
ax.FontSize = FONT_SIZE;
ax.YLabel.FontSize = FONT_SIZE;

x_lim = ax.XLim;
hold(ax,'on')
plot(ax,[0 6],[1.3 1.3],'LineWidth',LINE_WIDTH,'LineStyle','--','Color',BLACK);
ax.LineWidth = LINE_WIDTH;
ax.XLim = [0.5 5.5];
ax.YScale = 'log'; ax.YLim = [0.1 100];
fix_xticklabels(ax,0.2,{'FontSize',FONT_SIZE});
saveas(f1,'../ECH TE Paper/figures/phenol_waterfall.svg','svg')