clc; clear all; close all;
% Based on: http://jmcspot.com/Eigenface

% Images from the AT&T Facedatabase: http://www.cl.cam.ac.uk/research/dtg/attarchive/facedatabase.html
disp('Loading images')
M = 112; N = 92;
n_pixels = M*N;
n_person = 40;
n_img_pr_person = 10;
n_images = n_img_pr_person*n_person;
images = zeros(n_pixels,n_images); % Pre-allocate storage for images

for i=1:n_person
    for j=1:n_img_pr_person
        im = imread(sprintf('../orl_faces/s%u/%u.pgm', i, j));
        images(:,(i-1)*n_img_pr_person+j) = reshape(im,n_pixels,1); % Load all images into the matrix
    end
end

mu = mean(images,2); % Calculate the mean along each row
images_mu = bsxfun(@minus, images, mu); % Subtract means from all columns before doing SVD
%%
close all;

K = 15;
disp('Calculating the covariance matrix')
if n_images < n_pixels
    cov_matrix = images_mu'*images_mu; % Optimised SVD analysis

    if 1
        disp('Calculating the SVD')
        [U,S,V] = svds(cov_matrix,K); % Singular-Value Decomposition
    else
        disp('Calculating Eigenvectors')
        [V,D] = eig(cov_matrix);
        [D,i] = sort(diag(D), 'descend'); % Sort by Eigenvalues
        V = V(:,i);
        S = diag(D);

        V = V(:,1:K);
        S = S(1:K,:);
    end
    U = images_mu*V; % Calculate the actual Eigenvalues of the true coveriance matrix

    % Normalize Eigenvectors
    for i=1:K
        U(:,i) = U(:,i) / norm(U(:,i));
    end
else
    cov_matrix = images_mu*images_mu';
    disp('Calculating the SVD')
    [U,S,V] = svds(cov_matrix,K); % Calculate K largest singular values
end
norm(U,'fro')

figure; plot(diag(S), '*');
title('Eigenfaces singular values');

dist_S = zeros(K-1,1);
for i=1:K-1
    dist_S(i) = S(i,i) - S(i+1,i+1); % TODO: Use for determine value of K
end

eigenfaces = reshape(U,M,N,K); % Get Eigenfaces

figure
for i = 1:min(16,K)
    subplot(4,4,i)
    imagesc(eigenfaces(:,:,i)); colormap('gray')
    title(sprintf('Eigenface %u', i));
end

disp('Calculate weights for all images')
W_all = U'*images_mu;
face_all = bsxfun(@plus, U*W_all, mu); % Add means back again

disp('Done training')

%%
clc; close all;

target = imread('../orl_faces/s3/8.pgm');
figure; imagesc(target); colormap('gray');
target = double(reshape(target,n_pixels,1)); % Flatten image

disp('Reconstructing Faces')
W = U'*(target - mu); % Project target image onto Eigenfaces
face = U*W + mu; % Reconstruct face
figure; imagesc(reshape(face,M,N)); colormap('gray');

disp('Calculate distance to face space');
face_dist = (sqrt(sum((bsxfun(@minus, sum(face_all,2), face)/n_pixels).^2)')/sqrt(K));
fprintf('Face dist: %f\n', face_dist);

disp('Calculate normalized Euclidean distance');
dist = (sqrt(sum((bsxfun(@minus, W_all, W)/n_pixels).^2)')/sqrt(K));

[sorted_dist,order] = sort(dist);

figure;
for i=1:9 % Plot first four matches
    subplot(3,3,i)
    imagesc(reshape(images(:,order(i)),M,N)); colormap('gray');
    title(sprintf('dist: %f', sorted_dist(i)));
end
