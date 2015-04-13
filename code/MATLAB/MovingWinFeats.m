function [feature] = MovingWinFeats(x, fs, winLen, winDisp, featFn)
%MovingWinFeats(x, fs, winLen, winDisp, featFn) - function returns a vector
%of values representing a feature of signal x in all possible time windows.
%Feature defined by feature function (featFn) passed into the function.
%Input window length in seconds

%Use Num Wins anoyn func
NumWins = @(xLen,fs,winLen,winDisp) round((xLen-(winLen - winDisp)*fs)/(winDisp*fs));

%Find number of windows
windows = NumWins(length(x), fs, winLen, winDisp);

dispSamp = winDisp*fs;  %Disp in terms of samples

%initialize of array
xWin = zeros(winLen*fs,windows)';
feature = zeros(1,windows)';
%reshape matrix into rows of windows and calc. feature for each row 
for i=1:windows
    xWin(i,:) = x((i-1)*dispSamp + 1:(i-1)*dispSamp + winLen*fs); 
    feature(i) = featFn(xWin(i,:)); %compute featFn for each window

end

end

