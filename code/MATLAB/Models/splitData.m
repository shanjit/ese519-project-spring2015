function [trainX, testX, trainLab, testLab] = splitData(totF,totLab)
n = size(totF,1);
p = randperm(n);
trainX = totF(p(1:1000),:);
trainLab = totLab(p(1:1000),:);

testX = totF(p(1001:end),:);
testLab = totLab(p(1001:end),:);
end