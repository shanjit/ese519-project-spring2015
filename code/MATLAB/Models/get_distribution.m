%%Plotting the data labels on 2D (Arousal and Valence)
function [retval] = get_distribution(totLab,reference)

scatter(totLab(:,2),totLab(:,1));
grid;

retval = 0;
dist_zero = 0.5;
for i = 1:size(totLab,1)
    if(pdist([[totLab(i,2),totLab(i,1)];reference],'euclidean') < dist_zero)
        retval = retval +1;
    end
end
end