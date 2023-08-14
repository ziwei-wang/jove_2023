% fitting wavespeed to COMSOL dispersion results
function obj = fea_eval(X)
    global iter Target model freq
    iter = iter + 1; % iteration counter
    % set Young's modulus value
    model.param.set('E_s', table2array(X(1,1)));
    % run COMSOL simulation
    model.study('std1').run();
    % extract frequency and wave speed from COMSOL
    f = real(mphglobal(model,'freq','dataset','dset2','outersolnum','all'));
    c = real(mphglobal(model,'freq*2*pi/k*r','dataset','dset2','outersolnum','all'));
    %interpolate the COMSOL dispersion results with a spline, and extract 
    c_p = interp1(f(2:end),c(2:end),freq,'spline'); 
    % objective function
    % euclidean distance between FEA and test wave speeds
    obj = sqrt(sum((c_p - Target).^2));
end
 