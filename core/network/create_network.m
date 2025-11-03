function network = create_network(params)
    network = struct();
    network.room_size = params.room_size;
    network.wifi_ap_positions = params.wifi_ap_positions;
    network.vlc_ap_positions = params.vlc_ap_positions;
    network.wifi_coverage_radius = params.wifi_coverage_radius;
    network.vlc_coverage_radius = params.vlc_coverage_radius;
    network.total_capacity = params.total_capacity;
    network.wifi_capacity = params.wifi_capacity;
    network.vlc_capacity = params.vlc_capacity;
end
