function u = SB_ATV(g,mu,N)
% Split Bregman Anisotropic Total Variation Denoising
%
%   u = arg min_u 1/2||u-g||_2^2 + mu*ATV(u)
%   
%   g : noisy image
%   mu: regularisation parameter
%   u : denoised image
%
% Refs:
%  *Goldstein and Osher, The split Bregman method for L1 regularized problems
%   SIAM Journal on Imaging Sciences 2(2) 2009
%  *Micchelli et al, Proximity algorithms for image models: denoising
%   Inverse Problems 27(4) 2011
%
% Benjamin Trémoulhéac
% University College London
% b.tremoulheac@cs.ucl.ac.uk
% April 2012

g = g(:);
n = length(g);
[B Bt BtB] = DiffOper(N);
b = zeros(2*n,1);
d = b;
u = g;
err = 1;k = 1;
tol = 1e-3;
lambda = 1;
while err > tol
    fprintf('it. %g ',k);
    up = u;
    [u,~] = cgs(speye(n)+BtB, g-lambda*Bt*(b-d),1e-5,100); 
    Bub = B*u+b;
    d = max(abs(Bub)-mu/lambda,0).*sign(Bub);
    b = Bub-d;
    err = norm(up-u)/norm(u);
    fprintf('err=%g \n',err);
    k = k+1;
end
fprintf('Stopped because norm(up-u)/norm(u) <= tol=%.1e\n',tol);
end

function [B Bt BtB] = DiffOper(N)
D = spdiags([-ones(N(2),1) ones(N(2),1)], [0 1], N(2),N(2)+1);
D(:,1) = [];
D(1,1) = 0;
B = [ kron(speye(N(1)),D) ; kron(D,speye(N(1))) ];
Bt = B';
BtB = Bt*B;
end


function Lx = DiffOper2(N)

ind1 = 1:N(1);
ind2 = 1:N(1);

ind1 = [ind1,1:(N(1)-1)];
ind2 = [ind2,2:N(1)];

ind1 = [ind1,];




end
