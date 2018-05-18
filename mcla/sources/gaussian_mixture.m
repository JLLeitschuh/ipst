%
% Copyright (c) 2017, RTE (http://www.rte-france.com) and RSE (http://www.rse-web.it) 
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
function [Y inj_ID nat_ID obj idx_err1 idx_fore1 idx_err idx_fore ] = gaussian_mixture(err_new,inj_ID,nat_ID,outliers,Koutliers,ordo,imputation,tolvar,Nmin_obs_fract,Nnz,Nmin_obs_interv,check_mod0,idx_err0,idx_fore0,cs)

Y = err_new;

% grafico dei dati
Q1 = isnan(Y);


Q2 = sum(Q1,1);

% % % % %%%%%

% for perce = 1:perc
perce = 1;discarded=[];
Noriginalsamples = size(Y,1);
Nmin_obs=Nmin_obs_fract*Noriginalsamples; % valid points for calculating the ECDFs 
Nmin_nz=Nnz*Noriginalsamples; % non zero points for calculating the ECDFs 


allowable=[];
idxallo=[];idxdis = [];qualefor = []; 
%%% verifiche iniziali
for jY = 1:size(Y,2)
%     [parametri B metrica] = EMalgorithm(Y(find(~isnan(Y(:,(jY)))),(jY)));
        idxlambda{jY} = find(~isnan(Y(:,(jY))));
        non_sono_zeri{jY} = idxlambda{jY}(find(Y(idxlambda{jY},(jY))~=0));
        QUANTIVALIDI(jY)=length(idxlambda{jY});
%         if metrica > 2
%             keyboard
%         end
        if (length(idxlambda{jY}) < Nmin_obs || length(non_sono_zeri{jY}) < Nmin_nz) || var(Y(idxlambda{jY},(jY))) < tolvar %|| metrica > 2% length(find(idxlambda{jY} == 0)) > 0.05*size(Y,1)
            if cs == 0
            discarded = [discarded (jY)];
            
 if ismember(jY,idx_err0)
            disp(['*** DISCARDED SNAPSHOT VARIABLE FOR INJ: ' inj_ID{jY} ' -> NaN SAMPLES (' num2str(100-100*length(idxlambda{jY})/size(Y,1)) '%), ZERO VALUES (' num2str(100-100*length(non_sono_zeri{jY})/size(Y,1)) '%), VARIANCE ' num2str(var(Y(idxlambda{jY},(jY)))) ' MW -- TREATED AS CONSTANT INJECTOR'])
        else
            disp(['*** DISCARDED FORECAST VARIABLE FOR INJ: ' inj_ID{jY} ' -> NaN SAMPLES (' num2str(100-100*length(idxlambda{jY})/size(Y,1)) '%), ZERO VALUES (' num2str(100-100*length(non_sono_zeri{jY})/size(Y,1)) '%), VARIANCE ' num2str(var(Y(idxlambda{jY},(jY)))) ' MW -- TREATED AS CONSTANT INJECTOR'])

 end
            else
                if rem(jY,2)==0
                discarded = [discarded (jY) jY-1];
                            disp(['*** DISCARDED FORECAST VARIABLE FOR INJ: ' inj_ID{jY} ' -> NaN SAMPLES (' num2str(100-100*length(idxlambda{jY})/size(Y,1)) '%), ZERO VALUES (' num2str(100-100*length(non_sono_zeri{jY})/size(Y,1)) '%), VARIANCE ' num2str(var(Y(idxlambda{jY},(jY)))) ' MW -- TREATED AS CONSTANT INJECTOR'])

                 disp(['*** DISCARDED CORRESPONDING SNAPSHOT VARIABLE FOR INJ: ' inj_ID{jY-1} ])
                else
                discarded = [discarded (jY) jY+1];    
                
                 disp(['*** DISCARDED SNAPSHOT VARIABLE FOR INJ: ' inj_ID{jY} ' -> NaN SAMPLES (' num2str(100-100*length(idxlambda{jY})/size(Y,1)) '%), ZERO VALUES (' num2str(100-100*length(non_sono_zeri{jY})/size(Y,1)) '%), VARIANCE ' num2str(var(Y(idxlambda{jY},(jY)))) ' MW -- TREATED AS CONSTANT INJECTOR'])

                disp(['*** DISCARDED CORRESPONDING FORECAST VARIABLE FOR INJ: ' inj_ID{jY+1} ])

                end
            end
            
        else
           
            allowable = [allowable (jY)];
            if rem(jY,2)==0
               qualefor = [qualefor jY/2]; 
            end
            
        end
    
end

if cs == 1
   intersectio = intersect(discarded,allowable);
   allowable = setdiff(allowable,intersectio);
end


%%%%%%%%%%%
%    keyboard
idx_err1 = setdiff(idx_err0,discarded);
idx_fore1 = setdiff(idx_fore0,discarded);

idx_err = find(ismember(allowable,idx_err1));
idx_fore = find(ismember(allowable,idx_fore1));

Y = Y(:,allowable);%fraz_non_zero = fraz_non_zero(allowable);

QUANTIVALIDI = QUANTIVALIDI(allowable);

FY = Y;

inj_ID(:,discarded) = [];
nat_ID(:,discarded) = [];

Nvars = size(Y,2);

for jQ = 1:size(Y,2)
    idxlambda{jQ} = find(~isnan(Y(:,jQ)));
    setLAMBDA{jQ} = [Y(find(~isnan(Y(:,jQ))),jQ)];
    idxx = find(abs(setLAMBDA{jQ}-mean(setLAMBDA{jQ})) > Koutliers*sqrt(var(setLAMBDA{jQ})));
    if isempty(idxx)==0 
    remaining = setdiff(idxlambda{jQ},idxlambda{jQ}(idxx));
    if var(Y(remaining,jQ)) < tolvar
        dimensione = min(0.1,max(1e-4,0.01*max(abs(Y(remaining,jQ)))));
        Y(remaining,jQ) = Y(remaining,jQ) + dimensione.*randn(length(remaining),1);
    end
    
    if outliers == 1
        Y(idxlambda{jQ}(idxx),jQ)=NaN;
        idxlambda{jQ} = find(~isnan(Y(:,jQ)));
    setLAMBDA{jQ} = [Y(find(~isnan(Y(:,jQ))),jQ)];
    end
    
    end
    [EMPCDF{jQ} xQ{jQ}] = ecdf( setLAMBDA{jQ});
%          
   
end
Y0=Y;
Q = isnan(Y);
disp(['***' num2str(sum(sum(Q,1))) ' gaps to fix'])
Qn = 1-Q;
% qualitutte = all(Qn,2);

% qualitutte = all(Qn,2);


% [AY BY] = sort(QUANTIVALIDI,'ascend');
% disp('Variables with fewest valid points')
% disp('Variable      nr of valid points')
% % keyboard
% for jY2 = 1:min(length(BY),10)
%    disp([ 'nr ' num2str(allowable(BY(jY2))) ': ' inj_ID{(BY(jY2))} '   '   num2str(AY(jY2))]) 
% end


disp(['calcolati empirical CDFs'])
% stima correlazione  tra le coppie di variabili
if check_mod0
clear COR
COR = eye(size(Q,2));
for jQ = 1:size(Q,2)-1

    for iQ = jQ+1:size(Q,2)
        setLAMBDAINTER = intersect(idxlambda{jQ},idxlambda{iQ});
        
            if length(setLAMBDAINTER) > Nmin_obs_interv
                [R] = corr(Y(setLAMBDAINTER,[jQ iQ]),'type','kendall');
                RR = R(1,2);
                if isnan(RR)
                    RR = 0;
                end
            else
                RR = 0;
            end
        

        COR(jQ,iQ)=RR;
        COR(iQ,jQ)=RR;
    end
end
%  keyboard

thresl = 1e-2;D1=-1;
disp(['calcolate correlazioni lineari tra variabili'])

% tolgo righe identiche
DCOR = diff(COR,1,1);
RDCOR = sum(abs(DCOR),2);
idxelimin = find(RDCOR < thresl)+1;
idx_restanti = setdiff([1:size(COR,1)],idxelimin);

COR0=COR;
end



%  keyboard
if any(find(isnan(Y)))
[Y obj ] = gausmix3(Y,imputation,ordo);
else
    obj=[];
end

if check_mod0
RHO = corr([Y],'type','kendall');
ERRO = [100*(RHO - COR0)./COR0];
ERROA = [(RHO - COR0)];

QUALI = (abs(COR0) > 0.);

RHOV = RHO - eye(size(RHO));
COR0V = COR0 - eye(size(COR0));

ERROV = ERRO.*QUALI;
ERROVA = ERROA.*QUALI;


maxabserr = max(max(abs(ERROVA)))
maxrelerr = max(max(abs(ERROV)))
end

