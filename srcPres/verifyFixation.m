function [fixOk] = verifyFixation(el,x,y,r,fixTime)

%
% function [fixOk] = verifyFixation(el,x,y,r,fixTime);
%

fixOk = 1;
t0 = GetSecs;

while ((fixOk)&&((GetSecs-t0)<fixTime))
    % sample from eyelink
    sample=eyelink( 'newfloatsampleavailable');

    if sample > 0
        evt = eyelink( 'newestfloatsample');
        xE = evt.gx(2);
        yE = evt.gy(2);
        pupil=evt.pa(2);

        if ((xE~=el.MISSING_DATA) && (yE~=el.MISSING_DATA) && (pupil>0))  % pupil visisible? */

            % within radius?
            if ((xE-x)^2+(yE-y)^2>r^2)

                fixOk = 0;

            end
        end
    end

end % while
