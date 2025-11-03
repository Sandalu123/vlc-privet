function users = update_user_movement(users, params, network)
    for i = 1:length(users)
        users(i).x = users(i).x + users(i).velocity(1);
        users(i).y = users(i).y + users(i).velocity(2);
        
        if users(i).x < 0 || users(i).x > network.room_size(1)
            users(i).velocity(1) = -users(i).velocity(1);
            users(i).x = max(0, min(network.room_size(1), users(i).x));
        end
        if users(i).y < 0 || users(i).y > network.room_size(2)
            users(i).velocity(2) = -users(i).velocity(2);
            users(i).y = max(0, min(network.room_size(2), users(i).y));
        end
        
        users(i).position = [users(i).x, users(i).y];
    end
end
