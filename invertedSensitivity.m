% Initialize the structure that will be used as the base case for all
% calculations to follow
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

%First let's look at how selectivity and activity trade off
figure(1); clf;
hold all
for herFE = 0:0.1:0.9
    struct.herFE = herFE;
    currents = [];
    for prodFE = 0.01:0.01:1-herFE
        struct.productFE = prodFE;
        phenol = EconomicCase(struct,1.2,'Current Density');
        currents = [currents,phenol.output];
        drawnow
    end
    plot(0.01:0.01:1-herFE,currents)
end



