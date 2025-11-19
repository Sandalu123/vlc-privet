# VLC-WiFi Hybrid Network Simulation Documentation

## Project Overview
This project simulates a hybrid network combining Visible Light Communication (VLC) and WiFi technologies. It aims to optimize resource allocation and user handover between these two networks using various algorithms, including a Reinforcement Learning (RL) approach.

## Directory Structure

- **main/**: Contains the entry points for the simulation.
  - `main_pipeline.m`: The main script to run different modes of the simulation (Setup, Baselines, Training, Evaluation).
  - `setup_environment.m`: Sets up the MATLAB environment.
- **config/**: Configuration files.
  - `load_config.m`: Defines simulation parameters such as room size, AP positions, capacities, and user behavior.
- **core/**: Core simulation logic.
  - **network/**: Network topology creation (`create_network.m`) and handover logic (`perform_handover.m`).
  - **users/**: User generation and movement (`generate_hybrid_users.m`, `update_user_movement.m`).
  - **utils/**: Utility functions for results recording and data processing.
- **algorithms/**: Resource allocation algorithms.
  - **allocation/**: Baseline algorithms (`allocate_resources.m`, `wwa_algorithm.m`, `proportional_algorithm.m`).
  - **rl/**: Reinforcement Learning implementation (`QLearningAgent.m`, `train_rl_agent.m`, `apply_rl_action.m`).
- **simulation/**: Simulation runners.
  - `baseline_simulation.m`: Runs simulations using baseline algorithms.
  - `rl_enhanced_simulation.m`: Runs simulations using the trained RL agent.
- **evaluation/**: Scripts for comparing and evaluating different methods.
  - `compare_all_methods.m`: Compares WWA, Proportional, and RL methods.
  - `generate_comparison_report.m`: Generates a report of the comparison results.
- **experiments/**: Specific experiment scripts.
- **visualization/**: Plotting and visualization scripts.

## Key Modules

### Main Pipeline
The `main_pipeline.m` script provides a menu-driven interface to execute various parts of the project. It supports:
1.  **Setup & Verification**: Verifies the environment.
2.  **Baseline Experiments**: Runs WWA and Proportional allocation experiments.
3.  **RL Training**: Trains the Q-Learning agent.
4.  **RL-Enhanced Simulation**: Runs the simulation with the trained agent.
5.  **Comparison**: Compares all methods and generates reports.

### Configuration
The `load_config.m` file is central to the simulation setup. It defines:
- **Network Parameters**: Capacities, coverage radii, delays, jitters, BERs.
- **Environment**: Room size, AP positions.
- **Service Profiles (QoS)**:
    - **Web Browsing**: Standard internet usage (Priority 1).
    - **Video Streaming (4K)**: High bandwidth eMBB (Priority 5).
    - **Online Gaming**: Low latency (Priority 7).
    - **VR/AR**: High bandwidth & low latency, Beyond 5G (Priority 9).
    - **Industrial Automation**: Ultra-Reliable Low Latency (URLLC), Beyond 5G (Priority 10).
- **User Dynamics**: Number of users, velocity.
- **Simulation Settings**: Duration, time steps.

### Algorithms
1.  **WWA (Weighted Water Filling)**: Allocates resources based on user weights and channel conditions.
2.  **Reinforcement Learning (Q-Learning)**:
    - **State Space**: User distribution, network load, etc.
    - **Action Space**: Adjusting handover thresholds, power levels, etc.
    - **Reward Function**: Based on fairness, throughput, and handover cost.

## Usage

1.  **Start the Simulation**: Run `main_pipeline.m` in MATLAB.
2.  **Select Mode**: Choose an option from the menu (e.g., "Train RL Agent" or "Compare All Methods").
3.  **View Results**: Results are saved in the `output/` directory, including plots and data files.

## Simulation Flow
1.  **Initialization**: Load config, create network, generate users.
2.  **Time Stepping**:
    - Update user positions.
    - Perform handovers (assign users to WiFi or VLC).
    - Allocate resources (WiFi and VLC).
    - Record metrics (Fairness, Throughput, Handovers).
3.  **Completion**: Aggregate results and generate plots/reports.
