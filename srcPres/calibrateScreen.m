
% open window for this experiment
screen1=0;
isColor=0;
pixelSize=8;
width=1024;
height=768;
hz=120;

[window, rect]=setupwindow(screen1, width, height, hz, pixelSize,isColor);

levels = [ 0:10:250 255 ];

for i=1:length(levels)
    Screen(window,'FillRect', [levels(i)] );
    
    Screen(window,'DrawText', num2str(levels(i)), 20, 20, [255 0 0]);

    
    GetChar;
end

%TSCREEN('CloseAll');
clear mex
