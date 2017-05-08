function [f_c, tau_gen] = contactForcesCLPC(obj, clink_conf, tau, f_e, a_c, Jc, djcdq, M, c_qv, varargin)
    switch nargin
        % f_e  ... external forces affecting on the contact links
        % a_c  ... contact accelerations
        case 14 % normal modes:
            % generalized forces with friction:
            % wf_R_b_arr = varargin{1}
            % wf_p_b     = varargin{2}
            % q_j        = varargin{3}
            dq_j = varargin{1,4};
            v_b  = varargin{1,5};
            nu   = vertcat(v_b, dq_j); % mixed generalized velocity

            tau_fr  = frictionForces(obj, dq_j);         % friction torques (negated torque values)
            tau_gen = vertcat(zeros(6,1), tau + tau_fr); % generalized forces tau_gen = S_j*(tau + (-tau_fr)),
                                                         % S_j = [0_(6xn); I_(nxn)] ... joint selection matrix
            error_clp = clnkPoseError(obj, clink_conf, varargin{1:3});
        case 13
            % general case:
            nu = varargin{1,4};

            tau_gen   = vertcat(zeros(6,1), tau);
            error_clp = clnkPoseError(obj, clink_conf, varargin{1:3});
        case 11 % optimized modes:
            % with friction:
            dq_j = varargin{1,1};
            nu   = varargin{1,2};

            tau_fr    = frictionForces(obj, dq_j);
            tau_gen   = vertcat(zeros(6,1), tau + tau_fr);
            error_clp = clnkPoseError(obj, clink_conf);
        case 10
            % general case:
            nu = varargin{1,1};

            tau_gen   = vertcat(zeros(6,1), tau);
            error_clp = clnkPoseError(obj, clink_conf);
        otherwise
            error('WBM::contactForcesCLPC: %s', WBM.wbmErrorMsg.WRONG_ARG);
    end
    if ( isscalar(error_clp) && ~error_clp )
        % both contact links have no contact to the ground/object ...
        f_c = obj.ZERO_EX_FORCE_12;
        return
    end
    k_p = clink_conf.ctrl_gains.k_p; % control gain for correcting the link positions (position feedback).
    k_v = clink_conf.ctrl_gains.k_v; % control gain for correcting the velocities (rate feedback).

    % Calculation of the contact force vector for a closed-loop control system with additional
    % velocity and position correction for the contact links (position-regulation system):
    % For further details about the basic formula see,
    %   [1] Control Strategies for Robots in Contact, J. Park, PhD-Thesis, Artificial Intelligence Laboratory,
    %       Department of Computer Science, Stanford University, 2006, chapter 5, pp. 106-110, eq. (5.5)-(5.14),
    %       <http://cs.stanford.edu/group/manips/publications/pdfs/Park_2006_thesis.pdf>.
    %   [2] A Mathematical Introduction to Robotic Manipulation, Murray & Li & Sastry, CRC Press, 1994, pp. 269-270, eq. (6.5) & (6.6).
    Jc_t      = Jc.';
    JcMinv    = Jc / M;        % x*M = Jc --> x = Jc*M^(-1)
    Upsilon_c = JcMinv * Jc_t; % inverse mass matrix in contact space Upsilon_c = (Jc * M^(-1) * Jc^T) ... (= "inverse pseudo-kinetic energy matrix"?)

    % contact constraint forces (generated by the environment) ...
    f_c = (Upsilon_c \ (a_c + JcMinv*(c_qv - tau_gen) - djcdq - k_v.*(Jc*nu) - k_p.*error_clp)) - f_e;
end
%% END of contactForcesCLPC.


%% POSE TRANSFORMATIONS & ERROR FUNCTION:

function error_clp = clnkPoseError(obj, clink_conf, varargin)
    ctc_l = clink_conf.contact.left;
    ctc_r = clink_conf.contact.right;

    % check which link is in contact with the ground or object and calculate the corresponding
    % error between the reference (desired) and the new link transformations:
    if (ctc_l && ctc_r)
        % both links are in contact with the ground/object:
        clink_l = obj.mwbm_config.cstr_link_names{1,clink_conf.lnk_idx_l};
        clink_r = obj.mwbm_config.cstr_link_names{1,clink_conf.lnk_idx_r};

        % set the desired poses (VE-Transformations*) of the contact links as reference ...
        fk_ref_pose.veT_llnk = clink_conf.des_pose.veT_llnk;
        fk_ref_pose.veT_rlnk = clink_conf.des_pose.veT_rlnk;

        % get the new VQ-Transformations (link frames) for the contact links ...
        fk_new_pose = clnkPoseTransformations(clink_l, clink_r, varargin{:});
        % convert the link frames in VE-Transformations (veT) ...
        [p_ll, eul_ll] = WBM.utilities.frame2posEul(fk_new_pose.vqT_llnk);
        [p_rl, eul_rl] = WBM.utilities.frame2posEul(fk_new_pose.vqT_rlnk);
        fk_new_pose.veT_llnk = vertcat(p_ll, eul_ll); % current motions
        fk_new_pose.veT_rlnk = vertcat(p_rl, eul_rl);

        % compute the Euler angle velocity transformations ...
        Er_ll = WBM.utilities.eul2angVelTF(eul_ll);
        Er_rl = WBM.utilities.eul2angVelTF(eul_rl);
        % create for each link the mixed velocity transformation matrix ...
        vX_ll = WBM.utilities.mixveltfm(Er_ll);
        vX_rl = WBM.utilities.mixveltfm(Er_rl);

        % get the error (distances) between the contact link poses (CLP):
        % delta  =   vX * (current transf. T   -   desired transf. T*)
        %                   (curr. motion)           (ref. motion)
        delta_ll = vX_ll*(fk_new_pose.veT_llnk - fk_ref_pose.veT_llnk);
        delta_rl = vX_rl*(fk_new_pose.veT_rlnk - fk_ref_pose.veT_rlnk);

        error_clp = vertcat(delta_ll, delta_rl);
    elseif ctc_l
        % only the left link is in contact with the ground/object:
        clink_l = obj.mwbm_config.cstr_link_names{1,clink_conf.lnk_idx_l};

        % set the desired pose transformation as reference and compute
        % compute the new pose transformation:
        fk_ref_pose.veT_llnk = clink_conf.des_pose.veT_llnk;
        fk_new_pose = clnkPoseTransformationLeft(clink_l, varargin{:});
        % convert to VE-transformation ...
        [p_ll, eul_ll] = WBM.utilities.frame2posEul(fk_new_pose.vqT_llnk);
        fk_new_pose.veT_llnk = vertcat(p_ll, eul_ll); % current motion

        % create the mixed velocity transformation ...
        Er_ll = WBM.utilities.eul2angVelTF(eul_ll);
        vX_ll = WBM.utilities.mixveltfm(Er_ll);
        % compute the error (distance) ...
        error_clp = vX_ll*(fk_new_pose.veT_llnk - fk_ref_pose.veT_llnk);
    elseif ctc_r
        % only the right link is in contact with the ground/object:
        clink_r = obj.mwbm_config.cstr_link_names{1,clink_conf.lnk_idx_r};

        % set the desired pose transformation as reference and compute
        % the new pose transformation:
        fk_ref_pose.veT_rlnk = clink_conf.des_pose.veT_rlnk;
        fk_new_pose = clnkPoseTransformationRight(clink_r, varargin{:});

        [p_rl, eul_rl] = WBM.utilities.frame2posEul(fk_new_pose.vqT_rlnk);
        fk_new_pose.veT_rlnk = vertcat(p_rl, eul_rl);

        % create the mixed velocity transformation ...
        Er_rl = WBM.utilities.eul2angVelTF(eul_rl);
        vX_rl = WBM.utilities.mixveltfm(Er_rl);
        % compute the error (distance) ...
        error_clp = vX_rl*(fk_new_pose.veT_rlnk - fk_ref_pose.veT_rlnk);
    else
        % both links have no contact with the ground/object ...
        error_clp = 0;
    end
end

% *) veT: Position vector with Euler angles (in this case it represents a
%    joint motion m(t) = (p(t), e(t))^T, where p(t) in R^3 and e(t) in S^3).

function fk_new_pose = clnkPoseTransformations(clink_l, clink_r, varargin)
    % get the new positions and orientations (VQ-Transformations) for both contact links:
    switch nargin
        case 5 % normal mode:
            % wf_R_b_arr = varargin{1}
            % wf_p_b     = varargin{2}
            % q_j        = varargin{3}
            fk_new_pose.vqT_llnk = mexWholeBodyModel('forward-kinematics', varargin{1,1}, varargin{1,2}, varargin{1,3}, clink_l);
            fk_new_pose.vqT_rlnk = mexWholeBodyModel('forward-kinematics', varargin{1,1}, varargin{1,2}, varargin{1,3}, clink_r);
        case 2 % optimized mode:
            fk_new_pose.vqT_llnk = mexWholeBodyModel('forward-kinematics', clink_l);
            fk_new_pose.vqT_rlnk = mexWholeBodyModel('forward-kinematics', clink_r);
        otherwise
            error('clnkPoseTransformations: %s', WBM.wbmErrorMsg.WRONG_ARG);
    end
end

function fk_new_pose = clnkPoseTransformationLeft(clink_l, varargin)
    % get the new VQ-Transformation for the left contact link:
    switch nargin
        case 4 % normal mode:
            % wf_R_b_arr = varargin{1}
            % wf_p_b     = varargin{2}
            % q_j        = varargin{3}
            fk_new_pose.vqT_llnk = mexWholeBodyModel('forward-kinematics', varargin{1,1}, varargin{1,2}, varargin{1,3}, clink_l);
        case 1 % optimized mode:
            fk_new_pose.vqT_llnk = mexWholeBodyModel('forward-kinematics', clink_l);
        otherwise
            error('clnkPoseTransformationLeft: %s', WBM.wbmErrorMsg.WRONG_ARG);
    end
end

function fk_new_pose = clnkPoseTransformationRight(clink_r, varargin)
    % get the new VQ-Transformation for the right contact link:
    switch nargin
        case 4 % normal mode:
            % wf_R_b_arr = varargin{1}
            % wf_p_b     = varargin{2}
            % q_j        = varargin{3}
            fk_new_pose.vqT_rlnk = mexWholeBodyModel('forward-kinematics', varargin{1,1}, varargin{1,2}, varargin{1,3}, clink_r);
        case 1 % optimized mode:
            fk_new_pose.vqT_rlnk = mexWholeBodyModel('forward-kinematics', clink_r);
        otherwise
            error('clnkPoseTransformationRight: %s', WBM.wbmErrorMsg.WRONG_ARG);
    end
end
