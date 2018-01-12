function [ EI_euclid ] = Obj_func_EI_euclid( obj, x_test )
%OBJ_FUNC_EHVI 
%   Objective function for local optimization of EI_euclid

for i = 1 : obj.m_y
    
    [ y_pred(:,i), MSE_pred(:,i) ] = obj.meta_y(i,:).Predict( x_test );
    
end

EI_euclid = -obj.EI_euclid(y_pred, sqrt(abs( MSE_pred )), obj.y_pareto_temp, obj.y_ref_temp);






% ==========================================================================
%
%    This file is part of SBDOT.
%
%    SBDOT is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    SBDOT is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with SBDOT.  If not, see <http://www.gnu.org/licenses/>.
%
%    Use of SBDOT is free for personal, non-profit, pure academic research
%    and educational purposes. Restrictions apply on commercial or funded
%    research use. Please read the IMPORTANT_LICENCE_NOTICE file.
%
% ==========================================================================


