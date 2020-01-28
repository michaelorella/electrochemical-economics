%EconomicCase Calculate the economics of electrolyzers
%
%Written by: Mike Orella
%Last Edited by: Mike Orella 12 August 2019
%Class file for handling technoeconomic model of electrolytic reactor for
%reductive reactions of the type R --> P, R --> W.
%
%For details on derivations of equations presented herein, see 
%[citation to add]

classdef EconomicCase < handle

    properties (Access = private)
        costTarget;
        paramToManipulate;
        
        %% Specified Values
        %Material, Electricity, and System Pricing
        feedPrice = 0.0;                     % [=] $ kg^{-1}
        saltPrice = 0.0;                     % [=] $ kg^{-1}
        solventPrice = 0.001;                % [=] $ kg^{-1}
        electricityPrice = 0.0612;           % [=] $ kWh^{-1}
        catalystPrice = 32000;               % [=] $ kg^{-1}
        additionalFactor = 0.14;             % [=] -
        
        %Physical Values
        %Electrical parameters
        standardPotential = -1.233;         % [=] V
        transferCoefficient = 0.5;          % [=]
        numberElectrons = 2;                % [=] mol e/mol P
        wasteElectrons = 2;                 % [=] mol e/mol W
        productFE = 0.90;                   % [=] -
        herFE = 0;                          % [=] -
        currentDensity = -15000.0;          % [=] A m^{-2} geometric
        exchangeCurrentDensity = -0.1;      % [=] A m^{-2} geometric
        rateName = 'BV';                    % [=] String (e.g. BV or MHC)
        
        %Solution Properties
        molality = 1;                       % [=] mol R kg solvent^{-1}
        molarity = 1000;                    % [=] mol R m^{-3}
        reactantMW = 1.01;                  % [=] g (mol R)^{-1}
        saltMW = 98;                        % [=] g (mol salt)^{-1}
        prodMW = 2.02;                      % [=] g (mol P)^{-1}
        wasteMW = 100;                      % [=] g (mol W)^{-1}
        electrolyteRatio = 1;               % [=] mol salt/mol e
        
        %Separations
        kp = 0.000;                         % [=] $/kg mixture
        
        
        %Reactor Properties
        diffusionCoeff = 5e-9;              % [=] m^2 s^{-1}
        blThickness = 1e-5;                 % [=] m
        productionRate = 8.6;               % [=] mol s^{-1}
        conversion = 0.5;                   % [=] mol consumed / mol fed
        cellGap = .02;                      % [=] cm
        conductivity = 0.1;                 % [=] S cm^{-1}
        temperature = 298.15;               % [=] K
        
        basePrice = 1.0626e4;               % [=] $ m^{-2}
        baseBopPrice = 1.5318e4;            % [=] $ m^{-2}
        
        scaleArea = log(423/385) / log(50000/1500);
        % [=] -
        scaleBop = log(477/555) / log(50000/1500);
        % [=] -
        
        %System Properties
        catalystLoading = .01               % [=] mg metal cm^{-2}
        lifetime = 7;                       % [=] years
        operatingDays = 300;                % [=] days
        recycleElectrolyte = 0.99;          % [=] mol / mol
        recycleFeed = 0.99;                 % [=] mol / mol
        recycleSolvent = 0.99;              % [=] mol / mol
        
        %Economic parameters
        costOfCapital = 0.1;                % [=] % taken from investopedia article that lists 10.72% for chemicals companies being on the high end
    end
    
    properties (Constant = true, Access = private)
        %Plotting values
        FONT_SIZE = 14;
        LINE_WIDTH = 2;
        LINE_ORDER = '-|--|:|-.';
        COST_LIM = [0 10];
        RES_LIM = [0 50];
        K_LIM = [0 0.05];
        
        %Physical Constants
        FARADAY_CONSTANT = 96485;
        GAS_CONSTANT = 8.3140;
        
        %Unit Conversions
        G_TO_KG = 1000 ;
        SECONDS_TO_YEARS = 365.25 * 24 * 60 * 60 ;
        WATT_TO_KWHPERYEAR = 365.25 * 24 / 1000 ;
        CM_TO_M = 100;
        MS_TO_S = 1000;
        L_TO_M3 = 1000;
        W_TO_KW = 1000;
        SECONDS_TO_HOURS = 3600;
        WATT_TO_KW = 1000;
        
        %Other stuff

        BASE_RATE = 8.6;                        % [=] mol s^{-1}
    end
    
    properties
        %Important calculated outputs
        
        %Reactor properties
        
        reactorArea;                % [=] m^2   -- required area       
        
        %Electrical properties
        
        current;                    % [=] A     -- total current
        ohmics;                     % [=] V     -- ohmic overpotential
        massTransfer;               % [=] V     -- mass transfer overpotential
        kinetics;                   % [=] V     -- kinetic overpotential
        ocv;                        % [=] V     -- open circuit potential
        cellVoltage;                % [=] V     -- total cell voltage
        
        %Final calculated cost values
        
        capitalCosts;               % [=] $     -- total capital cost
        bopCosts;                   % [=] $     -- total balance of plant cost
        electricityCosts;           % [=] $/s   -- instantaneous electricity cost
        electrolyteCosts;           % [=] $/s   -- instantaneous feed costs
        sepCosts;                   % [=] $/s   -- equivalent cost of separations
        cost;                       % [=] $/kg  -- minimum selling price
        
        %Output from inverted model
        
        output;                     % [=] ?     -- value of any parameter solved in inverted model
    end
    
    properties (Hidden = true)
        %Mass balances
        flowRate;
        feedRate;
        
        %Kinetics
        rateExpression;
        limitingCurrentDensity;
        
        %Cost intermediates
        areaPrice;
        areaBOPPrice;
        breakdown;
        
        varyParam;
    end
    
    
    methods
        function this = EconomicCase(struct,costTarget,paramToVary)
            %EconomicCase constructor builds electrolyzer model
            %
            %Can be used to build two types of models. In the first, all
            %non-default parameter values are specified in a data structure
            %and the system cost ($/kg) is solved according to the
            %specified equations. In the second, all-but-one are specified,
            %along with the desired cost. An optimization then solves for
            %the required parameter value to satisfy the cost.            
            %
            %Inputs:
            %   struct                  --  struct - contains all of the
            %                               information that should be used
            %                               for the default construction of
            %                               the model (i.e. all of the
            %                               properties are contained within
            %                               the structure)
            %   costTarget              --  double - if model is being
            %                               inverted
            %   paramToVary             --  str - the name of the parameter
            %                               that is unspecified            
            %Outputs:
            %   this                    --  EconomicCase - new economic
            %                               case object with all of the
            %                               model details calculated
            
            if nargin > 0 %Non - default constructor called
                if nargin >= 1 %Calculate traditional model (i.e. not inverted)
                    fields = fieldnames(struct);
                    this.varyParam = '';
                    
                    %See what properties have been assigned to the input
                    %structure, and copy those over to the object, while
                    %maintaining other defaults
                    for field = fields'
                        try
                            this.(char(field)) = struct.(char(field));
                            if length(struct.(char(field))) > 1
                            	this.varyParam = EconomicCase.convertName(char(field));
                            end
                        catch err
                            %Repackage field missing as a warning and
                            %continue with the default parameter value
                            switch err.identifier
                                case 'MATLAB:noPublicFieldForClass'
                                    warning([ 'Error while trying to ', ...
                                        'execute ',char(field),'. Ensure ', ...
                                        'that this name is spelled ', ...
                                        'correctly, or is the correct ', ...
                                        'parameter. Using default behavior', ...
                                        ' to continue program execution'])
                                otherwise
                                    err.rethrow()
                            end
                        end
                    end
                end
                    
                if nargin == 2
                    error(['Error while trying to invert the model',...
                           ', not sure which parameter to vary'])
                end
                
                
                
            end
            
            %Run default constructor behavior
            %Correct units to all be SI
            this.lifetime = this.lifetime * this.SECONDS_TO_YEARS ...
                * this.operatingDays / 365.25;
            this.reactantMW = this.reactantMW / this.G_TO_KG;
            this.saltMW = this.saltMW / this.G_TO_KG;
            this.prodMW = this.prodMW / this.G_TO_KG;
            this.catalystLoading = this.catalystLoading / this.G_TO_KG^2 ...
                * this.CM_TO_M^2;
            
            %Run the model in the order specified by output set assignment
            this.runModel();
            
            if nargin == 3
                this.costTarget = costTarget;
                this.paramToManipulate = paramToVary; %Sets a parameter that can be changed to change cost

                %Set up the solver to calculate the manipulated variable
                %value
                opts = optimoptions('fmincon','display','off');
                ub = Inf(size(this.cost));
                lb = -Inf(size(this.cost));
                
                %Make sure that the solver doesn't take us to a point where
                %the current density is not feasible
                if strcmp(EconomicCase.convertName(paramToVary),'currentDensity')
                    ub = zeros(size(this.cost));
                    if size(this.limitingCurrentDensity) == size(this.cost)
                        lb = this.limitingCurrentDensity;
                    else
                        lb = repmat(this.limitingCurrentDensity,size(this.cost));
                    end
                end
                
                %Start from the default value of the parameter
                guess = this.(EconomicCase.convertName(paramToVary));
                
                %Should work for inputs of all sizes, but works best for
                %scalar tests
                if length(guess) ~= length(this.cost)
                	guess = repmat(guess,size(this.cost));
                end
                
                %Try to get the calculated cost as close to the eval cost
                %as possible
                [result,fval] = fmincon(@(x) norm(this.evalCost(paramToVary,x) - costTarget),...
                    guess,[],[],[],[],lb,ub,[],opts);
                this.output = result;
                if fval > 1e-4
                    warning('Equation not solved, check final conditions')
                end
            end
        end
        
        function vary(this,paramName,paramValue)
            %vary Recalculates the economic model after changed input
            %
            %In general, this function is used for sensitivity analysis to
            %examine the effect of changing parameter values on system
            %cost.
            %
            %Inputs:
            %   paramName       --  str     --  name of the parameter being
            %                                   changed
            %   paramValue      --  double  --  new value of the parameter
            %Outputs:
            %   recalculates the model, and mutates the values found in
            %   this (the EconomicCase instance)
            
            %Parse the passed character string into the name of one of the
            %fields of Economic Case, or throw an error if it is
            %unrecognized
            name = EconomicCase.convertName(paramName);
            
            %Convert inputs to SI units from passed values
            switch lower(paramName(~isspace(paramName)))
                case 'lifetime'
                    paramValue = paramValue * this.SECONDS_TO_YEARS ...
                        * this.operatingDays / 365.25;
                case {'reactantmw','feedmw','productmw','prodmw',...
                        'saltmw','electrolytemw'}
                    paramValue = paramValue / this.G_TO_KG ;
                case {'catalystloading','metalloading'}
                    paramValue = paramValue / this.G_TO_KG^2 ...
                        * this.CM_TO_M^2 ;
            end
            
            %Implement the necessary changes
            this.(name) = paramValue;
            
            %Set the name of the sensitivity study
            if any(size(paramValue) > 1)
                this.varyParam = name;
            end
            
            this.runModel();
        end
        
        function result = getInput(this,paramName)
            %getInput Helper function to return public and private
            %attributes of the instance
            %
            %Inputs:
            %   paramName   --  str     --  name of the attribute
            %Outputs:
            %   result      --  ?       --  value of the parameter
            
            %Parse the input string
            name = EconomicCase.convertName(paramName);
            
            result = this.(name);
        end        
        
        function plotBreakdown(this,ax,cmap)
            %plotBreakdown Plot the cost contributions for this study
            %
            %Looks at all of the cost variables that have been calculated
            %and normalizes and compares them on a bar chart that can be
            %used for further analysis
            %
            %Inputs:
            %   ax      -- handle   --  any axis that is blank or has
            %                           previous economic data in it
            %   cmap    -- Nx3      --  color map to use for the different
            %                           categories of costs
            %Outputs:
            %   Plot with the current cost contributions broken down in a
            %   stacked bar chart
            
            %Initialize with default values
            currentData = NaN;
            map = [206.04 59.16 59.16;
                    0 127.5 0;
                    8.95 63.25 189.95;
                    117.3 0 117.3;
                    168.3 83.16 0;
                    135.41 135.41 17.59;
                    23.87 108.73 108.73;
                    91.8 91.8 91.8]/255;
                
            %Get the data that is already on this plot before erasing it
            if nargin > 1
                currentData = ax.Children(1).XData;
            end
            
            %Use the non-default colormap
            if nargin > 2
                map = cmap;
            end

            pad = [];
            
            %Look to see whether or not there was prior data
            if ~isnan(currentData)
                xData = [currentData currentData(end)+1];
                
                %Pre-allocate space for the 6 cost contributions of
                %everything that was shown previously
                yData = zeros(length(xData)-1,6);
                
                %Extract the prior breakdowns that were on the chart
                %The organization is such that Children(i) is a particular
                %cost contribution, not a particular case
                for i = 1:length(ax.Children)
                    yData(:,i) = ax.Children(i).YData;
                end
                
                %Arrange it so that data is still presented in the same
                %order
                yData = fliplr(yData);
                
                %If there were more cost contributions present on the
                %prior chart, just pad whatever is not there with 0s
                %(typically this shouldn't happen)
                if i > length(this.breakdown)
                    pad = zeros(1,i-length(this.breakdown));
                end
                
                yData = [yData ; pad , this.breakdown'];
                
                %Replot the data
                cla(ax);
                b = bar(ax,xData,yData,'stacked','FaceColor','flat');
                for i = 1:size(b,2)
                    b(i).CData = repmat(map(i,:),size(b(i).CData,1),1);
                end
            else
                %Make up some fake data to hide so that MATLAB is happy
                xData = [-1 1];
                yData = [ones(6,1), this.breakdown ]';
                
                %Plot the data
                figure(1); clf;
                b = bar(xData,yData,'stacked','FaceColor','flat');
                for i = 1:size(b,2)
                    b(i).CData = repmat(map(i,:),size(b(i).CData,1),1);
                end
                ax = gca;
            end
            
            %Hide any data hidden behind x = 0
            xlim([0 xData(end)+1])
            
            %Add a legend to the figure
            legend(ax.Children(1:6),...
                fliplr({'Electricity','Separations','Electrolyte','Additional','BOP','Capital'}),...
                'AutoUpdate','off','Location','Best')
        end
        
        function runSensitivity(this,paramName,paramValues,fig)
            %runSensitivity Shortcut method for running and plotting
            %analysis
            %
            %Runs a sensitivity analysis over a list of parameters and
            %plots the cost results on a figure
            %
            %Inputs:
            %   paramName   -- str      --  name of the parameter for which
            %                               to run sensitivity
            %   paramValues -- N x 1    --  values the parameter should
            %                               take
            %   fig         -- handle   --  handle to the figure that we
            %                               should plot the results on
            %Outputs:
            %   Updated fig with the new sensitivity plots
            
            %Call the vary method on the list of parameters to test (this
            %work's but should be used sparingly)
            this.vary(paramName,paramValues)
            
            %Parse the parameter name so that the results can be plotted
            name = EconomicCase.convertName(paramName);
            
            %Make a new figure if one isn't provided
            if nargin < 4 || isempty(fig)
                fig = figure('Name',['Sensitivity on ',paramName]);
                axes(fig)
            end
            
            %Plot results from the sensitivity run
            hold(fig.Children(end),'on')
            plot(fig.Children(end),this.(name),this.cost)
        end
    end
    
    methods (Access = private)
        function res = evalCost(this,name,value,idx)
            %evalCost calculates the cost for a certain parameter value and
            %returns the result
            %
            %Wrapper for the VARY function, which is used to re-evaluate
            %the model. In this case, evalCost also checks whether or not
            %certain parameter values are allowed, to ensure physical
            %behavior of the solver.
            %
            %Inputs:
            %   name    -- str      -- Name of the parameter
            %   value   -- double   -- New value being tested
            %   idx     -- double   -- Valid parameter values
            %Outputs:
            %   res     -- double   -- Cost of the electrolyzer
            
            %All values are valid by default
        	if nargin < 4
        		idx = true(size(value));
            end

            %Make sure to limit the current density applied so that it is
            %never over limiting
            switch EconomicCase.convertName(name)
                case 'currentDensity'
                    if any(abs(value) > abs(this.limitingCurrentDensity))
                        if length(this.limitingCurrentDensity) ~= 1
                            value(abs(value) > abs(this.limitingCurrentDensity)) ...
                                = this.limitingCurrentDensity(abs(value) > abs(this.limitingCurrentDensity));
                        else
                            value(abs(value) > abs(this.limitingCurrentDensity)) = ...
                                this.limitingCurrentDensity;
                        end
                        
                        warning('Limiting the applied current density')
                    end
            end
            
            %Recalculate the model
            this.vary(name,value)
            res = this.cost(idx);
        end
            
        function runModel(this)
            %runModel Calculates the economic model for the electrolyzer
            %
            %Using the output set assignment, calculate the cost values
            %from the model parameter inputs
            %
            %Inputs:
            %   None - all of the parameter values that have previously
            %   been specified in the economic case
            %Outputs:
            %   None - updates the instance of the economic case to reflect
            %   that the model has calculated and there is a cost
            
            this.setRateExpression();
            this.calculateCurrent();
            this.calculateReactorArea();
            this.calculateOhmicLosses();
            this.calculateLimitingCurrentDensity();
            
            if abs(this.currentDensity) >= abs(this.limitingCurrentDensity)
                warning('You are over limiting current density, check values')
            end
            
            this.calculateMassTransferLosses();
            this.calculateKineticLosses();
            this.calculateOpenCircuitVoltage();
            this.calculateCellVoltage();
            this.calculateInletFlowRate();
            this.calculateFeedFlowRate();
            this.calculateCapitalCosts();
            this.calculateBOPCosts();
            this.calculateSeparationCosts();
            this.calculateElectricityCosts();
            this.calculateElectrolyteCosts();
            this.calculateTotalCost();
        end
        
        function setRateExpression(this)
            %setRateExpression chooses the electrokinetic model for
            %calculating kinetic overpotential
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            switch lower( this.rateName (~ isspace ( this.rateName ) ) )
                case {'bv','butler-volmer','butlervolmer'}
                    this.rateExpression = @(n) ( exp (...
                        - this.numberElectrons .* this.FARADAY_CONSTANT...
                        .* this.transferCoefficient .* n ...
                        ./ this.GAS_CONSTANT ./ this.temperature ) - ...
                        exp ( this.numberElectrons .* this.FARADAY_CONSTANT ...
                        .* ( 1 - this.transferCoefficient ) .* n ...
                        ./ this.GAS_CONSTANT ./ this.temperature ) );
                otherwise
                    error('Unknown model, try BV!')
            end
        end
        
        function calculateCurrent(this)
            %calculateCurrent computes the total required current
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Use the total mass balance in the reactor
            this.current = - this.productionRate .* this.numberElectrons ...
                .* this.FARADAY_CONSTANT ./ this.productFE ;
        end
        
        function calculateReactorArea(this)
            %calculateReactorArea computes the required area to achieve the
            %total current requirement
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Yep, we just have to divide
            this.reactorArea = this.current ./ this.currentDensity;
        end
        
        function calculateOhmicLosses(this)
            %calculateOhmicLosses Ohm's law for electrolyte conductivity
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Ohm's law
            this.ohmics = this.currentDensity .* this.cellGap ... 
                ./ this.conductivity ./ this.CM_TO_M^2;
        end
        
        function calculateLimitingCurrentDensity(this)
            %calculateLimitingCurrentDensity uses 1D diffusion at SS to a
            %flat plate to find j_lim
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %1D steady state diffusion model
            this.limitingCurrentDensity = - this.numberElectrons ...
                .* this.FARADAY_CONSTANT .* this.diffusionCoeff ...
                .* this.molarity .* ( 1 - this.conversion ) ...
                ./ this.blThickness ;
        end
        
        function calculateMassTransferLosses(this)
            %calculateMassTransferLosses uses the Nernst equation to
            %compute the overall overpotential from MT
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Adaptation of Nernst equation using surface instead of bulk
            %concentrations where surface concentrations can be calculated
            %from the approach to j_lim
            this.massTransfer = this.GAS_CONSTANT .* this.temperature ...
                ./ this.numberElectrons ./ this.FARADAY_CONSTANT ...
                .* log ( 1 - this.currentDensity ...
                ./ this.limitingCurrentDensity ) ;
        end
        
        function calculateKineticLosses(this)
            %calculateKineticLosses computes the kinetic overpotentials
            %from the kinetic expression
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Start out with a guess that the overpotential is 100 mV
            n0 = -0.1 .* ones(size(this.currentDensity));
            
            %Solve the kinetic expression
            options = optimoptions('fsolve','display','off');
            this.kinetics = fsolve(@(n) this.currentDensity...
                - this.exchangeCurrentDensity .* ...
                this.rateExpression(n) , n0 , options);
        end
        
        function calculateOpenCircuitVoltage(this)
            %calculateOpenCircuitVoltage uses Nernst equation to bias
            %standard conditions
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %The Nernst equation
            this.ocv = this.standardPotential + this.GAS_CONSTANT ...
                .* this.temperature ./ this.numberElectrons ...
                ./ this.FARADAY_CONSTANT .* log ( ( 1 - this.conversion )...
                ./ this.conversion ./ this.productFE ) ;
        end
        
        function calculateCellVoltage(this)
            %calculateCellVoltage adds all of the cell inefficiencies
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            
            this.cellVoltage = this.ocv + this.ohmics + this.massTransfer ...
                + this.kinetics;
        end

        function calculateInletFlowRate(this)
            %calculateInletFlowRate does mass balance based on how much
            %feed material needs to enter reactor
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %The amount of feed consumed is just however much goes to
            %producing both waste and desired product, with any unconverted
            %material coming out the back end
            wasteFE = 1 - this.productFE - this.herFE;
            this.flowRate = - this.current ./ this.conversion ... 
                ./ this.FARADAY_CONSTANT .* ( this.productFE ...
                ./ this.numberElectrons + wasteFE ./ this.wasteElectrons );
        end
        
        function calculateFeedFlowRate(this)
            %calculateFeedFlowRate accounts for any recycling of unreacted
            %material
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            this.feedRate = this.flowRate .* ( 1 - this.recycleFeed ...
                .* ( 1 - this.conversion ) );
        end
        
        function calculateCapitalCosts(this)
            %calculateCapitalCosts determines the capital cost
            %contributions
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %First calculate what the capital cost factor will be at this
            %scale
            lnP = log(this.basePrice) + this.scaleArea ...
                .* log ( this.productionRate / this.BASE_RATE );
            this.areaPrice = exp(lnP);
            
            %Calculate the capital cost using prior values
            this.capitalCosts = this.reactorArea .* ( this.areaPrice ...
                + this.catalystLoading .* this.catalystPrice );
        end
        
        function calculateBOPCosts(this)
            %calculateBOPCosts determines bop contribution
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Same as above, determine BOP cost factor at this throughput
            lnP = log(this.baseBopPrice) + this.scaleBop ...
                .* log ( this.productionRate / this.BASE_RATE );
            this.areaBOPPrice = exp(lnP);
            
            %Determine what the price will be
            this.bopCosts = this.areaBOPPrice .* this.reactorArea;
        end
        
        function calculateSeparationCosts(this)
            %calculateSeparationsCosts estimates separations via Sherwood
            %analysis
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Mass flows from mass balance
            prodFlow = this.productionRate * this.prodMW;
            wasteFlow = -this.current/ this.FARADAY_CONSTANT ...
                .* ( 1 - this.productFE - this.herFE ) ./ this.wasteElectrons * this.wasteMW;
            hydrogenFlow = -this.current/ this.FARADAY_CONSTANT ...
                .* this.herFE ./ 2 * 0.00202; %2 = number of electrons to produce H2
            reactantFlow = this.flowRate .* ( 1 - this.conversion ) * this.reactantMW;
            
            
            totalFlow = prodFlow + wasteFlow + hydrogenFlow + reactantFlow;
            
            %Separation costs according to Sherwood (PNAS 2011 paper with
            %plot - House et al)
            this.sepCosts = this.kp .* totalFlow;
        end
        
        function calculateElectricityCosts(this)
            %calculateElectricityCosts considers the electrical
            %requirements
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %It's all about the power draw
            this.electricityCosts = this.current .* this.cellVoltage ...
                .* this.electricityPrice ./ this.WATT_TO_KW ...
                ./ this.SECONDS_TO_HOURS;
        end
        
        function calculateElectrolyteCosts(this)
            %calculateElectrolyteCosts uses the prior mass balances to
            %determine how much material is needed
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Do mass balances on each of the individual species and sum
            %them
            reactant = this.feedRate .* this.reactantMW .* this.feedPrice;
            solvent = this.flowRate .* this.solventPrice .* ( 1 ...
                - this.recycleSolvent ) ./ this.molality ;
            salt = - this.current ./ this.FARADAY_CONSTANT ...
                .* this.electrolyteRatio .* this.saltMW .* this.saltPrice ...
                .* ( 1 - this.recycleElectrolyte ) ;
            this.electrolyteCosts = reactant + solvent + salt;
        end
        
        function calculateTotalCost(this)
            %calculateTotalCost adds everything together
            %
            %Inputs:
            %   None - prior parameters of the EconomicCase instance
            %Outputs:
            %   None - updates instance
            
            %Sum everything up and annualize capital costs by the
            %operating lifetime
            
            OPEX = ( this.electricityCosts + this.electrolyteCosts ...
                + this.sepCosts ) ; 
            % Sep costs should likely be capital after Aspen sim
            
            CAPEX = this.capitalCosts + this.bopCosts ; 
            
            years = this.lifetime * ( this.SECONDS_TO_YEARS ...
                * this.operatingDays / 365.25 ) ^ (-1);
            if this.costOfCapital ~= 0 % convert opex to $/yr rather than $/s
                noAdditions = OPEX * ( this.SECONDS_TO_YEARS ...
                            * this.operatingDays / 365.25 ) + CAPEX ...
                            * this.costOfCapital ...
                            / ( 1 - ( 1 + this.costOfCapital ) .^ -years );
                noAdditions = noAdditions * ( this.SECONDS_TO_YEARS ...
                            * this.operatingDays / 365.25 ) ^ (-1); %Convert EAC back
            else
                noAdditions = OPEX + CAPEX / this.lifetime ; 
            end            
            this.cost = noAdditions ...
                ./ ( 1 - this.additionalFactor ) ./ this.productionRate ...
                ./ this.prodMW;
            
            %Calculate the breakdown for each of the cost contributions as
            %normalized by production rate
            electricity = this.electricityCosts  ...
                ./ this.productionRate ./ this.prodMW ;
            seps = this.sepCosts...
                ./ this.productionRate ./ this.prodMW ;
            electrolyte = this.electrolyteCosts  ...
                ./ this.productionRate ./ this.prodMW ;
            if this.costOfCapital == 0    
                cell = this.capitalCosts ./ this.productionRate ...
                    ./ this.lifetime ./ this.prodMW ;
                bop = this.bopCosts ./ this.productionRate ...
                    ./ this.lifetime ./ this.prodMW ;
            else
                cell = this.capitalCosts .* this.costOfCapital ...
                    / ( 1 - ( 1 + this.costOfCapital ) .^ -years ) ;
                cell = cell * ( this.SECONDS_TO_YEARS ...
                            * this.operatingDays / 365.25 ) ^ (-1);
                cell = cell ./ this.productionRate ./ this.prodMW;
                        
                bop = this.bopCosts .* this.costOfCapital ...
                    / ( 1 - ( 1 + this.costOfCapital ) .^ -years ) ;
                bop = bop * ( this.SECONDS_TO_YEARS ...
                            * this.operatingDays / 365.25 ) ^ (-1);
                bop = bop ./ this.productionRate ./ this.prodMW;
            end
            cost = electrolyte + electricity + cell + bop + seps;
            finalCost = cost ./ ( 1 - this.additionalFactor ) ;
            
            additional = this.cost - electricity - electrolyte - cell - bop - seps;
            
            %Resize as necessary
            if any(size(electricity) ~= size(this.cost))
                electricity = repmat(electricity,size(this.cost));
            end
            if any(size(seps) ~= size(this.cost))
                seps = repmat(seps,size(this.cost));
            end
            if any(size(electrolyte) ~= size(this.cost))
                electrolyte = repmat(electrolyte,size(this.cost));
            end
            if any(size(cell) ~= size(this.cost))
                cell = repmat(cell,size(this.cost));
            end
            if any(size(bop) ~= size(this.cost))
                bop = repmat(bop,size(this.cost));
            end
            if any(size(additional) ~= size(this.cost))
                additional = repmat(additional,size(this.cost));
            end
            
            %Store in the object
            this.breakdown = [electricity; seps; electrolyte; additional ;bop ;cell];
        end
        
    end
    
    methods (Access = private, Static = true)
        function msg = convertName(paramName)
            %convertName Helper function for modifying any of the inputs to
            %the EconomicCase
            %
            %Takes common spelling of parameter names and converts them to
            %the names that I have implemented in the model
            %
            %Inputs:
            %   paramName   --  str     --  Name of the parameter
            %Outputs:
            %   msg         --  str     --  The correct spelling of a
            %                               property in the model
            switch lower(paramName(~isspace(paramName)))
                case 'feedprice'
                    msg = 'feedPrice';
                case 'saltprice'
                    msg = 'saltPrice';
                case 'solventprice'
                    msg = 'solventPrice';
                case 'catalystprice'
                    msg = 'catalystPrice';
                case 'electricityprice'
                    msg = 'electricityPrice';
                case {'capitalprice','areaprice'}
                    msg = 'basePrice';
                case 'bopprice'
                    msg = 'baseBopPrice';
                case {'additionalfraction','additionalfactor'}
                    msg = 'additionalFactor';
                case {'standardvoltage','standardpotential'}
                    msg = 'standardPotential';
                case 'transfercoefficient'
                    msg = 'transferCoefficient';
                case 'numberelectrons'
                    msg = 'numberElectrons';
                case 'wasteelectrons'
                    msg = 'wasteElectrons';
                case {'productefficiency','productfe','prodfe'}
                    msg = 'productFE';
                case {'herefficiency','herfe'}
                    msg = 'herFE';
                case 'currentdensity'
                    msg = 'currentDensity';
                case 'exchangecurrentdensity'
                    msg = 'exchangeCurrentDensity';
                case 'molality'
                    msg = 'molality';
                case 'molarity'
                    msg = 'molarity';
                case {'feedmw','reactantmw'}
                    msg = 'reactantMW';
                case 'saltmw'
                    msg = 'saltMW';
                case {'productmw','prodmw'}
                    msg = 'prodMW';
                case 'electrolyteratio'
                    msg = 'electrolyteRatio';
                case {'diffusioncoeff','diffusioncoefficient'}
                    msg = 'diffusionCoeff';
                case 'blthickness'
                    msg = 'blThickness';
                case 'productionrate'
                    msg = 'productionRate';
                case 'conversion'
                    msg = 'conversion';
                case 'cellgap'
                    msg = 'cellGap';
                case 'conductivity'
                    msg = 'conductivity';
                case 'catalystloading'
                    msg = 'catalystLoading';
                case 'temperature'
                    msg = 'temperature';
                case 'lifetime'
                    msg = 'lifetime';
                case 'recyclefeed'
                    msg = 'recycleFeed';
                case 'recyclesolvent'
                    msg = 'recycleSolvent';
                case {'recyclesalt','recycleelectrolyte'}
                    msg = 'recycleElectrolyte';
                case {'operatingdays'}
                    msg = 'operatingDays';
                case {'kp'}
                    msg = 'kp';
                otherwise
                    error('Unknown name to convert - check your spelling')
            end
        end
    end
    
end