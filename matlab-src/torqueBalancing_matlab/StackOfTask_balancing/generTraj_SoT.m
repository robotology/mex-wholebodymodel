function  desired_x_dx_ddx_CoM = generTraj_SoT (xCoM_0,t,trajectory)
%% generTraj_SoT
% Generates a desired trajectory for robot's global CoM. It can be applied
% in every direction (X,Y,Z)
% Output
% 
% desired_x_dx_ddx_CoM [3x3]    it is a matrix wich contains the desired
%                               CoM position, velocity and acceleration
%% Trajectory generation
if t > trajectory.noOscillationTime
    
    Ampl = trajectory.referenceParams(1);
    
else
    
    Ampl = 0;

end

 freq    = trajectory.referenceParams(2);

 xCoMDes    =  xCoM_0 + Ampl*sin(2*pi*freq*t)*trajectory.directionOfOscillation;
 dxCoMDes   =  Ampl*2*pi*freq*cos(2*pi*freq*t)*trajectory.directionOfOscillation;
 ddxCoMDes  = -Ampl*(2*pi*freq)^2*sin(2*pi*freq*t)*trajectory.directionOfOscillation;

 desired_x_dx_ddx_CoM = [xCoMDes dxCoMDes ddxCoMDes];
 
end