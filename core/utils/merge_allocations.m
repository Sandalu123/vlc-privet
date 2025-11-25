function users = merge_allocations(users, wifi_users, vlc_users, wifi_alloc, vlc_alloc, wifi_alloc_ul, vlc_alloc_ul)
    wifi_idx = 1;
    vlc_idx = 1;
    
    for i = 1:length(users)
        if users(i).current_network == 1
            if wifi_idx <= length(wifi_alloc)
                users(i).allocated_bandwidth = wifi_alloc(wifi_idx);
                if nargin > 5
                    users(i).allocated_bandwidth_ul = wifi_alloc_ul(wifi_idx);
                end
                wifi_idx = wifi_idx + 1;
            end
        else
            if vlc_idx <= length(vlc_alloc)
                users(i).allocated_bandwidth = vlc_alloc(vlc_idx);
                if nargin > 5
                    users(i).allocated_bandwidth_ul = vlc_alloc_ul(vlc_idx);
                end
                vlc_idx = vlc_idx + 1;
            end
        end
    end
end
