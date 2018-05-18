%
% Copyright (c) 2017, RTE (http://www.rte-france.com) and RSE (http://www.rse-web.it) 
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
%% m1file - sampling network data, to be read
%% m2file - FEA output file (output from module1 and module2), to be read  
%% ofile  - module3 output file, to be written
%% s_scenarios - number of samples to generate (in ofile)
%% s_rng_seed - int seed (optional, default is 'shuffle' on current date)
%% option_sign - option to avoid sign inversion in samples wrt relevant forecasts
% UPDATE June-July 2017:
% 1) added option of separate analysis of unimodal and multimodal variables
% (added type_Xm for multimodal vars)
% 2) added deterministic variation of P andQ variables in case of
% "deterministic" option (see from row 467 onwards)
% UPDATE Sept - OCt 2017:
% added the homothetic disaggregation of crossborder variables onto the
% loads of each nation
function exitcode=MCLA_HELPER(m1file,m3file, ofile, s_scenarios,option_sign,centerings,full_deps)
close all;
mversion='1.8.2';
disp(sprintf('wp5 - MCLA - version: %s', mversion));
disp(sprintf(' base case file:  %s',m1file));
disp(sprintf(' m3file:  %s',m3file));
disp(sprintf(' ofile:  %s', ofile));
disp(sprintf(' scenarios:  %s',s_scenarios));
disp(sprintf(' option_sign:  %s',option_sign));
disp(sprintf(' centering:  %s', centerings));
disp(sprintf(' full correlation in Gaussian cond. sampling:  %s', full_deps));

moutput.errmsg='Ok';
try
    % module1: struct, output from module1
    load(m1file);
        % module2:  module2 output
    load(m3file);
    % s_scenarios: number of samples to generate
    scenarios=str2double(s_scenarios);
    opt_sign = str2double(option_sign);
    centering = str2double(centerings);
    isdeterministic = out(1).mod_deterministic;
    homoth = out(1).mod_homoth;
     full_dep = str2double(full_deps);
    %if seed is not specified, 'shuffle'  on current platform time    
    
disp(sprintf('flagPQ:  %u', out(1).flagPQ));
disp(sprintf('isdeterministic:  %u', out(1).mod_deterministic));
disp(sprintf('homoth:  %u', out(1).mod_homoth));
disp(sprintf('conditional_sampling:  %u', out(1).conditional_sampling));
disp(['preprocessing: type_x, etc.'])
tic;
% keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here start RSE CODE, EXTRACTED FROM TEST_MCLA.m example
% with respect to the original TEST_MCLA.m :
%  - changed input matrix name from X to inj_ID
%  - 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% type_X is the vector which specifies the nature of the stochastic
% injections (RES or load). here is an example with 3 RES and one stochastic load. the vector must be
% completed taking information from IIDM.

% flagPQ: =0 se ci sono solo P stocastiche, =1 se anche le Q sono
% stocastiche
%%%%% 
y0=[];y0m=[];
% conditional_sampling=0;
if isdeterministic == 0
for iout = 1:length(out)
   type_X=[];type_Xm=[];
    conditional_sampling = out(iout).conditional_sampling;
    mod_gaussian = out(iout).mod_gaussian;
     mod_unif = out(iout).mod_unif;
    dati_condUNI = out(iout).dati_condUNI;
    dati_condMULTI = out(iout).dati_condMULTI;
    dati_Q = out(iout).dati_Q;
    flagPQ = out(iout).flagPQ;
    maxvalue = out(iout).maxvalue;
    module2 = out(iout).module2;
     module3 = out(iout).module3;
     out(iout).module3=[]; %free variable memory
     inj_ID = out(iout).inj_ID;
     type_X = [];
     flagesistenza = out(iout).flagesistenza;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if homoth == 1
        nations = unique(out(iout).nation);nats=0;vect_nat=[];
        for ina = 1:length(nations)
           
            idxg = intersect(intersect(find(ismember({generatore.nation},nations{ina})),find(not(isnan([generatore.Q])))),find(not(isnan([generatore.P]))));
            idxc = intersect(intersect(find(ismember({carico.nation},nations{ina})),find(not(isnan([carico.Q])))),find(not(isnan([carico.P]))));
            inj_ids = find(ismember(out(iout).nation,nations{ina}));
            
            if isempty(idxg)==0 || isempty(idxc)==0
            nats = nats+1;
        carico1(nats).P =  -sum([generatore(idxg).P]) - sum([carico(idxc).P]);
        carico1(nats).Q = -sum([generatore(idxg).Q]) - sum([carico(idxc).Q]);
        carico1(nats).codice = inj_ID{inj_ids(1)}(1:end-2);
        carico1(nats).conn=1;
            else
                vect_nat=[vect_nat ina];
            end
        end
        generatore1=generatore;
        nations(vect_nat)=[];
    else
         carico1 = carico;
        generatore1 = generatore;
         nations = [];
    end
    
    if conditional_sampling == 1 && mod_gaussian == 0 && mod_unif == 0
        if isempty(dati_condUNI)==0
        idx_err0 = dati_condUNI.idx_err0;
        idx_fore0 = dati_condUNI.idx_fore0;
        inj_ID0 = dati_condUNI.inj_ID0;
        idx_err = dati_condUNI.idx_err;
        inj_IDQ = dati_Q.inj_IDQ;
        limits_reactive=[];
        type_X=zeros(2,length(inj_ID0));
        y0 = zeros(1,length(idx_fore0));
        y1 = zeros(1,length(inj_ID0));
        if flagPQ == 0
            
            for jcol = 1:size(inj_ID0,2)
                idxgen = find(ismember({generatore1.codice},inj_ID0{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID0{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_X(:,jcol) = [1;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = generatore1(idxgen(1)).P;
                                y1(jcol)=generatore1(idxgen(1)).P;
                            end
                        else
                            type_X(:,jcol) = [4;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = generatore1(idxgen(1)).Q;
                                y1(jcol)=generatore1(idxgen(1)).Q;
                            end
                        end
                        %type_X(5,jcol) = [generatore1(idxgen(1)).nation];
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1% && carico1(idxload(1)).P ~= 0 && carico1(idxload(1)).Q ~= 0
                        type_X(:,jcol) = [2;idxload(1)];
                        if ismember(jcol,idx_fore0)
                            y0(find(idx_fore0==jcol)) = carico1(idxload(1)).P;
                            y1(jcol) = carico1(idxload(1)).P;
                        end
                        if isempty(maxvalue)
                            limits_reactive(idxload(1),1:2)=[-9999 9999];
                        else
                            jquale = find(ismember(inj_IDQ,carico1(idxload).codice));
                            
                            limits_reactive(idxload(1),1:2)=maxvalue(jquale,:);
                            
                        end
                       %type_X(5,jcol) = [carico1(idxload(1)).nation]; 
                    end
                end
                
            end
        else
            for jcol = 1:size(inj_ID0,2)
                idxgen = find(ismember({generatore1.codice},inj_ID0{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID0{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_X(:,jcol) = [1;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = generatore1(idxgen(1)).P;
                                y1((jcol)) = generatore1(idxgen(1)).P;
                            end
                        else
                            type_X(:,jcol) = [4;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = generatore1(idxgen(1)).Q;
                                y1((jcol)) = generatore1(idxgen(1)).Q;
                            end
                        end
                        %type_X(5,jcol) = [generatore1(idxgen(1)).nation];
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_X(:,jcol) = [2;idxload(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = carico1(idxload(1)).P;
                                y1(jcol) = carico1(idxload(1)).P;
                            end
                        else
                            type_X(:,jcol) = [3;idxload(1)];
                            if ismember(jcol,idx_fore0)
                                y0(find(idx_fore0==jcol)) = carico1(idxload(1)).Q;
                                y1(jcol) = carico1(idxload(1)).Q;
                            end
                        end
                        %type_X(5,jcol) = [carico1(idxload(1)).nation]; 
                    end
                end
            end
        end
        
        idx_miss = find(~any(type_X,1));
        idx_available = setdiff([1:size(type_X,2)],idx_miss);
        type_X(4,idx_fore0(ismember(idx_fore0,idx_available)))=-1;
        type_X(4,idx_err0(ismember(idx_err0,idx_available)))=1;
        type_X(3,:) = zeros(1,size(type_X,2));
        type_X(3,idx_available) = [1];
        
        for ifore = 1:length(idx_fore0)
            quali_inj = type_X(1:2,idx_fore0(ifore));
            idx1 = find(ismember(type_X(1,:),quali_inj(1)));idx2 = find(ismember(type_X(2,:),quali_inj(2)));idx3 = find(ismember(type_X(4,:),1));
            idxqu = intersect(idx3,intersect(idx1,idx2));
            try
                if isempty(idxqu)==0
                    type_X(5,idxqu(1)) = [y1(idx_fore0(ifore))];
                    
                end
            catch err
                keyboard
            end
        end
        end
        if isempty(dati_condMULTI)==0
             idx_err = dati_condMULTI.idx_err_mult;
        idx_fore = dati_condMULTI.idx_fore_mult;
        idx_err0 = dati_condMULTI.idx_err_mult;
        idx_fore0 = dati_condMULTI.idx_fore_mult;
        inj_ID0 = dati_condMULTI.inj_ID_mult;
        inj_IDQ = dati_Q.inj_IDQ;
        limits_reactive=[];
         type_Xm=zeros(2,length(inj_ID0));
          y0m = zeros(1,length(idx_fore0));
          y1m = zeros(1,size(inj_ID0,2));
        if flagPQ == 0
            for jcol = 1:size(inj_ID0,2)
                idxgen = find(ismember({generatore1.codice},inj_ID0{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID0{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_Xm(:,jcol) = [1;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = generatore1(idxgen(1)).P;
                                y1m(jcol)=generatore1(idxgen(1)).P;
                            end
                        else
                            type_Xm(:,jcol) = [4;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = generatore1(idxgen(1)).Q;
                                y1m(jcol)=generatore1(idxgen(1)).Q;
                            end
                        end
                        %type_X(5,jcol) = [generatore1(idxgen(1)).nation];
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1%% && carico1(idxload(1)).P ~= 0 && carico1(idxload(1)).Q ~= 0
                        type_Xm(:,jcol) = [2;idxload(1)];
                        if ismember(jcol,idx_fore0)
                            y0m(find(idx_fore0==jcol)) = carico1(idxload(1)).P;
                            y1m(jcol) = carico1(idxload(1)).P;
                        end
                        if isempty(maxvalue)
                            limits_reactive(idxload(1),1:2)=[-9999 9999];
                        else
                            jquale = find(ismember(inj_IDQ,carico1(idxload).codice));
                            
                            limits_reactive(idxload(1),1:2)=maxvalue(jquale,:);
                            
                        end
                        %type_X(5,jcol) = [carico1(idxload(1)).nation];
                    end
                end
            end
        else
            for jcol = 1:size(inj_ID0,2)
                idxgen = find(ismember({generatore1.codice},inj_ID0{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID0{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_Xm(:,jcol) = [1;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = generatore1(idxgen(1)).P;
                                y1m((jcol)) = generatore1(idxgen(1)).P;
                            end
                        else
                            type_Xm(:,jcol) = [4;idxgen(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = generatore1(idxgen(1)).Q;
                                y1m((jcol)) = generatore1(idxgen(1)).Q;
                            end
                        end
                        
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1
                        if strcmp(inj_ID0{jcol}(end),'P')
                            type_Xm(:,jcol) = [2;idxload(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = carico1(idxload(1)).P;
                                y1m(jcol) = carico1(idxload(1)).P;
                            end
                        else
                            type_Xm(:,jcol) = [3;idxload(1)];
                            if ismember(jcol,idx_fore0)
                                y0m(find(idx_fore0==jcol)) = carico1(idxload(1)).Q;
                                y1m(jcol) = carico1(idxload(1)).Q;
                            end
                        end
                    end
                end
            end
        end
        
        idx_miss = find(~any(type_Xm,1));
        idx_available = setdiff([1:size(type_Xm,2)],idx_miss);
        type_Xm(4,idx_fore0(ismember(idx_fore0,idx_available)))=-1;
        type_Xm(4,idx_err0(ismember(idx_err0,idx_available)))=1;
        type_Xm(3,:) = zeros(1,size(type_Xm,2));
        type_Xm(3,idx_available) = [1];
        
        for ifore = 1:length(idx_fore0)
            quali_inj = type_Xm(1:2,idx_fore0(ifore));
            idx1 = find(ismember(type_Xm(1,:),quali_inj(1)));idx2 = find(ismember(type_Xm(2,:),quali_inj(2)));idx3 = find(ismember(type_Xm(4,:),1));
            idxqu = intersect(idx3,intersect(idx1,idx2));
            try
                if isempty(idxqu)==0
                    type_Xm(5,idxqu(1)) = [y1m(idx_fore0(ifore))];
                    
                end
            catch err
                keyboard
            end
        end
        end
    else
        inj_IDQ = dati_Q.inj_IDQ;
        
        limits_reactive=[];
        type_X=zeros(2,length(inj_ID));
        if flagPQ == 0
            
            for jcol = 1:size(inj_ID,2)
                idxgen = find(ismember({generatore1.codice},inj_ID{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID{jcol}(end),'P')
                            type_X(:,jcol) = [1;idxgen(1)];
                            
                        else
                            type_X(:,jcol) = [4;idxgen(1)];
                            
                        end
                        %type_X(5,jcol) = [generatore1(idxgen(1)).nation];
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1%% && carico1(idxload(1)).P ~= 0 && carico1(idxload(1)).Q ~= 0
                        type_X(:,jcol) = [2;idxload(1)];
                        
                        if isempty(maxvalue)
                            limits_reactive(idxload(1),1:2)=[-9999 9999];
                        else
                            jquale = find(ismember(inj_IDQ,carico1(idxload).codice));
                            if flagesistenza
                                limits_reactive(idxload(1),1:2)=maxvalue(jquale,:);
                            else
                                limits_reactive(idxload(1),1:2)=[carico1(idxload).Q + abs(carico1(idxload).Q).*maxvalue(jquale,:).*module2.allparas.stddev(1)];
                            end
                        end
                        %type_X(5,jcol) = [carico1(idxload(1)).nation];
                    end
                end
            end
        else
            for jcol = 1:size(inj_ID,2)
                idxgen = find(ismember({generatore1.codice},inj_ID{jcol}(1:end-2)));
                idxload = find(ismember({carico1.codice},inj_ID{jcol}(1:end-2)));
                if isempty(idxgen)==0
                    if generatore1(idxgen(1)).conn == 1
                        if strcmp(inj_ID{jcol}(end),'P')
                            type_X(:,jcol) = [1;idxgen(1)];
                            
                        else
                            type_X(:,jcol) = [4;idxgen(1)];
                            
                        end
                        %type_X(5,jcol) = [generatore1(idxgen(1)).nation];
                    end
                end
                if isempty(idxload)==0
                    if carico1(idxload(1)).conn == 1
                        if strcmp(inj_ID{jcol}(end),'P')
                            type_X(:,jcol) = [2;idxload(1)];
                            
                        else
                            type_X(:,jcol) = [3;idxload(1)];
                            
                        end
                        %type_X(5,jcol) = [carico1(idxload(1)).nation];
                    end
                end
            end
        end
        
        idx_miss = find(~any(type_X,1));
        idx_available = setdiff([1:size(type_X,2)],idx_miss);
        type_X(4,:)=1;
        type_X(3,:) = zeros(1,size(type_X,2));
        type_X(3,idx_available) = [1];
        y0=[];
    end
    
    %%% criterion to set the field "dispacc" of generator data
% here it is assumed that all units except for nuclear units are available
% for redispatching


gruppi_ridispacciabili = intersect(find([generatore.conn]==1),intersect(find([generatore.fuel]~=4),find([generatore.RES]==0)));
for jgen = 1:length(gruppi_ridispacciabili)
    generatore(gruppi_ridispacciabili(jgen)).dispacc=1;
end
%%%%%%%%%

       
%%% EURISTICA PARTICIPATION FACTORS
%%% EURISTICA DEI LIMITI DI POTENZA PMIN E PMAX
BANDA = 10; % perc of Pmax
anomalies = [];quali_gen_stoch=[];
if isempty(type_X)==0
quali_gen_stoch = [quali_gen_stoch unique(type_X(2,[find(type_X(1,:)==1) find(type_X(1,:)==4)]))];
end
if isempty(type_Xm)==0
quali_gen_stoch = [quali_gen_stoch unique(type_Xm(2,[find(type_Xm(1,:)==1) find(type_Xm(1,:)==4)]))];
end
for u=1:length(generatore)
    if ismember(u,gruppi_ridispacciabili)
    generatore(u).participationFactor=generatore(u).Pmax;PMAX = generatore(u).Pmax;
    if generatore(u).conn == 1 && (-generatore(u).P < generatore(u).Pmin)
        disp(['*** WARNING: CONNECTED GENERATOR ' generatore(u).codice ' HAS AN ACTIVE POWER SETPOINT LOWER THAN PMIN '])  
    generatore(u).Pmax=min(PMAX,generatore(u).Pmin+BANDA*0.01*PMAX);
    generatore(u).Pmin=max(generatore(u).Pmin,-generatore(u).P-BANDA*0.01*PMAX);
    anomalies = [anomalies u];
    end
    if generatore(u).conn == 1 && (-generatore(u).P > generatore(u).Pmax)
        disp(['*** WARNING: CONNECTED GENERATOR ' generatore(u).codice ' HAS AN ACTIVE POWER SETPOINT HIGHER THAN PMAX '])
        generatore(u).Pmax=min(PMAX,-generatore(u).P+BANDA*0.01*PMAX);
    generatore(u).Pmin=max(generatore(u).Pmin,PMAX-BANDA*0.01*PMAX);
    anomalies = [anomalies u];
    end
    if generatore(u).conn == 1 && (-generatore(u).P <= generatore(u).Pmax) && (-generatore(u).P >= generatore(u).Pmin)
    PMAX = generatore(u).Pmax;
    generatore(u).Pmax=min(PMAX,-generatore(u).P+BANDA*0.01*PMAX);
    generatore(u).Pmin=max(generatore(u).Pmin,-generatore(u).P-BANDA*0.01*PMAX);
    end
    end
end


toc;

disp(['STARTED MCLA'])
tic;
% keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[PGENS PLOADS QLOADS ] = main_MCLA2PC3(generatore,carico,generatore1,carico1,nodo,scenarios,type_X,type_Xm,module2,module3,flagPQ,limits_reactive,opt_sign,dati_condUNI,dati_condMULTI,y0,y0m,conditional_sampling,mod_gaussian,centering,mod_unif,full_dep,nations,homoth);
    
    if iout == 1
          PGEN=PGENS;
   PLOAD=PLOADS;
   QLOAD=QLOADS;
    else
    idx_RES = (type_X(2,intersect(find(type_X(1,:)==1),find(type_X(4,:)==1))));
    idx_carichi = (type_X(2,intersect(find(type_X(1,:)==2),find(type_X(4,:)==1))));
    idx_carichiQ = (type_X(2,intersect(find(type_X(1,:)==3),find(type_X(4,:)==1))));
gen_attivi = find([generatore.conn]==1);
carichi_attivi = find([carico.conn]==1);
    PGEN(:,ismember(gen_attivi,idx_RES))=PGENS(1:min(size(PGEN,1),size(PGENS,1)),ismember(gen_attivi,idx_RES));
   PLOAD(:,ismember(carichi_attivi,idx_carichi))=PLOADS(1:min(size(PLOAD,1),size(PLOADS,1)),ismember(carichi_attivi,idx_carichi));
   QLOAD(:,ismember(carichi_attivi,idx_carichiQ))=QLOADS(1:min(size(QLOAD,1),size(QLOADS,1)),ismember(carichi_attivi,idx_carichiQ));
    end
   
   disp(['MCLA COMPLETED.'])
toc;

%save output in .mat
   moutput.errmsg='Ok';
  moutput.rng_data=out(iout).rng_data;
   moutput.mversion=out(iout).mversion;
   moutput.PLOAD = PLOAD;
   moutput.QLOAD = QLOAD;
   moutput.PGEN = PGEN;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

else
    
    BANDA = 10; % perc of Pmax
    anomalies = [];
    quali_gen_stoch = find([generatore.RES]>0);
    gruppi_ridispacciabili = intersect(find([generatore.conn]==1),intersect(find([generatore.fuel]~=4),find([generatore.RES]==0)));
    for jgen = 1:length(gruppi_ridispacciabili)
        generatore(gruppi_ridispacciabili(jgen)).dispacc=1;
    end
    for u=1:length(generatore)
        if ismember(u,gruppi_ridispacciabili)
            generatore(u).participationFactor=generatore(u).Pmax;PMAX = generatore(u).Pmax;
            if generatore(u).conn == 1 && (-generatore(u).P < generatore(u).Pmin)
                disp(['*** WARNING: CONNECTED GENERATOR ' generatore(u).codice ' HAS AN ACTIVE POWER SETPOINT LOWER THAN PMIN '])
                generatore(u).Pmax=min(PMAX,generatore(u).Pmin+BANDA*0.01*PMAX);
                generatore(u).Pmin=max(generatore(u).Pmin,-generatore(u).P-BANDA*0.01*PMAX);
                anomalies = [anomalies u];
            end
            if generatore(u).conn == 1 && (-generatore(u).P > generatore(u).Pmax)
                disp(['*** WARNING: CONNECTED GENERATOR ' generatore(u).codice ' HAS AN ACTIVE POWER SETPOINT HIGHER THAN PMAX '])
                generatore(u).Pmax=min(PMAX,-generatore(u).P+BANDA*0.01*PMAX);
                generatore(u).Pmin=max(generatore(u).Pmin,PMAX-BANDA*0.01*PMAX);
                anomalies = [anomalies u];
            end
            if generatore(u).conn == 1 && (-generatore(u).P <= generatore(u).Pmax) && (-generatore(u).P >= generatore(u).Pmin)
                PMAX = generatore(u).Pmax;
                generatore(u).Pmax=min(PMAX,-generatore(u).P+BANDA*0.01*PMAX);
                generatore(u).Pmin=max(generatore(u).Pmin,-generatore(u).P-BANDA*0.01*PMAX);
            end
        end
    end
    
    
     module2 = out(1).module2;
    [PGEN PLOAD QLOAD ] = main_det_var(generatore,carico,nodo,module2);
    
    moutput.errmsg='Ok';
  moutput.rng_data=out(1).rng_data;
   moutput.mversion=out(1).mversion;
   moutput.PLOAD = PLOAD;
   moutput.QLOAD = QLOAD;
   moutput.PGEN = PGEN;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here ends the  RSE CODE, extracted from TEST_MCLA.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   
   exitcode=0;
catch err
   moutput.errmsg=err.message;
   disp(getReport(err,'extended'));
   exitcode=-1;
end
save(ofile, '-struct', 'moutput');
end
