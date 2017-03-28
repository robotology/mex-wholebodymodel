function FORKINEMATICS = robotForKinematics(STATE,DYNAMICS)
%ROBOTFORKINEMATICS uses forward kinematics to define the pose and velocity
%                   of some points in Cartesian space, e.g. the CoM or
%                   the contact locations.
%
% Format: FORKINEMATICS = ROBOTFORKINEMATICS(STATE,DYNAMICS)
%
% Inputs:  - STATE contains the current system state;
%          - DYNAMICS contains current robot dynamics;
%
% Output:  - FORKINEMATICS which is a structure containing the following variables:
%
% xCoM              center of mass position (R^3)
% dxCoM             center of mass velocity (R^3)
% poseLFoot_qt      left foot position and orientation using quaternions (R^7)
% poseRFoot_qt      right foot position and orientation using quaternions (R^7)
% poseLFoot_ang     left foot position and orientation using Euler angles (R^6)
% poseRFoot_ang     right foot position and orientation using Euler angles (R^6)
% v_feet            feet velocities (R^6)
% TL                multiplies delta left foot positions (R^(6 x 6))
% TR                multiplies delta right foot positions (R^(6 x 6))
%
% Author : Gabriele Nava (gabriele.nava@iit.it)
% Genova, March 2017

%% ------------Initialization----------------
import WBM.utilities.frame2posRotm;
import WBM.utilities.rotm2eulAngVelTF;

%% State parameters
w_R_b          = STATE.w_R_b;
x_b            = STATE.x_b;
qj             = STATE.qj;
nu             = STATE.nu;

%% Dynamics parameters
JCoM           = DYNAMICS.JCoM;
Jc             = DYNAMICS.Jc;

%% FORWARD KINEMATICS
% feet pose (quaternions), CoM position
poseLFoot_qt                     = wbm_forwardKinematics(w_R_b,x_b,qj,'l_sole');
poseRFoot_qt                     = wbm_forwardKinematics(w_R_b,x_b,qj,'r_sole');
poseCoM                          = wbm_forwardKinematics(w_R_b,x_b,qj,'com');
xCoM                             = poseCoM(1:3);
% feet velocity, CoM velocity
v_feet                           = Jc*nu;
dposeCoM                         = JCoM*nu;
dxCoM                            = dposeCoM(1:3);

%% Feet orientation using Euler angles
% feet current position and orientation (rotation matrix)
[x_Lfoot,b_R_Lfoot]              = frame2posRotm(poseLFoot_qt);
[x_Rfoot,b_R_Rfoot]              = frame2posRotm(poseRFoot_qt);
% orientation is parametrized with euler angles
[theta_Lfoot,TLfoot]             = rotm2eulAngVelTF(b_R_Lfoot);
[theta_Rfoot,TRfoot]             = rotm2eulAngVelTF(b_R_Rfoot);
poseLFoot_ang                    = [x_Lfoot; theta_Lfoot];
poseRFoot_ang                    = [x_Rfoot; theta_Rfoot];

%% Output structure
FORKINEMATICS.xCoM               = xCoM;
FORKINEMATICS.dxCoM              = dxCoM;
FORKINEMATICS.poseLFoot_qt       = poseLFoot_qt;
FORKINEMATICS.poseRFoot_qt       = poseRFoot_qt;
FORKINEMATICS.poseLFoot_ang      = poseLFoot_ang;
FORKINEMATICS.poseRFoot_ang      = poseRFoot_ang;
FORKINEMATICS.v_feet             = v_feet;
FORKINEMATICS.TL                 = [eye(3) zeros(3) ; zeros(3) TLfoot];
FORKINEMATICS.TR                 = [eye(3) zeros(3) ; zeros(3) TRfoot];

end
