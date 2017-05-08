function B = tform2angVelTF(tform, rtype, sequence)
    switch nargin
        case 3
            if ~strcmp(rtype, 'eul')
                error('tform2angVelTF: %s', WBM.wbmErrorMsg.STRING_MISMATCH);
            end
            eul = WBM.utilities.tform2eul(tform, sequence);
            B   = WBM.utilities.eul2angVelTF(eul);
        case 2
            switch rtype
                case 'eul'
                    % use the default ZYX axis sequence ...
                    eul = WBM.utilities.tform2eul(tform);
                    B   = WBM.utilities.eul2angVelTF(eul);
                case 'quat'
                    quat = WBM.utilities.tform2quat(tform);
                    B    = WBM.utilities.quat2angVelTF(quat);
                case 'axang'
                    axang = WBM.utilities.tform2axang(tform);
                    B     = WBM.utilities.axang2angVelTF(axang);
                otherwise
                    error('tform2angVelTF: %s', WBM.wbmErrorMsg.STRING_MISMATCH);
            end
        otherwise
            error('tform2angVelTF: %s', WBM.wbmErrorMsg.WRONG_ARG);
    end
end
