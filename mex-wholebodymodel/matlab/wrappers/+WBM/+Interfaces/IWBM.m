classdef (Abstract) IWBM < handle
    properties(Abstract, Dependent)
        % public properties for fast get/set methods:
        robot_name@char
        robot_model@char
        robot_manuf@char
        robot_params@WBM.wbmRobotParams
        sim_config@WBM.wbmSimConfig
        base_link@char
        base_tform@double matrix
        tool_tform@double matrix
        feet_conf@struct
        hand_conf@struct
        gravity@double    vector
        jlimits@struct
        ndof@uint16       scalar
    end

    methods(Abstract)
        initRobot(obj, robot_wbm)

        initRobotFcn(obj, fhInitRobotWBM, wf2fixlnk)

        initRobotParams(obj, robot_params)

        [vqT_b, q_j, v_b, dq_j] = getState(obj)

        stFltb = getBaseState(obj)

        feet_conf = feetConfig(obj, varargin)

        hand_conf = handsConfig(obj, varargin)

        ddq_j = jointAcc(obj, tau, q_j, dq_j, stFltb)

        ddq_j = jointAccEF(obj, tau, fe_h, ac_h, ac_f, q_j, dq_j, stFltb) % EF ... External Forces at the hands (no pose correction)

        ddq_j = jointAccPL(obj, tau, fhTotCWrench, f_cp, ac_f, q_j, dq_j, stFltb) % PL ... PayLoad at the hands (no pose correction)

        ddq_j = jointAccFPC(obj, tau, ac_f, q_j, dq_j, stFltb) % FPC ... Feet Pose Correction (no external forces)

        ddq_j = jointAccFPCEF(obj, tau, fe_h, ac_h, ac_f, q_j, dq_j, stFltb) % FPCEF ... Feet Pose Correction with External Forces (at the hands)

        ddq_j = jointAccFPCPL(obj, tau, fhTotCWrench, f_cp, ac_f, q_j, dq_j, stFltb) % FPCPL ... Feet Pose Correction with PayLoad (at the hands)

        ac_h = handAcc(obj, tau, q_j, dq_j, stFltb)

        vc_h = handVel(obj, q_j, dq_j, stFltb)

        c_qv = corForces(obj, q_j, dq_j, stFltb)

        tau_fr = frictForces(obj, dq_j)

        c_qv = genBiasForces(obj, q_j, dq_j, stFltb)

        tau_gen = genForces(obj, Je_t, f_e, q_j, dq_j, stFltb)

        g_q = gravForces(obj, q_j, stFltb)

        tau_j = invDyn(obj, q_j, dq_j, ddq_j, dv_b, stFltb)

        tau_j = invHybridDyn(obj, q_j, dq_j, ddq_j, stFltb)

        [t, stmChi] = fwdDyn(obj, tspan, stvChi_0, fhTrqControl, ode_opt, varargin)

        visFwdDyn(obj, stmChi, sim_tstep, vis_ctrl)

        wf_H_lnk = fwdKin(obj, lnk_name, q_j, stFltb)

        wf_H_lnk = linkFrame(obj, lnk_name, q_j, stFltb) % link transformation matrix

        wf_H_tt = toolFrame(obj, t_idx, q_j, stFltb) % tool-tip transformation matrix

        M = massMatrix(obj, q_j, stFltb)

        h_c = centMoment(obj, q_j, dq_j, stFltb)

        [M, c_qv, h_c] = wholeBodyDyn(obj, q_j, dq_j, stFltb)

        wf_J_lnk = jacob(obj, lnk_name, q_j, stFltb)

        djdq_lnk = jacobDot(obj, lnk_name, q_j, dq_j, stFltb)

        wf_J_tt = jacobTool(obj, t_idx, q_j, stFltb) % Jacobian matrix in tool-frame

        payload(obj, pl_lnk_data)

        f_pl = ploadForces(obj, fhTotCWrench, f_cp, tau, q_j, dq_j, stFltb)

        resv = isJntLimit(obj, q_j)

        dispParams(obj, prec)

    end
end
