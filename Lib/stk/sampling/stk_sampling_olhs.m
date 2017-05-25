% STK_SAMPLING_OLHS generates a random Orthogonal Latin Hypercube (OLH) sample
%
% CALL: X = stk_sampling_olhs (N)
%
%    generates a random Orthogonal Latin Hypercube (OLH) sample X, using the
%    construction of Ye (1998). The algorithm only works for sample sizes N
%    of the form 2^(R+1)+1, with R >= 1. Trying to generate an OLHS with a
%    value of N that is not of this form generates an error. The number of
%    factors is D = 2*R, and the OLHS is defined on [-1; 1]^D.
%
% CALL: X = stk_sampling_olhs (N, D)
%
%    does exactly the same thing, provided that there exists an integer R
%    such that N = 2^(R+1)+1 and D = 2*R (or D is empty).
%
% CALL: X = stk_sampling_olhs (N, D, BOX)
%
%    generates an OLHS on BOX. Again, D can be empty since the number of
%    factors can be deduced from N.
%
% CALL: X = stk_sampling_olhs (N, D, BOX, PERMUT)
%
%    uses a given permutation PERMUT, instead of a random permutation, to
%    initialize the construction of Ye (1998). As a result, the generated
%    OLHS is not random anymore. PERMUT must be a permutation of 1:2^R. If
%    BOX is empty, then the default domain [-1, 1]^D is used.
%
% NOTE: orthogonality
%
%    The samples generated by this functions are only orthogonal, stricty-
%    speaking, if BOX is a symmetric domain (e.g., [-1, 1] ^ D). Otherwise,
%    the generated samples should be called "uncorrelated".
%
% REFERENCE
%
%    Kenny Q. Ye, "Orthogonal Column Latin Hypercubes and Their
%    Application in Computer Experiments", Journal of the American
%    Statistical Association, 93(444), 1430-1439, 1998.
%    http://dx.doi.org/10.1080/01621459.1998.10473803
%
% See also: stk_sampling_randomlhs, stk_sampling_maximinlhs

% Copyright Notice
%
%    Copyright (C) 2017 CentraleSupelec
%    Copyright (C) 2012-2014 SUPELEC
%
%    Author:  Julien Bect  <julien.bect@centralesupelec.fr>

% Copying Permission Statement
%
%    This file is part of
%
%            STK: a Small (Matlab/Octave) Toolbox for Kriging
%               (http://sourceforge.net/projects/kriging)
%
%    STK is free software: you can redistribute it and/or modify it under
%    the terms of the GNU General Public License as published by the Free
%    Software Foundation,  either version 3  of the License, or  (at your
%    option) any later version.
%
%    STK is distributed  in the hope that it will  be useful, but WITHOUT
%    ANY WARRANTY;  without even the implied  warranty of MERCHANTABILITY
%    or FITNESS  FOR A  PARTICULAR PURPOSE.  See  the GNU  General Public
%    License for more details.
%
%    You should  have received a copy  of the GNU  General Public License
%    along with STK.  If not, see <http://www.gnu.org/licenses/>.

function [x, aux] = stk_sampling_olhs (n, d, box, permut, extended)

if nargin > 5,
    stk_error ('Too many input arguments.', 'TooManyInputArgs');
end

% Read argument dim
if (nargin < 2) || ((nargin < 3) && (isempty (d)))
    d = 1;  % Default dimension
elseif (nargin > 2) && (~ isempty (box))
    d = size (box, 2);
end

if nargin < 5, extended = false; end

%%% PROCESS INPUT ARGUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recover the "order" r from the value of n
r = floor(log2(n - 1) - 1);
n_ = 2^(r + 1) + 1;
if (r <= 0) || (abs(n - n_) > eps),
    errmsg = 'n must be an integer of the form 2^(r+1) + 1 with r > 0';
    stk_error(errmsg, 'IncorrectArgument');
end
n = n_;

if ~extended
    % check that d has the correct value for a "full" Ye98-OLHS
    % (other values of d can be reached by removing columns from a full OLHS)
    if (nargin > 1) && ~isempty(d),
        if d ~= 2 * r,
            errmsg = 'Incorrect value of d, please read the documentation...';
            stk_error(errmsg, 'IncorrectArgument');
        end
    else
        d = 2 * r;
    end
else
    % check that d has the correct value for a "full" Cioppa-Lucas(2007) NOLHS
    % (other values of d can be reached by removing columns from a full NOLHS)
    if (nargin > 1) && ~isempty(d),
        if d ~= r + 1 + nchoosek(r, 2),
            errmsg = 'Incorrect value of d, please read the documentation...';
            stk_error(errmsg, 'IncorrectArgument');
        end
    else
        d = r + 1 + nchoosek(r, 2);
    end
end

% number of "positive levels"
q = 2^r; % = (n - 1)/2

% read argument 'box'
if (nargin < 3) || isempty (box)
    box = stk_hrect (repmat ([-1; 1], 1, d));  % build a default box
else
    box = stk_hrect (box);  % convert input argument to a proper box
end

% permutation
if (nargin < 4) || isempty(permut),
    permut = randperm(q)';
else
    permut = permut(:);
    if ~isequal(sort(permut), (1:q)'),
        errmsg = sprintf('permut should be a permutation of 1:%d.', q);
        stk_error(errmsg, 'IncorrectArgument');
    end
end

%%% CONSTRUCT AN "ORTHOGONAL" LHS FOLLOWING PROCESS INPUT ARGUMENTS %%%%%%%%%%%

% Construct permutation matrices A1, A2, ..., Ar
A = cell(1, r);
for i = 1:r,
    Ai = 1;
    for j = 1:i,
        Z  = zeros(size(Ai));
        Ai = [Z Ai; Ai Z]; %#ok<AGROW>
    end
    for j = (i+1):r,
        Z  = zeros(size(Ai));
        Ai = [Ai Z; Z Ai]; %#ok<AGROW>
    end
    A{i} = Ai;
end

% Construct the matrix M
M = [permut zeros(q, 2*r-1)];
for j = 1:r, % from column 2 to column r+1
    M(:, j+1) = A{j} * permut;
end
if ~extended, % OLHS / Ye (1998)
    for j = 1:(r-1), % from column r+2 to column 2*r
        M(:, j+r+1) = A{j} * A{r} * permut;
    end
else % NOLHS / Cioppa & Lucas(2007)
    col = r + 2;
    for j = 1:(r-1),
        for k = (j + 1):r,
            M(:, col) = A{j} * A{k} * permut;
            col = col + 1;
        end
    end
end

% Construct the matrix S
S = ones(q, 2*r);
for j = 1:r, % from column 2 to column r+1
    aj = 1;
    for l = r:(-1):1,
        if l == r - j + 1,
            aj = [-aj; aj]; %#ok<AGROW>
        else
            aj = [aj; aj]; %#ok<AGROW>
        end
    end
    S(:, j+1) = aj;
end
if ~extended, % OLHS / Ye (1998)
    for j = 1:(r-1), % from column r+2 to column 2*r
        S(:, r+1+j) = S(:, 2) .* S(:, j+2);
    end
else % NOLHS / Cioppa & Lucas(2007)
    col = r + 2;
    for j = 1:(r - 1),
        for k = (j + 1):r,
            S(:, col) = S(:, j+1) .* S(:, k+1);
            col = col + 1;
        end
    end
end

% Construct the matrix T
T = M .* S;

% Construct the OLHS X (with integer levels -q, ..., 0, ... +q)
x_integer_levels = [T; zeros(1, d); -T];

%%% CONVERT TO THE REQUESTED BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert to positive integer levels (1 ... n)
x = x_integer_levels + q + 1;

% Convert to [0; 1]-valued levels
x = (2*x - 1) / (2*n);

% And, finally, convert to box
x = stk_dataframe (stk_rescale (x, [], box), box.colnames);

% Note: the results reported in Cioppa & Lucas correspond to the scaling
%   x = struct('a', stk_rescale(x, [min(x); max(x)], box));

%%% OUTPUT SOME AUXILIARY DATA IF REQUESTED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout > 1,
    aux = struct('M', M, 'S', S, 'X', x_integer_levels);
end

end % function


%%
% Check error for incorrect number of input arguments

%!shared x, n, d, box, permut
%! n = 5; d = 2; box = [0 0; 1, 1]; permut = 1:2;

%!error x = stk_sampling_olhs();
%!test  x = stk_sampling_olhs(n);
%!test  x = stk_sampling_olhs(n, d);
%!test  x = stk_sampling_olhs(n, d, box);
%!test  x = stk_sampling_olhs(n, d, box, permut);
%!error x = stk_sampling_olhs(n, d, box, permut, pi);

%%
% Check that the output is a dataframe
% (all stk_sampling_* functions should behave similarly in this respect)

%!assert (isa (x, 'stk_dataframe'));

%%
% Check that column names are properly set, if available in box

%!assert (isequal (x.colnames, {}));

%!test
%! cn = {'W', 'H'};  box = stk_hrect (box, cn);
%! x = stk_sampling_olhs (n, d, box);
%! assert (isequal (x.colnames, cn));

%%
% Check output argument

%!test
%! for r = 1:5
%!
%!   n = 2 ^ (r + 1) + 1;  d = 2 * r;
%!   x = stk_sampling_olhs (n, d);
%!
%!   assert (isequal (size (x), [n d]));
%!
%!   box = repmat ([-1; 1], 1, d);
%!   assert (stk_is_lhs (x, n, d, box));
%!
%!   x = double (x);  w = x' * x;
%!   assert (stk_isequal_tolabs (w / w(1,1), eye (d)));
%!
%! end