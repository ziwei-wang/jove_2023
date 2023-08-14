choice = menu('Continue?','Yes','No');
if choice==2 | choice==0
   return;
end
close all; clear all;
global iter Target model freq
%% optimization setting parameters
% maximum iteration number
iter_max = 50;
% number of initial evaluation points
n_init = 40;
% elastic modulus search range, modified based on samples
[E_min, E_max] = deal(100e3, 200e3);
% radius of curvature of the sample
r = 1.7e-3;
% wave number evaluation range, modified to cover the desired frequencies
[k_min, k_max, k_num] = deal(1,30,20);
%% optimization
% load COMSOL mph file
mphopen
% load dispersion test data
T_data = readtable('sample_1.txt');
% convert to units to Hz and m/s
% select the subset of data to fit, if necessary
freq = T_data.Frequency(11:end)*1e3;
c_e = T_data.WaveSpeed(11:end);
% example data
% freq = [2000, 
%        2500,
%        3000,
%        3500,
%    	   4000,
%        4500,
%    	   5000];
% c_e  = [8.6044,
%         8.5269,
%         8.3844,
%         8.2461,
%         8.1187,
%         8.0075,
%         7.9110];

% assign parameters to the COMSOL model
model.param.set('r',r);
model.param.set('k_max',k_max);
model.param.set('k_min',k_min);
model.param.set('k_num',k_num);
%set test wave speed as target
Target = [c_e]; 
% define the range of modulus to search
X1 = optimizableVariable(strcat('x1'), [E_min,E_max],'Type','real');
X = [X1];
% number of optimization variables
Mr = 1; 
% initial points
N_LHS = Mr*n_init; 
A = lhsdesign(N_LHS,Mr);
InitialX = [A(:,1)*E_min+E_max-E_min];% initial range, should be the same as X1, A from 0 to 1
iter = 0;
% Bayesian optimization of the modulus to fit the FEA dispersion curve to
% the OCE test dispersion data
BO = bayesopt(@fea_eval,X,'Verbose',2,...
                          'AcquisitionFunctionName','expected-improvement',...
                          'MaxObjectiveEvaluations', iter_max,...
                          'IsObjectiveDeterministic', 1, ...
                          'InitialX', array2table(InitialX),...
                          'UseParallel',false);
% optimization results
[x, y] = min(BO.ObjectiveTrace);
opt= table2array(BO.XAtMinObjective);
min_obj = BO.MinObjective;
% optimized E_s
E = opt(1);

%% plot and compare FEA and OCE test dispersion data
model.param.set('E_s', opt(1));
model.study('std1').run();
f = real(mphglobal(model,'freq','dataset','dset2','outersolnum','all'));
c = real(mphglobal(model,'freq*2*pi/k*r','dataset','dset2','outersolnum','all'));
figure;
plot(f,c,'-o');
hold on;
plot(freq,c_e,'o')
