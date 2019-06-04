BLACK = [0 0 0];
BLUE = [33.05 86.66 211.75]/255;
RED = [206.04 59.16 59.16]/255;
GREEN = [0 1 0];
FONT_SIZE = 10;
WIDTH = 7;
HEIGHT = 3.5;
LINE_WIDTH = 1.5;
DETAILED = 0;

close all

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

phenol = EconomicCase(struct);
if DETAILED
    
    phenol.plotBreakdown()
    
    f1 = gcf; reset(gcf); clf; ax = gca;
    f1.Units = 'inches';
    f1.Position(3) = WIDTH; f1.Position(4) = HEIGHT;
    f1.Name = 'Phenol Waterfall Chart';
    
    baseCost = phenol.breakdown;
    costDiff = zeros(3,6);
    
    phenol.vary('Current Density',-2000)
    costDiff(1,:) = [ - phenol.cost , phenol.breakdown - baseCost ];
    cost = phenol.breakdown;
    
    phenol.vary('HER FE',0.2)
    phenol.vary('Product FE',0.4)
    costDiff(2,:) = [ - phenol.cost , phenol.breakdown - cost ];
    cost = phenol.breakdown;
    
    
    phenol.vary('Product FE',0.75)
    costDiff(3,:) = [ - phenol.cost , phenol.breakdown - cost ];
    cost = phenol.breakdown;
    
    cla;
    bar(ax,[1 2 3 4],[0 baseCost ; -costDiff],'stacked')
    phenol.plotBreakdown(ax)
    
else
    f1 = figure(); clf; ax = axes(f1);
    f1.Units = 'inches';
    f1.Position(3) = WIDTH; f1.Position(4) = HEIGHT;
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
    ax.Children(1).FaceColor = BLUE;
end


ylabel('Cost [$ kg^{-1}]')
ax.Children(end).FaceColor = 'none';
ax.Children(end).EdgeColor = 'none';
ax.XColor = BLACK; ax.YColor = BLACK;

ax.XTickLabel = {'Base Case';
    'j = -2 kA m^{-2}';
    '\epsilon_{HER} = 0.2, \epsilon_P = 0.096';
    '\epsilon_P = 0.75';
    'Final Case'};
ax.FontSize = FONT_SIZE;
ax.YLabel.FontSize = FONT_SIZE;

x_lim = ax.XLim;
hold(ax,'on')
plot(ax,[0 6],[1.3 1.3],'LineWidth',LINE_WIDTH,'LineStyle','--','Color',RED);
ax.XLim = [0.5 5.5];
ax.YScale = 'log'; ax.YLim = [0.1 100];
fix_xticklabels(ax,0.2,{'FontSize',FONT_SIZE});
saveas(f1,'../ECH TE Paper/figures/generated_waterfall.svg','svg')
