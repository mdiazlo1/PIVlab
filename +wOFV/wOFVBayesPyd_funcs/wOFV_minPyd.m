function [func,gd]=wOFV_minPyd(Theta,I0,I1,scale,lambda,Fw,FwInv,Ni,...
    regscheme,Dmat,mask)

%Compute the objective function and gradient for performing the WOF
%algorithm using l-BFGS. Theta is the wavelet transform of the velocity 
%field, I0 is the original image, I1 is the image one timestep after I0, 
%and scale is the current scale. lambda is the weighting parameter for 
%regularization according to regularization scheme regscheme. Fw and FwInv
%are forward and reverse wavelet transform matrices, respectively, and the
%Ni's are differentiation matrices in the wavelet domain. Dmat is a 
%differentiator matrix for computing the gradient of Iw. Outputs are f, 
%the function, and g, the gradient. Theta has been transformed to a 1-D 
%vector to allow use with the minimizer function

A = Theta;

%Compute v from Theta
Theta=reshape(Theta,[2^scale,2^scale,2]);
v=cat(3,Psitrunc_mat(Theta(:,:,1),FwInv),Psitrunc_mat(Theta(:,:,2),FwInv));

%Motion-compensated image
IwF = wOFV_warpS(I0,v/2);
IwR=wOFV_warpS(I1,-v/2);


%Evaluate function
sigma=2;
f1=(IwF-IwR);

func=log(1+.5*f1.^2/sigma^2).*mask;

% Iwgd=OFgrad(Iw);
Iwgd=1/2*(cat(3,Dmat*IwF,IwF*Dmat')+cat(3,Dmat*IwR,IwR*Dmat'));

%Compute gradient
df1=-Iwgd.*repmat(f1.*mask,[1,1,2]);
gd=df1./(2*sigma^2+repmat(f1.^2,[1,1,2]));
gd=cat(3,Psitrunc_mat(gd(:,:,1),Fw),Psitrunc_mat(gd(:,:,2),Fw));

%Compute regularization gradient and functional
gdr=wOFV_Reg(Theta,Ni,regscheme);

fr=.5*Theta(:)'*gdr;

%Combine data and regularization terms
func=trapz(trapz(func))+lambda*fr;
%Reshape to vector
gd=gd(:)+lambda*gdr;