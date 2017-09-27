classdef CoRBF < Metamodel
    %CORBF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        corr        % Correlation function of coRBF
        hyp_corr    % Correlation length paramete (log scale)
        lb_hyp_corr % Lower bound of correlation length
        ub_hyp_corr % Upper bound of correlation length
        rho         % Scaling factor
        lb_rho      % Lower bound of scaling factor
        ub_rho      % Upper bound of scaling factor
        hyp_corr0   % Initial correlation length for optimization
        rho0        % Initial scaling parameter for optimization
        estimator   % Method for estimating parameters
        optimizer   % Optimization method for hyperparameters
                
        RBF_c % Low fidelity RBF (coarse)
        RBF_d % Difference model RBF
               
    end
    
    methods
        
        function obj=CoRBF(prob,y_ind,g_ind,varargin)
            % CoRBF constructor (see also Metamodel)
            %
            % Initialized a CoRBF object with mandatory inputs :
            % 	obj=CoRBF(prob,y_ind,g_ind)
            %
            % Initialized a CoRBF object with optionnal inputs :
            % 	obj=Cokriging(prob,y_ind,g_ind,varargin)
            %   obj=Cokriging(prob,y_ind,g_ind,'regpoly','regpoly0')
            %
            % Optionnal inputs [default value], * has to be replaced by HF or LF :
            %   'corr_*'      ['Corrmatern52'], 'Corrgauss', 'Corrlinear' , 'Corrthinplatespline' , 'Corrmultiquadric' , 'Corrcubic', 'Corrinvmultiquadric', 'Corrmatern32'
            %   'hyp_corr_*'  [Auto calibrate with training dataset]
            %   'rho'         [Auto calibrate with training dataset]
            %   'hyp_corr0_*' [Auto calibrate with training dataset]
            %   'rho0'        [Auto calibrate with training dataset]
            %   'lb_hyperp_*' [Auto calibrate with training dataset]
            %   'ub_hyperp_*' [Auto calibrate with training dataset]
            %   'lb_rho'      [Auto calibrate with training dataset]
            %   'ub_rho'      [Auto calibrate with training dataset]
            %   'estimator_*'  ['LOO'] , 'CV'  
            %   'optimizer_*'  ['CMAES'] , 'fmincon' 
            
            % Parser
            p = inputParser;
            p.KeepUnmatched = true;
            p.PartialMatching = false;
            p.addOptional('rho',[],@(x)isnumeric(x)&&(isempty(x)||isscalar(x)));
            p.addOptional('rho0',[],@(x)isnumeric(x)&&(isempty(x)||isscalar(x)));
            p.addOptional('lb_rho',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('ub_rho',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));            
            p.addOptional('corr_LF','Corrgauss',@(x)(isa(x,'char'))&&(strcmp(x,'Corrgauss')||strcmp(x,'Corrmatern32')||strcmp(x,'Corrmatern52')||strcmp(x,'Corrlinear')||strcmp(x,'Corrthinplatespline')||strcmp(x,'Corrinvmultiquadric')||strcmp(x,'Corrmultiquadric')||strcmp(x,'Corrcubic')));
            p.addOptional('hyp_corr_LF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('hyp_corr0_LF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('lb_hyp_corr_LF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('ub_hyp_corr_LF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('estimator_LF','LOO',@(x)(isa(x,'char'))&&(strcmp(x,'LOO')||strcmp(x,'CV')));
            p.addOptional('optimizer_LF','CMAES',@(x)(isa(x,'char'))&&(strcmp(x,'CMAES')||strcmp(x,'fmincon')));
            
            p.addOptional('corr_HF','Corrgauss',@(x)(isa(x,'char'))&&(strcmp(x,'Corrgauss')||strcmp(x,'Corrmatern32')||strcmp(x,'Corrmatern52')||strcmp(x,'Corrlinear')||strcmp(x,'Corrthinplatespline')||strcmp(x,'Corrinvmultiquadric')||strcmp(x,'Corrmultiquadric')||strcmp(x,'Corrcubic')));
            p.addOptional('hyp_corr_HF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('hyp_corr0_HF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('lb_hyp_corr_HF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('ub_hyp_corr_HF',[],@(x)isnumeric(x)&&(isempty(x)||isrow(x)));
            p.addOptional('estimator_HF','LOO',@(x)(isa(x,'char'))&&(strcmp(x,'LOO')||strcmp(x,'CV')));
            p.addOptional('optimizer_HF','CMAES',@(x)(isa(x,'char'))&&(strcmp(x,'CMAES')||strcmp(x,'fmincon')));
            p.parse(varargin{:})
            in = p.Results;
            unmatched = p.Unmatched;
            
            % Superclass constructor
            obj@Metamodel(prob,y_ind,g_ind,unmatched)
            
            % Store
            obj.corr = { in.corr_LF , in.corr_HF };
            obj.hyp_corr = {in.hyp_corr_LF , in.hyp_corr_HF};
            obj.hyp_corr0 = {in.hyp_corr0_LF , in.hyp_corr0_HF};
            obj.lb_hyp_corr = {in.lb_hyp_corr_LF , in.lb_hyp_corr_HF};
            obj.ub_hyp_corr = {in.ub_hyp_corr_LF , in.ub_hyp_corr_HF};
            obj.lb_rho = in.lb_rho;
            obj.ub_rho = in.ub_rho;
            obj.rho0 = in.rho0;
            obj.rho = in.rho;
            obj.estimator = {in.estimator_LF , in.estimator_HF};
            obj.optimizer = {in.optimizer_LF , in.optimizer_HF};
            
            % Training
            obj.Train();
            
        end
        
    end
    
end
