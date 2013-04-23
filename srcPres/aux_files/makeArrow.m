function w = makeArrow(direc, patchSize, fg, bg)

w = bg*ones(patchSize);

w(...
    round(patchSize/4):round(3*patchSize/4),...
    round(4*patchSize/10):round(6*patchSize/10)) = fg;

y = ( (0:patchSize-1) / (patchSize-1))' * ones(1,patchSize);
x = y';

if direc==2
    idx = find((y<0.4)&(y>abs(x-.5)));
else
    idx =find((y>0.6)&((1-y)>abs(x-.5)));
end

w(idx) = fg;

