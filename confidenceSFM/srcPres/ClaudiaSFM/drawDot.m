function drawDot(AM,pos,window)
screen(window,'fillrect',AM.color,...
    [AM.fixationXY AM.fixationXY] + [pos pos] + AM.size/2*[-1 -1 1 1])

% disp( [pos pos] + AM.size/2*[-1 -1 1 1] ) 
