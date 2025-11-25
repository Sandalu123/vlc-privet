% Test Uplink Allocation
clc; clear; warning('off', 'all');
addpath('config');
addpath('core/network');
addpath('core/users');
addpath('core/utils');
addpath('algorithms/allocation');

params = load_config();
network = create_network(params);
users = generate_hybrid_users(params, network, 1);

fprintf('Checking Uplink Configuration:\n');
fprintf('WiFi DL Capacity: %.2f\n', params.wifi_capacity);
fprintf('WiFi UL Capacity: %.2f\n', params.wifi_capacity_ul);
fprintf('VLC DL Capacity: %.2f\n', params.vlc_capacity);
fprintf('VLC UL Capacity: %.2f\n', params.vlc_capacity_ul);

if params.wifi_capacity_ul == params.wifi_capacity * 0.5
    fprintf('✓ Uplink Capacity is 50%% of Downlink\n');
else
    fprintf('✗ Uplink Capacity Incorrect\n');
end

fprintf('\nChecking User Requests:\n');
fprintf('User 1 DL Request: %.2f\n', users(1).request);
fprintf('User 1 UL Request: %.2f\n', users(1).request_ul);

if users(1).request_ul > 0
    fprintf('✓ Uplink Request Generated\n');
else
    fprintf('✗ Uplink Request Missing\n');
end

% Test Allocation
[wifi_users, vlc_users] = split_users_by_network(users);
wifi_alloc_ul = allocate_resources(wifi_users, params.wifi_capacity_ul, 'wwa', 'uplink');
vlc_alloc_ul = allocate_resources(vlc_users, params.vlc_capacity_ul, 'wwa', 'uplink');

users = merge_allocations(users, wifi_users, vlc_users, [], [], wifi_alloc_ul, vlc_alloc_ul);

fprintf('\nChecking Allocation:\n');
fprintf('User 1 UL Allocation: %.2f\n', users(1).allocated_bandwidth_ul);

if users(1).allocated_bandwidth_ul >= 0
    fprintf('✓ Uplink Allocation Successful\n');
else
    fprintf('✗ Uplink Allocation Failed\n');
end
