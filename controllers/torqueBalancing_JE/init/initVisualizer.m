function figureCont = initVisualizer(t,chi,CONFIG)
%INITVISUALIZER initializes the visualization of forward dynamics
%               integration results.
%
% INITVISUALIZER visualizes results of the forward dynamics
% integration (e.g. the robot state, contact forces, control torques...) 
% and initialize robot simulator.
%
% figureCont = INITVISUALIZER(t,chi,CONFIG) takes as input the integration
% time t, the robot state chi and the robot configuration. The output is a
% counter for the automatic correction of figures numbers in case a new 
% figure is added.
%
% Author : Gabriele Nava (gabriele.nava@iit.it)
% Genova, May 2016
%

% ------------Initialization----------------
%% Configuration parameters
ndof                        = CONFIG.ndof;
initState                   = CONFIG.initState;
figureCont                  = CONFIG.figureCont;
p                           = CONFIG.p;

%% Forward dynamics results
if CONFIG.visualize_integration_results == 1  || CONFIG.visualize_joints_dynamics == 1 || CONFIG.visualize_motors_dynamics == 1
    
    CONFIG.wait = waitbar(0,'Generating the results...');
    set(0,'DefaultFigureWindowStyle','Docked');
    
    state         = zeros(1,length(t));
    
    % joints initialization
    qj            = zeros(ndof,length(t));
    qjInit        = zeros(ndof,length(t));
    qjRef         = zeros(ndof,length(t));
    
    % motors variables
    xi            = zeros(ndof,length(t));
    dxi           = zeros(ndof,length(t));
    dxi_ref       = zeros(ndof,length(t));
    
    % contact forces and torques initialization
%     fc            = zeros(6*CONFIG.numConstraints,length(t));
%     f0            = zeros(6*CONFIG.numConstraints,length(t));
    tau_m         = zeros(ndof,length(t));
    tau_norm      = zeros(length(t),1);
    
    % forward kinematics initialization
    xCoM          = zeros(3,length(t));
    poseFeet      = zeros(12,length(t));
    CoP           = zeros(4,length(t));
    H             = zeros(6,length(t));
    HRef          = zeros(6,length(t));
    
    % generate the vectors from forward dynamics
    for time = 1:length(t)
        
        [~,visual]          = forwardDynamics(t(time), chi(time,:)', CONFIG);
        
        state(time)         = visual.state;
        
        % joints dynamics
        qj(:,time)          = visual.qj;
        qjInit(:,time)      = initState.qj;
        qjRef(:,time)       = visual.jointRef.qjRef;
        
        % motor dynamics
        xi(:,time)          = visual.xi;
        dxi(:,time)         = visual.dxi;
        dxi_ref(:,time)     = visual.dxi_ref;
        
        %% Other parameters
        % contact forces and torques
%         fc(:,time)          = visual.fc;
%         f0(:,time)          = visual.f0;
        tau_m(:,time)       = visual.tau_xi/p;
        tau_norm(time)      = norm(visual.tau_xi/p);
        
        % forward kinematics
        xCoM(:,time)        = visual.xCoM;
        poseFeet(:,time)    = visual.poseFeet;
        H(:,time)           = visual.H;
        HRef(:,time)        = visual.HRef;
        
        % centers of pressure at feet
        CoP(1,time)         = -visual.fc(5)/visual.fc(3);
        CoP(2,time)         =  visual.fc(4)/visual.fc(3);
        
%         if  CONFIG.numConstraints == 2
%             
%             CoP(3,time)     = -visual.fc(11)/visual.fc(9);
%             CoP(4,time)     =  visual.fc(10)/visual.fc(9);
%         end
        
    end
    
    delete(CONFIG.wait)
    HErr = H-HRef;
    
    %% Robot simulator
if CONFIG.visualize_robot_simulator == 1
    % list of joints used in the visualizer
    CONFIG.indexState3      = sum(state == 1) + sum(state == 2) +1;
    CONFIG.modelName        = 'iCub';
    CONFIG.setPos           = [1,0,0.5];    
    CONFIG.setCamera        = [0.4,0,0.5];
    CONFIG.mdlLdr           = iDynTree.ModelLoader();
    consideredJoints        = iDynTree.StringVector();
    
    consideredJoints.push_back('torso_pitch');
    consideredJoints.push_back('torso_roll');
    consideredJoints.push_back('torso_yaw');
    consideredJoints.push_back('l_shoulder_pitch');
    consideredJoints.push_back('l_shoulder_roll');
    consideredJoints.push_back('l_shoulder_yaw');
    consideredJoints.push_back('l_elbow');
    consideredJoints.push_back('l_wrist_prosup');
    consideredJoints.push_back('r_shoulder_pitch');
    consideredJoints.push_back('r_shoulder_roll');
    consideredJoints.push_back('r_shoulder_yaw');
    consideredJoints.push_back('r_elbow');
    consideredJoints.push_back('r_wrist_prosup');
    consideredJoints.push_back('l_hip_pitch');
    consideredJoints.push_back('l_hip_roll');
    consideredJoints.push_back('l_hip_yaw');
    consideredJoints.push_back('l_knee');
    consideredJoints.push_back('l_ankle_pitch');
    consideredJoints.push_back('l_ankle_roll');
    consideredJoints.push_back('r_hip_pitch');
    consideredJoints.push_back('r_hip_roll');
    consideredJoints.push_back('r_hip_yaw');
    consideredJoints.push_back('r_knee');
    consideredJoints.push_back('r_ankle_pitch');
    consideredJoints.push_back('r_ankle_roll');

    % load the model from .urdf
    CONFIG.mdlLdr.loadReducedModelFromFile('../models/icub/model.urdf',consideredJoints);
            
    % set lights
    CONFIG.lightDir = iDynTree.Direction();     
    CONFIG.lightDir.fromMatlab([-0.5 0 -0.5]/sqrt(2)); 
    
    visualizeSimulation_iDyntree(chi,CONFIG);
end
    
    %% Basic visualization (forward dynamics integration results)
    if CONFIG.visualize_integration_results == 1
        
        CONFIG.figureCont = visualizeForwardDyn(t,CONFIG,xCoM,poseFeet,fc,f0,tau_norm,CoP,HErr);
    end
    
    %% Joints positions and position error
    if CONFIG.visualize_joints_dynamics == 1
        
        CONFIG.figureCont = visualizeJointDynamics(t,CONFIG,qj,qjRef);
    end
    
    %% Motors dynamics
    if CONFIG.visualize_motors_dynamics == 1
        
        CONFIG.figureCont = visualizeMotorsDynamics(t,CONFIG,xi,dxi_ref,dxi);
    end
    
    figureCont     = CONFIG.figureCont;
    set(0,'DefaultFigureWindowStyle','Normal');
    
end
