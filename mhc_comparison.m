struct.feedPrice = 0.0165;                  % [=] $/kg from CEH market report 2010
struct.standardPotential = -1.333;          % [=] V from thermo
struct.productFE = 0.95;                    % [=] - Masel/Jiao
struct.herFE = 0.05;                        % [=] - no other products made
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

struct.lambda = 9.65e4;
struct.exchangeCurrentDensity = -10;        % [=] A/m^2 these can vary massively

struct.transferCoefficient = 0.2;
colors = [1 0 0; 1 0.8 0.8];

js = -100:-10:-5000;
ks = -50:5:-5;

hold on
mincosts = zeros(size(ks));
for k = ks
    mhc_costs = zeros(size(js));

    for j = js
        struct.currentDensity = j;

        struct.rateName = 'MHC';
        struct.exchangeCurrentDensity = k;
        co2econ = EconomicCase(struct);
        mhc_costs(j==js) = co2econ.cost;
    end
    mincosts(k == ks) = min(mhc_costs);
end

bv_costs = zeros(size(js));
for j = js
    struct.rateName = 'BV';
    struct.currentDensity = j;
    struct.exchangeCurrentDensity = k/1000;
    co2econ = EconomicCase(struct);
    bv_costs(j == js) = co2econ.cost;
end

min_BV = min(bv_costs);

figure(1); clf;
hold on
xlims = [-120 0];
plot(2*ks*sqrt(struct.lambda*pi/8.314/298)/10, mincosts, '.',...
    'MarkerSize',15,'Color','Red')
plot(xlims,[min_BV min_BV],'LineStyle','--','Color','Black','LineWidth',1)
xlim(xlims)
xlabel('$2k_0\sqrt{\lambda\pi}$','Interpreter','Latex')
ylabel('Cost ($ kg^{-1})')
ax = gca;
ax.FontSize = 10;
ax.Parent.Units = 'inches';
ax.Parent.Position(3:4) = [3.3 3.3];
ax.LineWidth = 1;
ax.XColor = 'Black';
ax.YColor = 'Black';
ax.Color = 'None';
ax.Box = 'on';
ax.TickLength = [0.02 0.005];