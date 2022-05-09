function [delta_xyzb, mo, PDOP] = comp_pos(curr_obs, rec_xyz)

% Broadcast Orbit
SPos    = curr_obs.data(:,curr_obs.col.XS:curr_obs.col.ZS);
numOfSatellites = size(SPos, 1);
A       = zeros(numOfSatellites, 4);

% Pseudorange of Each Satellite
obs = curr_obs.data(:,curr_obs.col.CorrP);

for i = 1 : numOfSatellites
     b(i, 1) = (obs(i,1) - norm(SPos(i,:) - rec_xyz, 'fro')); 
     A(i, :) =  [(-(SPos(i,1) - rec_xyz(1))) / obs(i) ,(-(SPos(i,2) - rec_xyz(2))) / obs(i) ,(-(SPos(i,3) - rec_xyz(3))) / obs(i) , 1 ];
end

if rank(A) ~= 4
    delta_xyzb = zeros(4, 1);
else
    delta_xyzb   = A \ b;
end

v = A * delta_xyzb - b;
mo = sqrt((v'*v)/(numOfSatellites-4));
Qxx = inv(A'*A);
q = diag(Qxx);
if rank(A) ~= 4
    PDOP = 0;
else
    PDOP = sqrt(sum(q(1:3)));
end