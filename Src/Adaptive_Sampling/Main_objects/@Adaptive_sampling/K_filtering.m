function X_filter = K_filtering( obj, x_new )
% K_FILTERING
% Method for gaussian process classes
% Select before evaluation relevent points by looking at reduction of MSE


if isa(obj.meta_y,'Kriging')
    
    for i = 1 : obj.m_y
        
        [ ~, mse_pred_temp(:,i) ] = obj.meta_y(i).Predict(x_new);
        
    end
    
    mse_pred_init = sum( mse_pred_temp, 2 );
    
    X_filter = Scale_data( x_new(1,:), obj.prob.lb, obj.prob.ub);
    Y_filter = 1;
    
    for i= 1 : obj.m_y
        krig_var_updated(i,:) = obj.meta_y(i,:).k_oodace.fit( ...
            [ obj.meta_y(i).x_train ; X_filter ], [ obj.prob.y(:,obj.y_ind(i)) ; Y_filter]);
    end
    
    for j = 2 : size(x_new,1)
        
        for i = 1 : obj.m_y
            [ ~, mse_current(:,i) ] = krig_var_updated(i).predict( x_new(j,:) );
        end
        mse_current = sum( mse_current, 2 );
        
        if ( mse_current / mse_pred_init(j) ) > 0.1
            
            X_filter = [ X_filter ; Scale_data(x_new(j,:), obj.prob.lb, obj.prob.ub) ];
            Y_filter = [ Y_filter ; 1 ];
            for i=1:obj.m_y
                krig_var_updated(i,:)=obj.meta_y(i,:).k_oodace.fit( ...
                    [ obj.meta_y(i).x_train ; X_filter ], ...
                    [ obj.prob.y(:,obj.y_ind(i)) ; Y_filter ]);
            end
        end
        
    end

    X_filter = Unscale_data( X_filter, obj.prob.lb, obj.prob.ub);

elseif isa(obj.meta_y,'Q_kriging')
    
    mse_pred_temp = zeros(size(x_new,1),prod(obj.prob.m_t));
    
    for i = 1 : prod(obj.prob.m_t)
        
        [ ~, mse_pred_temp(:,i) ] = obj.meta_y.Predict( x_new, repmat(i,size(x_new,1),1) );
        
    end
    
    mse_pred_init = sum( mse_pred_temp, 2 );
    [ ~, mod_init ] = max(mse_pred_temp(1,:));
    
    krig_upt = copy(obj.meta_y);
    krig_upt.Clean({'all'})
    num_x = zeros(1,prod(obj.prob.m_t));
    num_x(mod_init) = 1;
    q_val = obj.prob.t{1}(ind2subVect(obj.prob.m_t,mod_init));
    
    krig_upt.prob.Eval( num_x, [x_new(1,:), q_val] );
    krig_upt.Train();
    
    X_filter = [x_new(1,:), q_val];
    
    for j = 2 : size(x_new,1)
        
        mse_current = zeros(1,prod(obj.prob.m_t));
        
        for i = 1 : prod(obj.prob.m_t)
            
            [ ~, mse_current(i) ] = krig_upt.Predict( x_new(j,:), i );
            
        end
        
        sum_mse_current = sum( mse_current, 2 );
        
        if ( sum_mse_current / mse_pred_init(j) ) > 0.1
            
            [ ~, mod_current ] = max(mse_current);
            
            q_val = obj.prob.t{1}(ind2subVect(obj.prob.m_t,mod_current));
            num_x = zeros(1,prod(obj.prob.m_t));
            num_x(mod_current) = 1;
            
            krig_upt.Clean({'all'})
            krig_upt.prob.Eval( num_x, [x_new(j,:), q_val] );
            krig_upt.Train();
            
            X_filter = [ X_filter; [x_new(j,:),q_val] ];
            
        end
        
    end
    
else
    
    error('SBDO:Adaptive_sampling:k_filtering','Filtering method is only for Kriging and Q_kriging')
    
end

end