function params = load_config()
    params = struct();
    
    params.total_capacity = 150;
    params.simulation_time = 50;
    params.base_num_users = 20;
    params.user_change_rate = 5;
    params.request_range = [1, 5];
    params.weight_range = [1, 10];
    params.fairness_threshold = 0.9;
    params.plot_smoothing = 5;
    
    params.room_size = [20, 20];
    params.wifi_ap_positions = [5, 15; 15, 15];
    params.vlc_ap_positions = [5, 5; 10, 10; 15, 5];
    params.wifi_coverage_radius = 12;
    params.vlc_coverage_radius = 4;
    params.wifi_capacity_ratio = 0.7;
    params.vlc_capacity_ratio = 0.3;
    params.wifi_capacity = params.total_capacity * params.wifi_capacity_ratio;
    params.vlc_capacity = params.total_capacity * params.vlc_capacity_ratio;
    params.handover_threshold = 0.15;
    params.user_velocity_range = [-0.25, 0.25];
    
    params.qos_weights = [0.4, 0.3, 0.2, 0.1];
    params.wifi_base_delay = 5;
    params.vlc_base_delay = 2;
    params.wifi_base_jitter = 2;
    params.vlc_base_jitter = 1;
    params.wifi_base_ber = 1e-6;
    params.vlc_base_ber = 5e-7;
end
