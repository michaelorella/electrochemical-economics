%Written by: Mike Orella
%Last Edited by: Mike Orella 28 May 2018
%Class file for handling technoeconomic model of electrolytic reactor for
%reaction types R --> P , R --> W. For details on derivations of equations
%presented herein, see notebook

classdef EconomicCase < handle
    properties (Access = private)
        costTarget;
        paramToManipulate;
        
        %% Specified Values
        %Material, Electricity, and System Pricing
        feedPrice = 0.0;                     % [=] $ kg^{-1}
        saltPrice = 0.1;                     % [=] $ kg^{-1}
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
        molality = 1;                       % [=] mol R kg^{-1}
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
        
        basePrice = 1.1011e4;               % [=] $ m^{-2}
        baseBopPrice = 1.5873e4;            % [=] $ m^{-2}
        
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
        %Reactor properties
        reactorArea;
        
        %Electrical properties
        current;
        ohmics;
        massTransfer;
        kinetics;
        ocv;
        cellVoltage;
        
        %Final calculated cost values
        capitalCosts;
        bopCosts;
        electricityCosts;
        electrolyteCosts;
        sepCosts;
        cost;
        
        %Output from inverted model
        output;
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
        %Constructor definition for the EconomicCase class -- decides
        %whether sensitivity analysis or inversion is being performed, and
        %builds correct model
        function this = EconomicCase(struct,costTarget,paramToVary)
            %Inputs:
            %   struct                  --  struct - contains all of the
            %                               information that should be used
            %                               for the default construction of
            %                               the model (i.e. all of the
            %                               properties are contained within
            %                               the structure)
            %   costTarget              --  double - if model is being
            %                               inverted
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

                opts = optimoptions('fmincon','display','iter');
                ub = Inf(size(this.cost));
                lb = -Inf(size(this.cost));
                if strcmp(EconomicCase.convertName(paramToVary),'currentDensity')
                    ub = zeros(size(this.cost));
                    if size(this.limitingCurrentDensity) == size(this.cost)
                        lb = this.limitingCurrentDensity;
                    else
                        lb = repmat(this.limitingCurrentDensity,size(this.cost));
                    end
                end
                keyboard
                guess = this.(EconomicCase.convertName(paramToVary));
                if length(guess) ~= length(this.cost)
                	guess = repmat(guess,size(this.cost));
                end
                [result,fval,flag,out,~,g,H] = fmincon(@(x) norm(this.evalCost(paramToVary,x) - costTarget)^2,...
                    guess,[],[],[],[],lb,ub,[],opts)
                this.output = result;
                if flag > 0
                    this.output = result;
                else
                    if contains(out.message,'No solution found')
                        warning('No solution found in this case, the calculated cost is %0.2f $/kg',fval + costTarget)
                    end
                end
            end
            

        end
        
        %Function for changing model parameters and rerunning the model
        %with the newly specified input
        function vary(this,paramName,paramValue)
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
            name = EconomicCase.convertName(paramName);
            result = this.(name);
        end
        
        
        function plotBreakdown(this,ax,cmap)
            currentData = NaN;
            if nargin > 2
                currentData = ax.Children(1).XData;
            elseif nargin >= 1
                cmap = [206.04 59.16 59.16;
                    0 127.5 0;
                    8.95 63.25 189.95;
                    117.3 0 117.3;
                    168.3 83.16 0;
                    135.41 135.41 17.59;
                    23.87 108.73 108.73;
                    91.8 91.8 91.8]/255;
            end
               
            pad = [];
            if ~isnan(currentData)
                xData = [currentData currentData(end)+1];
                yData = zeros(length(xData)-1,6);
                for i = 1:length(ax.Children)
                    yData(:,i) = ax.Children(i).YData;
                end
                yData = fliplr(yData);
                
                if i > length(this.breakdown)
                    pad = zeros(1,i-length(this.breakdown));
                end
                yData = [yData ; pad , this.breakdown'];
                
                cla(ax);
                
                b = bar(ax,xData,yData,'stacked','FaceColor','flat');

                for i = 1:size(b,2)
                    b(i).CData = repmat(cmap(i,:),size(b(i).CData,1),1);
                end
                
            else
                xData = [-1 1];
                yData = [ones(6,1), this.breakdown ]';
                figure(1); clf;
                
                b = bar(xData,yData,'stacked','FaceColor','flat');
                
                for i = 1:size(b,2)
                    b(i).CData = repmat(cmap(i,:),size(b(i).CData,1),1);
                end
                
                ax = gca;
            end
            xlim([0 xData(end)+1])
            
            legend(ax.Children(1:6),...
                fliplr({'Electricity','Separations','Electrolyte','Additional','BOP','Capital'}),...
                'AutoUpdate','off')
        end
        
        function runSensitivity(this,paramName,paramValues,fig,...
                fileLocation)
            this.vary(paramName,paramValues)
            name = EconomicCase.convertName(paramName);
            if nargin < 4 || isempty(fig)
                fig = figure('Name',['Sensitivity on ',paramName]);
                axes(fig)
            end
            %Plot results from the sensitivity run
            hold(fig.Children(end),'on')
            plot(fig.Children(end),this.(name),this.cost)
            
            if nargin == 5
                %Save generated figure in the desired location
            end
        end
    end
    
    methods (Access = private)
        function res = evalCost(this,name,value,idx)

        	if nargin < 4
        		idx = logical(ones(size(this.cost)));
        	end

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
            this.vary(name,value)
            res = this.cost(idx);
        end
            
        function runModel(this)
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
            if or( strcmpi( this.rateName , 'BV' ) ,...
                   strcmpi( this.rateName , 'Butler-Volmer' ) )
               this.rateExpression = @(n) ( exp (...
                   - this.numberElectrons .* this.FARADAY_CONSTANT...
                   .* this.transferCoefficient .* n ...
                   ./ this.GAS_CONSTANT ./ this.temperature ) - ...
                   exp ( this.numberElectrons .* this.FARADAY_CONSTANT ...
                   .* ( 1 - this.transferCoefficient ) .* n ...
                   ./ this.GAS_CONSTANT ./ this.temperature ) );                   
%            elseif or( strcmp( this.rateName , 'MHC' ) ,...
%                    strcmp( this.rateName , 'Marcus-Hush-Chidsey' ) )
%                this.rateExpression = @(n) [Insert MHC] ;
%            elseif or( strcmp( this.rateName , 'BVR' ) ,...
%                    strcmp( this.rateName , 'Butler-Volmer R' ) )
%                this.rateExpression = @(n) [Insert BVR];
           else
               error( 'Rate expression not recognized, try BV' ) ;
           end
        end
        
        function calculateCurrent(this)
            this.current = - this.productionRate .* this.numberElectrons ...
                .* this.FARADAY_CONSTANT ./ this.productFE ;
        end
        
        function calculateReactorArea(this)
            this.reactorArea = this.current ./ this.currentDensity;
        end
        
        function calculateOhmicLosses(this)
            this.ohmics = this.currentDensity .* this.cellGap ... 
                ./ this.conductivity ./ this.CM_TO_M^2;
        end
        
        function calculateLimitingCurrentDensity(this)
            this.limitingCurrentDensity = - this.numberElectrons ...
                .* this.FARADAY_CONSTANT .* this.diffusionCoeff ...
                .* this.molarity .* ( 1 - this.conversion ) ...
                ./ this.blThickness ;
        end
        
        function calculateMassTransferLosses(this)
            this.massTransfer = this.GAS_CONSTANT .* this.temperature ...
                ./ this.numberElectrons ./ this.FARADAY_CONSTANT ...
                .* log ( 1 - this.currentDensity ...
                ./ this.limitingCurrentDensity ) ;
        end
        
        function calculateKineticLosses(this)
            n0 = -0.1 .* ones(size(this.currentDensity));
            options = optimoptions('fsolve','display','off');
            this.kinetics = fsolve(@(n) this.currentDensity...
                - this.exchangeCurrentDensity .* ...
                this.rateExpression(n) , n0 , options);
        end
        
        function calculateOpenCircuitVoltage(this)
            this.ocv = this.standardPotential + this.GAS_CONSTANT ...
                .* this.temperature ./ this.numberElectrons ...
                ./ this.FARADAY_CONSTANT .* log ( ( 1 - this.conversion )...
                ./ this.conversion ./ this.productFE ) ;
        end
        
        function calculateCellVoltage(this)
            this.cellVoltage = this.ocv + this.ohmics + this.massTransfer ...
                + this.kinetics;
        end

        function calculateInletFlowRate(this)
            wasteFE = 1 - this.productFE - this.herFE;
            this.flowRate = - this.current ./ this.conversion ... 
                ./ this.FARADAY_CONSTANT .* ( this.productFE ...
                ./ this.numberElectrons + wasteFE ./ this.wasteElectrons );
        end
        
        function calculateFeedFlowRate(this)
            this.feedRate = this.flowRate .* ( 1 - this.recycleFeed ...
                .* ( 1 - this.conversion ) );
        end
        
        function calculateCapitalCosts(this)
            lnP = log(this.basePrice) + this.scaleArea ...
                .* log ( this.productionRate / this.BASE_RATE );
            this.areaPrice = exp(lnP);
            this.capitalCosts = this.reactorArea .* ( this.areaPrice ...
                + this.catalystLoading .* this.catalystPrice );
        end
        
        function calculateBOPCosts(this)
            lnP = log(this.baseBopPrice) + this.scaleBop ...
                .* log ( this.productionRate / this.BASE_RATE );
            this.areaBOPPrice = exp(lnP);
            this.bopCosts = this.areaBOPPrice .* this.reactorArea;
        end
        
        function calculateSeparationCosts(this)
            
            %Mass flows
            prodFlow = this.productionRate * this.prodMW;
            wasteFlow = -this.current/ this.FARADAY_CONSTANT ...
                .* ( 1 - this.productFE - this.herFE ) ./ this.wasteElectrons * this.wasteMW;
            hydrogenFlow = -this.current/ this.FARADAY_CONSTANT ...
                .* this.herFE ./ 2 * 0.00202; %2 = number of electrons to produce H2
            reactantFlow = this.flowRate .* ( 1 - this.conversion ) * this.reactantMW;
            
            
            totalFlow = prodFlow + wasteFlow + hydrogenFlow + reactantFlow;
            
            prodFrac = prodFlow ./ totalFlow;
            wastFrac = wasteFlow ./ totalFlow;
            hydrFrac = hydrogenFlow ./ totalFlow;
            reacFrac = reactantFlow ./ totalFlow;
            
            %Separation costs
            this.sepCosts = this.kp .* totalFlow;
        end
        
        function calculateElectricityCosts(this)
            this.electricityCosts = this.current .* this.cellVoltage ...
                .* this.electricityPrice ./ this.WATT_TO_KW ...
                ./ this.SECONDS_TO_HOURS;
        end
        
        function calculateElectrolyteCosts(this)
            reactant = this.feedRate .* this.reactantMW .* this.feedPrice;
            solvent = this.flowRate .* this.solventPrice .* ( 1 ...
                - this.recycleSolvent ) ./ this.molality ;
            salt = - this.current ./ this.FARADAY_CONSTANT ...
                .* this.electrolyteRatio .* this.saltMW .* this.saltPrice ...
                .* ( 1 - this.recycleElectrolyte ) ;
            this.electrolyteCosts = reactant + solvent + salt;
        end
        
        function calculateTotalCost(this)
            this.cost = ( this.electricityCosts + this.electrolyteCosts ...
                + this.sepCosts ...
                + ( this.capitalCosts + this.bopCosts ) ./ this.lifetime ...
                ) ./ ( 1 - this.additionalFactor ) ./ this.productionRate ...
                ./ this.prodMW;
            
            electricity = this.electricityCosts  ...
                ./ this.productionRate ./ this.prodMW ;
            seps = this.sepCosts...
                ./ this.productionRate ./ this.prodMW ;
            electrolyte = this.electrolyteCosts  ...
                ./ this.productionRate ./ this.prodMW ;
            cell = this.capitalCosts ./ this.productionRate ...
                ./ this.lifetime ./ this.prodMW ;
            bop = this.bopCosts ./ this.productionRate ...
                ./ this.lifetime ./ this.prodMW ;
            additional = this.cost - electricity - electrolyte - cell - bop;
            
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
            
            this.breakdown = [electricity; seps; electrolyte; additional ;bop ;cell];
        end
        
    end
    
    methods (Access = private, Static = true)
        function msg = convertName(paramName)
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
                case 'productmw'
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
                otherwise
                    error('Unknown name to convert - check your spelling')
            end
        end
    end
    
end