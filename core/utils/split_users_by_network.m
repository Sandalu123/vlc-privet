function [wifi_users, vlc_users] = split_users_by_network(users)
    wifi_users = users([users.current_network] == 1);
    vlc_users = users([users.current_network] > 1);
end
