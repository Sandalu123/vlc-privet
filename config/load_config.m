function params = load_config()
    params = struct();
    
    params.version = '2.0.1';
    params.total_capacity = 1000; % Increased for B5G scenarios
    params.simulation_time = 50;
    params.base_num_users = 20;
    params.user_change_rate = 5;
    % params.request_range and params.weight_range are replaced by service profiles
    params.fairness_threshold = 0.9;
    params.plot_smoothing = 5;
    
    % Define Service Profiles (QoS Requirements)
    % [Min Bandwidth (Mbps), Max Latency (ms), Max Jitter (ms), Max BER, Priority]
    params.services = struct();
    
    % 1. Web Browsing (Standard Internet Activity)
    params.services.web_browsing.name = 'Web Browsing';
    params.services.web_browsing.bandwidth_range = [1, 3];
    params.services.web_browsing.max_latency = 100;
    params.services.web_browsing.max_jitter = 50;
    params.services.web_browsing.max_ber = 1e-5;
    params.services.web_browsing.priority = 1;
    
    % 2. Video Streaming 4K (eMBB - Enhanced Mobile Broadband)
    params.services.video_streaming.name = 'Video Streaming (4K)';
    params.services.video_streaming.bandwidth_range = [15, 25];
    params.services.video_streaming.max_latency = 50;
    params.services.video_streaming.max_jitter = 20;
    params.services.video_streaming.max_ber = 1e-6;
    params.services.video_streaming.priority = 5;
    
    % 3. Online Gaming (Low Latency)
    params.services.online_gaming.name = 'Online Gaming';
    params.services.online_gaming.bandwidth_range = [2, 5];
    params.services.online_gaming.max_latency = 20;
    params.services.online_gaming.max_jitter = 10;
    params.services.online_gaming.max_ber = 1e-5;
    params.services.online_gaming.priority = 7;
    
    % 4. VR/AR (Beyond 5G - High Bandwidth & Low Latency)
    params.services.vr_ar.name = 'VR/AR';
    params.services.vr_ar.bandwidth_range = [50, 100]; % High demand
    params.services.vr_ar.max_latency = 10;
    params.services.vr_ar.max_jitter = 5;
    params.services.vr_ar.max_ber = 1e-7;
    params.services.vr_ar.priority = 9;
    
    % 5. Industrial Automation (URLLC - Ultra-Reliable Low Latency)
    params.services.industrial.name = 'Industrial Automation';
    params.services.industrial.bandwidth_range = [1, 10];
    params.services.industrial.max_latency = 1; % Ultra low
    params.services.industrial.max_jitter = 1;
    params.services.industrial.max_ber = 1e-9;
    params.services.industrial.priority = 10;

    % Probability distribution for user generation (must sum to 1)
    % [Web, Video, Gaming, VR/AR, Industrial]
    params.service_probabilities = [0.3, 0.3, 0.2, 0.1, 0.1]; 
    
    params.room_size = [20, 20];
    params.wifi_ap_positions = [5, 15; 15, 15];
    params.vlc_ap_positions = [5, 5; 10, 10; 15, 5];
    params.wifi_coverage_radius = 12;
    params.vlc_coverage_radius = 4;
    params.wifi_capacity_ratio = 0.7;
    params.vlc_capacity_ratio = 0.3;
    params.wifi_capacity = params.total_capacity * params.wifi_capacity_ratio;
    params.vlc_capacity = params.total_capacity * params.vlc_capacity_ratio;
    
    % Uplink Capacity (50% of Downlink)
    params.wifi_capacity_ul = params.wifi_capacity * 0.5;
    params.vlc_capacity_ul = params.vlc_capacity * 0.5;
    params.handover_threshold = 0.15;
    params.user_velocity_range = [-0.25, 0.25];
    
    % Handover Calculation Parameters (VLC/WiFi AP Characteristics)
    params.qos_weights = [0.4, 0.3, 0.2, 0.1];
    params.wifi_base_delay = 5;
    params.vlc_base_delay = 2;
    params.wifi_base_jitter = 2;
    params.vlc_base_jitter = 1;
    params.wifi_base_ber = 1e-6;
    params.vlc_base_ber = 5e-7;
end
