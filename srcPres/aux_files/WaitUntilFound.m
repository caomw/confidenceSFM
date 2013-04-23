function [found] = WaitUntilFound(el,x,y,r,minTime,timeOut)

%
% function [found] = WaitUntilFound(el,x,y,r,minTime,timeOut);
%
% checks whether eye position is within radius for minTime
% returns 1, if so; 0 if timeOut is reached
%

found = 0;

t0 = GetSecs;

inRadius = 0;


enterT = inf;
while ((~found)&((GetSecs-t0)<timeOut))
    % sample from eyelink
    sample=eyelink( 'newfloatsampleavailable');
    
    if sample > 0
        evt = eyelink( 'newestfloatsample');
        xE = evt.gx(2);
        yE = evt.gy(2);
        pupil=evt.pa(2);
       
        if ((xE~=el.MISSING_DATA) & (yE~=el.MISSING_DATA) & (pupil>0))  % pupil visisible? */

            % within radius
            if ((xE-x)^2+(yE-y)^2<r^2)
               if ~inRadius
                    inRadius = 1;
                    enterT = GetSecs;
               end
            else
                inRadius = 0;
            end

        end
        
        
    end
    
    if ((GetSecs-enterT)>minTime)&(inRadius)
        found = 1;
    end
end % while
