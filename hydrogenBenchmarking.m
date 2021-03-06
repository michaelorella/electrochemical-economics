%% Build the hydrogen data
% Economic case has default Hydrogen DOE data built in as the default
% constructor
struct.costOfCapital = 0;
hydrogenCase = EconomicCase(struct);

%% Get the DOE report data and Model Data - taken straight out of report 14004 DOE
hydrogenData = fliplr([0.42 0.61 0.76 0.01 0 3.34 ;
                0.48 0.53 0.72 0.01 0 3.38 ]);

%% Plot the results

FONT_SIZE = 10;
left = 1;
bottom = 1;
height = 3.5;
width = 7;
BLACK = [0 0 0];
BLUE = [33.05 86.66 211.75]/255;

cmap = [206.04 59.16 59.16;
        0 127.5 0;
        8.95 63.25 189.95;
        117.3 0 117.3;
        168.3 83.16 0;
        135.41 135.41 17.59;
        23.87 108.73 108.73;
        91.8 91.8 91.8]/255;

f1 = figure(1); clf;
f1.Name = 'Benchmarking H2';
f1.Units = 'inches';
f1.Position = [left bottom width height];
ax = axes(f1);
ax.XColor = BLACK; ax.YColor = BLACK;
b = bar(ax,hydrogenData,'stacked','LineWidth',1,'FaceColor','flat');

for i = 1:size(hydrogenData,2)
    b(i).CData = repmat(cmap(i,:),size(b(i).CData,1),1);
end


legend({'Electricity','Electrolyte','Additional','BOP','Capital'})

hydrogenCase.plotBreakdown(ax,cmap)

hydrogenCase.vary('Production Rate',287);
hydrogenCase.plotBreakdown(ax,cmap)

ax.XTickLabel = {'H2A Model Forecourt',...
    'H2A Model Central',...
    'Current Work Forecourt', ...
    'Current Work Central'};

ax.FontSize = FONT_SIZE;
ylabel(ax,'Cost [$ kg^{-1}]')
ax.YLabel.FontSize = FONT_SIZE;
fix_xticklabels(ax,0.3,{'FontSize',FONT_SIZE});

%
hydrogenCase.vary('Production Rate',8.6);
basePrice = hydrogenCase.getInput('Electricity Price');
baseCost = hydrogenCase.cost;


% 50% increase in electricity
hydrogenCase.vary('electricityPrice',basePrice * 1.5);
highCost = [ hydrogenCase.cost / baseCost - 1 ];

hydrogenCase.vary('electricityPrice',basePrice * 0.5);
lowCost = [ hydrogenCase.cost / baseCost - 1 ] ;

%Reset model
hydrogenCase.vary('electricityPrice',basePrice);
base = hydrogenCase.getInput('lifetime') / 3600 / 24 ...
    / hydrogenCase.getInput('operatingDays') ;

%             %Correct units to all be SI
%             obj.lifetime = obj.lifetime * obj.SECONDS_TO_YEARS;
%             obj.feedMass = obj.feedMass / obj.G_TO_KG;
%             obj.saltMass = obj.saltMass / obj.G_TO_KG;

%50 % change in lifetime
hydrogenCase.vary('lifetime',4);
highCost = [ hydrogenCase.cost / baseCost - 1 ; highCost];

hydrogenCase.vary('lifetime',20);
lowCost = [ hydrogenCase.cost / baseCost - 1 ; lowCost] ;


%Reset model
hydrogenCase.vary('lifetime',base);

% Change in efficiency of electrolyzer
base = hydrogenCase.getInput('Exchange Current Density');

hydrogenCase.vary('Exchange Current Density',-5e-7 );
highCost = [ hydrogenCase.cost / baseCost - 1 ; highCost];

hydrogenCase.vary('Exchange Current Density',-1e2 );
lowCost = [ hydrogenCase.cost / baseCost - 1 ; lowCost] ;

%Change in cost of electrolyzer
hydrogenCase.vary('Exchange Current Density',base);

base = hydrogenCase.getInput('Area Price');

hydrogenCase.vary('areaPrice',base * 1.5);
highCost = [ hydrogenCase.cost / baseCost - 1 ; highCost];

hydrogenCase.vary('areaPrice',base * 0.5);
lowCost = [ hydrogenCase.cost / baseCost - 1 ; lowCost];

f2 = figure(2); clf;
f2.Name = 'Model Tornado Chart';
f2.Units = 'inches';
f2.Position = [left height+bottom width/1.6 height];
hold on
barh(100*highCost,'FaceColor',BLUE)
barh(100*lowCost,'FaceColor',BLUE)
ax = gca;

ax.YTick = [1 2 3 4];
clear cell
ax.XColor = BLACK; ax.YColor = BLACK;
xlabel('% Change in Total Cost')
ax.YTickLabel = cell(length(lowCost),1);

text = {'Electricity Cost',...
    'Lifetime',...
    'Energy Efficiency',...
    'Installed Capital Cost'};
ax.Children(1).LineWidth = 1;
ax.Children(2).LineWidth = 1;
ax.Box = 'on';
for i = 1:length(highCost)
    ax.YTickLabel{length(lowCost) + 1 - i} = text{i};
end
ax.FontSize = FONT_SIZE;
fix_yticklabels(ax,0.1,{'FontSize',FONT_SIZE});

%From current forecourt sensitivity
doeHigh = flipud([6.81;5.25;6.11;5.49]);
doeLow = flipud([3.47;5.04;4.71;4.79]);

doeHigh = (doeHigh - 5.14)/5.14;
doeLow = (doeLow - 5.14)/5.14;

f3 = figure(3); clf;
f3.Name = 'DOE Tornado Chart';
f3.Units = 'inches';
f3.Position = [left+width/1.5 bottom+height width/1.7 height];
hold on
barh(100*doeHigh,'FaceColor',BLUE)
barh(100*doeLow,'FaceColor',BLUE)
ax = gca;

clear cell
ax.XColor = BLACK; ax.YColor = BLACK;
xlabel('% Change in Total Cost')
ax.FontSize = FONT_SIZE;
ax.YTick = 1:4;
ax.YTickLabel = cell(length(lowCost)*2 + 1);
ax.Children(1).LineWidth = 1;
ax.Children(2).LineWidth = 1;
ax.Box = 'on';

saveas(f1,'../ECH TE Paper/figures/hydrogenBenchmarking.svg','svg')
saveas(f2,'../ECH TE Paper/figures/hydrogenTornado.svg','svg')
saveas(f3,'../ECH TE Paper/figures/doeHydrogenTornado.svg','svg')


%% Monte Carlo Sensitivity Analysis
Nrep = 10000;
costs = zeros(Nrep,1);

params = {'saltPrice','solventPrice','electricityPrice','catalystPrice','additionalFactor',...
    'transferCoefficient','productFE','currentDensity','exchangeCurrentDensity',...
    'diffusionCoefficient','blThickness','conversion','cellGap','conductivity','temperature',...
    'catalystLoading','lifetime','areaPrice'};

baseCase.saltPrice = 0.1;
baseCase.solventPrice = 0.001;
baseCase.electricityPrice = 0.0612;
baseCase.catalystPrice = 32000;
baseCase.additionalFactor = 0.14;

baseCase.transferCoefficient = 0.5;
baseCase.productFE = 0.9;
baseCase.currentDensity = -15000;
baseCase.exchangeCurrentDensity = -0.1;
baseCase.diffusionCoefficient = 5e-9;
baseCase.blThickness = 1e-5;
baseCase.conversion = 0.5;
baseCase.cellGap = 0.02;
baseCase.conductivity = 0.1;
baseCase.temperature = 298.15;
baseCase.catalystLoading = 0.01;
baseCase.lifetime = 7;
baseCase.areaPrice = 1.1011e4;

partialcosts = zeros(Nrep,numel(params));

Nbar = 50;
Nmod = floor(Nrep / Nbar);
tic
fprintf(['|',repmat(' ',1,Nbar),'|\n']);
econ = EconomicCase();

for i = 1:Nrep
    baseEcon = EconomicCase();
    
    %Generate random number with mean 1 and standard deviation of 0.1
    %These numbers will be used to vary the cost parameters
    x = 0.1 * randn([1,length(params)]) + 1;
    v = partialcosts(i,:);
    
    for j = 1:length(params)
        if strcmpi(params{j},'productfe') || strcmpi(params{j},'transfercoefficient') || strcmpi(params{j},'conversion')
            mappedVal = - log ( 1 / baseCase.(params{j}) - 1) ;
            newval = ( x(j) - 1 ) + mappedVal ;
            newval = 1 ./ ( 1 + exp ( - newval ) ) ;
        else
            newval = x(j) * baseCase.(params{j});
        end
        econ.vary ( params{j} , newval )
        
        baseEcon.vary ( params{j} , newval )
        v ( j ) = baseEcon.cost;
        baseEcon.vary ( params{j} , baseCase.(params{j}) );
    end    
    partialcosts(i,:) = v;
    costs(i) = econ.cost;
    if mod(i,Nmod) == 0
        fprintf(repmat('\b',1,Nbar + 3))
        fprintf(['|',repmat('*',1,floor(i/Nmod)),repmat(' ',1,Nbar - floor(i/Nmod)),'|\n']);
    end
end
toc
histogram(costs,100,'Normalization','Probability')