trainA = trainLab(:,1);
trainV = trainLab(:,2);
trainL = trainLab(:,4);

testA = testLab(:,1);
testV = testLab(:,2);
testL = testLab(:,4);


[bA,bintA,rA] = regress(trainA,trainX);
[bV,bintV,rV] = regress(trainV,trainX);
[bL,bintL,rL] = regress(trainL,trainX);
n = size(testX,1);
predA = zeros(n,1);
predV = zeros(n,1);
predL = zeros(n,1);

for i =1:n
    predA(i,1) = sum(testX(i,:).*(bA'));
    predV(i,1) = sum(testX(i,:).*(bV'));
    predL(i,1) = sum(testX(i,:).*(bL'));
end

rmsR(1) = sqrt(mean((testA - predA).^2));
rmsR(2) = sqrt(mean((testV - predV).^2));
rmsR(3) = sqrt(mean((testL - predL).^2));