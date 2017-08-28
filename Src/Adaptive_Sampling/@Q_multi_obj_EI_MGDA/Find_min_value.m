function [] = Find_min_value( obj )
% FIND_MIN_VALUE
% Find the actual minimum value of the optimization problem in the already evaluated points

    
% min_y is directly the min value
y_mat = cell2mat(obj.prob.y');
[obj.y_min, obj.loc_min] = min( y_mat( :, obj.y_ind ) );
    
% x value of the minimum
x_temp = cell2mat(obj.prob.x');
obj.x_min = x_temp( obj.loc_min , : ); 
    
obj.hist.y_min = [ obj.hist.y_min ; obj.y_min ];
obj.hist.x_min = [ obj.hist.x_min ; obj.x_min ];

end