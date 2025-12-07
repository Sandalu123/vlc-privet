# VLC-WiFi Hybrid Network System - Code Explanation

**Version:** 2.0.1  
**System:** B5G/6G VLC-WiFi Hybrid Network with Uplink Support

---

## 1. CORE CONFIGURATION & SETUP

### load_config.m
**Location:** `config/load_config.m`  
**Purpose:** Central configuration file defining all system parameters

**Key Parameters:**
- Version: 2.0.1
- Total Capacity: 1000 Mbps
- Simulation Time: 50 steps
- Base Users: 20 (±5 variation)
- Room Size: 20m × 20m
- WiFi Capacity Ratio: 70% (downlink), 50% uplink ratio
- VLC Capacity Ratio: 30% (downlink), 50% uplink ratio
- Handover Threshold: 0.15
- QoS Weights: [0.4, 0.3, 0.2, 0.1] (Bandwidth, Delay, Jitter, BER)

**Service Profiles (B5G/6G Use Cases):**

| Service | Bandwidth (Mbps) | Max Latency (ms) | Max Jitter (ms) | Max BER | Priority |
|---------|------------------|------------------|-----------------|---------|----------|
| Web Browsing | 1-3 | 100 | 50 | 1e-5 | 1 |
| Video Streaming (4K) | 15-25 | 50 | 20 | 1e-6 | 5 |
| Online Gaming | 2-5 | 20 | 10 | 1e-5 | 7 |
| VR/AR | 50-100 | 10 | 5 | 1e-7 | 9 |
| Industrial Automation | 1-10 | 1 | 1 | 1e-9 | 10 |

**Service Distribution:** [30%, 30%, 20%, 10%, 10%]

---

## 2. NETWORK & USER GENERATION

### create_network.m
**Location:** `core/network/create_network.m`  
**Purpose:** Creates network structure with AP positions and coverage  
**Outputs:** Network struct with WiFi/VLC AP positions, coverage radii, capacities

**Network Configuration:**
- WiFi APs: 2 positions at [5,15], [15,15]
- VLC APs: 3 positions at [5,5], [10,10], [15,5]
- WiFi Coverage Radius: 12m
- VLC Coverage Radius: 4m

### create_hybrid_users.m
**Location:** `core/users/create_hybrid_users.m`  
**Purpose:** Generates users with dynamic position, service type, and QoS requirements

**Key Features:**
- User count varies sinusoidally: `base ± sin(t*0.2) * variation`
- Random positioning in 20m × 20m room
- Random velocity: ±0.25 m/step
- Service-based bandwidth assignment
- Downlink request: Based on service profile range
- Uplink request: 20-50% of downlink request
- Priority weight: From service profile (1-10)
- Initial network assignment (VLC if within coverage, else WiFi)

**User Properties:**
```matlab
- id, position, velocity
- service_type, weight
- request (downlink), request_ul (uplink)
- max_latency, max_jitter, max_ber
- current_network
- allocated_bandwidth, allocated_bandwidth_ul
```

### update_user_movement.m
**Location:** `core/users/update_user_movement.m`  
**Purpose:** Updates user positions with boundary reflection

---

## 3. HANDOVER MANAGEMENT

### perform_handover.m - PROPOSED FUZZY LOGIC ALGORITHM
**Location:** `core/network/perform_handover.m`  
**Purpose:** Implements fuzzy logic-based handover mechanism

**Algorithm Steps:**

1. **Find Available Networks:** Check WiFi and VLC coverage for each user
2. **Calculate QoS Metrics:**
   - Bandwidth: `max_bw * (1 - 0.7*dist/max_range) * (0.9-1.2 random)`
   - Delay: `base_delay + (dist/max_range)*10 + random*2`
   - Jitter: `base_jitter + (dist/max_range)*5 + random`
   - BER: `1e-6 * (1 + dist/max_range*10)`

3. **Apply Fuzzy Scoring:**
```matlab
function score = fuzzy_score(qos)
    bw_norm = min(1, max(0, qos.bandwidth / 30));
    delay_norm = max(0, min(1, 1 - qos.delay / 50));
    jitter_norm = max(0, min(1, 1 - qos.jitter / 20));
    ber_norm = max(0, min(1, 1 - log10(max(qos.ber, 1e-10)) / -3));
    
    weights = [0.4, 0.3, 0.2, 0.1];
    score = 0.4*bw_norm + 0.3*delay_norm + 0.2*jitter_norm + 0.1*ber_norm;
end
```

4. **Handover Decision:** `if best_score > current_score + threshold: handover`

---

## 4. RESOURCE ALLOCATION

### wwa_algorithm.m - PROPOSED WWA ALGORITHM
**Location:** `algorithms/allocation/wwa_algorithm.m`  
**Purpose:** Weight-weighted allocation with reduced dynamic range  
**Full Name:** Weight-based allocation with weighted unions

**Algorithm Steps:**

1. **Create Unions:**
   - Odd users (n=5): [r1+r5], [r2+r4], [2*r3]
   - Even users (n=4): [r1+r4], [r2+r3]

2. **Group Allocation:**
   - Sum each union's request rates
   - Allocate bandwidth proportionally: `(union_totals / total_demand) * capacity`

3. **User-Level Allocation:**
   - Within each group, distribute by user weight
   - Formula: `group_bw * (user_weight / group_weight_sum)`

4. **Request Capping:**
   - Cap allocation at user request: `min(allocation, request)`

**Union Creation Logic:**
```matlab
Odd (n=5):  [r1+r5], [r2+r4], [2*r3]
Even (n=4): [r1+r4], [r2+r3]
```

### allocate_resources.m
**Location:** `algorithms/allocation/allocate_resources.m`  
**Purpose:** Router function for resource allocation supporting downlink/uplink

**Supported Methods:**
- `wwa` - Weight-weighted allocation (proposed)
- Other allocation methods can be added

**Direction Support:** `'downlink'` or `'uplink'`

---

## 5. NETWORK SIMULATION CORE

### split_users_by_network.m
**Location:** `core/utils/split_users_by_network.m`  
**Purpose:** Separates users into WiFi (network_id=1) and VLC (network_id>1)

### merge_allocations.m
**Location:** `core/utils/merge_allocations.m`  
**Purpose:** Combines WiFi and VLC allocations back into user array  
**Supports:** Both downlink and uplink allocations

### record_results.m
**Location:** `core/utils/record_results.m`  
**Purpose:** Logs metrics per time step

**Metrics Tracked:**
- Handover count
- User distribution (WiFi/VLC)
- **Fairness Index (Downlink):** Jain's Fairness Index
- **Fairness Index (Uplink):** Jain's Fairness Index for uplink
- Average bandwidth allocation (downlink and uplink)

**Fairness Formula:**
```matlab
ratios = allocations ./ max(requests, 0.01);
fairness = (sum(ratios))^2 / (N * sum(ratios^2));
```

### initialize_results.m
**Location:** `core/utils/initialize_results.m`  
**Purpose:** Pre-allocates result arrays for simulation

---

## 6. MAIN SIMULATIONS

### baseline_simulation.m
**Location:** `simulation/baseline_simulation.m`  
**Purpose:** Baseline simulation (WWA + Fuzzy Handover, no RL)

**Workflow:**
1. Generate/update users at each time step
2. Perform fuzzy logic handover
3. Split users by network
4. Allocate resources (downlink and uplink separately)
5. Merge allocations
6. Record metrics
7. Repeat for 50 steps

**Supports:**
- Single simulation run
- Multiple runs for statistical analysis

### rl_enhanced_simulation.m
**Location:** `simulation/rl_enhanced_simulation.m`  
**Purpose:** RL-enhanced simulation using trained agent

**Key Difference:** Uses RL agent to select actions dynamically for network parameters

---

## 7. REINFORCEMENT LEARNING LAYER

### extract_state.m - RL STATE SPACE
**Location:** `algorithms/rl/extract_state.m`  
**Purpose:** Converts network conditions into 12-dimensional state vector

**State Components:**
```
state(1):  WiFi user ratio
state(2):  VLC user ratio
state(3):  Total user density (normalized to 30)
state(4):  WiFi demand ratio
state(5):  VLC demand ratio
state(6):  Current fairness index
state(7):  Mean user distance to nearest AP
state(8):  Handover frequency ratio
state(9):  Average allocation ratio
state(10): User density with coverage ratio
state(11): Fairness improvement trend
state(12): Handover frequency trend
```

All values normalized to [0, 1] or [0, 1.5] with NaN/Inf handling.

### calculate_reward.m - RL REWARD FUNCTION
**Location:** `algorithms/rl/calculate_reward.m`  
**Purpose:** Computes reward signal for RL agent

**Reward Components:**
```
Combined Fairness Reward: (DL_fairness + UL_fairness)/2 * 45
Handover Penalty: handovers * 35
Combined Throughput Reward: (DL_tput + UL_tput)/2 * 6
High Fairness Bonus: 8 or 15 (if >0.92 or >0.95)
High Throughput Bonus: 10, 25, or 40 (if >10, >12, or >15 Mbps)
Low Handover Bonus: 30 or 60 (if <20% or <10% handover rate)
```

**Range:** Clamped to [-200, 400]

### define_action_space_reduced.m - RL ACTION SPACE
**Location:** `algorithms/rl/define_action_space_reduced.m`  
**Purpose:** Defines 24 discrete actions (3×2×2×1×2)

**Action Parameters:**
- Handover Thresholds: [0.20, 0.25, 0.30] (3 values)
- WiFi Ratios: [0.60, 0.70] (2 values)
- Weight Max: [6, 8] (2 values)
- Allocation Method: ['wwa'] (1 value)
- QoS Presets: 2 different weight combinations

**Total Actions:** 3 × 2 × 2 × 1 × 2 = **24 actions**

### apply_rl_action.m
**Location:** `algorithms/rl/apply_rl_action.m`  
**Purpose:** Applies selected RL action to network parameters

**Modifies:**
- handover_threshold
- wifi_capacity_ratio / vlc_capacity_ratio
- weight_range
- qos_weights

---

## 8. RL AGENT

### QLearningAgent.m - Q-LEARNING IMPLEMENTATION
**Location:** `algorithms/rl/QLearningAgent.m`  
**Purpose:** Q-Learning agent with state discretization

**Key Components:**
- **Q-table:** `bins_per_dim^state_dim` table
- **State Discretization:** 4 key features (fairness, throughput, handovers, wifi demand)
- **Epsilon-greedy Policy:** For exploration-exploitation

**Q-Learning Update Formula:**
```
Q(s,a) ← Q(s,a) + α[r + γ·max_a'Q(s',a') - Q(s,a)]
```

**Key Methods:**
- `select_action()`: Epsilon-greedy action selection
- `update()`: TD update
- `discretize_state()`: Maps continuous state to table index
- `decay_epsilon()`: Reduces exploration over time
- `save/load()`: Checkpoint management
- `get_coverage()`: Q-table exploration coverage

**Hyperparameters:**
```matlab
learning_rate: 0.012
discount_factor (gamma): 0.97
epsilon_start: 1.0
epsilon_decay: 0.9995
epsilon_min: 0.05
bins_per_dim: 4
state_dim: 4 (key features)
```

---

## 9. TRAINING PIPELINE

### train_rl_agent.m
**Location:** `algorithms/rl/train_rl_agent.m`  
**Purpose:** Full training loop for RL agent with checkpoint selection

**Training Process (per episode):**
1. Create network and results array
2. For each time step:
   - Generate/update users
   - Extract state
   - Select action (ε-greedy)
   - Apply RL action
   - Perform handover & allocation (both DL/UL)
   - Record results
   - Calculate reward
   - Update Q-table
3. Decay epsilon
4. Save checkpoint every 5% of episodes

**Checkpoint Selection Process:**
1. Create 20 checkpoints throughout training
2. Calculate statistics (mean, std) for Fairness, Throughput, and Handovers from the exploitation phase (last 2000-3000 episodes)
3. Calculate Z-scores for each checkpoint: `Score = Z_Fairness + Z_Throughput - Z_Handovers`
   - Where `Z = (Value - Mean) / Std`
4. Select top 20 candidates based on Z-score
5. Re-evaluate each candidate with 10 simulation runs
6. Recalculate scores using the same Z-score normalization parameters
7. Display top candidates in table format
8. User selects best checkpoint interactively
9. Load selected checkpoint as final agent
10. Option to save as custom best model

**Training Outputs:**
- `output/data/trained_agent.mat`: Final trained Q-table
- `output/data/training_stats.mat`: Episode metrics
- `output/checkpoints/`: 20 checkpoint files
- `output/custom_checkpoint/best_model.mat`: Optional custom save

---

## 10. EVALUATION & ANALYSIS

### evaluate_system_performance.m
**Location:** `evaluation/evaluate_system_performance.m`  
**Purpose:** Comprehensive performance metric calculation

**Metrics Computed:**
- Mean/Std Fairness (DL and UL)
- Mean Throughput (DL and UL)
- Total/Average Handovers
- Average Users

### compare_all_methods.m
**Location:** `evaluation/compare_all_methods.m`  
**Purpose:** Compares different allocation methods and RL approaches

**Comparison Metrics:**
- Fairness (mean ± std)
- Throughput (mean ± std)
- Handovers (mean ± std)
- % Improvement calculations

### generate_comparison_report.m
**Location:** `evaluation/generate_comparison_report.m`  
**Purpose:** Generates detailed text report of comparisons

---

## 11. EXPERIMENTS

### experiment_wwa_only.m
**Location:** `experiments/experiment_wwa_only.m`  
**Purpose:** Dedicated WWA algorithm testing

### experiment_rl_training.m
**Location:** `experiments/experiment_rl_training.m`  
**Purpose:** RL training with configurable episodes

### experiment_full_comparison.m
**Location:** `experiments/experiment_full_comparison.m`  
**Purpose:** Compares WWA baseline vs RL-enhanced over multiple runs

**Outputs:** Comparison plots and statistical analysis

---

## 12. VISUALIZATION

### plot_simulation_results.m
**Location:** `visualization/plot_simulation_results.m`  
**Purpose:** 9-panel visualization of simulation results

**Panels:**
1. Fairness over time
2. User distribution (WiFi vs VLC)
3. Handover events
4. Fairness histogram
5. Average bandwidth allocation
6. Fairness vs handovers
7. Smoothed fairness
8. Network load distribution
9. Cumulative handovers

### plot_training_results.m
**Location:** `visualization/plot_training_results.m`  
**Purpose:** 6-panel RL training visualization

**Panels:**
1. Episode rewards
2. Average fairness per episode
3. Total handovers per episode
4. Epsilon decay
5. Smoothed rewards
6. Smoothed fairness

### create_comparison_plots.m
**Location:** `visualization/create_comparison_plots.m`  
**Purpose:** Comparison plots between methods

---

## 13. MAIN EXECUTION

### main_pipeline.m
**Location:** `main/main_pipeline.m`  
**Purpose:** Main execution orchestrator with interactive menu

**Operation Modes:**
1. Setup & Verify Environment
2. Run WWA Baseline Experiment
3. Train RL Agent
4. Run RL-Enhanced Simulation
5. Compare All Methods
6. Full Pipeline (All steps)
7. Exit

**Full Pipeline Workflow:**
1. WWA Baseline (10 runs)
2. RL Training (configurable episodes)
3. RL Evaluation (10 runs)
4. Full Comparison & Report

### setup_environment.m
**Location:** `main/setup_environment.m`  
**Purpose:** Validates all required files and tests basic functions

---

## KEY ALGORITHMS SUMMARY

### Fuzzy Logic-Based Dynamic Handover
- **File:** `core/network/perform_handover.m`
- **Algorithm:** Rule-based handover with fuzzy scoring
- **Formula:** `score = 0.4×bw_norm + 0.3×delay_norm + 0.2×jitter_norm + 0.1×ber_norm`
- **Decision:** `if best_score > current_score + threshold: handover`

### WWA (Weight-Weighted Allocation)
- **File:** `algorithms/allocation/wwa_algorithm.m`
- **Algorithm:** Fair resource allocation with dynamic range reduction
- **Key Steps:** Union creation → Group allocation → User-level allocation → Request capping
- **Union Formula:**
  - Odd (n=5): [r1+r5], [r2+r4], [2×r3]
  - Even (n=4): [r1+r4], [r2+r3]

### RL-Based Adaptive Resource Management
- **Files:** Multiple in `algorithms/rl/`
- **Algorithm:** Q-Learning with continuous state discretization
- **State Space:** 12-dimensional
- **Action Space:** 24 discrete actions
- **Reward:** Fairness + Utilization - Handovers - Instability

---

## FAIRNESS METRIC

**Location:** `core/utils/record_results.m`  
**Formula:** Jain's Fairness Index

```
F = (Σ ratios)² / (N × Σ ratios²)
where ratios_i = allocated_i / requested_i
```

**Properties:**
- Range: [0, 1]
- F = 1: Perfect fairness
- F → 0: High unfairness
- Applied separately for downlink and uplink

---

## UPLINK/DOWNLINK SUPPORT

**Key Changes in Version 2.0:**
- Separate uplink capacity (50% of downlink)
- Uplink requests (20-50% of downlink)
- Dual allocation in all simulations
- Separate fairness tracking for uplink
- Combined metrics in reward function

**Implementation:**
```matlab
wifi_alloc = allocate_resources(wifi_users, wifi_capacity, method, 'downlink');
wifi_alloc_ul = allocate_resources(wifi_users, wifi_capacity_ul, method, 'uplink');
users = merge_allocations(users, ..., wifi_alloc, vlc_alloc, wifi_alloc_ul, vlc_alloc_ul);
```

---

## CONFIGURATION PARAMETERS

**All configurable in `config/load_config.m`:**

**Network:**
- Total Capacity: 1000 Mbps
- WiFi Capacity Ratio: 70% (DL), 50% (UL)
- VLC Capacity Ratio: 30% (DL), 50% (UL)
- Room Size: 20m × 20m
- Coverage Radii: WiFi 12m, VLC 4m

**Simulation:**
- Simulation Time: 50 steps
- Base Users: 20 ± 5
- Service Probabilities: [0.3, 0.3, 0.2, 0.1, 0.1]

**Handover:**
- Handover Threshold: 0.15
- QoS Weights: [0.4, 0.3, 0.2, 0.1]

**RL Training:**
- Learning Rate (α): 0.012
- Discount Factor (γ): 0.97
- Epsilon Start: 1.0
- Epsilon Decay: 0.9995
- Epsilon Min: 0.05
- State Dimensions: 4 key features
- Bins per Dimension: 4

---

## PROJECT STRUCTURE

```
vlc-privet/
├── algorithms/
│   ├── allocation/
│   │   ├── allocate_resources.m
│   │   └── wwa_algorithm.m
│   └── rl/
│       ├── apply_rl_action.m
│       ├── calculate_reward.m
│       ├── define_action_space.m
│       ├── define_action_space_reduced.m
│       ├── extract_state.m
│       ├── QLearningAgent.m
│       └── train_rl_agent.m
├── config/
│   └── load_config.m
├── core/
│   ├── network/
│   │   ├── create_network.m
│   │   └── perform_handover.m
│   ├── users/
│   │   ├── create_hybrid_users.m
│   │   └── update_user_movement.m
│   └── utils/
│       ├── initialize_results.m
│       ├── merge_allocations.m
│       ├── record_results.m
│       └── split_users_by_network.m
├── evaluation/
│   ├── compare_all_methods.m
│   ├── evaluate_system_performance.m
│   └── generate_comparison_report.m
├── experiments/
│   ├── experiment_full_comparison.m
│   ├── experiment_rl_training.m
│   └── experiment_wwa_only.m
├── main/
│   ├── main_pipeline.m
│   └── setup_environment.m
├── simulation/
│   ├── baseline_simulation.m
│   └── rl_enhanced_simulation.m
├── visualization/
│   ├── create_comparison_plots.m
│   ├── plot_simulation_results.m
│   └── plot_training_results.m
└── output/
    ├── checkpoints/
    ├── custom_checkpoint/
    ├── data/
    ├── plots/
    └── reports/
```

---

## USAGE EXAMPLES

### Run Main Pipeline
```matlab
main_pipeline()
```

### Run Baseline Simulation
```matlab
results = baseline_simulation('wwa', 10);
```

### Train RL Agent
```matlab
config = struct('num_episodes', 1000, 'learning_rate', 0.012, ...
                'gamma', 0.97, 'epsilon_start', 1.0, ...
                'epsilon_decay', 0.9995, 'epsilon_min', 0.05);
[agent, stats] = train_rl_agent(config);
```

### Run RL-Enhanced Simulation
```matlab
load('output/data/trained_agent.mat', 'agent');
results = rl_enhanced_simulation(agent, 10);
```

---

**END OF DOCUMENT**
