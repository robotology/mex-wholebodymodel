function [ dJdq ] = wbm_djdq( varargin )
%WBM_DJDQ computes the product of derivative of Jacobian wrt to state
%(DJ/dq) and the derivative of state for a desired link. Used for providing external contact contraints
%   Arguments : 
%       Optimised Mode  : link_name - string matching URDF name of the link (frame)
%       Normal Mode : qj - joint angles (NumDoF x 1 vector)
%                     dqj - joint velocities (NumDoF x 1 vector)
%                     vxb - floating base spatial velocity (6x1 vector)
%                     link_name - string matching URDF name of the link (frame)
%   Returns : dJdq, a vector of dimension 6X1
%
% Author : Naveen Kuppuswamy (naveen.kuppuswamy@iit.it)
% Genovas, Dec 2014

    switch(nargin)
        case 1 
            dJdq = wholeBodyModel('djdq',varargin{1}); 
        case 4  
            dJdq = wholeBodyModel('djdq',varargin{1},varargin{2},varargin{3},varargin{4});
        otherwise
            disp('djdq : Incorrect number of arguments, check docs');        
    end
        

end

