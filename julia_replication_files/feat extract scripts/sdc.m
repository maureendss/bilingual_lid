function y = sdc( x, N, d, P, k)
%SDC Summary of this function goes here
%   https://www.ll.mit.edu/mission/communications/ist/publications/020916_Torres.pdf 
% x = input feature matrix
% N = number of cepstral coefficients
% d = delta time advance and delay
% P = time shift
% k = number of blocks to concatenate
% usual configuration is 7-1-3-7

if nargin == 1
N=7;  % number of c cepstral coefficients in each cepstral vector
d=1;  % time advance and delay for the delta computation
P=3;  % timeshift netween consecutive blocks
k=7;  % number of blocks whose delta coefficients are concatenated to form the SDC vector
elseif nargin ~= 5
  error('input mismatch');
end

[row,col]=size(x);
sdc1=zeros(N*k+N,col);

filter_array = zeros(k+1,(k-1)*P+2*d+1);
filter_len = length(filter_array);
center = ceil(filter_len/2);
filter_array(1,center) = 1;


half = floor(filter_len/2);
prefix = zeros(row,half);
for i=1:(half)
    prefix(:,i) = x(:,1);
end;

postfix = zeros(row,half*2);
for i=1:(half*2)
    postfix(:,i) = x(:,end);
end;



init = 2;
actual = 2;
for ii=2:k+1
    filter_array(ii,actual-d) = -1;
    filter_array(ii,actual+d) = 1;
    filter_array(ii,:) = fliplr(filter_array(ii,:));
    actual = init+(ii-1)*P;
end;



x=cat(2,prefix,x);
x=cat(2,x,postfix);

%filter_array

for n=1:N
    for i=1:k+1        
        if n == 1
           filtered = filter(filter_array(i,:),1,x(end,:),[],2); 
           
           size(filtered(1,filter_len:end-half));
           size(sdc1(((n-1)*(k+1)+i),:));
           sdc1(((n-1)*(k+1)+i),:) = filtered(1,filter_len:end-half); 
        else
           filtered = filter(filter_array(i,:),1,x(n-1,:),[],2); 
           sdc1(((n-1)*(k+1)+i),:) = filtered(1,filter_len:end-half);    
        end

    end    
end
 
y=sdc1; 


end

