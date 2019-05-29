close all
clear struct
cmap = [0 0 1; 0 1 0.8];
NUM_X_POINTS = 100;

FONT_SIZE = 16;
WIDTH = 8;
HEIGHT = 5;
LINE_WIDTH = 2.5;
BLACK = [0 0 0];

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

%% 
%Let's examine what current density we would need to achieve at given
%selectivities
figure(2); clf;
hold all
herFEs = (0:0.01:0.5);

varyStruct.herFE = herFEs;
varyStruct.productFE = 1 - herFEs;
for targetCost = linspace(0.8,1.5,8)
    currents = NaN(size(herFEs));
    co2econ = EconomicCase(varyStruct,targetCost,'Current Density');
    currents((co2econ.cost - targetCost).^2 < 1e-4) = co2econ.output((co2econ.cost - targetCost).^2 < 1e-4);
    plot(1-herFEs,currents)
end


%% Feed concentration dependence
figure(3); clf;
hold all
for chi = 0.1:0.1:0.9
    varyStruct = struct;
    percentages = linspace(1e-5,100,1e4);
    varyStruct.molarity = percentages/100*1000/22.4;
    varyStruct.conversion = chi;
    co2econ = EconomicCase(varyStruct);
    valid = co2econ.limitingCurrentDensity < varyStruct.currentDensity;
    plot(percentages(valid),co2econ.cost(valid))
    drawnow
end


%% Separations dependence on conversion
figure(4); clf;
convs = linspace(0.01,0.8,80);
varyStruct = struct;

varyStruct.conversion = convs;
co2econ = EconomicCase(varyStruct);
plot(convs,co2econ.breakdown(2,:))

%% Waterfall chart    
co2econ = EconomicCase(struct);
costs = zeros(5,1);
costs(1) = co2econ.cost;

co2econ.vary('Electricity Price',0.02)
costs(2) = co2econ.cost;

co2econ.vary('Current Density',-5000)
costs(3) = co2econ.cost;



phenol.vary('HER FE',0.2)
phenol.vary('Product FE',0.096)
costs(1,3) = costs(2,2) - phenol.cost;
costs(2,3) = phenol.cost;

phenol.vary('Product FE',0.75)
costs(1,4) = costs(2,3) - phenol.cost;
costs(2,4) = phenol.cost;
costs(1,5) = phenol.cost;

bar(1:5,fliplr(costs'),'stacked')
ax.Children(1).FaceColor = BLUE;