%Interpolates and normalizes x-scale data

[allData, ~, ~] = xlsread('rawData.xlsx');
numSimuls = size(allData, 2);

numPoints = 1000;
sumHolder = zeros(numPoints);

for currentSimul = 1:numSimuls
    
    data = allData(:, currentSimul);
    
    dataLength = length(data); %ADD HERE
    checkPoints = linspace(0, dataLength, numPoints);
    
    sumHolder = sumHolder + interp1(1:dataLength, data, checkPoints);
end


sumHolder = sumHolder / numSimuls;
xlswrite('newData.xlsx', sumHolder);