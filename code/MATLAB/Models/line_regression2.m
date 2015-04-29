%%linear regression : least square regression models

trainA = trainLab(:,1);
trainV = trainLab(:,2);
trainL = trainLab(:,4);

testA = testLab(:,1);
testV = testLab(:,2);
testL = testLab(:,4);

mdlA = fitlm(trainX,trainA,'linear','RobustOpts','on');
mdlV = fitlm(trainX,trainV,'linear','RobustOpts','on');
mdlL = fitlm(trainX,trainL,'linear','RobustOpts','on');

[predA,confA] = predict(mdlA,testX);
[predV,confV] = predict(mdlV,testX);
[predL,confL] = predict(mdlL,testX);

rms(1) = sqrt(mean((testA - predA).^2));
rms(2) = sqrt(mean((testV - predV).^2));
rms(3) = sqrt(mean((testL - predL).^2));