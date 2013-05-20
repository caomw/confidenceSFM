function [xx2, yy2, dots] = getSFMDotPos_2(SFM, Exp, dots, disparity, direction)

% nargin = 0;
% compute nFrames for SFM
if nargin < 2
    disparity = 0.01;
end
if nargin < 3
    direction = -1;
end

dbstop if error

% isAnaglyph = 1;
%initialize the dot positions

nPix = SFM.dotSize ^ 2;
[dotX, dotY] = meshgrid(1:SFM.dotSize, 1:SFM.dotSize);
dotX = dotX(:)';
dotY = dotY(:)';

% blankImg = zeros(SFM.imgSize);

dotBuffer = SFM.dotSize / 2 / Exp.SFM.pixPerDeg; %Exp.Cfg.pixelsPerDegree ;
radius = SFM.radius-dotBuffer ;

% img1 = blankImg;
% img2 = blankImg;
% img3 = zeros([size(img1),3]);

if SFM.spinaxis == 1  %horizontal axis (dots move up/down)
    
    %project and scale x and y positions
    dots.x = dots.xflat * SFM.radius;
    dots.y  = sin(dots.yflat * pi) * SFM.radius;
    dots.xdisp = dots.x + cos(dots.yflat*pi) *pi *SFM.dispFlag * disparity;
    %        dots.xdisp = dots.x + cos(dots.yflat*pi) *pi/10 *SFM.dispFlag * disparity;
    
    %find dots that are inside the square (within a buffer)
    goodDots = find(dots.x<(radius) & dots.x>-(radius) & dots.y<(radius) & dots.y>-(radius));
    goodDotsD = find(dots.xdisp<(radius) & dots.xdisp>-(radius) & dots.y<(radius) & dots.y>-(radius));
    
    %put the dots in the image
    xx1 = repmat(round((dots.x(goodDots)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotX,length(goodDots),1);
    xx2 = repmat(round((dots.xdisp(goodDotsD)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotX,length(goodDotsD),1);
    yy1 = repmat(round((dots.y(goodDots)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotY,length(goodDots),1);
    yy2 = repmat(round((dots.y(goodDotsD)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotY,length(goodDotsD),1);
    
%     img1((xx1(:))*SFM.imgSize+yy1(:)) = 1 ;
%     img2((xx2(:))*SFM.imgSize+yy2(:)) = 1 ;
%     
%     if isAnaglyph
%         img3(:,:,1) = img1 == 1;
%         img3(:,:,3) = img2 == 1;
%         img3 = img3*255;
%     end
    
    %move the dots
    dots.yflat = dots.yflat+ 2*SFM.degPerSec/360/SFM.frameRate * direction ;
    
elseif SFM.spinaxis == 2   %vertical axis (dots move left/right)
    %(still need to include dispDir here)
    
    %project and scale x and y positions
    dots.x  = sin(dots.xflat*pi) * SFM.radius;
    dots.xdisp = sin(dots.xflat*pi + pi*disparity) *SFM.radius * SFM.dispFlag;
    dots.y = dots.yflat*SFM.radius;
    
    %find dots that are inside the square (within a buffer)
    goodDots = find(dots.x<(radius) & dots.x>-(radius) & dots.y<(radius) & dots.y>-(radius));
    goodDotsD = find(dots.xdisp<(radius) & dots.xdisp>-(radius) & dots.y<(radius) & dots.y>-(radius));
    
    %put the dots in the image
    xx1 = repmat(round( (dots.x(goodDots)'+SFM.radius)*Exp.SFM.pixPerDeg  ) ,1,nPix ) + repmat(dotX,length(goodDots),1);
    xx2 = repmat(round((dots.xdisp(goodDotsD)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotX,length(goodDotsD),1);
    
%     xx1 = (dots.x(goodDots)' + SFM.radius) * Exp.SFM.pixPerDeg; 
    xx2 = (dots.xdisp(goodDotsD)' + SFM.radius) * Exp.SFM.pixPerDeg + ...
        Exp.Cfg.centerX - 115 - (( SFM.radius * Exp.SFM.pixPerDeg ) / 2) ;
    
%     yy1 = repmat(round((dots.y(goodDots)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotY,length(goodDots),1);
%     yy2 = repmat(round((dots.y(goodDotsD)'+SFM.radius)*Exp.SFM.pixPerDeg),1,nPix) + repmat(dotY,length(goodDotsD),1);
    
%     yy1 = (dots.y(goodDots)'+SFM.radius)*Exp.SFM.pixPerDeg);
    yy2 = (dots.y(goodDotsD)' + SFM.radius) * Exp.SFM.pixPerDeg + ...
        Exp.Cfg.centerY - 125 - (( SFM.radius * Exp.SFM.pixPerDeg ) / 2) ;
     
%     img1( ( xx1(:)) * SFM.imgSize + yy1(:) ) = 1 ;
%     img2( (xx2(:)) * SFM.imgSize + yy2(:) ) = 1 ;
% %     
%     if isAnaglyph
%         img3(:,:,1) = img1 == 1;
%         img3(:,:,3) = img2 == 1;
%         img3 = img3*255;
%     end
    
    % move the dots
    dots.xflat = dots.xflat+ 2* SFM.degPerSec / 360 / SFM.frameRate * direction;
end




